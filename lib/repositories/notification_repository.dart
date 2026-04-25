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
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // Intenta usar la zona horaria del dispositivo (funciona en iOS y Android
    // moderno que devuelve nombres IANA). Si el nombre no es reconocido, usa
    // America/Mexico_City como fallback para el mercado principal.
    try {
      final deviceTz = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(deviceTz));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
    }

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

  /// Indica si las notificaciones están activadas por el usuario.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
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

  /// Solicita permiso de notificaciones al sistema operativo.
  ///
  /// Retorna `true` si el permiso fue concedido. En plataformas que no
  /// requieren permiso explícito, retorna `true` directamente.
  Future<bool> requestPermission() async {
    await init();

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

  /// Muestra una notificación instantánea si las notificaciones están activadas.
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
    await init();

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

  /// Cancela las notificaciones programadas para la tarea identificada por
  /// [taskId] (recordatorio de 1 hora y de 1 día).
  Future<void> cancelTaskReminder(String taskId) async {
    await init();
    await _plugin.cancel(id: taskId.hashCode);
    await _plugin.cancel(id: '${taskId}_day'.hashCode);
  }
}
