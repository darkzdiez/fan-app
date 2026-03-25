import '../../core/api_client.dart';
import 'reservations_models.dart';

class ReservationsRepository {
  ReservationsRepository(this.apiClient);

  final ApiClient apiClient;

  Future<List<BookableResource>> listResources(
    BookableResourceType type, {
    String search = '',
  }) async {
    final json = await apiClient.postForm(
      type.info.resourcePath,
      fields: <String, String>{
        if (search.trim().isNotEmpty) 'filters[name]': search.trim(),
      },
    );

    final data = json['data'] as List<dynamic>? ?? const <dynamic>[];
    return data
        .map((item) => BookableResource.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ResourceDetail> fetchResourceDetail(
    BookableResourceType type,
    int resourceId,
  ) async {
    final json = await apiClient.getJsonMap(
      '${type.info.resourcePath}/$resourceId',
    );
    return ResourceDetail.fromJson(json, type);
  }

  Future<List<ReservationSummary>> fetchMyReservations(
    BookableResourceType type, {
    String date = '',
    int? resourceId,
  }) async {
    final json = await apiClient.postForm(
      '${type.info.reservationPath}/my-reservations',
      fields: <String, String>{
        if (date.isNotEmpty) 'filters[date]': date,
        if (resourceId != null)
          'filters[${type.info.resourceIdField}]': '$resourceId',
      },
    );

    final data = json['data'] as List<dynamic>? ?? const <dynamic>[];
    return data
        .map(
          (item) =>
              ReservationSummary.fromJson(item as Map<String, dynamic>, type),
        )
        .toList();
  }

  Future<ReservationAvailability> fetchAvailability(
    BookableResourceType type, {
    required String date,
    required int resourceId,
  }) async {
    final json = await apiClient.postForm(
      '${type.info.reservationPath}/availability',
      fields: <String, String>{
        'date': date,
        type.info.resourceIdField: '$resourceId',
      },
    );

    return ReservationAvailability.fromJson(json, type);
  }

  Future<void> createReservation(
    BookableResourceType type, {
    required String date,
    required String startTime,
    required int resourceId,
    String? endTime,
  }) async {
    await apiClient.postForm(
      '${type.info.reservationPath}/self-reservation',
      fields: <String, String>{
        'date': date,
        'start_time': startTime,
        if (endTime != null && endTime.isNotEmpty) 'end_time': endTime,
        type.info.resourceIdField: '$resourceId',
      },
    );
  }

  Future<void> cancelReservation(
    BookableResourceType type, {
    required int reservationId,
    required String reason,
  }) async {
    await apiClient.postForm(
      '${type.info.reservationPath}/cancel/$reservationId',
      fields: <String, String>{'cancellation_reason': reason},
    );
  }

  Future<void> rateReservation(
    BookableResourceType type, {
    required int reservationId,
    required int rating,
    required String observations,
  }) async {
    await apiClient.postForm(
      '${type.info.reservationPath}/rate/$reservationId',
      fields: <String, String>{
        'user_rating': '$rating',
        'user_observations': observations,
      },
    );
  }

  Future<ReservationCalendarResponse> fetchCalendar(
    BookableResourceType type, {
    required String ym,
    int? resourceId,
  }) async {
    final json = await apiClient.postForm(
      '${type.info.reservationPath}/calendar',
      fields: <String, String>{
        'ym': ym,
        if (resourceId != null) 'resource_id': '$resourceId',
      },
    );

    return ReservationCalendarResponse.fromJson(json);
  }
}
