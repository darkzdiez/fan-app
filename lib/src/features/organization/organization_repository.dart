import '../../core/api_client.dart';
import '../../core/models.dart';

class OrganizationRepository {
  OrganizationRepository(this.apiClient);

  final ApiClient apiClient;

  Future<OrganizationProfile> fetchOrganization() async {
    final json = await apiClient.getJsonMap('/incubada');
    return OrganizationProfile.fromJson(json);
  }

  Future<OrganizationProfile> saveOrganization({
    required Map<String, String> fields,
    required List<ApiFilePart> files,
  }) async {
    final json = await apiClient.postForm(
      '/incubada',
      fields: fields,
      files: files,
    );

    if (json.isEmpty) {
      return fetchOrganization();
    }

    return OrganizationProfile.fromJson(json);
  }
}
