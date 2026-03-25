import 'package:fan_app/src/core/models.dart';
import 'package:fan_app/src/core/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateTimeSlots', () {
    test('genera slots sin incluir el cierre por defecto', () {
      final slots = generateTimeSlots(
        startTime: '08:00',
        endTime: '10:00',
        intervalMinutes: 30,
      );

      expect(slots, <String>['08:00', '08:30', '09:00', '09:30']);
    });

    test('puede incluir el cierre cuando se usa como lista de límites', () {
      final slots = generateTimeSlots(
        startTime: '08:00',
        endTime: '09:00',
        intervalMinutes: 30,
        includeEnd: true,
      );

      expect(slots, <String>['08:00', '08:30', '09:00']);
    });
  });

  group('AppUser.userCan', () {
    test('resuelve permisos exactos y wildcard simples', () {
      const user = AppUser(
        id: 1,
        uuid: 'abc',
        name: 'Test',
        email: 'test@example.com',
        username: 'tester',
        mustChangePassword: false,
        locale: 'es',
        environment: '',
        permissions: <String, bool>{
          'meeting-rooms-view': true,
          'meeting-rooms-reserve': true,
        },
        organizationId: 1,
        organizationName: 'Org',
        organizationTypeId: 2,
        organizationTypeName: 'Incubada',
        organizationLogoUrl: null,
        organizationFaviconUrl: null,
        defaultHome: '/',
      );

      expect(user.userCan('meeting-rooms-view'), isTrue);
      expect(user.userCan('meeting-rooms-*'), isTrue);
      expect(user.userCan('lab-equipment-*'), isFalse);
    });
  });
}
