import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

/// Repositorio centralizado para operaciones del usuario en Firestore.
///
/// Estructura Firestore:
///   /users/{uid}          -> documento principal del usuario
///   /users/{uid}/tasks/   -> subcolección de tareas (gestionada por TasksRepository)
class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference _userDoc(String uid) => _db.collection('users').doc(uid);

  // ── Lectura en tiempo real ──────────────────────────────────────────────

  Stream<UserModel?> userStream(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ── Creación de perfil ──────────────────────────────────────────────────

  /// Crea el documento del usuario si no existe. Retorna true si lo creó.
  Future<bool> createIfNotExists(User firebaseUser) async {
    final doc = await _userDoc(firebaseUser.uid).get();
    if (doc.exists) return false;

    await _userDoc(firebaseUser.uid).set(UserModel.initialData(
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
    ));
    return true;
  }

  // ── Actualizaciones de campos ───────────────────────────────────────────

  Future<void> updateFields(Map<String, dynamic> fields) async {
    if (_uid == null) return;
    await _userDoc(_uid!).update(fields);
  }

  Future<void> updateName(String name) async {
    await updateFields({'name': name});
  }

  // ── Sistema de XP y niveles (PRD RF-07) ────────────────────────────────

  /// Suma XP al usuario y gestiona el level-up automático.
  ///
  /// Retorna true si ocurrió un level-up (para disparar SFX).
  /// El nivel se determina por umbrales fijos de XP total acumulada (PRD v1.0).
  Future<bool> addXp(int amount) async {
    if (_uid == null || amount <= 0) return false;

    final user = await getUser(_uid!);
    if (user == null) return false;

    final newTotalXpEver = user.totalXpEver + amount;
    final newLevel = UserModel.levelFromXp(newTotalXpEver);
    final newRank = UserModel.rankForLevel(newLevel);
    final didLevelUp = newLevel > user.level;

    await _userDoc(_uid!).update({
      'totalXpEver': newTotalXpEver,
      'level': newLevel,
      'rank': newRank,
    });

    await checkAndAwardBadges(
      totalXpEver: newTotalXpEver,
      level: newLevel,
      dayStreak: user.dayStreak,
      existingBadges: user.badges,
    );

    return didLevelUp;
  }

  // ── Sistema de Rachas Diarias (PRD RF-06) ──────────────────────────────

  /// Comprueba y actualiza la racha diaria del usuario.
  ///
  /// Lógica:
  ///   - Sin actividad previa → racha = 1
  ///   - Ya contado hoy → no hace nada
  ///   - Ayer → racha++
  ///   - Más de 1 día sin actividad → racha = 1 (rota)
  Future<void> checkAndUpdateStreak() async {
    if (_uid == null) return;

    final user = await getUser(_uid!);
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (user.lastActivityDate == null) {
      await _userDoc(_uid!).update({
        'dayStreak': 1,
        'lastActivityDate': Timestamp.fromDate(today),
      });
      return;
    }

    final last = user.lastActivityDate!;
    final lastOnly = DateTime(last.year, last.month, last.day);
    final diff = today.difference(lastOnly).inDays;

    if (diff == 0) return; // Ya contado hoy

    final newStreak = diff == 1 ? user.dayStreak + 1 : 1;
    await _userDoc(_uid!).update({
      'dayStreak': newStreak,
      'lastActivityDate': Timestamp.fromDate(today),
    });
  }

  // ── Sistema de Badges (PRD comercial) ──────────────────────────────────

  /// Evalúa las condiciones de badges y otorga los no desbloqueados aún.
  Future<void> checkAndAwardBadges({
    required int totalXpEver,
    required int level,
    required int dayStreak,
    required List<String> existingBadges,
  }) async {
    if (_uid == null) return;

    final newBadges = <String>[];

    void check(String id, bool condition) {
      if (condition && !existingBadges.contains(id)) newBadges.add(id);
    }

    check('first_quest', totalXpEver >= 50);
    check('streak_3', dayStreak >= 3);
    check('streak_7', dayStreak >= 7);
    check('nivel_3', level >= 3);
    check('nivel_5', level >= 5);
    check('nivel_7', level >= 7);

    if (newBadges.isEmpty) return;

    await _userDoc(_uid!).update({
      'badges': FieldValue.arrayUnion(newBadges),
      'badgesCount': FieldValue.increment(newBadges.length),
    });
  }

  // ── Avatar en Firebase Storage ──────────────────────────────────────────

  /// Sube la imagen del avatar a Firebase Storage y guarda la URL en Firestore.
  Future<String> uploadAvatar(File imageFile) async {
    if (_uid == null) throw Exception('Usuario no autenticado');

    final ref = FirebaseStorage.instance.ref('avatars/$_uid.jpg');
    await ref.putFile(imageFile);
    final downloadUrl = await ref.getDownloadURL();
    await updateFields({'avatarUrl': downloadUrl});
    return downloadUrl;
  }
}
