import '../../core/api_client.dart';
import '../../core/models.dart';

class ProfileRepository {
  ProfileRepository(this.apiClient);

  final ApiClient apiClient;

  Future<ProfileData> fetchProfile() async {
    final json = await apiClient.getJsonMap('/profile');
    return ProfileData.fromJson(json);
  }

  Future<ProfileData> saveProfile({
    required String name,
    required String username,
    required String email,
  }) async {
    final json = await apiClient.postForm(
      '/profile',
      fields: <String, String>{
        'name': name,
        'username': username,
        'email': email,
      },
    );

    return ProfileData.fromJson(json);
  }

  Future<void> changePassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    await apiClient.postForm(
      '/profile/change-password',
      fields: <String, String>{
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }
}
