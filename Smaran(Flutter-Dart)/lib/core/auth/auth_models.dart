import '../localization/app_languages.dart';

/// The three user roles defined in the PRD.
enum UserRole { patient, caregiver, family }

extension UserRoleX on UserRole {
  String get key => name;

  String get englishLabel => switch (this) {
        UserRole.patient => 'Patient',
        UserRole.caregiver => 'Caregiver',
        UserRole.family => 'Family Member',
      };

  String get tagline => switch (this) {
        UserRole.patient => 'I am using Smaran for myself.',
        UserRole.caregiver => 'I care for a Smaran patient.',
        UserRole.family => 'I am a family member of a Smaran patient.',
      };
}

UserRole parseRole(String? raw) {
  if (raw == null) return UserRole.patient;
  for (final r in UserRole.values) {
    if (r.key == raw) return r;
  }
  return UserRole.patient;
}

/// Account lifecycle states (PRD §48).
enum AccountStatus {
  pendingVerification,
  active,
  suspended,
  locked,
  deactivated,
  deleted,
}

extension AccountStatusX on AccountStatus {
  String get key => name;
  bool get canLogin => this == AccountStatus.active;
}

AccountStatus parseAccountStatus(String? raw) {
  if (raw == null) return AccountStatus.pendingVerification;
  for (final s in AccountStatus.values) {
    if (s.key == raw) return s;
  }
  return AccountStatus.pendingVerification;
}

/// Relationship types (PRD §46).
enum RelationshipType { caregiver, familyMember, trustedContact }

extension RelationshipTypeX on RelationshipType {
  String get key => name;
}

enum RelationshipStatus { pending, approved, rejected, revoked, expired }

extension RelationshipStatusX on RelationshipStatus {
  String get key => name;
}

/// Core user record (PRD §44).
class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final AppLanguage preferredLanguage;
  final AccountStatus accountStatus;
  final bool verified;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Patient-only fields (nullable for other roles)
  final DateTime? dateOfBirth;
  final String? trustedContactName;
  final String? trustedContactPhone;
  final String? pin;

  // Caregiver/Family-only fields
  final String? relationship;
  final List<String> linkedPatientIds;

  /// Only set for `UserRole.patient`.
  /// Format: `SMRN-XXXX-XXXX`.
  final String? patientId;

  /// True after the patient completes one-time face enrollment on this device.
  /// Not used for caregiver/family roles.
  final bool biometricEnrolled;

  /// Base64-encoded JPEG of the enrolled face photo. Patient only.
  /// Roughly 18–20 KB per record. Null until enrollment completes.
  final String? facePhotoBase64;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.preferredLanguage,
    required this.accountStatus,
    required this.verified,
    required this.createdAt,
    required this.updatedAt,
    this.dateOfBirth,
    this.trustedContactName,
    this.trustedContactPhone,
    this.pin,
    this.relationship,
    this.linkedPatientIds = const [],
    this.patientId,
    this.biometricEnrolled = false,
    this.facePhotoBase64,
  });

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    AppLanguage? preferredLanguage,
    AccountStatus? accountStatus,
    bool? verified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dateOfBirth,
    String? trustedContactName,
    String? trustedContactPhone,
    String? pin,
    String? relationship,
    List<String>? linkedPatientIds,
    String? patientId,
    bool? biometricEnrolled,
    String? facePhotoBase64,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      accountStatus: accountStatus ?? this.accountStatus,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      trustedContactName: trustedContactName ?? this.trustedContactName,
      trustedContactPhone: trustedContactPhone ?? this.trustedContactPhone,
      pin: pin ?? this.pin,
      relationship: relationship ?? this.relationship,
      linkedPatientIds: linkedPatientIds ?? this.linkedPatientIds,
      patientId: patientId ?? this.patientId,
      biometricEnrolled: biometricEnrolled ?? this.biometricEnrolled,
      facePhotoBase64: facePhotoBase64 ?? this.facePhotoBase64,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role.key,
        'preferredLanguage': preferredLanguage.key,
        'accountStatus': accountStatus.key,
        'verified': verified,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
        'trustedContactName': trustedContactName,
        'trustedContactPhone': trustedContactPhone,
        'pin': pin,
        'relationship': relationship,
        'linkedPatientIds': linkedPatientIds,
        'patientId': patientId,
        'biometricEnrolled': biometricEnrolled,
        'facePhotoBase64': facePhotoBase64,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id']?.toString() ?? '',
        fullName: j['fullName']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        phone: j['phone']?.toString() ?? '',
        role: parseRole(j['role']?.toString()),
        preferredLanguage:
            parseLanguage(j['preferredLanguage']?.toString()),
        accountStatus:
            parseAccountStatus(j['accountStatus']?.toString()),
        verified: j['verified'] as bool? ?? false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (j['createdAt'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (j['updatedAt'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        dateOfBirth: j['dateOfBirth'] is num
            ? DateTime.fromMillisecondsSinceEpoch(
                (j['dateOfBirth'] as num).toInt())
            : null,
        trustedContactName: j['trustedContactName']?.toString(),
        trustedContactPhone: j['trustedContactPhone']?.toString(),
        pin: j['pin']?.toString(),
        relationship: j['relationship']?.toString(),
        linkedPatientIds:
            (j['linkedPatientIds'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        patientId: j['patientId']?.toString(),
        biometricEnrolled: j['biometricEnrolled'] as bool? ?? false,
        facePhotoBase64: j['facePhotoBase64']?.toString(),
      );
}

/// Active authentication session (PRD §47).
class AuthSession {
  final String sessionId;
  final String userId;
  final String accessToken;
  final DateTime createdAt;
  final DateTime expiresAt;

  const AuthSession({
    required this.sessionId,
    required this.userId,
    required this.accessToken,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'userId': userId,
        'accessToken': accessToken,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
      };

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        sessionId: j['sessionId']?.toString() ?? '',
        userId: j['userId']?.toString() ?? '',
        accessToken: j['accessToken']?.toString() ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (j['createdAt'] as num?)?.toInt() ?? 0,
        ),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          (j['expiresAt'] as num?)?.toInt() ?? 0,
        ),
      );
}

/// Relationship record (PRD §46).
class UserRelationship {
  final String id;
  final String patientId;
  final String userId;
  final RelationshipType type;
  final RelationshipStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;

  const UserRelationship({
    required this.id,
    required this.patientId,
    required this.userId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.approvedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'userId': userId,
        'type': type.key,
        'status': status.key,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'approvedAt': approvedAt?.millisecondsSinceEpoch,
      };
}