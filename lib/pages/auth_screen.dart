// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:notova/pages/main_screen.dart';
import 'package:provider/provider.dart';

import '../viewmodel/auth_viewmodel.dart';

/// Pantalla de autenticación (login/registro) de Notova.
///
/// Consume [AuthViewModel] para iniciar sesión con Google o con email/contraseña,
/// registrar nuevas cuentas y enviar correos de recuperación de contraseña.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool _obscurePassword = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  static const _bgColor = Color(0xFF120E1A);
  static const _cardColor = Color(0xFF1E1926);
  static const _primaryPurple = Color(0xFF7B2CBF);
  static const _cyanAccent = Color(0xFFDEB7FF);

  late final AnimationController _entryController;
  late final Animation<double> _headerSlide;
  late final Animation<double> _headerOpacity;
  late final Animation<double> _formOpacity;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerSlide = Tween<double>(begin: -40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _formOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeIn),
      ),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final viewModel = context.read<AuthViewModel>();

    bool success;
    if (isLogin) {
      success = await viewModel.signInWithEmail(email, password);
    } else {
      success = await viewModel.registerWithEmail(email, password);
    }
    _handleAuthResult(success, viewModel);
  }

  Future<void> _googleSignIn() async {
    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.signInWithGoogle();
    _handleAuthResult(success, viewModel);
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetController =
        TextEditingController(text: emailController.text.trim());
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Recuperar contraseña',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Introduce tu correo y te enviaremos un enlace para restablecer la contraseña.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  hint: 'ejemplo@notova.com',
                  icon: Icons.email_outlined,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancelar',
                  style: TextStyle(color: Colors.grey.shade400)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final email = resetController.text.trim();
                if (!emailRegex.hasMatch(email)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Introduce un correo electrónico válido.'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                final vm = context.read<AuthViewModel>();
                final nav = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(context);
                final success = await vm.sendPasswordReset(email);
                if (!mounted) return;
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Revisa tu correo para restablecer la contraseña.'
                          : (vm.errorMessage ??
                              'No se pudo enviar el correo.'),
                    ),
                    backgroundColor:
                        success ? Colors.green.shade700 : Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Enviar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    resetController.dispose();
  }

  void _handleAuthResult(bool success, AuthViewModel viewModel) {
    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, a1, a2) => const MainScreen(),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (context, animation, secondary, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    } else if (viewModel.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: _cardColor,
      prefixIcon: Icon(icon, color: Colors.white38),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryPurple, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primaryPurple.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _cyanAccent.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28.0, vertical: 24.0),
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    Transform.translate(
                      offset: Offset(0, _headerSlide.value),
                      child: Opacity(
                        opacity: _headerOpacity.value,
                        child: Column(
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFEAD4FF),
                                    Color(0xFFB89BD9),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _cyanAccent.withOpacity(0.18),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Image.asset(
                                'assets/images/logo_sinfondo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'NOTOVA',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    Opacity(
                      opacity: _formOpacity.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              isLogin
                                  ? '¡Hola de nuevo!'
                                  : '¡Únete a Notova!',
                              key: ValueKey(isLogin),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              isLogin
                                  ? 'Inicia sesión para continuar tu racha.'
                                  : 'Crea tu cuenta y empieza a subir de nivel.',
                              key: ValueKey('sub_$isLogin'),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade400),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Opacity(
                      opacity: _formOpacity.value,
                      child: Column(
                        children: [
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              hint: 'ejemplo@notova.com',
                              icon: Icons.email_outlined,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.white38,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),

                          if (isLogin) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: const Text(
                                  '¿Olvidaste la contraseña?',
                                  style: TextStyle(
                                    color: _cyanAccent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ] else
                            const SizedBox(height: 24),

                          SizedBox(
                            height: 54,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submitAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                                disabledBackgroundColor:
                                    _primaryPurple.withOpacity(0.4),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22, width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          isLogin
                                              ? 'Iniciar Sesión'
                                              : 'Crear Cuenta',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward,
                                            color: Colors.white, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                      color:
                                          Colors.white.withOpacity(0.08))),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Text(
                                  'O CONTINUAR CON',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Divider(
                                      color:
                                          Colors.white.withOpacity(0.08))),
                            ],
                          ),
                          const SizedBox(height: 28),

                          SizedBox(
                            height: 54,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  isLoading ? null : _googleSignIn,
                              icon: const Icon(Icons.g_mobiledata,
                                  size: 28, color: Colors.white),
                              label: const Text(
                                'Google',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cardColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  side: BorderSide(
                                      color: Colors.white
                                          .withOpacity(0.08)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLogin
                                    ? '¿No tienes una cuenta? '
                                    : '¿Ya tienes una cuenta? ',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () => setState(
                                        () => isLogin = !isLogin),
                                child: Text(
                                  isLogin
                                      ? 'Regístrate'
                                      : 'Inicia Sesión',
                                  style: const TextStyle(
                                    color: _cyanAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
