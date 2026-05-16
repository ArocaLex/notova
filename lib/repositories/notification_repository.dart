import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Repositorio de notificaciones locales para Notova.
///
/// Singleton que encapsula [FlutterLocalNotificationsPlugin] para mostrar
/// notificaciones instantáneas y programar recordatorios vinculados a las
/// tareas del usuario. Respeta la preferencia de activación almacenada en
/// [SharedPreferences].
class NotificationRepository {
  static const _prefKey = 'notifications_enabled';
  static final NotificationRepository _instance = NotificationRepository._();
  factory NotificationRepository() => _instance;
  NotificationRepository._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Inicializa el plugin de notificaciones y configura la zona horaria.
  ///
  /// Es idempotente: las llamadas sucesivas no tienen efecto.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // Intenta usar la zona horaria del dispositivo (funciona en iOS y Android
    // moderno que devuelve nombres IANA). Si el nombre no es reconocido, usa
    // Europe/Madrid como fallback.
    try {
      final deviceTz = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(deviceTz));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Madrid'));
    }

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
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

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }

  /// Activa o desactiva las notificaciones y cancela todas las pendientes
  /// si [value] es `false`.
  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    if (!value) {
      await _plugin.cancelAll();
    }
  }

  /// Comprueba si el permiso de notificaciones está concedido en el OS
  /// **sin mostrar ningún diálogo**. Útil para sincronizar la preferencia
  /// local con el estado real del sistema (e.g., tras revocar desde Ajustes).
  Future<bool> arePermissionsGranted() async {
    await _ensureInitialized();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final perms = await ios.checkPermissions();
      return perms?.isEnabled ?? false;
    }
    return true;
  }

  /// Solicita permiso de notificaciones al sistema operativo.
  ///
  /// Retorna `true` si el permiso fue concedido. En plataformas que no
  /// requieren permiso explícito, retorna `true` directamente.
  Future<bool> requestPermission() async {
    await _ensureInitialized();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

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

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'task_reminders',
      'Recordatorios de Quests',
      channelDescription: 'Notificaciones de tareas y recordatorios',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Muestra una notificación instantánea si las notificaciones están activadas.
  Future<void> showImmediate({
    required String title,
    required String body,
    int? id,
  }) async {
    final enabled = await isEnabled();
    if (!enabled) return;
    await _ensureInitialized();

    await _plugin.show(
      id: id ?? title.hashCode,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  /// Programa recordatorios 1 hora y 1 día antes de [dueDate] para la tarea.
  ///
  /// Solo programa una notificación si la fecha calculada es posterior al
  /// momento actual. No tiene efecto si las notificaciones están desactivadas.
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime dueDate,
  }) async {
    final enabled = await isEnabled();
    if (!enabled) return;
    await _ensureInitialized();

    final oneHourBefore = dueDate.subtract(const Duration(hours: 1));
    final thirtyMinBefore = dueDate.subtract(const Duration(minutes: 30));
    final now = DateTime.now();

    if (oneHourBefore.isAfter(now)) {
      final tzTime = tz.TZDateTime.from(oneHourBefore, tz.local);
      await _plugin.zonedSchedule(
        id: taskId.hashCode,
        title: '⏰ Quest por vencer',
        body: '"$title" vence en 1 hora',
        scheduledDate: tzTime,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } else if (thirtyMinBefore.isAfter(now)) {
      final tzTime = tz.TZDateTime.from(thirtyMinBefore, tz.local);
      await _plugin.zonedSchedule(
        id: taskId.hashCode,
        title: '⏰ Quest por vencer',
        body: '"$title" vence en 30 minutos',
        scheduledDate: tzTime,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    final oneDayBefore = dueDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      final tzTime = tz.TZDateTime.from(oneDayBefore, tz.local);
      await _plugin.zonedSchedule(
        id: '${taskId}_day'.hashCode,
        title: '📋 Quest pendiente',
        body: '"$title" vence mañana',
        scheduledDate: tzTime,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Cancela las notificaciones programadas para la tarea identificada por
  /// [taskId] (recordatorio de 1 hora y de 1 día).
  Future<void> cancelTaskReminder(String taskId) async {
    await _ensureInitialized();
    await _plugin.cancel(id: taskId.hashCode);
    await _plugin.cancel(id: '${taskId}_day'.hashCode);
  }
}
