import 'package:flutter_test/flutter_test.dart';
import 'package:notova/models/user_model.dart';

UserModel makeUser({required int level, required int xp}) =>
    UserModel(id: '1', email: 'a@b.c', name: 'Test', level: level, totalXpEver: xp);

void main() {
  // ── levelFromXp ──────────────────────────────────────────────────────────
  // Thresholds: nivel1=[0,150) nivel2=[150,500) nivel3=[500,1200)
  //             nivel4=[1200,2500) nivel5=[2500,4500) nivel6=[4500,7500) nivel7=[7500,∞)
  group('UserModel.levelFromXp', () {
    test('0 XP → nivel 1', () => expect(UserModel.levelFromXp(0), 1));
    test('149 XP → nivel 1 (límite superior)', () => expect(UserModel.levelFromXp(149), 1));
    test('150 XP → nivel 2 (umbral exacto)', () => expect(UserModel.levelFromXp(150), 2));
    test('499 XP → nivel 2 (límite superior)', () => expect(UserModel.levelFromXp(499), 2));
    test('500 XP → nivel 3 (umbral exacto)', () => expect(UserModel.levelFromXp(500), 3));
    test('1199 XP → nivel 3 (límite superior)', () => expect(UserModel.levelFromXp(1199), 3));
    test('1200 XP → nivel 4 (umbral exacto)', () => expect(UserModel.levelFromXp(1200), 4));
    test('2499 XP → nivel 4 (límite superior)', () => expect(UserModel.levelFromXp(2499), 4));
    test('2500 XP → nivel 5 (umbral exacto)', () => expect(UserModel.levelFromXp(2500), 5));
    test('4499 XP → nivel 5 (límite superior)', () => expect(UserModel.levelFromXp(4499), 5));
    test('4500 XP → nivel 6 (umbral exacto)', () => expect(UserModel.levelFromXp(4500), 6));
    test('7499 XP → nivel 6 (límite superior)', () => expect(UserModel.levelFromXp(7499), 6));
    test('7500 XP → nivel 7 (umbral exacto)', () => expect(UserModel.levelFromXp(7500), 7));
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

  // ── rankKeyForLevel ──────────────────────────────────────────────────────
  group('UserModel.rankKeyForLevel', () {
    for (var level = 1; level <= 7; level++) {
      final l = level;
      test('nivel $l → rank_$l', () => expect(UserModel.rankKeyForLevel(l), 'rank_$l'));
    }
    test('nivel 0 → clampea a rank_1', () => expect(UserModel.rankKeyForLevel(0), 'rank_1'));
    test('nivel 8 → clampea a rank_7', () => expect(UserModel.rankKeyForLevel(8), 'rank_7'));
  });

  // ── xpProgress ───────────────────────────────────────────────────────────
  group('UserModel.xpProgress', () {
    test('0 XP en nivel 1 → 0.0', () {
      expect(makeUser(level: 1, xp: 0).xpProgress, 0.0);
    });
    test('75 XP en nivel 1 (mitad) → 0.5', () {
      expect(makeUser(level: 1, xp: 75).xpProgress, closeTo(0.5, 0.01));
    });
    test('150 XP en nivel 2 (inicio de nivel) → 0.0', () {
      expect(makeUser(level: 2, xp: 150).xpProgress, closeTo(0.0, 0.01));
    });
    test('325 XP en nivel 2 (mitad: 150-500 span=350) → ~0.5', () {
      expect(makeUser(level: 2, xp: 325).xpProgress, closeTo(0.5, 0.01));
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
    test('nivel 2, 150 XP → 350 restantes', () {
      expect(makeUser(level: 2, xp: 150).xpRemaining, 350);
    });
    test('nivel 2, 400 XP → 100 restantes', () {
      expect(makeUser(level: 2, xp: 400).xpRemaining, 100);
    });
    test('nivel 7 (end-game) → 0 restantes', () {
      expect(makeUser(level: 7, xp: 8000).xpRemaining, 0);
    });
  });

  // ── currentLevelMinXp ────────────────────────────────────────────────────
  group('UserModel.currentLevelMinXp', () {
    test('nivel 1 → 0', () => expect(makeUser(level: 1, xp: 0).currentLevelMinXp, 0));
    test('nivel 2 → 150', () => expect(makeUser(level: 2, xp: 200).currentLevelMinXp, 150));
    test('nivel 3 → 500', () => expect(makeUser(level: 3, xp: 600).currentLevelMinXp, 500));
    test('nivel 7 → 7500', () => expect(makeUser(level: 7, xp: 8000).currentLevelMinXp, 7500));
  });

  // ── nextLevelMinXp ───────────────────────────────────────────────────────
  group('UserModel.nextLevelMinXp', () {
    test('nivel 1 → 150', () => expect(makeUser(level: 1, xp: 0).nextLevelMinXp, 150));
    test('nivel 2 → 500', () => expect(makeUser(level: 2, xp: 200).nextLevelMinXp, 500));
    test('nivel 3 → 1200', () => expect(makeUser(level: 3, xp: 600).nextLevelMinXp, 1200));
    test('nivel 6 → 7500', () => expect(makeUser(level: 6, xp: 5000).nextLevelMinXp, 7500));
  });

  // ── toJson / fromJson round-trip ─────────────────────────────────────────
  group('UserModel JSON round-trip', () {
    test('serializa y deserializa campos básicos correctamente', () {
      final original = UserModel(
        id: 'uid123',
        email: 'test@notova.app',
        name: 'Tester',
        level: 3,
        totalXpEver: 750,
        dayStreak: 5,
        rank: 'Táctico',
        badgesCount: 2,
        badges: const ['badge1', 'badge2'],
      );
      final json = original.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.email, original.email);
      expect(restored.name, original.name);
      expect(restored.level, original.level);
      expect(restored.totalXpEver, original.totalXpEver);
      expect(restored.dayStreak, original.dayStreak);
      expect(restored.badges, original.badges);
    });

    test('fromJson con mapa vacío usa valores por defecto', () {
      final u = UserModel.fromJson({'uid': 'x', 'email': '', 'name': ''});
      expect(u.level, 1);
      expect(u.totalXpEver, 0);
      expect(u.dayStreak, 0);
      expect(u.badges, isEmpty);
    });

    test('fromJson recalcula level a partir de totalXpEver', () {
      final u = UserModel.fromJson({'uid': 'x', 'email': '', 'name': '', 'totalXpEver': 600});
      expect(u.level, 3);
    });

    test('toJson incluye avatarUrl cuando está definido', () {
      final u = UserModel(
        id: 'x', email: '', name: '',
        avatarUrl: 'https://cdn.notova.app/avatar.png',
      );
      expect(u.toJson()['avatarUrl'], 'https://cdn.notova.app/avatar.png');
    });
  });
}
