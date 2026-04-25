import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Retorna la referencia al documento Firestore del usuario con [uid].
  DocumentReference _userDoc(String uid) => _db.collection('users').doc(uid);

  /// Retorna un stream reactivo del [UserModel] del usuario con [uid].
  ///
  /// Emite `null` si el documento no existe.
  Stream<UserModel?> userStream(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Obtiene el [UserModel] del usuario con [uid] en una sola lectura, o
  /// `null` si el documento no existe.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Crea el documento del usuario en Firestore si no existe.
  ///
  /// Retorna `true` si el documento fue creado, `false` si ya existía.
  Future<bool> createIfNotExists(User firebaseUser) async {
    final doc = await _userDoc(firebaseUser.uid).get();
    if (doc.exists) return false;

    await _userDoc(firebaseUser.uid).set(UserModel.initialData(
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
    ));
    return true;
  }

  /// Actualiza los campos indicados en [fields] en el documento Firestore
  /// del usuario autenticado.
  Future<void> updateFields(Map<String, dynamic> fields) async {
    if (_uid == null) return;
    await _userDoc(_uid!).update(fields);
  }

  /// Actualiza el nombre visible del usuario en Firestore.
  Future<void> updateName(String name) async {
    await updateFields({'name': name});
  }

  /// Suma [amount] de XP al usuario, recalcula nivel y rango, y otorga
  /// los badges correspondientes.
  ///
  /// Retorna `true` si el usuario subió de nivel, lo que puede usarse para
  /// disparar efectos visuales o de sonido en la UI.
  Future<bool> addXp(int amount) async {
    if (_uid == null || amount <= 0) return false;
    final uid = _uid!;
    final userRef = _userDoc(uid);
    late int newTotalXpEver;
    late int newLevel;
    late bool didLevelUp;
    late int dayStreak;
    late List<String> existingBadges;

    final applied = await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) return false;
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final currentTotal = (data['totalXpEver'] as num?)?.toInt() ?? 0;
      final currentLevel = (data['level'] as num?)?.toInt() ?? 1;
      final currentDayStreak = (data['dayStreak'] as num?)?.toInt() ?? 0;
      final badges = (data['badges'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList();

      newTotalXpEver = currentTotal + amount;
      newLevel = UserModel.levelFromXp(newTotalXpEver);
      final newRank = UserModel.rankForLevel(newLevel);
      didLevelUp = newLevel > currentLevel;
      dayStreak = currentDayStreak;
      existingBadges = badges;

      tx.update(userRef, {
        'totalXpEver': newTotalXpEver,
        'level': newLevel,
        'rank': newRank,
      });
      return true;
    });

    if (!applied) return false;

    await checkAndAwardBadges(
      totalXpEver: newTotalXpEver,
      level: newLevel,
      dayStreak: dayStreak,
      existingBadges: existingBadges,
    );

    return didLevelUp;
  }

  /// Comprueba y actualiza la racha diaria del usuario.
  ///
  /// La racha se incrementa si la última actividad fue ayer, se reinicia a 1
  /// si pasó más de un día, y no se modifica si ya se registró actividad hoy.
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

    if (diff == 0) return;

    final newStreak = diff == 1 ? user.dayStreak + 1 : 1;
    await _userDoc(_uid!).update({
      'dayStreak': newStreak,
      'lastActivityDate': Timestamp.fromDate(today),
    });
  }

  /// Evalúa las condiciones de desbloqueo de badges y otorga los que aún no
  /// tiene el usuario.
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

  /// Guarda [imageFile] como avatar local del usuario y retorna el path local.
  ///
  /// Copia el archivo a `<documents>/avatars/<uid>.jpg` y persiste el path
  /// en [SharedPreferences]. Esta operación es rápida y síncrona con la UI:
  /// la imagen queda disponible inmediatamente aun sin conexión.
  ///
  /// La subida a Firebase Storage se hace aparte con [syncAvatarToCloud].
  Future<String> saveAvatarLocally(File imageFile) async {
    if (_uid == null) throw Exception('Usuario no autenticado');

    final docs = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory(p.join(docs.path, 'avatars'));
    if (!avatarsDir.existsSync()) avatarsDir.createSync(recursive: true);
    final localFile = File(p.join(avatarsDir.path, '$_uid.jpg'));
    await imageFile.copy(localFile.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_local_$_uid', localFile.path);

    return localFile.path;
  }

  /// Sube el avatar local a Firebase Storage y actualiza `avatarUrl` en
  /// Firestore con la URL de descarga.
  ///
  /// Pensado para ejecutarse en background tras [saveAvatarLocally]. Si falla
  /// (sin red, permisos, etc.) no propaga la excepción: el avatar local sigue
  /// siendo válido y el próximo intento lo volverá a sincronizar.
  Future<void> syncAvatarToCloud() async {
    if (_uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('avatar_local_$_uid');
    if (path == null) return;
    final file = File(path);
    if (!file.existsSync()) return;

    try {
      final ref = FirebaseStorage.instance.ref('avatars/$_uid.jpg');
      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await ref.getDownloadURL();
      await updateFields({'avatarUrl': downloadUrl});
    } catch (_) {}
  }

  /// Devuelve el path local del avatar si existe (para usar como FileImage).
  Future<String?> getLocalAvatarPath() async {
    if (_uid == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('avatar_local_$_uid');
    if (path == null) return null;
    return File(path).existsSync() ? path : null;
  }

  static const _userCacheKey = 'cached_user';

  /// Serializa [user] y lo guarda en [SharedPreferences] como caché local.
  Future<void> cacheUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userCacheKey, jsonEncode(user.toJson()));
  }

  /// Recupera el [UserModel] de la caché local, o `null` si no existe.
  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userCacheKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Elimina el [UserModel] almacenado en la caché local.
  Future<void> clearCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userCacheKey);
  }

  /// Obtiene los datos actuales del usuario y evalúa si hay badges nuevos.
  ///
  /// Útil para llamar tras completar una tarea, cuando el XP se actualiza
  /// directamente en Firestore sin pasar por [addXp].
  Future<void> refreshAndCheckBadges() async {
    if (_uid == null) return;
    final user = await getUser(_uid!);
    if (user == null) return;
    await checkAndAwardBadges(
      totalXpEver: user.totalXpEver,
      level: user.level,
      dayStreak: user.dayStreak,
      existingBadges: user.badges,
    );
  }

  /// Elimina los datos del usuario en Firestore y su avatar en Storage.
  ///
  /// Las tareas se eliminan primero en batches. El documento principal del
  /// usuario solo se borra si todos los batches se completan correctamente,
  /// evitando dejar tareas huérfanas en caso de fallo parcial.
  Future<void> deleteUserData(String uid) async {
    final userRef = _userDoc(uid);

    final tasksSnap = await userRef.collection('tasks').get();
    final taskDocs = tasksSnap.docs;

    const batchSize = 500;
    for (var i = 0; i < taskDocs.length; i += batchSize) {
      final batch = _db.batch();
      final end = (i + batchSize < taskDocs.length) ? i + batchSize : taskDocs.length;
      for (var j = i; j < end; j++) {
        batch.delete(taskDocs[j].reference);
      }
      // Si este commit falla lanza excepción y el userDoc no se borra,
      // preservando la integridad referencial.
      await batch.commit();
    }

    await userRef.delete();

    try {
      await FirebaseStorage.instance.ref('avatars/$uid.jpg').delete();
    } catch (_) {}
  }
}
