import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../repositories/local_task_repository.dart';
import '../repositories/user_repository.dart';

/// Gestiona la autenticación del usuario mediante Google, email/contraseña
/// y recuperación de contraseña.
///
/// Delega las operaciones de autenticación a [AuthRepository] y la creación
/// del perfil inicial a [UserRepository]. Expone [isLoading] y [errorMessage]
/// para que la vista refleje el estado de cada operación.
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

  /// Inicia sesión con la cuenta de Google del usuario.
  ///
  /// Retorna `true` si la autenticación fue exitosa o `false` si el usuario
  /// canceló el diálogo o se produjo un error. En caso de error, establece
  /// [errorMessage] con un mensaje descriptivo.
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

  /// Inicia sesión con las credenciales de correo electrónico y contraseña proporcionadas.
  ///
  /// Retorna `true` si la autenticación fue exitosa. En caso de fallo,
  /// establece [errorMessage] y retorna `false`.
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

  /// Registra un nuevo usuario con correo electrónico y contraseña.
  ///
  /// Crea el perfil inicial en Firestore mediante [UserRepository] si el
  /// registro es exitoso. Retorna `true` en caso de éxito o `false` si
  /// ocurre un error, estableciendo [errorMessage].
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

  /// Envía un correo de recuperación de contraseña a la dirección proporcionada.
  ///
  /// Retorna `true` si el correo se envió correctamente o `false` en caso
  /// de error, estableciendo [errorMessage].
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

  /// Cierra la sesión del usuario actual.
  ///
  /// Limpia la caché local de tareas mediante [LocalTaskRepository] y
  /// delega el cierre de sesión a [AuthRepository].
  Future<void> signOut() async {
    await _localTaskRepository.clearLocalCache();
    await _repository.signOut();
  }

  Future<void> _createInitialUserProfile(User user) async {
    await _userRepository.createIfNotExists(user);
  }
}
