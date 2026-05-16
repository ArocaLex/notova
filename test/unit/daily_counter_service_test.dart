import 'package:flutter_test/flutter_test.dart';
import 'package:notova/services/daily_counter_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DailyCounterService service;

  String todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = DailyCounterService();
  });

  // ── getCount ─────────────────────────────────────────────────────────────
  group('DailyCounterService.getCount', () {
    test('usuario nuevo → devuelve 0', () async {
      final count = await service.getCount('uid1');
      expect(count, 0);
    });

    test('mismo día con count almacenado → devuelve ese count', () async {
      SharedPreferences.setMockInitialValues({
        'uid1_daily_count': 5,
        'uid1_daily_date': todayStr(),
      });
      final count = await service.getCount('uid1');
      expect(count, 5);
    });

    test('fecha almacenada es del pasado → devuelve 0 y resetea', () async {
      SharedPreferences.setMockInitialValues({
        'uid1_daily_count': 99,
        'uid1_daily_date': '2000-01-01',
      });
      final count = await service.getCount('uid1');
      expect(count, 0);

      // Segunda llamada: ahora la fecha está actualizada, debería devolver 0
      final countAgain = await service.getCount('uid1');
      expect(countAgain, 0);
    });

    test('usuarios distintos tienen contadores independientes', () async {
      SharedPreferences.setMockInitialValues({
        'userA_daily_count': 3,
        'userA_daily_date': todayStr(),
        'userB_daily_count': 7,
        'userB_daily_date': todayStr(),
      });

      expect(await service.getCount('userA'), 3);
      expect(await service.getCount('userB'), 7);
    });
  });

  // ── increment ─────────────────────────────────────────────────────────────
  group('DailyCounterService.increment', () {
    test('desde 0 → count queda en 1', () async {
      await service.increment('uid1');
      final count = await service.getCount('uid1');
      expect(count, 1);
    });

    test('incremento múltiple → count acumula correctamente', () async {
      await service.increment('uid1');
      await service.increment('uid1');
      await service.increment('uid1');
      final count = await service.getCount('uid1');
      expect(count, 3);
    });

    test('increment con fecha pasada almacenada → resetea y queda en 1', () async {
      SharedPreferences.setMockInitialValues({
        'uid1_daily_count': 10,
        'uid1_daily_date': '2000-01-01',
      });
      await service.increment('uid1');
      final count = await service.getCount('uid1');
      expect(count, 1);
    });

    test('increment con fecha de hoy → suma al existente', () async {
      SharedPreferences.setMockInitialValues({
        'uid1_daily_count': 4,
        'uid1_daily_date': todayStr(),
      });
      await service.increment('uid1');
      final count = await service.getCount('uid1');
      expect(count, 5);
    });
  });

  // ── resetForUser ──────────────────────────────────────────────────────────
  group('DailyCounterService.resetForUser', () {
    test('resetea contador a 0', () async {
      SharedPreferences.setMockInitialValues({
        'uid1_daily_count': 15,
        'uid1_daily_date': todayStr(),
      });
      await service.resetForUser('uid1');
      final count = await service.getCount('uid1');
      expect(count, 0);
    });

    test('reset en usuario sin datos previos → no lanza excepción', () async {
      await expectLater(service.resetForUser('uid_nuevo'), completes);
      final count = await service.getCount('uid_nuevo');
      expect(count, 0);
    });

    test('reset solo afecta al usuario indicado', () async {
      SharedPreferences.setMockInitialValues({
        'userA_daily_count': 5,
        'userA_daily_date': todayStr(),
        'userB_daily_count': 8,
        'userB_daily_date': todayStr(),
      });
      await service.resetForUser('userA');

      expect(await service.getCount('userA'), 0);
      expect(await service.getCount('userB'), 8);
    });
  });
}
