const String bookableResourcesQrScanPermission = 'bookable-resources-qr-scan';

class BookableResourceTypeInfo {
  const BookableResourceTypeInfo({
    required this.title,
    required this.shortTitle,
    required this.resourcesTabLabel,
    required this.resourcePath,
    required this.reservationPath,
    required this.resourceIdField,
    required this.resourceJsonKey,
    required this.viewPermission,
    required this.reservePermission,
    required this.calendarPermission,
    required this.usesSingleSlotForIncubada,
  });

  final String title;
  final String shortTitle;
  final String resourcesTabLabel;
  final String resourcePath;
  final String reservationPath;
  final String resourceIdField;
  final String resourceJsonKey;
  final String viewPermission;
  final String reservePermission;
  final String calendarPermission;
  final bool usesSingleSlotForIncubada;
}

enum BookableResourceType {
  meetingRoom(
    BookableResourceTypeInfo(
      title: 'Salas de reunión',
      shortTitle: 'Sala',
      resourcesTabLabel: 'Salas',
      resourcePath: '/meeting-room',
      reservationPath: '/meeting-room-reservation',
      resourceIdField: 'meeting_room_id',
      resourceJsonKey: 'meeting_room',
      viewPermission: 'meeting-rooms-view',
      reservePermission: 'meeting-rooms-reserve',
      calendarPermission: 'meeting-rooms-calendar',
      usesSingleSlotForIncubada: true,
    ),
  ),
  labEquipment(
    BookableResourceTypeInfo(
      title: 'Equipos de laboratorio',
      shortTitle: 'Equipo',
      resourcesTabLabel: 'Equipos',
      resourcePath: '/lab-equipment',
      reservationPath: '/lab-equipment-reservation',
      resourceIdField: 'lab_equipment_id',
      resourceJsonKey: 'lab_equipment',
      viewPermission: 'lab-equipment-view',
      reservePermission: 'lab-equipment-reserve',
      calendarPermission: 'lab-equipment-calendar',
      usesSingleSlotForIncubada: false,
    ),
  );

  const BookableResourceType(this.info);

  final BookableResourceTypeInfo info;

  static BookableResourceType? fromApiResourceType(String value) {
    switch (value) {
      case 'meeting-room':
        return BookableResourceType.meetingRoom;
      case 'lab-equipment':
        return BookableResourceType.labEquipment;
      default:
        return null;
    }
  }
}

class BookableResource {
  const BookableResource({
    required this.id,
    required this.name,
    required this.description,
    this.uuid,
    this.fileUrl,
    this.resourceType,
    this.resourceTypeLabel,
    this.qrPayload,
    this.qrResolveUrl,
    this.qrImageUrl,
    this.deletedAt,
  });

  final int id;
  final String name;
  final String description;
  final String? uuid;
  final String? fileUrl;
  final String? resourceType;
  final String? resourceTypeLabel;
  final String? qrPayload;
  final String? qrResolveUrl;
  final String? qrImageUrl;
  final String? deletedAt;

  bool get isDeleted => deletedAt != null && deletedAt!.isNotEmpty;

  factory BookableResource.fromJson(Map<String, dynamic> json) {
    return BookableResource(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      uuid: json['uuid']?.toString(),
      fileUrl: json['file_url']?.toString(),
      resourceType: json['resource_type']?.toString(),
      resourceTypeLabel: json['resource_type_label']?.toString(),
      qrPayload: json['qr_payload']?.toString(),
      qrResolveUrl: json['qr_resolve_url']?.toString(),
      qrImageUrl: json['qr_image_url']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
    );
  }
}

class ResourceDetail extends BookableResource {
  const ResourceDetail({
    required super.id,
    required super.name,
    required super.description,
    required this.reservations,
    super.uuid,
    super.fileUrl,
    super.resourceType,
    super.resourceTypeLabel,
    super.qrPayload,
    super.qrResolveUrl,
    super.qrImageUrl,
    super.deletedAt,
  });

  final List<ReservationSummary> reservations;

  factory ResourceDetail.fromJson(
    Map<String, dynamic> json,
    BookableResourceType type,
  ) {
    final reservations =
        (json['reservations'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (item) => ReservationSummary.fromJson(
                item as Map<String, dynamic>,
                type,
                fallbackResourceName: (json['name'] ?? '').toString(),
              ),
            )
            .toList();

    return ResourceDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      uuid: json['uuid']?.toString(),
      fileUrl: json['file_url']?.toString(),
      resourceType: json['resource_type']?.toString(),
      resourceTypeLabel: json['resource_type_label']?.toString(),
      qrPayload: json['qr_payload']?.toString(),
      qrResolveUrl: json['qr_resolve_url']?.toString(),
      qrImageUrl: json['qr_image_url']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
      reservations: reservations,
    );
  }
}

class BookableQrResolution {
  const BookableQrResolution({
    required this.type,
    required this.resourceTypeLabel,
    required this.resource,
  });

  final BookableResourceType type;
  final String resourceTypeLabel;
  final BookableResource resource;

  factory BookableQrResolution.fromJson(Map<String, dynamic> json) {
    final resourceType = (json['resource_type'] ?? '').toString();
    final type = BookableResourceType.fromApiResourceType(resourceType);

    if (type == null) {
      throw const FormatException(
        'El QR no corresponde a un recurso soportado.',
      );
    }

    final resourceJson =
        Map<String, dynamic>.from(
            json['resource'] as Map<String, dynamic>? ??
                const <String, dynamic>{},
          )
          ..putIfAbsent('resource_type', () => resourceType)
          ..putIfAbsent(
            'resource_type_label',
            () => (json['resource_type_label'] ?? '').toString(),
          );

    return BookableQrResolution(
      type: type,
      resourceTypeLabel: (json['resource_type_label'] ?? '').toString(),
      resource: BookableResource.fromJson(resourceJson),
    );
  }
}

class ReservationSummary {
  const ReservationSummary({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.resourceName,
    this.organizationName,
    this.cancelledAt,
    this.cancellationReason,
    this.userRating,
    this.userObservations,
  });

  final int id;
  final String date;
  final String startTime;
  final String endTime;
  final String resourceName;
  final String? organizationName;
  final String? cancelledAt;
  final String? cancellationReason;
  final int? userRating;
  final String? userObservations;

  bool get isCancelled => cancelledAt != null && cancelledAt!.isNotEmpty;

  factory ReservationSummary.fromJson(
    Map<String, dynamic> json,
    BookableResourceType type, {
    String? fallbackResourceName,
  }) {
    final resource = json[type.info.resourceJsonKey] as Map<String, dynamic>?;
    final organization = json['organization'] as Map<String, dynamic>?;

    return ReservationSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      date: (json['date'] ?? '').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      resourceName:
          resource?['name']?.toString() ??
          fallbackResourceName ??
          type.info.shortTitle,
      organizationName: organization?['name']?.toString(),
      cancelledAt: json['cancelled_at']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      userRating: (json['user_rating'] as num?)?.toInt(),
      userObservations: json['user_observations']?.toString(),
    );
  }
}

class ReservationAvailability {
  const ReservationAvailability({
    required this.resourceName,
    required this.reservedHours,
    required this.disabledHours,
  });

  final String resourceName;
  final List<String> reservedHours;
  final List<String> disabledHours;

  factory ReservationAvailability.fromJson(
    Map<String, dynamic> json,
    BookableResourceType type,
  ) {
    final resource = json[type.info.resourceJsonKey] as Map<String, dynamic>?;

    return ReservationAvailability(
      resourceName: resource?['name']?.toString() ?? type.info.shortTitle,
      reservedHours:
          (json['reservedHours'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(),
      disabledHours:
          (json['disabledHours'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(),
    );
  }
}

class ReservationCalendarResponse {
  const ReservationCalendarResponse({required this.meta, required this.days});

  final CalendarMeta meta;
  final List<CalendarDay> days;

  factory ReservationCalendarResponse.fromJson(Map<String, dynamic> json) {
    return ReservationCalendarResponse(
      meta: CalendarMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      days: (json['days'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => CalendarDay.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CalendarMeta {
  const CalendarMeta({
    required this.title,
    required this.year,
    required this.month,
    required this.today,
    required this.previous,
    required this.next,
  });

  final String title;
  final int year;
  final int month;
  final String today;
  final String previous;
  final String next;

  factory CalendarMeta.fromJson(Map<String, dynamic> json) {
    return CalendarMeta(
      title: (json['title'] ?? '').toString(),
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      today: (json['today'] ?? '').toString(),
      previous: (json['prev'] ?? '').toString(),
      next: (json['next'] ?? '').toString(),
    );
  }
}

class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.inCurrentMonth,
    required this.weekdayShort,
    required this.dayNumber,
    required this.isToday,
    required this.reservations,
  });

  final String date;
  final bool inCurrentMonth;
  final String weekdayShort;
  final int dayNumber;
  final bool isToday;
  final List<CalendarReservationItem> reservations;

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date: (json['date'] ?? '').toString(),
      inCurrentMonth: json['in_current_month'] == true,
      weekdayShort: (json['weekday_short'] ?? '').toString(),
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 0,
      isToday: json['is_today'] == true,
      reservations:
          (json['reservations'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (item) => CalendarReservationItem.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }
}

class CalendarReservationItem {
  const CalendarReservationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.typeLabel,
    required this.resourceName,
    required this.organizationName,
  });

  final int id;
  final String title;
  final String subtitle;
  final String startTime;
  final String endTime;
  final String status;
  final String typeLabel;
  final String resourceName;
  final String organizationName;

  factory CalendarReservationItem.fromJson(Map<String, dynamic> json) {
    final resource = json['resource'] as Map<String, dynamic>?;
    final organization = json['organization'] as Map<String, dynamic>?;

    return CalendarReservationItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      typeLabel: (json['type_label'] ?? '').toString(),
      resourceName: resource?['name']?.toString() ?? '',
      organizationName: organization?['name']?.toString() ?? '',
    );
  }
}
