import 'dart:math';

import '../localization/app_languages.dart';
import 'auth_models.dart';
import 'patient_id.dart';

/// Mock authentication backend.
///
/// Simulates a real backend: registration, login, OTP, password reset,
/// session issuing, and patient↔caregiver linking.
/// To swap in a real backend later, replace the method bodies with HTTP
/// calls. The public API stays the same.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _mockLatency = Duration(milliseconds: 600);

  /// In-memory user registry (persisted by AuthStore).
  final Map<String, AppUser> _users = {};

  /// In-memory OTP store: userId → _OtpRecord.
  final Map<String, _OtpRecord> _otps = {};

  /// DEV ONLY — last OTP issued. Shown on-screen for testing.
  String? _lastOtp;
  String? get debugLastOtp => _lastOtp;

  // ---------------------------------------------------------------------------
  // USER REGISTRY
  // ---------------------------------------------------------------------------

  void hydrateUsers(Iterable<AppUser> users) {
    _users
      ..clear()
      ..addEntries(users.map((u) => MapEntry(u.id, u)));
  }

  List<AppUser> exportUsers() => _users.values.toList();

  AppUser? findById(String id) => _users[id];

  AppUser? findByContact(String contact) {
    final normalized = _normalizeContact(contact);
    for (final u in _users.values) {
      if (_normalizeContact(u.email) == normalized) return u;
      if (_normalizeContact(u.phone) == normalized) return u;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // REGISTRATION
  // ---------------------------------------------------------------------------

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    required String preferredLanguageKey,
    DateTime? dateOfBirth,
    String? trustedContactName,
    String? trustedContactPhone,
    String? pin,
    String? relationship,
  }) async {
    await Future.delayed(_mockLatency);

    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.trim();

    if (cleanEmail.isNotEmpty && findByContact(cleanEmail) != null) {
      throw AuthException('An account with this email already exists.');
    }
    if (cleanPhone.isNotEmpty && findByContact(cleanPhone) != null) {
      throw AuthException('An account with this phone number already exists.');
    }

    final userId = _generateId();
    final now = DateTime.now();

    final user = AppUser(
      id: userId,
      fullName: fullName.trim(),
      email: cleanEmail,
      phone: cleanPhone,
      role: role,
      preferredLanguage: parseLanguage(preferredLanguageKey),
      accountStatus: AccountStatus.pendingVerification,
      verified: false,
      createdAt: now,
      updatedAt: now,
      dateOfBirth: dateOfBirth,
      trustedContactName: trustedContactName,
      trustedContactPhone: trustedContactPhone,
      pin: pin,
      relationship: relationship,
      // Only patients get a Patient ID.
      patientId: role == UserRole.patient ? PatientId.generate() : null,
    );

    _users[userId] = user;

    await _issueOtp(userId, reason: _OtpReason.registration);

    return user;
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------

  Future<AppUser> login({
    required String contact,
    required String password,
  }) async {
    await Future.delayed(_mockLatency);

    final user = findByContact(contact);
    if (user == null) {
      throw AuthException('Invalid credentials.');
    }

    if (user.accountStatus == AccountStatus.locked) {
      throw AuthException(
        'Your account is temporarily locked. Please try again later.',
      );
    }

    if (user.accountStatus == AccountStatus.suspended ||
        user.accountStatus == AccountStatus.deactivated ||
        user.accountStatus == AccountStatus.deleted) {
      throw AuthException('This account is not available.');
    }

    if (password.trim().isEmpty) {
      throw AuthException('Invalid credentials.');
    }

    return user;
  }

  Future<AppUser> loginWithPin({
    required String contact,
    required String pin,
  }) async {
    await Future.delayed(_mockLatency);

    final user = findByContact(contact);
    if (user == null || user.role != UserRole.patient) {
      throw AuthException('Patient account not found.');
    }
    if (user.pin == null || user.pin != pin) {
      throw AuthException('Incorrect PIN.');
    }
    return user;
  }

  // ---------------------------------------------------------------------------
  // OTP
  // ---------------------------------------------------------------------------

  Future<void> _issueOtp(String userId, {required _OtpReason reason}) async {
    final code = (100000 + Random().nextInt(900000)).toString();
    _otps[userId] = _OtpRecord(
      code: code,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      attempts: 0,
      reason: reason,
    );

    // DEV ONLY
    _lastOtp = code;

    // ignore: avoid_print
    print('[Smaran Auth] OTP for $userId: $code');
  }

  Future<void> resendOtp(String userId) async {
    final existing = _otps[userId];
    if (existing != null &&
        DateTime.now().difference(existing.issuedAt) <
            const Duration(seconds: 30)) {
      throw AuthException('Please wait before requesting a new code.');
    }
    await _issueOtp(
      userId,
      reason: existing?.reason ?? _OtpReason.registration,
    );
  }

  Future<bool> verifyOtp({
    required String userId,
    required String code,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final record = _otps[userId];
    if (record == null) {
      throw AuthException('No code was requested. Tap resend.');
    }
    if (DateTime.now().isAfter(record.expiresAt)) {
      _otps.remove(userId);
      throw AuthException('This code has expired. Please request a new code.');
    }
    if (record.attempts >= 5) {
      _otps.remove(userId);
      throw AuthException('Too many attempts. Please request a new code.');
    }

    record.attempts++;

    if (record.code != code) {
      throw AuthException('That code is not correct.');
    }

    final user = _users[userId];
    if (user != null) {
      _users[userId] = user.copyWith(
        accountStatus: AccountStatus.active,
        verified: true,
        updatedAt: DateTime.now(),
      );
    }
    _otps.remove(userId);
    _lastOtp = null;

    return true;
  }

  int get otpLength => 6;

  // ---------------------------------------------------------------------------
  // PASSWORD RECOVERY
  // ---------------------------------------------------------------------------

  Future<String> startPasswordReset(String contact) async {
    await Future.delayed(_mockLatency);

    final user = findByContact(contact);
    if (user == null) return '__no_user__';

    await _issueOtp(user.id, reason: _OtpReason.passwordReset);
    return user.id;
  }

  Future<void> completePasswordReset({
    required String userId,
    required String newPassword,
  }) async {
    await Future.delayed(_mockLatency);

    final user = _users[userId];
    if (user == null) {
      throw AuthException('This account is no longer available.');
    }
    _users[userId] = user.copyWith(
      updatedAt: DateTime.now(),
      accountStatus: AccountStatus.active,
      verified: true,
    );
    _lastOtp = null;
  }

  // ---------------------------------------------------------------------------
  // SESSION
  // ---------------------------------------------------------------------------

  AuthSession issueSession(String userId) {
    final now = DateTime.now();
    return AuthSession(
      sessionId: _generateId(),
      userId: userId,
      accessToken: 'mock.${_generateId()}.${_generateId()}',
      createdAt: now,
      expiresAt: now.add(const Duration(days: 30)),
    );
  }

  // ---------------------------------------------------------------------------
  // PATIENT ID LOOKUP & LINKING
  // ---------------------------------------------------------------------------

  /// Find a patient by their `SMRN-XXXX-XXXX` ID (case/hyphen insensitive).
  AppUser? findByPatientId(String rawId) {
    if (!PatientId.isValid(rawId)) return null;
    final normalized = PatientId.normalize(rawId);
    for (final u in _users.values) {
      if (u.role != UserRole.patient) continue;
      final id = u.patientId;
      if (id == null) continue;
      if (PatientId.normalize(id) == normalized) return u;
    }
    return null;
  }

  /// Link a caregiver/family user to a patient by ID.
  Future<AppUser> linkPatient({
    required String caregiverUserId,
    required String patientIdRaw,
  }) async {
    await Future.delayed(_mockLatency);

    final caregiver = _users[caregiverUserId];
    if (caregiver == null) {
      throw AuthException('Your account is no longer available.');
    }
    if (caregiver.role == UserRole.patient) {
      throw AuthException(
          'Only caregivers and family members can link patients.');
    }

    final patient = findByPatientId(patientIdRaw);
    if (patient == null) {
      throw AuthException(
        'That Patient ID was not found. Please check the code and try again.',
      );
    }

    if (caregiver.linkedPatientIds.contains(patient.id)) {
      return caregiver;
    }

    // PRD §1: max 10 patients per caregiver.
    if (caregiver.linkedPatientIds.length >= 10) {
      throw AuthException(
        'You have reached the maximum of 10 linked patients.',
      );
    }

    final updated = caregiver.copyWith(
      linkedPatientIds: [...caregiver.linkedPatientIds, patient.id],
      updatedAt: DateTime.now(),
    );
    _users[caregiverUserId] = updated;
    return updated;
  }

  /// Remove a patient link.
  Future<AppUser> unlinkPatient({
    required String caregiverUserId,
    required String patientIdRaw,
  }) async {
    await Future.delayed(_mockLatency);

    final caregiver = _users[caregiverUserId];
    if (caregiver == null) {
      throw AuthException('Your account is no longer available.');
    }

    final patient = findByPatientId(patientIdRaw);
    if (patient == null) {
      throw AuthException('That Patient ID was not found.');
    }

    final updated = caregiver.copyWith(
      linkedPatientIds: caregiver.linkedPatientIds
          .where((id) => id != patient.id)
          .toList(),
      updatedAt: DateTime.now(),
    );
    _users[caregiverUserId] = updated;
    return updated;
  }

  /// Resolve a list of patient userIds to full [AppUser] records.
  List<AppUser> resolvePatients(Iterable<String> userIds) {
    final out = <AppUser>[];
    for (final id in userIds) {
      final u = _users[id];
      if (u != null && u.role == UserRole.patient) out.add(u);
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString() +
      Random().nextInt(9999).toString().padLeft(4, '0');

  String _normalizeContact(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
}

// =============================================================================
// SUPPORT TYPES
// =============================================================================

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

enum _OtpReason { registration, passwordReset }

class _OtpRecord {
  final String code;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final _OtpReason reason;
  int attempts;

  _OtpRecord({
    required this.code,
    required this.expiresAt,
    required this.reason,
    this.attempts = 0,
  }) : issuedAt = DateTime.now();
}