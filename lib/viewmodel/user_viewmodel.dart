import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

/// ViewModel central del usuario.
///
/// Escucha automaticamente los cambios de autenticacion:
///   - Al iniciar sesion, se suscribe al documento Firestore del usuario.
///   - Al cerrar sesion, limpia los datos y cancela la suscripcion.
///
/// Cualquier pantalla puede acceder a los datos del usuario con:
///   final user = context.watch<UserViewModel>().user;
class UserViewModel extends ChangeNotifier {
  final UserRepository _repository = UserRepository();

  UserModel? _user;
  bool _isLoading = true;

  StreamSubscription<UserModel?>? _userSub;
  StreamSubscription<User?>? _authSub;

  /// Datos actuales del usuario (null si no ha iniciado sesion o esta cargando).
  UserModel? get user => _user;

  /// True mientras se espera la primera carga de datos.
  bool get isLoading => _isLoading;

  /// True si hay un usuario autenticado con datos cargados.
  bool get hasUser => _user != null;

  UserViewModel() {
    // Escucha cambios en la autenticacion para conectar/desconectar el stream
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? firebaseUser) {
    _userSub?.cancel();

    if (firebaseUser == null) {
      _user = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _userSub = _repository.userStream(firebaseUser.uid).listen((userModel) {
      _user = userModel;
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Actualiza el nombre del usuario.
  Future<void> updateName(String name) => _repository.updateName(name);

  /// Suma XP al usuario (con level-up automatico).
  Future<void> addXp(int amount) => _repository.addXp(amount);

  /// Actualiza campos arbitrarios del usuario.
  Future<void> updateFields(Map<String, dynamic> fields) =>
      _repository.updateFields(fields);

  @override
  void dispose() {
    _userSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
