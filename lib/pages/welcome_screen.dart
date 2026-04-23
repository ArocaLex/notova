// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'auth_screen.dart';

/// Pantalla de bienvenida que precede al flujo de autenticación.
///
/// Muestra el logo de Notova y dos botones principales: Iniciar Sesión
/// y Registrarse. Cada botón navega a [AuthScreen] con el modo preseleccionado.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  WelcomeScreenState createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const _bgColor = Color(0xFF120E1A);
  static const _primaryPurple = Color(0xFF7B2CBF);
  static const _cyanAccent = Color(0xFFDEB7FF);

  late final AnimationController _ctrl;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _contentOpacity;
  late final Animation<double> _contentSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );
    _contentSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _navigateTo({required bool isLogin}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (pageContext, primaryAnimation, secondaryAnimation) =>
            AuthScreen(initialIsLogin: isLogin),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder:
            (pageContext, primaryAnimation, secondaryAnimation, child) =>
                FadeTransition(opacity: primaryAnimation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_primaryPurple.withOpacity(0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_cyanAccent.withOpacity(0.08), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  AnimatedBuilder(
                    animation: _ctrl,
                    child: Column(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFEAD4FF), Color(0xFFB89BD9)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryPurple.withOpacity(0.45),
                                blurRadius: 36,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo_sinfondo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'NOTOVA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 30,
                            letterSpacing: 6,
                          ),
                        ),
                      ],
                    ),
                    builder: (context2, child2) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child2,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Content: tagline + buttons
                  AnimatedBuilder(
                    animation: _ctrl,
                    child: Column(
                      children: [
                        const Text(
                          'Bienvenido a Notova',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Convierte tus tareas en misiones.\nGana XP y sube de nivel.',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // Iniciar Sesión
                        SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _navigateTo(isLogin: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Registrarse
                        SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _navigateTo(isLogin: false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _cyanAccent.withOpacity(0.4),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Registrarse',
                              style: TextStyle(
                                color: _cyanAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    builder: (context3, child3) => Opacity(
                      opacity: _contentOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _contentSlide.value),
                        child: child3,
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Tu productividad gamificada',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
