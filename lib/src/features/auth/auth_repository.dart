import '../../core/api_client.dart';
import '../../core/models.dart';

/// Capa del feature de autenticación.
class AuthRepository {
  AuthRepository(this.apiClient);

  final ApiClient apiClient;

  Future<AppSession> login({
    required String username,
    required String password,
  }) async {
    final json = await apiClient.postForm(
      '/external/auth/login',
      fields: <String, String>{
        'username': username,
        'password': password,
        'device_name': 'Flutter FAN',
      },
    );

    final token = (json['access_token'] ?? json['token'] ?? '')
        .toString()
        .trim();

    if (token.isEmpty) {
      throw ApiException(
        statusCode: 500,
        message: 'La API no devolvió un token de acceso válido.',
      );
    }

    return AppSession(
      token: token,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Future<AppUser> fetchCurrentUser() async {
    final json = await apiClient.getJsonMap('/external/auth/me');
    return AppUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await apiClient.postForm('/external/auth/logout');
  }

  Future<ReservationConfig> fetchReservationConfig() async {
    final json = await apiClient.getJsonMap('/config-general');
    return ReservationConfig.fromJson(json);
  }
}
