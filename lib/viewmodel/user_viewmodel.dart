import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

/// ViewModel central del usuario.
///
/// Flujo offline-first:
///   1. Carga inmediata desde caché local (SharedPreferences).
///   2. Se suscribe al stream de Firestore para sincronizar.
///   3. Cada actualización remota se guarda en caché local.
class UserViewModel extends ChangeNotifier {
  final UserRepository _repository = UserRepository();

  UserModel? _user;
  bool _isLoading = true;
  String? _localAvatarPath;
  int _avatarVersion = 0;

  StreamSubscription<UserModel?>? _userSub;
  StreamSubscription<User?>? _authSub;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get hasUser => _user != null;

  /// Path local del avatar en disco si existe; tiene prioridad sobre
  /// `user.avatarUrl` para mostrar la imagen del usuario.
  String? get localAvatarPath => _localAvatarPath;

  /// Contador que se incrementa cada vez que el avatar local cambia.
  /// La UI puede usarlo como `ValueKey` para forzar un rebuild sin
  /// depender de la caché de `FileImage`.
  int get avatarVersion => _avatarVersion;

  UserViewModel() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  /// Reacciona a cambios en la sesión de Firebase: cancela la suscripción
  /// anterior, carga desde caché local de forma inmediata y se suscribe
  /// al stream de Firestore para mantener los datos sincronizados.
  void _onAuthChanged(User? firebaseUser) {
    _userSub?.cancel();

    if (firebaseUser == null) {
      _user = null;
      _isLoading = false;
      _repository.clearCachedUser();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _repository.getLocalAvatarPath().then((path) {
      if (path != null && _localAvatarPath != path) {
        _localAvatarPath = path;
        notifyListeners();
      }
    });

    _repository.getCachedUser().then((cached) {
      if (cached != null && _user == null) {
        _user = cached;
        _isLoading = false;
        notifyListeners();
      }
    });

    _userSub = _repository.userStream(firebaseUser.uid).listen((userModel) {
      _user = userModel;
      _isLoading = false;
      notifyListeners();
      if (userModel != null) {
        _repository.cacheUser(userModel);
      }
    });
  }

  /// Actualiza el nombre visible del usuario en Firestore.
  Future<void> updateName(String name) => _repository.updateName(name);

  /// Incrementa el XP total del usuario en [amount] puntos.
  Future<void> addXp(int amount) => _repository.addXp(amount);

  /// Actualiza los campos indicados en el documento Firestore del usuario.
  Future<void> updateFields(Map<String, dynamic> fields) =>
      _repository.updateFields(fields);

  /// Actualiza el avatar del usuario con efecto inmediato en la UI.
  ///
  /// Copia la imagen a almacenamiento local, invalida la caché de imágenes de
  /// Flutter para el path previo y notifica a la vista. La subida a Firebase
  /// Storage y la actualización de `avatarUrl` en Firestore se disparan en
  /// background sin bloquear al usuario.
  Future<void> uploadAvatar(File imageFile) async {
    final path = await _repository.saveAvatarLocally(imageFile);

    if (_localAvatarPath != null) {
      await FileImage(File(_localAvatarPath!)).evict();
    }
    await FileImage(File(path)).evict();

    _localAvatarPath = path;
    _avatarVersion++;
    notifyListeners();

    unawaited(_repository.syncAvatarToCloud());
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
