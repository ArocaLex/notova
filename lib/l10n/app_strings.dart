import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestión de idioma (ES/EN) con persistencia en SharedPreferences.
class AppStrings extends ChangeNotifier {
  static const _key = 'app_locale';

  String _locale = 'es';
  String get locale => _locale;
  bool get isSpanish => _locale == 'es';

  AppStrings() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString(_key) ?? 'es';
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale);
    notifyListeners();
  }

  Future<void> toggle() async {
    await setLocale(_locale == 'es' ? 'en' : 'es');
  }

  /// Acceso rápido a un string por clave.
  String get(String key) => (_strings[_locale]?[key]) ?? key;

  // ═══════════════════════════════════════════════════════════════════════
  //  Strings por idioma
  // ═══════════════════════════════════════════════════════════════════════

  static const _strings = {
    'es': {
      // General
      'app_name': 'Notova',
      'loading': 'Cargando…',
      'cancel': 'Cancelar',
      'close': 'Cerrar',
      'delete': 'Eliminar',
      'save': 'Guardar',
      'error': 'Error',

      // Auth
      'login': 'Iniciar sesión',
      'register': 'Registrarse',
      'email': 'Correo electrónico',
      'password': 'Contraseña',
      'sign_in_google': 'Continuar con Google',
      'no_account': '¿No tienes cuenta?',
      'have_account': '¿Ya tienes cuenta?',
      'welcome_back': '¡Bienvenido de nuevo!',
      'create_account': 'Crear cuenta',

      // Splash
      'hello': 'Hola',

      // Onboarding
      'onboarding_title_1': 'Bienvenido a Notova',
      'onboarding_sub_1': 'Convierte tus tareas en Quests.\nGana XP, sube de nivel y construye hábitos duraderos.',
      'onboarding_title_2': 'Sistema de Rangos',
      'onboarding_sub_2': 'Desde Novato hasta SuperNotova.\nCada tarea completada te acerca al siguiente nivel.',
      'onboarding_title_3': 'Conecta tu Calendario',
      'onboarding_sub_3': 'Sincroniza Google Calendar para ver tus eventos y planificar tu día.',
      'skip': 'Omitir',
      'next': 'Siguiente',
      'start': 'Comenzar',

      // Home
      'good_morning': 'Buenos días',
      'good_afternoon': 'Buenas tardes',
      'good_evening': 'Buenas noches',
      'daily_progress': 'PROGRESO DIARIO',
      'pending_quests': 'Quests Pendientes',
      'today_events': 'Eventos de Hoy',
      'no_pending': 'Sin quests pendientes',
      'no_events': 'Sin eventos hoy',
      'level': 'NIVEL',
      'streak': 'RACHA',
      'days': 'días',

      // Tasks
      'my_quests': 'Mis Quests',
      'all': 'Todas',
      'high_priority': 'Alta Prioridad',
      'completed': 'Completadas',
      'active_quests': 'QUESTS ACTIVAS',
      'completed_quests': 'QUESTS COMPLETADAS',
      'no_pending_quests': '¡Sin quests pendientes!\nPulsa + para añadir una nueva.',
      'no_completed_quests': 'Aún no has completado ninguna quest.',
      'new_quest': 'Nueva Quest',
      'quest_title': 'Título de la Quest',
      'notes_optional': 'Notas (opcional)',
      'date_time_optional': 'Fecha y hora (opcional)',
      'add_quest': 'Añadir Quest',
      'quest_completed': '¡Quest completada!',
      'overdue': '¡VENCIDA!',
      'completed_count': 'Completadas',

      // Calendar
      'calendar': 'Calendario',
      'my_calendars': 'Mis Calendarios',
      'connect_calendar': 'Conectar Google Calendar',
      'disconnect': 'Desconectar',
      'calendar_connected': 'Google Calendar conectado',
      'connect_hint': 'Sincroniza tus eventos automáticamente.',
      'schedule': 'Agenda',
      'todays_schedule': 'Agenda de Hoy',
      'no_events_day': 'Sin eventos este día.',
      'connect_to_see': 'Conecta Google Calendar para ver tu agenda.',
      'connect_to_see_calendars': 'Conecta Google Calendar para ver tus calendarios.',
      'new_event': 'Nuevo Evento',
      'event_title': 'Título del evento',
      'create_event': 'Crear Evento',
      'time_start': 'Inicio',
      'time_end': 'Fin',
      'delete_event': 'Eliminar evento',
      'delete_event_confirm': '¿Eliminar',
      'read_only': 'Solo lectura',
      'all_day': 'Todo el día',

      // Profile
      'profile': 'Perfil de Notova',
      'experience': 'EXPERIENCIA',
      'next_level': '¡PRÓXIMO NIVEL!',
      'max_level': '¡Has alcanzado el nivel máximo! Estado SuperNotova.',
      'xp_to_reach': 'XP para alcanzar',
      'rank': 'RANGO',
      'total_xp': 'XP TOTAL',
      'streak_label': 'RACHA',
      'badges_label': 'INSIGNIAS',
      'badges': 'INSIGNIAS',

      // Settings
      'settings': 'AJUSTES',
      'export_quests': 'Exportar Quests',
      'export_subtitle': 'Descarga tu historial en .csv / .txt',
      'sound_settings': 'Ajustes de Sonido',
      'sound_subtitle': 'Activa o desactiva los SFX',
      'sfx_label': 'Efectos de sonido (SFX)',
      'configure_avatar': 'Configurar Avatar',
      'avatar_subtitle': 'Elige una imagen de tu galería',
      'language': 'Idioma',
      'language_subtitle': 'Cambiar entre español e inglés',
      'logout': 'Cerrar Sesión',
      'logout_subtitle': 'Salir de tu cuenta Notova',
      'export_history': 'EXPORTAR HISTORIAL',
      'export_csv': 'Exportar como CSV',
      'export_txt': 'Exportar como TXT',
      'exporting': 'Exportando…',
      'saved_at': 'Guardado en:',
      'send_to_server': 'Enviar al servidor',
      'sent_ok': '¡Enviado correctamente!',
      'send_error': 'Error al enviar al servidor',
      'export_error': 'Error al exportar:',
      'uploading_avatar': 'Subiendo avatar…',
      'avatar_updated': '¡Avatar actualizado!',
      'avatar_error': 'Error al subir avatar:',

      // Badge names
      'badge_first_quest': 'Primera Quest',
      'badge_streak_3': 'Racha x3',
      'badge_streak_7': 'Racha x7',
      'badge_nivel_3': 'Táctico',
      'badge_nivel_5': 'Maestro',
      'badge_nivel_7': 'SuperNotova',
    },

    'en': {
      // General
      'app_name': 'Notova',
      'loading': 'Loading…',
      'cancel': 'Cancel',
      'close': 'Close',
      'delete': 'Delete',
      'save': 'Save',
      'error': 'Error',

      // Auth
      'login': 'Sign In',
      'register': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'sign_in_google': 'Continue with Google',
      'no_account': "Don't have an account?",
      'have_account': 'Already have an account?',
      'welcome_back': 'Welcome back!',
      'create_account': 'Create Account',

      // Splash
      'hello': 'Hello',

      // Onboarding
      'onboarding_title_1': 'Welcome to Notova',
      'onboarding_sub_1': 'Turn your tasks into Quests.\nEarn XP, level up and build lasting habits.',
      'onboarding_title_2': 'Rank System',
      'onboarding_sub_2': 'From Rookie to SuperNotova.\nEvery completed task brings you closer to the next level.',
      'onboarding_title_3': 'Connect your Calendar',
      'onboarding_sub_3': 'Sync Google Calendar to see your events and plan your day.',
      'skip': 'Skip',
      'next': 'Next',
      'start': 'Get Started',

      // Home
      'good_morning': 'Good morning',
      'good_afternoon': 'Good afternoon',
      'good_evening': 'Good evening',
      'daily_progress': 'DAILY PROGRESS',
      'pending_quests': 'Pending Quests',
      'today_events': "Today's Events",
      'no_pending': 'No pending quests',
      'no_events': 'No events today',
      'level': 'LEVEL',
      'streak': 'STREAK',
      'days': 'days',

      // Tasks
      'my_quests': 'My Quests',
      'all': 'All',
      'high_priority': 'High Priority',
      'completed': 'Completed',
      'active_quests': 'ACTIVE QUESTS',
      'completed_quests': 'COMPLETED QUESTS',
      'no_pending_quests': 'No pending quests!\nTap + to add a new one.',
      'no_completed_quests': 'No completed quests yet.',
      'new_quest': 'New Quest',
      'quest_title': 'Quest Title',
      'notes_optional': 'Notes (optional)',
      'date_time_optional': 'Date and time (optional)',
      'add_quest': 'Add Quest',
      'quest_completed': 'Quest completed!',
      'overdue': 'OVERDUE!',
      'completed_count': 'Completed',

      // Calendar
      'calendar': 'Calendar',
      'my_calendars': 'My Calendars',
      'connect_calendar': 'Connect Google Calendar',
      'disconnect': 'Disconnect',
      'calendar_connected': 'Google Calendar connected',
      'connect_hint': 'Sync your events automatically.',
      'schedule': 'Schedule',
      'todays_schedule': "Today's Schedule",
      'no_events_day': 'No events for this day.',
      'connect_to_see': 'Connect Google Calendar to see your schedule.',
      'connect_to_see_calendars': 'Connect Google Calendar to see your calendars here.',
      'new_event': 'New Event',
      'event_title': 'Event title',
      'create_event': 'Create Event',
      'time_start': 'Start',
      'time_end': 'End',
      'delete_event': 'Delete event',
      'delete_event_confirm': 'Delete',
      'read_only': 'Read-only',
      'all_day': 'All day',

      // Profile
      'profile': 'Notova Profile',
      'experience': 'EXPERIENCE',
      'next_level': 'NEXT LEVEL!',
      'max_level': "You've reached max level! SuperNotova status.",
      'xp_to_reach': 'XP to reach',
      'rank': 'RANK',
      'total_xp': 'TOTAL XP',
      'streak_label': 'STREAK',
      'badges_label': 'BADGES',
      'badges': 'BADGES',

      // Settings
      'settings': 'SETTINGS',
      'export_quests': 'Export Quests',
      'export_subtitle': 'Download your history as .csv / .txt',
      'sound_settings': 'Sound Settings',
      'sound_subtitle': 'Enable or disable SFX',
      'sfx_label': 'Sound effects (SFX)',
      'configure_avatar': 'Configure Avatar',
      'avatar_subtitle': 'Choose an image from your gallery',
      'language': 'Language',
      'language_subtitle': 'Switch between Spanish and English',
      'logout': 'Sign Out',
      'logout_subtitle': 'Sign out of your Notova account',
      'export_history': 'EXPORT HISTORY',
      'export_csv': 'Export as CSV',
      'export_txt': 'Export as TXT',
      'exporting': 'Exporting…',
      'saved_at': 'Saved at:',
      'send_to_server': 'Send to server',
      'sent_ok': 'Sent successfully!',
      'send_error': 'Error sending to server',
      'export_error': 'Error exporting:',
      'uploading_avatar': 'Uploading avatar…',
      'avatar_updated': 'Avatar updated!',
      'avatar_error': 'Error uploading avatar:',

      // Badge names
      'badge_first_quest': 'First Quest',
      'badge_streak_3': 'Streak x3',
      'badge_streak_7': 'Streak x7',
      'badge_nivel_3': 'Tactician',
      'badge_nivel_5': 'Master',
      'badge_nivel_7': 'SuperNotova',
    },
  };
}
