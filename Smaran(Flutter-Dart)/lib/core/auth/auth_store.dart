import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_languages.dart';
import 'auth_models.dart';
import 'auth_service.dart';
import 'patient_id.dart';
import 'pre_home_state.dart';

class AuthStore extends ChangeNotifier {
  AuthStore._();
  static final AuthStore instance = AuthStore._();

  static const _kUsers = 'auth_users_v1';
  static const _kSession = 'auth_session_v1';
  static const _kLanguage = 'auth_language_v1';
  static const _kLastUserId = 'auth_last_user_v1';
  static const _kPhase = 'auth_phase_v1';
  static const _kPendingRole = 'auth_pending_role_v1';
  static const _kOtpMethod = 'auth_otp_method_v1';

  AppUser? _currentUser;
  AuthSession? _session;
  AppLanguage _preferredLanguage = AppLanguage.english;
  bool _booted = false;
  bool _hasChosenLanguage = false;

  OnboardingPhase _phase = OnboardingPhase.none;
  UserRole? _pendingRole;
  String? _otpMethod;
  String? _lastUserId;

  // ── Getters ──────────────────────────────────────────────────
  AppUser? get currentUser => _currentUser;
  AuthSession? get session => _session;
  AppLanguage get preferredLanguage => _preferredLanguage;
  bool get isBooted => _booted;
  bool get isLoggedIn => _currentUser != null && _session != null;
  bool get hasChosenLanguage => _hasChosenLanguage;

  OnboardingPhase get phase => _phase;
  UserRole? get pendingRole => _pendingRole;
  String? get otpMethod => _otpMethod;

  AppUser? get lastKnownUser => _lastUserId == null
      ? null
      : AuthService.instance.findById(_lastUserId!);

  // ── Boot ─────────────────────────────────────────────────────
  Future<void> boot() async {
    final prefs = await SharedPreferences.getInstance();

    final rawUsers = prefs.getString(_kUsers);
    if (rawUsers != null) {
      try {
        final list = (jsonDecode(rawUsers) as List)
            .whereType<Map>()
            .map((e) => AppUser.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        AuthService.instance.hydrateUsers(list);
      } catch (_) {}
    }

    final rawSession = prefs.getString(_kSession);
    if (rawSession != null) {
      try {
        final s = AuthSession.fromJson(
          Map<String, dynamic>.from(jsonDecode(rawSession) as Map),
        );
        if (!s.isExpired) {
          _session = s;
          _currentUser = AuthService.instance.findById(s.userId);
        } else {
          await prefs.remove(_kSession);
        }
      } catch (_) {}
    }

    final rawLang = prefs.getString(_kLanguage);
    _hasChosenLanguage = rawLang != null;
    _preferredLanguage = parseLanguage(rawLang);

    _lastUserId = prefs.getString(_kLastUserId);
    _phase = OnboardingPhaseX.fromKey(prefs.getString(_kPhase));

    final rawRole = prefs.getString(_kPendingRole);
    if (rawRole != null) {
      _pendingRole = UserRole.values.firstWhere(
        (r) => r.name == rawRole,
        orElse: () => UserRole.patient,
      );
    }

    _otpMethod = prefs.getString(_kOtpMethod);

    // Resume mid-registration if the app was killed after account creation
    // but before OTP verification.
    if (_currentUser == null &&
        _lastUserId != null &&
        (_phase == OnboardingPhase.otpMethod ||
            _phase == OnboardingPhase.otpEntry)) {
      _currentUser = AuthService.instance.findById(_lastUserId!);
    }

    _booted = true;
    notifyListeners();
  }

  // ── Phase management ────────────────────────────────────────
  Future<void> setPhase(OnboardingPhase p) async {
    _phase = p;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPhase, p.name);
  }

  Future<void> setPendingRole(UserRole? role) async {
    _pendingRole = role;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (role == null) {
      await prefs.remove(_kPendingRole);
    } else {
      await prefs.setString(_kPendingRole, role.name);
    }
  }

  Future<void> setOtpMethod(String? method) async {
    _otpMethod = method;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (method == null) {
      await prefs.remove(_kOtpMethod);
    } else {
      await prefs.setString(_kOtpMethod, method);
    }
  }

  // ── Language ─────────────────────────────────────────────────
  Future<void> setLanguage(AppLanguage language) async {
    _preferredLanguage = language;
    _hasChosenLanguage = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, language.key);

    final user = _currentUser;
    if (user != null) {
      _currentUser = user.copyWith(
        preferredLanguage: language,
        updatedAt: DateTime.now(),
      );
      await _persistUsers();
    }
  }

  // ── Registration ─────────────────────────────────────────────
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    DateTime? dateOfBirth,
    String? trustedContactName,
    String? trustedContactPhone,
    String? pin,
    String? relationship,
  }) async {
    final user = await AuthService.instance.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      role: role,
      preferredLanguageKey: _preferredLanguage.key,
      dateOfBirth: dateOfBirth,
      trustedContactName: trustedContactName,
      trustedContactPhone: trustedContactPhone,
      pin: pin,
      relationship: relationship,
    );

    _currentUser = user;
    _lastUserId = user.id;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastUserId, user.id);

    notifyListeners();
    await _persistUsers();
    return user;
  }

  // ── Login ────────────────────────────────────────────────────
  Future<AppUser> login({
    required String contact,
    required String password,
  }) async {
    final user = await AuthService.instance.login(
      contact: contact,
      password: password,
    );

    _currentUser = user;
    _session = AuthService.instance.issueSession(user.id);
    _lastUserId = user.id;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastUserId, user.id);

    notifyListeners();
    await _persistUsers();
    await _persistSession();
    return user;
  }

  Future<AppUser> loginWithPin({
    required String contact,
    required String pin,
  }) async {
    final user = await AuthService.instance.loginWithPin(
      contact: contact,
      pin: pin,
    );

    _currentUser = user;
    _session = AuthService.instance.issueSession(user.id);
    _lastUserId = user.id;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastUserId, user.id);

    notifyListeners();
    await _persistUsers();
    await _persistSession();
    return user;
  }

  /// Reissues a session for an already-verified user.
  /// Called only after biometric success — the biometric is the trust boundary.
  Future<void> reissueSessionFor(String userId) async {
    final user = AuthService.instance.findById(userId);
    if (user == null) throw AuthException('Account not found.');
    _currentUser = user;
    _session = AuthService.instance.issueSession(userId);
    notifyListeners();
    await _persistSession();
  }

  // ── OTP ──────────────────────────────────────────────────────
  Future<bool> verifyOtp({required String code}) async {
    final user = _currentUser;
    if (user == null) throw AuthException('No pending registration.');

    final ok = await AuthService.instance.verifyOtp(
      userId: user.id,
      code: code,
    );

    _currentUser = AuthService.instance.findById(user.id) ?? user;

    if (ok) {
      _session = AuthService.instance.issueSession(_currentUser!.id);
      await _persistSession();
    }

    notifyListeners();
    await _persistUsers();
    return ok;
  }

  Future<void> resendOtp() async {
    final user = _currentUser;
    if (user == null) throw AuthException('No pending registration.');
    await AuthService.instance.resendOtp(user.id);
  }

  // ── Password recovery ────────────────────────────────────────
  Future<String> startPasswordReset(String contact) async {
    return AuthService.instance.startPasswordReset(contact);
  }

  Future<void> completePasswordReset({
    required String userId,
    required String newPassword,
  }) async {
    await AuthService.instance.completePasswordReset(
      userId: userId,
      newPassword: newPassword,
    );
    await _persistUsers();
  }

  // ── Biometric / face photo ───────────────────────────────────
  Future<void> setBiometricEnrolled(bool value) async {
    final user = _currentUser;
    if (user == null) return;
    _currentUser = user.copyWith(biometricEnrolled: value);
    notifyListeners();
    await _persistUsers();
  }

  Future<void> setFacePhoto(String base64Jpeg) async {
    final user = _currentUser;
    if (user == null) return;
    _currentUser = user.copyWith(facePhotoBase64: base64Jpeg);
    notifyListeners();
    await _persistUsers();
  }

  Future<void> clearFacePhoto() async {
    final user = _currentUser;
    if (user == null) return;
    _currentUser = user.copyWith(facePhotoBase64: null);
    notifyListeners();
    await _persistUsers();
  }

  // ── Logout ───────────────────────────────────────────────────
  Future<void> logout() async {
    _currentUser = null;
    _session = null;
    _phase = OnboardingPhase.none;
    _pendingRole = null;
    _otpMethod = null;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSession);
    await prefs.remove(_kPhase);
    await prefs.remove(_kPendingRole);
    await prefs.remove(_kOtpMethod);
    // _kLastUserId is intentionally retained for session recovery.
  }

  /// Forget the last known account entirely (used by "Use a different account").
  Future<void> clearLastUser() async {
    _lastUserId = null;
    _currentUser = null;
    _session = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastUserId);
    await prefs.remove(_kSession);
  }

  // ─────────────────────────────────────────────────────────────
  // LINKED PATIENTS
  // ─────────────────────────────────────────────────────────────

  List<AppUser> get linkedPatients {
    final user = _currentUser;
    if (user == null) return const [];

    if (user.role == UserRole.patient) return [user];

    return AuthService.instance.resolvePatients(user.linkedPatientIds);
  }

  Future<void> linkPatientById(String rawId) async {
    final user = _currentUser;
    if (user == null) throw AuthException('You are not signed in.');
    if (!PatientId.isValid(rawId)) {
      throw AuthException(
        'Please enter a valid ID in the format SMRN-XXXX-XXXX.',
      );
    }

    final updated = await AuthService.instance.linkPatient(
      caregiverUserId: user.id,
      patientIdRaw: rawId,
    );

    _currentUser = updated;
    notifyListeners();
    await _persistUsers();
  }

  Future<bool> linkPatientBySmrnId(String rawId) async {
    try {
      await linkPatientById(rawId);
      return true;
    } on AuthException catch (e) {
      if (e.message.contains('maximum')) rethrow;
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> unlinkPatientById(String rawId) async {
    final user = _currentUser;
    if (user == null) return;

    final updated = await AuthService.instance.unlinkPatient(
      caregiverUserId: user.id,
      patientIdRaw: rawId,
    );

    _currentUser = updated;
    notifyListeners();
    await _persistUsers();
  }

  Future<void> ensurePatientId() async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.patient) return;
    if (user.patientId != null) return;

    final newId = PatientId.generate();
    final updated = user.copyWith(patientId: newId);
    _currentUser = updated;
    notifyListeners();
    await _persistUsers();
  }

  // ── Persist ──────────────────────────────────────────────────
  Future<void> _persistUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      AuthService.instance.exportUsers().map((u) => u.toJson()).toList(),
    );
    await prefs.setString(_kUsers, raw);
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    final s = _session;
    if (s == null) {
      await prefs.remove(_kSession);
      return;
    }
    await prefs.setString(_kSession, jsonEncode(s.toJson()));
  }

  Future<void> updateCurrentUser(AppUser updated) async {
    _currentUser = updated;
    notifyListeners();
    await _persistUsers();
  }
}