import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../repositories/local_task_repository.dart';
import '../repositories/user_repository.dart';

class AuthViewModel extends ChangeNotifier {
  late final AuthRepository _repository;
  late final UserRepository _userRepository;
  late final LocalTaskRepository _localTaskRepository;

  AuthViewModel({
    AuthRepository? repository,
    UserRepository? userRepository,
    LocalTaskRepository? localTaskRepository,
  })  : _repository = repository ?? AuthRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _localTaskRepository =
            localTaskRepository ?? LocalTaskRepository();

  bool isLoading = false;
  String? errorMessage;

  void _setLoading(bool value) {
    isLoading = value;
    if (value) errorMessage = null; 
    notifyListeners();
  }

  // =========================================================
  // 1. AUTENTICACIÓN CON GOOGLE
  // =========================================================
  Future<bool> signInWithGoogle() async {
    _setLoading(true);

    try {
      final User? user = await _repository.signInWithGoogle();

      if (user != null) {
        await _createInitialUserProfile(user);
        _setLoading(false);
        return true; // Éxito
      } else {
        _setLoading(false);
        return false; // Cancelado por el usuario
      }
    } on AuthException catch (e) {
      errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      errorMessage = 'Ocurrió un error inesperado al conectar con Google.';
      _setLoading(false);
      return false;
    }
  }

  // =========================================================
  // 2. INICIAR SESIÓN CON EMAIL Y CONTRASEÑA
  // =========================================================
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);

    try {
      await _repository.signInWithEmail(email, password);
      _setLoading(false);
      return true; // Éxito
    } on AuthException catch (e) {
      errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      errorMessage = 'Ocurrió un error inesperado al iniciar sesión.';
      _setLoading(false);
      return false;
    }
  }

  // =========================================================
  // 3. REGISTRARSE CON EMAIL Y CONTRASEÑA
  // =========================================================
  Future<bool> registerWithEmail(String email, String password) async {
    _setLoading(true);

    try {
      final User? user = await _repository.registerWithEmail(email, password);

      if (user != null) {
        await _createInitialUserProfile(user);
      }
      _setLoading(false);
      return true; // Éxito
    } on AuthException catch (e) {
      errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      errorMessage = 'Ocurrió un error inesperado al registrarte.';
      _setLoading(false);
      return false;
    }
  }

  // =========================================================
  // 4. RECUPERAR CONTRASEÑA
  // =========================================================
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);

    try {
      await _repository.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      errorMessage = 'No se pudo enviar el correo de recuperación.';
      _setLoading(false);
      return false;
    }
  }

  // =========================================================
  // 5. CERRAR SESIÓN
  // =========================================================
  Future<void> signOut() async {
    await _localTaskRepository.clearLocalCache();
    await _repository.signOut();
  }

  // =========================================================
  // 6. CREACIÓN DEL PERFIL EN FIRESTORE
  // =========================================================
  Future<void> _createInitialUserProfile(User user) async {
    await _userRepository.createIfNotExists(user);
  }
}
