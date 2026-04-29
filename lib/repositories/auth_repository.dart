import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'user_repository.dart';

/// Excepción de dominio para errores de autenticación en la app.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Sesión de Google obtenida durante el login con scope de Calendar concedido.
/// Permite que CalendarViewModel adjunte la cuenta sin volver a abrir el picker.
class GooglePrimaryAccount {
  final String email;
  final String accessToken;
  final DateTime expiry;

  const GooglePrimaryAccount({
    required this.email,
    required this.accessToken,
    required this.expiry,
  });
}

/// Repositorio de autenticación de Notova.
///
/// Encapsula el acceso a [FirebaseAuth] y [GoogleSignIn], traduce códigos de
/// error técnicos a mensajes legibles para la UI y expone operaciones de
/// sesión (login, registro, recuperación y cierre de sesión).
class AuthRepository {
  final FirebaseAuth _auth;
  final UserRepository _userRepository = UserRepository();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
  }

  /// Usuario autenticado en la sesión actual, o `null` si no hay sesión.
  User? get currentUser => _auth.currentUser;

  /// Stream reactivo de cambios de autenticación de Firebase.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Stream de eventos de autenticación de Google Sign-In.
  Stream<GoogleSignInAuthenticationEvent> get googleAuthEvents => _googleSignIn.authenticationEvents;

  /// Inicia sesión con Google y autentica esa cuenta en Firebase.
  ///
  /// Retorna `(user, isNewUser)`. [isNewUser] es `true` cuando es la primera
  /// vez que este usuario inicia sesión con Google en la app.
  Future<(User?, bool, GooglePrimaryAccount?)> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      GoogleSignInAccount? googleUser;

      if (_googleSignIn.supportsAuthenticate()) {
        googleUser = await _googleSignIn.authenticate();
      } else {
        throw AuthException('La plataforma no soporta autenticación de Google.');
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;

      // Pedir el scope de Calendar reusando la cuenta ya seleccionada — así
      // luego no hace falta volver a abrir el selector de cuentas. Si el
      // usuario rechaza el consent, devolvemos primary=null y el flujo
      // manual sigue disponible desde la pantalla de Calendar.
      GooglePrimaryAccount? primary;
      try {
        final auth = await googleUser.authorizationClient
            .authorizeScopes([gcal.CalendarApi.calendarScope]);
        primary = GooglePrimaryAccount(
          email: googleUser.email,
          accessToken: auth.accessToken,
          expiry: DateTime.now().add(const Duration(minutes: 55)),
        );
      } catch (_) {
        primary = null;
      }

      return (userCredential.user, isNew, primary);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return (null, false, null);
      }
      throw AuthException('Error de Google Sign-In: ${e.description ?? e.code.name}');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translateAuthError(e.code));
    } catch (e) {
      throw AuthException('Error al iniciar sesión con Google: $e');
    }
  }

  /// Inicia sesión con [email] y [password].
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translateAuthError(e.code));
    } catch (e) {
      throw AuthException('Ocurrió un error inesperado al iniciar sesión.');
    }
  }

  /// Registra un nuevo usuario con [email] y [password].
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translateAuthError(e.code));
    } catch (e) {
      throw AuthException('Ocurrió un error inesperado al registrarte.');
    }
  }

  /// Envía un correo de recuperación de contraseña a [email].
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translateAuthError(e.code));
    } catch (e) {
      throw AuthException('No se pudo enviar el correo de recuperación.');
    }
  }

  /// Elimina permanentemente la cuenta del usuario actual de Firebase Auth.
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw AuthException('No hay sesión activa.');
      await _userRepository.deleteUserData(user.uid);
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translateAuthError(e.code));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Error al eliminar la cuenta.');
    }
  }

  /// Cierra la sesión local de Firebase y de Google Sign-In.
  Future<void> signOut() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Error al cerrar sesión.');
    }
  }

  /// Traduce códigos de error de Firebase a mensajes en español.
  String _translateAuthError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'La contraseña o el correo son incorrectos.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado en Notova.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      case 'network-request-failed':
        return 'Revisa tu conexión a internet.';
      case 'missing-email':
        return 'Introduce un correo electrónico.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
      case 'requires-recent-login':
        return 'Por seguridad, vuelve a iniciar sesión antes de eliminar tu cuenta.';
      default:
        return 'Error de autenticación ($errorCode). Inténtalo de nuevo.';
    }
  }
}
