import 'dart:convert';
import 'dart:typed_data';

/// Excepción de infraestructura para cualquier error HTTP/API.
class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.fieldErrors = const <String, List<String>>{},
  });

  final int statusCode;
  final String message;
  final Map<String, List<String>> fieldErrors;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Usuario autenticado retornado por la API externa de FAN.
class AppUser {
  const AppUser({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    required this.username,
    required this.mustChangePassword,
    required this.locale,
    required this.environment,
    required this.permissions,
    required this.organizationId,
    required this.organizationName,
    required this.organizationTypeId,
    required this.organizationTypeName,
    required this.organizationLogoUrl,
    required this.organizationFaviconUrl,
    required this.defaultHome,
  });

  final int id;
  final String uuid;
  final String name;
  final String email;
  final String username;
  final bool mustChangePassword;
  final String locale;
  final String environment;
  final Map<String, bool> permissions;
  final int? organizationId;
  final String? organizationName;
  final int? organizationTypeId;
  final String? organizationTypeName;
  final String? organizationLogoUrl;
  final String? organizationFaviconUrl;
  final String? defaultHome;

  bool get isIncubada => organizationTypeId == 2;

  bool userCan(String permission) {
    if (permission.endsWith('*')) {
      final prefix = permission.substring(0, permission.length - 1);
      return permissions.entries.any(
        (entry) => entry.key.startsWith(prefix) && entry.value,
      );
    }

    return permissions[permission] ?? false;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rawPermissions =
        json['permissions'] as Map<String, dynamic>? ??
        const <String, dynamic>{};

    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      uuid: (json['uuid'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      mustChangePassword: json['must_change_password'] == true,
      locale: (json['locale'] ?? 'es').toString(),
      environment: (json['environment'] ?? '').toString(),
      permissions: rawPermissions.map(
        (key, value) => MapEntry(
          key,
          value is Map<String, dynamic>
              ? value['access'] == true
              : value == true,
        ),
      ),
      organizationId: (json['organization_id'] as num?)?.toInt(),
      organizationName: json['organization_name']?.toString(),
      organizationTypeId: (json['organization_type_id'] as num?)?.toInt(),
      organizationTypeName: json['organization_type_name']?.toString(),
      organizationLogoUrl: json['organization_logo_url']?.toString(),
      organizationFaviconUrl: json['organization_favicon_url']?.toString(),
      defaultHome: json['default_home']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'uuid': uuid,
    'name': name,
    'email': email,
    'username': username,
    'must_change_password': mustChangePassword,
    'locale': locale,
    'environment': environment,
    'permissions': permissions.map(
      (key, value) => MapEntry(key, <String, dynamic>{'access': value}),
    ),
    'organization_id': organizationId,
    'organization_name': organizationName,
    'organization_type_id': organizationTypeId,
    'organization_type_name': organizationTypeName,
    'organization_logo_url': organizationLogoUrl,
    'organization_favicon_url': organizationFaviconUrl,
    'default_home': defaultHome,
  };
}

/// Sesión persistida localmente.
class AppSession {
  const AppSession({required this.token, required this.user});

  final String token;
  final AppUser user;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'token': token,
    'user': user.toJson(),
  };

  String encode() => jsonEncode(toJson());

  factory AppSession.decode(String rawJson) {
    final json = jsonDecode(rawJson) as Map<String, dynamic>;

    return AppSession(
      token: (json['token'] ?? '').toString(),
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Configuración operativa para reservas.
class ReservationConfig {
  const ReservationConfig({
    required this.intervalMinutes,
    required this.startTime,
    required this.endTime,
    required this.maxHoursPerDay,
    required this.maxConsecutiveHours,
  });

  final int intervalMinutes;
  final String startTime;
  final String endTime;
  final int maxHoursPerDay;
  final int maxConsecutiveHours;

  factory ReservationConfig.defaults() => const ReservationConfig(
    intervalMinutes: 60,
    startTime: '08:00',
    endTime: '17:00',
    maxHoursPerDay: 4,
    maxConsecutiveHours: 3,
  );

  factory ReservationConfig.fromJson(Map<String, dynamic> json) {
    return ReservationConfig(
      intervalMinutes:
          (json['reservation_interval_minutes'] as num?)?.toInt() ?? 60,
      startTime: (json['reservation_start_time'] ?? '08:00').toString(),
      endTime: (json['reservation_end_time'] ?? '17:00').toString(),
      maxHoursPerDay:
          (json['meeting_room_max_hours_per_day'] as num?)?.toInt() ?? 4,
      maxConsecutiveHours:
          (json['meeting_room_max_consecutive_hours'] as num?)?.toInt() ?? 3,
    );
  }
}

/// Archivo seleccionado por el usuario para uploads multipart.
class SelectedFile {
  const SelectedFile({required this.fileName, this.path, this.bytes});

  final String fileName;
  final String? path;
  final Uint8List? bytes;

  bool get hasData => path != null || bytes != null;
}

/// Par `campo -> archivo` para requests multipart.
class ApiFilePart {
  const ApiFilePart({required this.fieldName, required this.file});

  final String fieldName;
  final SelectedFile file;
}

/// DTO simple del perfil de usuario autenticado.
class ProfileData {
  const ProfileData({
    required this.name,
    required this.username,
    required this.email,
  });

  final String name;
  final String username;
  final String email;

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
    name: (json['name'] ?? '').toString(),
    username: (json['username'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
  );
}

/// DTO de la incubada/organización del usuario.
class OrganizationProfile {
  const OrganizationProfile({
    required this.uuid,
    required this.name,
    required this.registrationDate,
    required this.incubator,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.alarmCode,
    required this.status,
    required this.logoUrl,
    required this.equipmentConsentUrl,
    required this.contractUrl,
    required this.artPolicyUrl,
    required this.artValidFrom,
    required this.artValidTo,
    required this.coverageCertificateUrl,
    required this.coverageValidFrom,
    required this.coverageValidTo,
    required this.hasNonRepetitionClause,
  });

  final String? uuid;
  final String name;
  final String registrationDate;
  final String incubator;
  final String contactPerson;
  final String phone;
  final String email;
  final String alarmCode;
  final String status;
  final String? logoUrl;
  final String? equipmentConsentUrl;
  final String? contractUrl;
  final String? artPolicyUrl;
  final String artValidFrom;
  final String artValidTo;
  final String? coverageCertificateUrl;
  final String coverageValidFrom;
  final String coverageValidTo;
  final bool hasNonRepetitionClause;

  factory OrganizationProfile.empty() => const OrganizationProfile(
    uuid: null,
    name: '',
    registrationDate: '',
    incubator: '',
    contactPerson: '',
    phone: '',
    email: '',
    alarmCode: '',
    status: '',
    logoUrl: null,
    equipmentConsentUrl: null,
    contractUrl: null,
    artPolicyUrl: null,
    artValidFrom: '',
    artValidTo: '',
    coverageCertificateUrl: null,
    coverageValidFrom: '',
    coverageValidTo: '',
    hasNonRepetitionClause: false,
  );

  factory OrganizationProfile.fromJson(Map<String, dynamic> json) {
    return OrganizationProfile(
      uuid: json['uuid']?.toString(),
      name: (json['name'] ?? '').toString(),
      registrationDate: (json['registration_date'] ?? '').toString(),
      incubator: (json['incubator'] ?? '').toString(),
      contactPerson: (json['contact_person'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      alarmCode: (json['alarm_code'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      logoUrl: json['logo_url']?.toString(),
      equipmentConsentUrl: json['equipment_consent_url']?.toString(),
      contractUrl: json['contract_url']?.toString(),
      artPolicyUrl: json['art_policy_url']?.toString(),
      artValidFrom: (json['art_valid_from'] ?? '').toString(),
      artValidTo: (json['art_valid_to'] ?? '').toString(),
      coverageCertificateUrl: json['coverage_certificate_url']?.toString(),
      coverageValidFrom: (json['coverage_valid_from'] ?? '').toString(),
      coverageValidTo: (json['coverage_valid_to'] ?? '').toString(),
      hasNonRepetitionClause:
          json['has_non_repetition_clause'] == true ||
          json['has_non_repetition_clause'] == 1,
    );
  }
}
