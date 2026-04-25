// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/task_model.dart';
import '../repositories/notification_repository.dart';
import '../viewmodel/calendar_viewmodel.dart';
import '../viewmodel/user_viewmodel.dart';
import '../viewmodel/task_viewmodel.dart';
import '../models/calendar_event.dart';
import '../theme/app_colors.dart';
import 'all_events_screen.dart';
import 'all_tasks_screen.dart';
import 'main_screen.dart';

/// Devuelve la imagen apropiada para el avatar dando prioridad al archivo
/// local (para reflejar cambios al instante y funcionar sin conexión) y, como
/// fallback, al `avatarUrl` remoto.
ImageProvider? _avatarImageProvider(String? localPath, String? remoteUrl) {
  if (localPath != null) {
    final file = File(localPath);
    if (file.existsSync()) return FileImage(file);
  }
  if (remoteUrl == null || remoteUrl.isEmpty) return null;
  if (remoteUrl.startsWith('file://')) {
    final path = remoteUrl.substring('file://'.length);
    final file = File(path);
    if (file.existsSync()) return FileImage(file);
    return null;
  }
  return NetworkImage(remoteUrl);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _notifRepo = NotificationRepository();
  bool _notificationsOn = false;

  @override
  void initState() {
    super.initState();
    _loadNotifPref();
  }

  Future<void> _loadNotifPref() async {
    final on = await _notifRepo.isEnabled();
    if (mounted) setState(() => _notificationsOn = on);
  }

  Future<void> _toggleNotifications() async {
    if (!_notificationsOn) {
      final granted = await _notifRepo.requestPermission();
      if (!granted) return;
    }
    final newValue = !_notificationsOn;
    await _notifRepo.setEnabled(newValue);
    if (!mounted) return;
    setState(() => _notificationsOn = newValue);
    final s = context.read<AppStrings>();
    
    // Premium Toast-like Notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              newValue ? Icons.notifications_active : Icons.notifications_off,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                newValue ? s.get('notifications_on') : s.get('notifications_off'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.primaryPurple,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado global de carga del usuario, pero delegamos los 
    // datos específicos a Selectors para optimizar el rendimiento.
    final isLoading = context.select((UserViewModel vm) => vm.isLoading);
    final hasUser = context.select((UserViewModel vm) => vm.user != null);
    final s = context.watch<AppStrings>();
    final navHeight = MainScreen.navBarHeight(context);

    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
      );
    }

    if (!hasUser) {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserHeader(
                notificationsOn: _notificationsOn,
                onToggleNotifications: _toggleNotifications,
              ),
              const SizedBox(height: 24),
              const _XpCard(),
              const SizedBox(height: 28),
              _buildSectionHeader(s.get('up_next'), s.get('view_schedule'),
                onAction: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AllEventsScreen())),
              ),
              const SizedBox(height: 14),
              const _UpcomingEventsList(),
              const SizedBox(height: 28),
              _buildSectionHeader(s.get('pending_quests'), s.get('view_all'),
                onAction: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AllTasksScreen())),
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
    );
  }

  Widget _buildSectionHeader(String title, String actionText, {VoidCallback? onAction}) {
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
          onPressed: onAction,
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

    final localAvatar =
        context.select((UserViewModel vm) => vm.localAvatarPath);
    final avatarVersion =
        context.select((UserViewModel vm) => vm.avatarVersion);
    final avatarImage = _avatarImageProvider(localAvatar, user.avatarUrl);

    return Row(
      children: [
        Container(
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
  const _XpCard();

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

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
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
    final isSignedIn = context.select((CalendarViewModel vm) => vm.isSignedIn);
    final upcoming =
        context.select((CalendarViewModel vm) => vm.upcomingEvents);

    if (!isSignedIn) {
      return _infoCard(
        icon: Icons.calendar_month_outlined,
        message: s.get('connect_calendar_home'),
      );
    }

    final now = DateTime.now();
    final visible = upcoming
        .where((e) => e.start != null && e.start!.isAfter(now))
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  maxLines: 1,
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
                    color: Colors.grey.shade600,
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
    );
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
    final pendingTasks = context.select((TasksViewModel vm) => vm.pending);
    
    final tasksToShow = pendingTasks.take(3).toList();

    if (tasksToShow.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          s.get('no_pending_home'),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      );
    }

    return Column(
      children: tasksToShow.asMap().entries.map((entry) {
        final task = entry.value;
        Color priorityColor = AppColors.accentPurple;
        if (task.priority == 'HIGH') priorityColor = AppColors.cyanAccent;
        if (task.priority == 'LOW') priorityColor = Colors.grey;
        
        return Column(
          children: [
            _buildTaskCard(context, task, priorityColor, s),
            if (entry.key < tasksToShow.length - 1) const SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    TaskModel task,
    Color priorityColor,
    AppStrings s,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final taskVm = context.read<TasksViewModel>();
              final didLevelUp = await taskVm.toggleTaskCompletion(
                task.id,
                task.xpReward,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${s.get('quest_completed')} +${task.xpReward} XP',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.primaryPurple,
                  duration: const Duration(seconds: 2),
                ),
              );
              if (didLevelUp) _showLevelUpDialog(context, s);
            },
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primaryPurple, width: 2),
              ),
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
                if (task.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    task.subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _priorityLabel(task.priority, s),
              style: TextStyle(
                color: priorityColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelUpDialog(BuildContext context, AppStrings s) {
    final user = context.read<UserViewModel>().user;
    if (user == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '🎉 ${s.get('level_up')}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.military_tech, color: AppColors.cyanAccent, size: 64),
            const SizedBox(height: 16),
            Text(
              '${s.get('level')} ${user.level} · ${user.rank}',
              style: const TextStyle(
                color: AppColors.cyanAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.get('keep_completing'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              s.get('continue'),
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

  String _priorityLabel(String priority, AppStrings s) {
    switch (priority) {
      case 'HIGH':
        return s.get('priority_high');
      case 'MED':
        return s.get('priority_med');
      case 'LOW':
        return s.get('priority_low');
      default:
        return priority;
    }
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
            user.rank,
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
