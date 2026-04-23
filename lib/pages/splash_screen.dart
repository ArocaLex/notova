// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../repositories/local_task_repository.dart';
import '../repositories/user_repository.dart';
import 'main_screen.dart';
import 'welcome_screen.dart';

/// Pantalla inicial con animación de carga y enrutado.
///
/// Decide el primer destino en función de:
/// - Sesión de Firebase (si hay usuario autenticado).
/// - Flag `onboarding_seen` persistido en [SharedPreferences].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _bgColor = Color(0xFF120E1A);
  static const _primaryPurple = Color(0xFF7B2CBF);
  static const _cyanAccent = Color(0xFFDEB7FF);

  String? _userName;

  late final AnimationController _logoController;
  late final AnimationController _contentController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _titleSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _logoController.forward().then((_) {
      _contentController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/notova.png'), context)
          .then((_) => _checkAuthState())
          .catchError((_) => _checkAuthState());
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Actualiza la racha diaria en Firestore sin bloquear el flujo del splash.
  Future<void> _updateStreakSilently() async {
    try {
      await UserRepository().checkAndUpdateStreak();
    } catch (_) {}
  }

  Future<void> _checkAuthState() async {
    final minDisplay = Future.delayed(const Duration(milliseconds: 2800));

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        _userName =
            user.displayName ?? user.email?.split('@')[0] ?? 'Usuario';
      });
      LocalTaskRepository().syncFromFirestore();
      unawaited(_updateStreakSilently());
    }

    final Widget destination =
        user == null ? const WelcomeScreen() : const MainScreen();

    await minDisplay;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (pageContext, primaryAnimation, secondaryAnimation) =>
            destination,
        transitionDuration: const Duration(milliseconds: 500),
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
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 0.8,
                  colors: [
                    _primaryPurple.withOpacity(0.12),
                    _bgColor,
                  ],
                ),
              ),
            ),
          ),

          ..._buildParticles(),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge(
                      [_logoController, _pulseController]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (context, _) => Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryPurple
                                          .withOpacity(_pulseAnim.value),
                                      blurRadius: 50,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ClipOval(
                              child: Image.asset(
                                'assets/images/notova.png',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                AnimatedBuilder(
                  animation: _contentController,
                  builder: (context, _) => Opacity(
                    opacity: _subtitleOpacity.value,
                    child: const _LiquidLoadingBar(),
                  ),
                ),

                const SizedBox(height: 24),

                AnimatedBuilder(
                  animation: _contentController,
                  builder: (context, _) => Transform.translate(
                    offset: Offset(0, _titleSlide.value),
                    child: Column(
                      children: [
                        Opacity(
                          opacity: _titleOpacity.value,
                          child: const Text(
                            'NOTOVA',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: _subtitleOpacity.value,
                          child: Text(
                            _userName != null
                                ? '${context.watch<AppStrings>().get('hello')}, $_userName'
                                : context.watch<AppStrings>().get('splash_subtitle'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _cyanAccent.withOpacity(0.8),
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
          ),
        ],
      ),
    );
  }

  List<Widget> _buildParticles() {
    final rng = math.Random(42);
    return List.generate(8, (i) {
      final left = 0.2 + rng.nextDouble() * 0.6;
      final top = 0.25 + rng.nextDouble() * 0.5;
      final size = 2.0 + rng.nextDouble() * 3.0;
      final delay = Duration(milliseconds: rng.nextInt(2000));

      return Positioned(
        left: MediaQueryData.fromView(
                    WidgetsBinding.instance.platformDispatcher.views.first)
                .size
                .width *
            left,
        top: MediaQueryData.fromView(
                    WidgetsBinding.instance.platformDispatcher.views.first)
                .size
                .height *
            top,
        child: _FloatingParticle(
          size: size,
          delay: delay,
          color: i.isEven ? _primaryPurple : _cyanAccent,
        ),
      );
    });
  }
}

/// Barra de carga animada con efecto líquido que se muestra durante el splash.
class _LiquidLoadingBar extends StatefulWidget {
  const _LiquidLoadingBar();

  @override
  _LiquidLoadingBarState createState() => _LiquidLoadingBarState();
}

class _LiquidLoadingBarState extends State<_LiquidLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: 160,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white.withOpacity(0.08),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: CustomPaint(
              painter: _LiquidBarPainter(_ctrl.value),
              size: const Size(160, 3),
            ),
          ),
        );
      },
    );
  }
}

/// Pinta el blob líquido en movimiento sobre la barra de carga.
class _LiquidBarPainter extends CustomPainter {
  final double progress;
  _LiquidBarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const purple = Color(0xFF7B2CBF);
    const white = Colors.white;

    final blobWidth = size.width * 0.45;
    final center = size.width * (0.5 + 0.5 * math.sin(progress * 2 * math.pi));

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(rect);

    final gradient = LinearGradient(
      colors: [
        purple.withOpacity(0.0),
        white.withOpacity(0.9),
        purple,
        purple.withOpacity(0.8),
        white.withOpacity(0.7),
        purple.withOpacity(0.0),
      ],
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCenter(
          center: Offset(center, size.height / 2),
          width: blobWidth,
          height: size.height,
        ),
      );

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(2),
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_LiquidBarPainter old) => old.progress != progress;
}

/// Partícula flotante animada que rodea el logo en la pantalla de inicio.
class _FloatingParticle extends StatefulWidget {
  final double size;
  final Duration delay;
  final Color color;

  const _FloatingParticle({
    required this.size,
    required this.delay,
    required this.color,
  });

  @override
  _FloatingParticleState createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final dy = math.sin(_ctrl.value * math.pi) * 12;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Opacity(
            opacity: 0.15 + _ctrl.value * 0.2,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}
