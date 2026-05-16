import 'package:flutter/material.dart';

/// Un calendario de Google (una de las "listas" dentro de una cuenta:
/// personal, Cumpleaños, Festivos, Classroom, etc.).
class CalendarInfo {
  final String id;
  final String summary;
  final String? backgroundColor;
  final String accessRole;

  /// Email de la cuenta Google a la que pertenece este calendario.
  /// Se usa para agrupar los calendarios por cuenta en la UI.
  final String accountEmail;

  bool isVisible;

  CalendarInfo({
    required this.id,
    required this.summary,
    this.backgroundColor,
    required this.accessRole,
    required this.accountEmail,
    this.isVisible = true,
  });

  /// Indica si el usuario tiene permisos de escritura sobre este calendario
  /// (`'owner'` o `'writer'`).
  bool get isOwned => accessRole == 'owner' || accessRole == 'writer';

  /// Indica si el calendario es de solo lectura (acceso `'reader'` o
  /// `'freeBusyReader'`).
  bool get isReadOnly => !isOwned;

  /// Retorna el color de fondo del calendario como [Color], o `null` si el
  /// valor de [backgroundColor] no puede parsearse como hexadecimal.
  Color? get parsedBackgroundColor {
    if (backgroundColor == null) return null;
    try {
      final hex = backgroundColor!.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return null;
    }
  }
}

/// Una cuenta de Google conectada, con sus calendarios y un color asignado
/// aleatoriamente que se usa para los "puntitos" del grid y las barras de
/// eventos en la agenda.
class CalendarAccount {
  final String email;
  final Color color;

  /// Access token OAuth vigente para llamar a la API de Google Calendar.
  /// Se persiste en SQLite y se reusa hasta que Google lo rechace con un
  /// 401; en ese momento la cuenta se marca como expirada y la UI muestra
  /// el banner "Reconectar" para que el usuario reautentique manualmente.
  String accessToken;
  DateTime? tokenExpiry;

  /// `true` solo cuando Google rechazó explícitamente el token con un 401.
  /// Es la señal real para mostrar el banner "Reconectar" — el simple paso
  /// del tiempo (timestamp caducado) no activa el banner: el token podría
  /// seguir siendo válido para Google. Esta variable se limpia en cuanto se
  /// refresca exitosamente la cuenta.
  bool tokenRejected;

  List<CalendarInfo> calendars;

  CalendarAccount({
    required this.email,
    required this.color,
    required this.accessToken,
    required this.calendars,
    this.tokenExpiry,
    this.tokenRejected = false,
  });

  /// Indica si nuestra ventana conservadora de validez (55 min) ha pasado.
  /// Solo se usa para decidir si vale la pena intentar un refresh silencioso
  /// — NO para mostrar el banner "Reconectar" (eso lo hace [tokenRejected]).
  bool get isTokenExpired =>
      tokenExpiry != null && DateTime.now().isAfter(tokenExpiry!);
}
