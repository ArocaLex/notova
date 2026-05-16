// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/calendar_event.dart';
import '../models/task_model.dart';
import '../repositories/notification_repository.dart';
import '../viewmodel/calendar_viewmodel.dart';
import '../viewmodel/user_viewmodel.dart';
import '../viewmodel/task_viewmodel.dart';
import '../theme/app_colors.dart';
import '../utils/tutorial_keys.dart';
import 'all_events_screen.dart';
import 'all_tasks_screen.dart';
import '../models/user_model.dart';
import 'main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _notifRepo = NotificationRepository();
  bool _notificationsOn = false;
  bool _isTogglingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadNotifPref();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<TasksViewModel>().refresh(),
      context.read<CalendarViewModel>().refreshUpcoming(),
    ]);
  }

  Future<void> _loadNotifPref() async {
    final prefEnabled = await _notifRepo.isEnabled();
    if (!prefEnabled) {
      if (mounted) setState(() => _notificationsOn = false);
      return;
    }
    // Preferencia dice ON — consultar el OS sin mostrar ningún diálogo.
    final osGranted = await _notifRepo.arePermissionsGranted();
    if (!osGranted) {
      // Primera vez o permiso revocado desde Ajustes → pedir ahora.
      final granted = await _notifRepo.requestPermission();
      if (!granted) {
        await _notifRepo.setEnabled(false);
        if (mounted) setState(() => _notificationsOn = false);
        return;
      }
    }
    if (mounted) setState(() => _notificationsOn = true);
  }

  Future<void> _toggleNotifications() async {
    if (_isTogglingNotifications) return;
    if (mounted) setState(() => _isTogglingNotifications = true);
    try {
      if (!_notificationsOn) {
        final granted = await _notifRepo.requestPermission();
        if (!granted) {
          final osGranted = await _notifRepo.arePermissionsGranted();
          if (!osGranted && mounted) _showNotifBlockedDialog();
          return;
        }
      }
      final newValue = !_notificationsOn;
      await _notifRepo.setEnabled(newValue);
      if (mounted) setState(() => _notificationsOn = newValue);
    } finally {
      if (mounted) setState(() => _isTogglingNotifications = false);
    }
  }

  void _showNotifBlockedDialog() {
    final s = context.read<AppStrings>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          s.get('notif_blocked_title'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Text(
          s.get('notif_blocked_body'),
          style: TextStyle(color: Colors.grey.shade400, height: 1.5, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              s.get('ok'),
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
    // Escuchamos el State global de carga del User, pero delegamos los 
    // datos específicos a Selectors para optimizar el rendimiento.
    final estaCargando = context.select((UserViewModel vm) => vm.isLoading);
    final tieneUsuario = context.select((UserViewModel vm) => vm.hasUser);
    final s = context.watch<AppStrings>();
    final navHeight = MainScreen.navBarHeight(context);

    if (estaCargando) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
      );
    }

    if (!tieneUsuario) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(s.get('creating_profile'),
              style: const TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primaryPurple,
          backgroundColor: AppColors.card,
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserHeader(
                notificationsOn: _notificationsOn,
                onToggleNotifications: _toggleNotifications,
              ),
              const SizedBox(height: 24),
              _XpCard(key: TutorialKeys.homeXpCard),
              const SizedBox(height: 28),
              _buildSectionHeader(s.get('up_next'), s.get('view_schedule'),
                onTap: () async {
                  final result = await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AllEventsScreen()));
                  if (result is CalendarEvent) {
                    if (!context.mounted) return;
                    context.findAncestorStateOfType<MainScreenState>()?.navigateToEvent(result);
                  }
                },
              ),
              const SizedBox(height: 14),
              const _UpcomingEventsList(),
              const SizedBox(height: 28),
              _buildSectionHeader(s.get('pending_quests'), s.get('view_all'),
                onTap: () async {
                  final result = await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AllTasksScreen()));
                  if (result is TaskModel) {
                    if (!context.mounted) return;
                    context.findAncestorStateOfType<MainScreenState>()?.navigateToTask(result);
                  }
                },
              ),
              const SizedBox(height: 14),
              const _PendingTasksList(),
              const SizedBox(height: 28),
              const _StatsRow(),
              SizedBox(height: navHeight + 24),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionText, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
          ),
          child: Text(
            actionText,
            style: const TextStyle(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserHeader extends StatelessWidget {
  final bool notificationsOn;
  final VoidCallback onToggleNotifications;

  const _UserHeader({
    required this.notificationsOn,
    required this.onToggleNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final user = context.select((UserViewModel vm) => vm.user);
    if (user == null) return const SizedBox.shrink();

    final avatarVersion =
        context.select((UserViewModel vm) => vm.avatarVersion);
    final avatarImage =
        context.select((UserViewModel vm) => vm.avatarImage);

    return Row(
      children: [
        GestureDetector(
          onTap: () => context
              .findAncestorStateOfType<MainScreenState>()
              ?.selectTab(3),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primaryPurple, AppColors.cyanAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: CircleAvatar(
              key: ValueKey('home_avatar_$avatarVersion'),
              radius: 24,
              backgroundColor: const Color(0xFF2A223E),
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? const Icon(Icons.person, color: Colors.white70, size: 28)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting(s)}, ${user.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(DateTime.now(), s),
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onToggleNotifications,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: notificationsOn
                  ? AppColors.primaryPurple.withOpacity(0.2)
                  : AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(
                color: notificationsOn
                    ? AppColors.primaryPurple.withOpacity(0.5)
                    : Colors.white10,
              ),
            ),
            child: Icon(
              notificationsOn
                  ? Icons.notifications_active
                  : Icons.notifications_outlined,
              color: notificationsOn
                  ? AppColors.primaryPurple
                  : Colors.white70,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  String _greeting(AppStrings s) {
    final h = DateTime.now().hour;
    if (h < 12) return s.get('good_morning');
    if (h < 19) return s.get('good_afternoon');
    return s.get('good_evening');
  }

  String _formatDate(DateTime date, AppStrings s) {
    final days = s.get('days_short').split(',');
    final months = s.get('months_short').split(',');
    return s.isSpanish
        ? '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}'
        : '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _XpCard extends StatelessWidget {
  const _XpCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((UserViewModel vm) => vm.user);
    if (user == null) return const SizedBox.shrink();

    final s = context.watch<AppStrings>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C1A99), AppColors.primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    s.get('xp_progress'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Text(
                '${_formatNumber(user.totalXpEver)} / ${_formatNumber(user.nextLevelMinXp)} XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: user.xpProgress,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 6,
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.get('xp_to_next')
                .replaceFirst('%s', _formatNumber(user.xpRemaining))
                .replaceFirst('%d', '${user.level + 1}'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int numero) {
    return numero.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

/// Lista compacta de los próximos eventos agregados de todas las cuentas
/// conectadas. Cada item muestra el día, el rango horario y la cuenta
/// asociada en texto pequeño.
class _UpcomingEventsList extends StatelessWidget {
  const _UpcomingEventsList();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final estaIdentificado = context.select((CalendarViewModel vm) => vm.isSignedIn);
    final proximos =
        context.select((CalendarViewModel vm) => vm.upcomingEvents);

    if (!estaIdentificado) {
      return _infoCard(
        icon: Icons.calendar_month_outlined,
        message: s.get('connect_calendar_home'),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visible = proximos
        .where((e) => e.start != null && !e.start!.isBefore(today))
        .take(3)
        .toList();

    if (visible.isEmpty) {
      return _infoCard(
        icon: Icons.event_available,
        message: s.get('no_upcoming_week'),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < visible.length; i++) ...[
          _UpcomingEventTile(event: visible[i]),
          if (i < visible.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _infoCard({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Item compacto que representa un evento próximo en la lista de agenda
/// del Home. Muestra una barra con el color de la cuenta, el título del
/// evento, una etiqueta de día (HOY/MAÑANA/`LUN 21 ABR`), el rango horario
/// y el email de la cuenta en texto pequeño.
class _UpcomingEventTile extends StatelessWidget {
  final CalendarEvent event;

  const _UpcomingEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final accountColor = context.select(
      (CalendarViewModel vm) => vm.calendarColor(event.calendarId),
    );

    final dayLabel = _dayLabel(event.start!, s);
    final timeLabel = event.isAllDay
        ? s.get('all_day')
        : _formatTimeRange(event.start, event.end);

    return GestureDetector(
      onTap: () {
        context.findAncestorStateOfType<MainScreenState>()?.navigateToEvent(event);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: IntrinsicHeight(
        child: Row(
          children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: accountColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      dayLabel,
                      style: TextStyle(
                        color: accountColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '  ·  ',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                    ),
                    Flexible(
                      child: Text(
                        timeLabel,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.accountEmail,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    ));
  }

  /// Devuelve la etiqueta de día para [date]: `HOY`, `MAÑANA` o una
  /// combinación de día de semana abreviado + número + mes (por ejemplo
  /// `LUN 21 ABR` en español, `MON APR 21` en inglés).
  String _dayLabel(DateTime date, AppStrings s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) return s.get('today');
    if (diff == 1) return s.get('tomorrow');
    final days = s.get('days_short').split(',');
    final months = s.get('months_short').split(',');
    final weekday = days[date.weekday - 1].toUpperCase();
    final month = months[date.month - 1].toUpperCase();
    return s.isSpanish
        ? '$weekday ${date.day} $month'
        : '$weekday $month ${date.day}';
  }

  /// Formatea el rango horario del evento como `H:MM - H:MM AM/PM`, o sólo
  /// `H:MM AM/PM` si no hay hora de fin.
  String _formatTimeRange(DateTime? start, DateTime? end) {
    if (start == null) return '';
    String fmt(DateTime d) {
      final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
      final m = d.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    String period(DateTime d) => d.hour >= 12 ? 'PM' : 'AM';

    if (end == null) return '${fmt(start)} ${period(start)}';
    return '${fmt(start)} - ${fmt(end)} ${period(end)}';
  }
}

class _PendingTasksList extends StatelessWidget {
  const _PendingTasksList();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final tasks = context.select((TasksViewModel vm) => vm.pending);

    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(Icons.task_alt, color: Colors.grey.shade600, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                s.get('no_pending_home'),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final preview = tasks.take(3).toList();
    return Column(
      children: [
        for (int i = 0; i < preview.length; i++) ...[
          _TaskTile(task: preview[i]),
          if (i < preview.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  const _TaskTile({required this.task});

  static Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceFirst('#', '');
    if (clean.length != 6) return null;
    final val = int.tryParse(clean, radix: 16);
    return val != null ? Color(0xFF000000 | val) : null;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();

    final Color priorityColor = switch (task.priority) {
      'HIGH' => AppColors.priorityHigh,
      'MED'  => AppColors.priorityMed,
      'LOW'  => AppColors.priorityLow,
      _      => AppColors.accentPurple,
    };
    final Color? taskColor = _parseHex(task.color);
    final barColor = taskColor ?? priorityColor;
    final dueDateColor = AppColors.textMuted;

    return GestureDetector(
      onTap: () {
        context.findAncestorStateOfType<MainScreenState>()?.navigateToTask(task);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: taskColor?.withOpacity(0.3) ?? Colors.white.withOpacity(0.04),
          ),
          boxShadow: taskColor != null
              ? [
                  BoxShadow(
                    color: taskColor.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: barColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _PriorityChip(
                                label: _priorityLabel(task.priority, s),
                                color: priorityColor,
                              ),
                              if (task.subtitle.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    task.subtitle,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (task.dueDate != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 11,
                                  color: dueDateColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _dueDateLabel(task.dueDate!, s),
                                  style: TextStyle(
                                    color: dueDateColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cyanAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.cyanAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '+${task.xpReward} XP',
                        style: const TextStyle(
                          color: AppColors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
    ));
  }

  String _dueDateLabel(DateTime date, AppStrings s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) return s.get('today');
    if (diff == 1) return s.get('tomorrow');
    final days = s.get('days_short').split(',');
    final months = s.get('months_short').split(',');
    final weekday = days[date.weekday - 1].toUpperCase();
    final month = months[date.month - 1].toUpperCase();
    return s.isSpanish
        ? '$weekday ${date.day} $month'
        : '$weekday $month ${date.day}';
  }

  static String _priorityLabel(String priority, AppStrings s) {
    return switch (priority) {
      'HIGH' => s.get('priority_high'),
      'MED'  => s.get('priority_med'),
      'LOW'  => s.get('priority_low'),
      _      => priority,
    };
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  const _PriorityChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final user = context.select((UserViewModel vm) => vm.user);
    if (user == null) return const SizedBox.shrink();

    final s = context.watch<AppStrings>();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.local_fire_department,
            '${user.dayStreak} ${s.get('days')}',
            s.get('streak'),
            Colors.orangeAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            Icons.emoji_events,
            s.get(UserModel.rankKeyForLevel(user.level)),
            s.get('ranking'),
            AppColors.cyanAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

