// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';


import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/tutorial_keys.dart';
import '../viewmodel/calendar_viewmodel.dart';
import '../widgets/tutorial_bridge_dialog.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'task_screen.dart';
import 'profile_screen.dart';

/// Contenedor principal de la app con navegación inferior.
///
/// Aloja las pantallas base (Home, Calendar, Quests y Profile) y mantiene el
/// estado de navegación usando un `IndexedStack` para preservar el estado de
/// cada pestaña.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.showTutorial = false});

  /// Si `true`, lanza el tutorial de coach-marks directamente al entrar.
  /// Usado por [OnboardingScreen] y por "Repetir Tutorial" en [ProfileScreen].
  final bool showTutorial;

  /// Altura total de la cápsula de navegación desde la parte inferior
  /// de la pantalla, incluyendo el inset del sistema (home indicator /
  /// barra de 3 botones).
  static double navBarHeight(BuildContext context) {
    final sys = MediaQuery.of(context).viewPadding.bottom;
    return _capsuleHeight + (sys > 0 ? sys + 16.0 : 24.0);
  }

  /// Distancia desde la parte inferior de la pantalla a la que debe
  /// posicionarse la parte inferior de un FAB para quedar por encima
  /// de la cápsula con un margen de 12 px.
  static double fabBottom(BuildContext context) =>
      navBarHeight(context) + 12.0;

  /// Altura del contenedor de la cápsula de navegación.
  static const double _capsuleHeight = 66.0;

  @override
  MainScreenState createState() => MainScreenState();
}

/// Estado de [MainScreen].
///
/// Usa [WidgetsBindingObserver] para detectar el retorno de la app desde
/// background y reposicionar el calendario en el día de hoy cuando la
/// pestaña activa es la de calendario.
class MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  /// Índice de la pestaña del calendario dentro de [_screens].
  static const int _calendarTabIndex = 1;

  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    TasksScreen(),
    ProfileScreen(),
  ];

  final List<GlobalKey> _navKeys = List.generate(4, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });
  }

  Future<void> _checkAndShowTutorial() async {
    if (widget.showTutorial) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _currentIndex = 0);
          _showHomeTutorial();
        }
      });
      return;
    }
    // Para usuarios que ingresan por login (no onboarding): ofrecer tutorial
    // si todavía no lo han visto.
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenFullTutorial') ?? false;
    if (!hasSeen && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showBridgeAndMaybeTutorial();
      });
    }
  }

  Future<void> _showBridgeAndMaybeTutorial() async {
    final wantsTutorial = await showTutorialBridgeDialog(context);
    if (!mounted) return;
    if (wantsTutorial) {
      setState(() => _currentIndex = 0);
      _showHomeTutorial();
    } else {
      // Marcamos visto para no volver a preguntar.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenFullTutorial', true);
    }
  }

  void _showHomeTutorial() {
    final s = context.read<AppStrings>();
    TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "homeXp",
          keyTarget: TutorialKeys.homeXpCard,
          alignSkip: Alignment.bottomRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) => _buildTutorialContent(
                title: s.get('tutorial_home_title'),
                desc: s.get('tutorial_home_desc'),
              ),
            ),
          ],
        ),
      ],
      colorShadow: Colors.black,
      textSkip: s.get('tutorial_skip'),
      paddingFocus: 10,
      opacityShadow: 0.95,
      onFinish: () {
        setState(() => _currentIndex = 1);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _showCalendarTutorial();
        });
      },
      onSkip: () {
        SharedPreferences.getInstance()
            .then((p) => p.setBool('hasSeenFullTutorial', true));
        return true;
      },
    ).show(context: context);
  }

  void _showCalendarTutorial() {
    final s = context.read<AppStrings>();
    TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "calAdd",
          keyTarget: TutorialKeys.calAddEvent,
          alignSkip: Alignment.bottomRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              padding: const EdgeInsets.only(top: 40),
              builder: (context, controller) => _buildTutorialContent(
                title: s.get('tutorial_calendar_title'),
                desc: s.get('tutorial_calendar_desc'),
              ),
            ),
          ],
        ),
      ],
      colorShadow: Colors.black,
      textSkip: s.get('tutorial_skip'),
      paddingFocus: 10,
      opacityShadow: 0.95,
      onFinish: () {
        setState(() => _currentIndex = 2);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _showTasksTutorial();
        });
      },
      onSkip: () {
        SharedPreferences.getInstance()
            .then((p) => p.setBool('hasSeenFullTutorial', true));
        return true;
      },
    ).show(context: context);
  }

  void _showTasksTutorial() {
    final s = context.read<AppStrings>();
    TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "tasksFab",
          keyTarget: TutorialKeys.tasksFab,
          alignSkip: Alignment.bottomRight,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => _buildTutorialContent(
                title: s.get('tutorial_tasks_title'),
                desc: s.get('tutorial_tasks_desc'),
              ),
            ),
          ],
        ),
      ],
      colorShadow: Colors.black,
      textSkip: s.get('tutorial_skip'),
      paddingFocus: 10,
      opacityShadow: 0.95,
      onFinish: () {
        setState(() => _currentIndex = 3);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _showProfileTutorial();
        });
      },
      onSkip: () {
        SharedPreferences.getInstance()
            .then((p) => p.setBool('hasSeenFullTutorial', true));
        return true;
      },
    ).show(context: context);
  }

  void _showProfileTutorial() {
    final s = context.read<AppStrings>();
    TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "profileSettings",
          keyTarget: TutorialKeys.profileSettings,
          alignSkip: Alignment.bottomRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) => _buildTutorialContent(
                title: s.get('tutorial_profile_title'),
                desc: s.get('tutorial_profile_desc'),
              ),
            ),
          ],
        ),
      ],
      colorShadow: Colors.black,
      textSkip: s.get('tutorial_finish'),
      paddingFocus: 10,
      opacityShadow: 0.95,
      onFinish: () {
        SharedPreferences.getInstance()
            .then((p) => p.setBool('hasSeenFullTutorial', true));
        setState(() => _currentIndex = 0);
      },
      onSkip: () {
        SharedPreferences.getInstance()
            .then((p) => p.setBool('hasSeenFullTutorial', true));
        setState(() => _currentIndex = 0);
        return true;
      },
    ).show(context: context);
  }

  Widget _buildTutorialContent({required String title, required String desc}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryPurple,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          desc,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Al volver a primer plano con la pestaña calendario activa, reposiciona
  /// el calendario en el día de hoy para que no quede "atascado" en una
  /// fecha previamente seleccionada.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _currentIndex == _calendarTabIndex) {
      context.read<CalendarViewModel>().resetToToday();
    }
  }

  /// Cambia la pestaña activa y, al entrar al calendario desde otra pestaña,
  /// reposiciona la vista en el día de hoy.
  void _onTabTap(int index) {
    if (index == _calendarTabIndex && _currentIndex != _calendarTabIndex) {
      context.read<CalendarViewModel>().resetToToday();
    }
    setState(() => _currentIndex = index);
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    final s = context.read<AppStrings>();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          s.get('exit_dialog_title'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          s.get('exit_dialog_message'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              s.get('cancel'),
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.get('exit_dialog_exit'),
              style: const TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final sys = MediaQuery.of(context).viewPadding.bottom;
    final navBottom = sys > 0 ? sys + 16.0 : 24.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog(context);
        if (shouldExit == true) {
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(bottom: navBottom),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.card.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          blurRadius: 1,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildNavItem(0, Icons.home_rounded, s.get('nav_home'), key: _navKeys[0]),
                        const SizedBox(width: 4),
                        _buildNavItem(
                            1, Icons.calendar_month_rounded, s.get('nav_calendar'), key: _navKeys[1]),
                        const SizedBox(width: 4),
                        _buildNavItem(
                            2, Icons.check_circle_rounded, s.get('nav_quests'), key: _navKeys[2]),
                        const SizedBox(width: 4),
                        _buildNavItem(
                            3, Icons.person_rounded, s.get('nav_profile'), key: _navKeys[3]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {GlobalKey? key}) {
    final isSelected = _currentIndex == index;
    const primaryPurple = AppColors.primaryPurple;

    return GestureDetector(
      key: key,
      onTap: () => _onTabTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryPurple.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? Border.all(color: primaryPurple.withOpacity(0.5), width: 1)
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryPurple : Colors.grey.shade600,
              size: 26,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: primaryPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
