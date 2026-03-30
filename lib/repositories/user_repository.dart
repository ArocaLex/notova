import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Repositorio centralizado para operaciones del usuario en Firestore.
///
/// Estructura Firestore:
///   /users/{uid}          -> documento principal del usuario
///   /users/{uid}/tasks/   -> subcoleccion de tareas (gestionada por TasksRepository)
///
/// Todos los ViewModels que necesiten datos del usuario deben pasar por aqui.
class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference _userDoc(String uid) => _db.collection('users').doc(uid);

  // ── Lectura en tiempo real ──────────────────────────────────────────────

  /// Stream del documento del usuario. Se actualiza en tiempo real.
  Stream<UserModel?> userStream(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Lectura unica del usuario (sin escucha continua).
  Future<UserModel?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ── Creacion de perfil ──────────────────────────────────────────────────

  /// Crea el documento del usuario si no existe. Retorna true si lo creo.
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

  /// Actualiza campos especificos del usuario.
  Future<void> updateFields(Map<String, dynamic> fields) async {
    if (_uid == null) return;
    await _userDoc(_uid!).update(fields);
  }

  /// Actualiza el nombre del usuario.
  Future<void> updateName(String name) async {
    await updateFields({'name': name});
  }

  // ── Sistema de XP y niveles ─────────────────────────────────────────────

  /// Suma XP al usuario y gestiona el level-up automatico.
  ///
  /// Logica de level-up:
  ///   - Cuando currentXp >= totalXp, sube de nivel.
  ///   - currentXp se reinicia al sobrante.
  ///   - totalXp sube un 20% (mas XP necesaria por nivel).
  ///   - Rank se actualiza segun el nivel.
  Future<void> addXp(int amount) async {
    if (_uid == null || amount <= 0) return;

    // Leemos el estado actual para calcular level-up
    final user = await getUser(_uid!);
    if (user == null) return;

    int newCurrentXp = user.currentXp + amount;
    int newLevel = user.level;
    int newTotalXp = user.totalXp;
    int newTotalXpEver = user.totalXpEver + amount;

    // Level-up loop (por si gana suficiente XP para subir varios niveles)
    while (newCurrentXp >= newTotalXp) {
      newCurrentXp -= newTotalXp;
      newLevel++;
      newTotalXp = (newTotalXp * 1.2).round(); // +20% por nivel
    }

    String newRank = _rankForLevel(newLevel);

    await _userDoc(_uid!).update({
      'currentXp': newCurrentXp,
      'totalXp': newTotalXp,
      'totalXpEver': newTotalXpEver,
      'level': newLevel,
      'rank': newRank,
    });
  }

  /// Incrementa el streak diario.
  Future<void> incrementStreak() async {
    if (_uid == null) return;
    await _userDoc(_uid!).update({
      'dayStreak': FieldValue.increment(1),
    });
  }

  /// Reinicia el streak a 0.
  Future<void> resetStreak() async {
    if (_uid == null) return;
    await _userDoc(_uid!).update({'dayStreak': 0});
  }

  // ── Rango segun nivel ───────────────────────────────────────────────────

  static String _rankForLevel(int level) {
    if (level >= 50) return 'Legend';
    if (level >= 30) return 'Master';
    if (level >= 20) return 'Expert';
    if (level >= 10) return 'Advanced';
    if (level >= 5) return 'Intermediate';
    return 'Beginner';
  }
}
