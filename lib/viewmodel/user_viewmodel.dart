import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
  ImageProvider? _avatarImage;

  StreamSubscription<UserModel?>? _userSub;
  StreamSubscription<firebase_auth.User?>? _authSub;

  /// Marca si Firebase ya entregó un `User` no nulo en esta sesión. En cold
  /// start `authStateChanges()` puede emitir `null` antes de que Firebase
  /// termine de restaurar la sesión desde disco; ese null transitorio no es
  /// un sign-out real y no debe limpiar la caché del perfil.
  bool _firebaseAuthRestored = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get hasUser => _user != null;

  /// Path local del avatar en disco si existe; tiene prioridad sobre
  /// `user.avatarUrl` para mostrar la imagen del usuario.
  String? get localAvatarPath => _localAvatarPath;
  int get avatarVersion => _avatarVersion;
  ImageProvider? get avatarImage => _avatarImage;

  void _recomputeAvatarImage() {
    final localPath = _localAvatarPath;
    if (localPath != null) {
      final file = File(localPath);
      if (file.existsSync()) {
        _avatarImage = FileImage(file);
        return;
      }
    }
    final remoteUrl = _user?.avatarUrl;
    if (remoteUrl == null || remoteUrl.isEmpty) {
      _avatarImage = null;
      return;
    }
    if (remoteUrl.startsWith('file://')) {
      final path = remoteUrl.substring('file://'.length);
      final file = File(path);
      _avatarImage = file.existsSync() ? FileImage(file) : null;
      return;
    }
    _avatarImage = NetworkImage(remoteUrl);
  }

  UserViewModel() {
    _authSub = firebase_auth.FirebaseAuth.instance.authStateChanges().listen(
      _onAuthChanged,
    );
  }

  /// Reacciona a cambios en la sesión de Firebase: cancela la suscripción
  /// anterior, carga desde caché local de forma inmediata y se suscribe
  /// al stream de Firestore para mantener los datos sincronizados.
  void _onAuthChanged(firebase_auth.User? firebaseUser) {
    _userSub?.cancel();

    if (firebaseUser == null) {
      if (!_firebaseAuthRestored) return;
      _user = null;
      _isLoading = false;
      _repository.clearCachedUser();
      notifyListeners();
      return;
    }

    _firebaseAuthRestored = true;
    _isLoading = true;
    notifyListeners();

    _repository.getLocalAvatarPath().then((path) {
      if (path != null && _localAvatarPath != path) {
        _localAvatarPath = path;
        _recomputeAvatarImage();
        notifyListeners();
      }
    });

    _repository.getCachedUser().then((cached) {
      if (cached != null && _user == null) {
        _user = cached;
        _isLoading = false;
        _recomputeAvatarImage();
        notifyListeners();
      }
    });

    _userSub = _repository.userStream(firebaseUser.uid).listen((UserModel? userModel) {
      final remoteChanged = _user?.avatarUrl != userModel?.avatarUrl;
      _user = userModel;
      _isLoading = false;
      if (remoteChanged) _recomputeAvatarImage();
      notifyListeners();
      if (userModel != null) {
        _repository.cacheUser(userModel);
      }
    });
  }

  /// Actualiza el nombre visible del usuario en Firestore.
  Future<void> updateName(String name) => _repository.updateName(name);

  Future<void> addXp(int amount) => _repository.addXp(amount);

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
    _recomputeAvatarImage();
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
