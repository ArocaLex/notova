import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationRepository {
  static const _prefKey = 'notifications_enabled';
  static final NotificationRepository _instance = NotificationRepository._();
  factory NotificationRepository() => _instance;
  NotificationRepository._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    _initialized = true;
  }

  // ── Preference ────────────────────────────────────────────────────────────

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    if (!value) {
      await _plugin.cancelAll();
    }
  }

  // ── Request permission (Android 13+ / iOS) ───────────────────────────────

  Future<bool> requestPermission() async {
    await init();

    // Android 13+
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  // ── Schedule / Cancel ─────────────────────────────────────────────────────

  static const _notifDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'task_reminders',
      'Recordatorios de Quests',
      channelDescription: 'Notificaciones de tareas y recordatorios',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Muestra notificación inmediata (tarea creada, completada, etc.)
  Future<void> showInstant({
    required String title,
    required String body,
    int? id,
  }) async {
    final enabled = await isEnabled();
    if (!enabled) return;
    await init();

    await _plugin.show(
      id: id ?? title.hashCode,
      title: title,
      body: body,
      notificationDetails: _notifDetails,
    );
  }

  /// Programa notificación 1 hora antes de [dueDate].
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime dueDate,
  }) async {
    final enabled = await isEnabled();
    if (!enabled) return;
    await init();

    // 1-hour reminder
    final oneHourBefore = dueDate.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(DateTime.now())) {
      final tzTime = tz.TZDateTime.from(oneHourBefore, tz.local);
      await _plugin.zonedSchedule(
        id: taskId.hashCode,
        title: '⏰ Quest por vencer',
        body: '"$title" vence en 1 hora',
        scheduledDate: tzTime,
        notificationDetails: _notifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    // 1-day reminder
    final oneDayBefore = dueDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      final tzTime = tz.TZDateTime.from(oneDayBefore, tz.local);
      await _plugin.zonedSchedule(
        id: '${taskId}_day'.hashCode,
        title: '📋 Quest pendiente',
        body: '"$title" vence mañana',
        scheduledDate: tzTime,
        notificationDetails: _notifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Cancela las notificaciones programadas para una tarea.
  Future<void> cancelTaskReminder(String taskId) async {
    await init();
    await _plugin.cancel(id: taskId.hashCode);
    await _plugin.cancel(id: '${taskId}_day'.hashCode);
  }
}
