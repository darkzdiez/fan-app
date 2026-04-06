import 'models.dart';

String formatApiDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String formatHumanDate(String? rawDate) {
  if (rawDate == null || rawDate.isEmpty) {
    return 'Sin fecha';
  }

  final parsed = DateTime.tryParse(rawDate);

  if (parsed == null) {
    return rawDate;
  }

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();
  return '$day/$month/$year';
}

String formatMonthLabel(DateTime value) {
  const months = <String>[
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  return '${months[value.month - 1]} ${value.year}';
}

String formatMonthKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  return '${value.year}-$month';
}

List<String> generateTimeSlots({
  required String startTime,
  required String endTime,
  required int intervalMinutes,
  bool includeEnd = false,
}) {
  final startMinutes = timeToMinutes(startTime);
  final endMinutes = timeToMinutes(endTime);

  final slots = <String>[];
  for (
    var current = startMinutes;
    includeEnd ? current <= endMinutes : current < endMinutes;
    current += intervalMinutes
  ) {
    slots.add(minutesToTime(current));
  }

  return slots;
}

int timeToMinutes(String rawTime) {
  final parts = rawTime.split(':');
  if (parts.length < 2) {
    return 0;
  }

  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  return (hours * 60) + minutes;
}

String minutesToTime(int value) {
  final hours = (value ~/ 60).toString().padLeft(2, '0');
  final minutes = (value % 60).toString().padLeft(2, '0');
  return '$hours:$minutes';
}

DateTime? combineDateAndTime(String rawDate, String rawTime) {
  final date = DateTime.tryParse(rawDate);
  if (date == null) {
    return null;
  }

  final parts = rawTime.split(':');
  if (parts.length < 2) {
    return null;
  }

  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;

  return DateTime(date.year, date.month, date.day, hours, minutes);
}

bool isReservationInPast(String date, String endTime) {
  final value = combineDateAndTime(date, endTime);
  if (value == null) {
    return false;
  }

  return value.isBefore(DateTime.now());
}

bool isReservationInFuture(String date, String startTime) {
  final value = combineDateAndTime(date, startTime);
  if (value == null) {
    return false;
  }

  return value.isAfter(DateTime.now());
}

String collapseApiException(ApiException error) {
  final summary = _trimAggregateSuffix(_normalizeErrorText(error.message));
  final fieldMessages = <String>[];
  final seenMessages = <String>{};

  void addFieldMessage(String rawMessage) {
    final normalized = _trimAggregateSuffix(_normalizeErrorText(rawMessage));
    if (normalized.isEmpty || !seenMessages.add(normalized)) {
      return;
    }

    fieldMessages.add(normalized);
  }

  for (final entry in error.fieldErrors.entries) {
    for (final message in entry.value) {
      addFieldMessage(message);
    }
  }

  if (fieldMessages.isEmpty) {
    return summary;
  }

  final lines = <String>[];
  if (summary.isNotEmpty && !seenMessages.contains(summary)) {
    lines.add(summary);
  }

  if (fieldMessages.length == 1 && lines.isEmpty) {
    return fieldMessages.first;
  }

  lines.addAll(fieldMessages.map((message) => '• $message'));
  return lines.join('\n');
}

String describeUnexpectedError(Object error) {
  final raw = error.toString().trim();

  if (raw.isEmpty) {
    return 'Ocurrió un error inesperado.';
  }

  const prefixes = <String>[
    'Exception: ',
    'ClientException: ',
    'HttpException: ',
  ];

  for (final prefix in prefixes) {
    if (raw.startsWith(prefix)) {
      return _trimAggregateSuffix(
        _normalizeErrorText(raw.substring(prefix.length).trim()),
      );
    }
  }

  return _trimAggregateSuffix(_normalizeErrorText(raw));
}

String _normalizeErrorText(String raw) {
  if (raw.trim().isEmpty) {
    return '';
  }

  final withoutHtml = raw
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  final lines = withoutHtml
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.isNotEmpty);

  return lines.join('\n');
}

String _trimAggregateSuffix(String raw) {
  return raw
      .replaceAll(
        RegExp(r'\s*\(and \d+ more errors?\)\s*', caseSensitive: false),
        '',
      )
      .trim();
}
