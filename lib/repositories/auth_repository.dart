import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Excepción de dominio para errores de autenticación en la app.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Repositorio de autenticación de Notova.
///
/// Encapsula el acceso a [FirebaseAuth] y [GoogleSignIn], traduce códigos de
/// error técnicos a mensajes legibles para la UI y expone operaciones de
/// sesión (login, registro, recuperación y cierre de sesión).
class AuthRepository {
  final FirebaseAuth _auth;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Usuario autenticado en la sesión actual, o `null` si no hay sesión.
  User? get currentUser => _auth.currentUser;

  /// Stream reactivo de cambios de autenticación de Firebase.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Inicia sesión con Google y autentica esa cuenta en Firebase.
  ///
  /// Retorna el [User] autenticado o lanza [AuthException] si ocurre un fallo
  /// de autenticación o de conectividad.
  Future<User?> signInWithGoogle() async {
    try {

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final scopes = <String>['email', 'profile'];
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(scopes);

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      return userCredential.user;
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

  /// Cierra la sesión local de Firebase y desconecta Google Sign-In.
  Future<void> signOut() async {
    try {
      try {
        await _googleSignIn.disconnect();
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
      default:
        return 'Error de autenticación ($errorCode). Inténtalo de nuevo.';
    }
  }
}
