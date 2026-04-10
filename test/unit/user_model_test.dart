import 'package:flutter_test/flutter_test.dart';
import 'package:notova/models/user_model.dart';

UserModel makeUser({required int level, required int xp}) =>
    UserModel(uid: '1', email: 'a@b.c', name: 'Test', level: level, totalXpEver: xp);

void main() {
  // ── levelFromXp ──────────────────────────────────────────────────────────
  group('UserModel.levelFromXp', () {
    test('0 XP → nivel 1', () => expect(UserModel.levelFromXp(0), 1));
    test('150 XP → nivel 1 (límite superior)', () => expect(UserModel.levelFromXp(150), 1));
    test('151 XP → nivel 2', () => expect(UserModel.levelFromXp(151), 2));
    test('500 XP → nivel 2', () => expect(UserModel.levelFromXp(500), 2));
    test('501 XP → nivel 3', () => expect(UserModel.levelFromXp(501), 3));
    test('1200 XP → nivel 3', () => expect(UserModel.levelFromXp(1200), 3));
    test('1201 XP → nivel 4', () => expect(UserModel.levelFromXp(1201), 4));
    test('2500 XP → nivel 4', () => expect(UserModel.levelFromXp(2500), 4));
    test('2501 XP → nivel 5', () => expect(UserModel.levelFromXp(2501), 5));
    test('4500 XP → nivel 5', () => expect(UserModel.levelFromXp(4500), 5));
    test('4501 XP → nivel 6', () => expect(UserModel.levelFromXp(4501), 6));
    test('7500 XP → nivel 6', () => expect(UserModel.levelFromXp(7500), 6));
    test('7501 XP → nivel 7', () => expect(UserModel.levelFromXp(7501), 7));
    test('99999 XP → nivel 7 (cap)', () => expect(UserModel.levelFromXp(99999), 7));
  });

  // ── rankForLevel ─────────────────────────────────────────────────────────
  group('UserModel.rankForLevel', () {
    test('nivel 1 → Novato', () => expect(UserModel.rankForLevel(1), 'Novato'));
    test('nivel 2 → Aspirante', () => expect(UserModel.rankForLevel(2), 'Aspirante'));
    test('nivel 3 → Táctico', () => expect(UserModel.rankForLevel(3), 'Táctico'));
    test('nivel 4 → Ninja', () => expect(UserModel.rankForLevel(4), 'Ninja'));
    test('nivel 5 → Maestro', () => expect(UserModel.rankForLevel(5), 'Maestro'));
    test('nivel 6 → Leyenda', () => expect(UserModel.rankForLevel(6), 'Leyenda'));
    test('nivel 7 → SuperNotova', () => expect(UserModel.rankForLevel(7), 'SuperNotova'));
    test('nivel 0 → clampea a Novato', () => expect(UserModel.rankForLevel(0), 'Novato'));
    test('nivel 8 → clampea a SuperNotova', () => expect(UserModel.rankForLevel(8), 'SuperNotova'));
  });

  // ── xpProgress ───────────────────────────────────────────────────────────
  group('UserModel.xpProgress', () {
    test('0 XP en nivel 1 → 0.0', () {
      expect(makeUser(level: 1, xp: 0).xpProgress, 0.0);
    });
    test('75 XP en nivel 1 (mitad) → ~0.5', () {
      expect(makeUser(level: 1, xp: 75).xpProgress, closeTo(0.5, 0.01));
    });
    test('nivel 7 siempre → 1.0', () {
      expect(makeUser(level: 7, xp: 10000).xpProgress, 1.0);
    });
  });

  // ── xpRemaining ──────────────────────────────────────────────────────────
  group('UserModel.xpRemaining', () {
    test('nivel 1, 0 XP → 150 restantes', () {
      expect(makeUser(level: 1, xp: 0).xpRemaining, 150);
    });
    test('nivel 1, 100 XP → 50 restantes', () {
      expect(makeUser(level: 1, xp: 100).xpRemaining, 50);
    });
    test('nivel 7 (end-game) → 0 restantes', () {
      expect(makeUser(level: 7, xp: 8000).xpRemaining, 0);
    });
  });
}
