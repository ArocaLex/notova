class CalendarInfo {
  final String id;
  final String summary;
  final String? backgroundColor;
  final String accessRole;
  bool isVisible;

  CalendarInfo({
    required this.id,
    required this.summary,
    this.backgroundColor,
    required this.accessRole,
    this.isVisible = true,
  });

  /// Owner or writer can create/edit/delete events.
  bool get isOwned => accessRole == 'owner' || accessRole == 'writer';

  /// Calendars with reader or freeBusyReader access are read-only.
  bool get isReadOnly => !isOwned;
}
