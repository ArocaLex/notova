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

  StreamSubscription<UserModel?>? _userSub;
  StreamSubscription<User?>? _authSub;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get hasUser => _user != null;

  UserViewModel() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

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

    // 1. Carga inmediata desde caché local
    _repository.getCachedUser().then((cached) {
      if (cached != null && _user == null) {
        _user = cached;
        _isLoading = false;
        notifyListeners();
      }
    });

    // 2. Sincroniza con Firestore y actualiza caché
    _userSub = _repository.userStream(firebaseUser.uid).listen((userModel) {
      _user = userModel;
      _isLoading = false;
      notifyListeners();
      if (userModel != null) {
        _repository.cacheUser(userModel);
      }
    });
  }

  Future<void> updateName(String name) => _repository.updateName(name);
  Future<void> addXp(int amount) => _repository.addXp(amount);
  Future<void> updateFields(Map<String, dynamic> fields) =>
      _repository.updateFields(fields);
  Future<void> uploadAvatar(File imageFile) =>
      _repository.uploadAvatar(imageFile);

  @override
  void dispose() {
    _userSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
