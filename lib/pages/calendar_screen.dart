// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/calendar_event.dart';
import '../models/calendar_info.dart';
import '../l10n/app_strings.dart';
import '../viewmodel/calendar_viewmodel.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  // ── Paleta ────────────────────────────────────────────────────────────────
  static const _bgColor = Color(0xFF120E1A);
  static const _cardColor = Color(0xFF1E1926);
  static const _primaryPurple = Color(0xFF7B2CBF);
  static const _textPrimary = Color(0xFFF4EEFC);
  static const _textSecondary = Color(0xFFC8B8DB);
  static const _textMuted = Color(0xFF8F82A3);

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  int _firstWeekday(DateTime month) =>
      DateTime(month.year, month.month, 1).weekday % 7;

  String _monthName(DateTime month, AppStrings s) {
    final names = s.get('months_long').split(',');
    return '${names[month.month - 1]} ${month.year}';
  }

  String _dayMonthLabel(DateTime d) {
    const months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  // ── Add-event bottom sheet ────────────────────────────────────────────────

  void _showAddEventSheet(BuildContext context, CalendarViewModel vm) {
    final ownedCals = vm.ownedCalendars;
    if (ownedCals.isEmpty) return;

    final titleController = TextEditingController();
    CalendarInfo selectedCal = ownedCals.first;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nuevo Evento',
                style: TextStyle(
                  color: _textPrimary, fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: const TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  hintText: 'Título del evento',
                  hintStyle: const TextStyle(color: _textMuted),
                  filled: true, fillColor: _bgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (ownedCals.length > 1) ...[
                DropdownButtonFormField<CalendarInfo>(
                  value: selectedCal,
                  dropdownColor: _cardColor,
                  style: const TextStyle(color: _textPrimary),
                  decoration: InputDecoration(
                    filled: true, fillColor: _bgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ownedCals
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              '${c.summary}  ·  ${c.accountEmail}',
                              style: const TextStyle(color: _textPrimary),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheetState(() => selectedCal = v);
                  },
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  Expanded(
                    child: _TimeButton(
                      label: 'Inicio', time: startTime,
                      onTap: () async {
                        final t = await showTimePicker(
                            context: ctx, initialTime: startTime);
                        if (t != null) setSheetState(() => startTime = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeButton(
                      label: 'Fin', time: endTime,
                      onTap: () async {
                        final t = await showTimePicker(
                            context: ctx, initialTime: endTime);
                        if (t != null) setSheetState(() => endTime = t);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;
                    final base = vm.selectedDate;
                    final start = DateTime(base.year, base.month, base.day,
                        startTime.hour, startTime.minute);
                    final end = DateTime(base.year, base.month, base.day,
                        endTime.hour, endTime.minute);
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    final ok = await vm.createEvent(
                      calendarId: selectedCal.id,
                      title: title, start: start, end: end,
                    );
                    if (!ok && mounted) {
                      messenger.showSnackBar(SnackBar(
                        content: Text(vm.errorMessage ?? 'Error'),
                        backgroundColor: Colors.redAccent,
                      ));
                    }
                  },
                  child: const Text('Crear Evento',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final s = context.watch<AppStrings>();

    return Scaffold(
      backgroundColor: _bgColor,
      floatingActionButton: vm.isSignedIn && vm.ownedCalendars.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: _primaryPurple,
              onPressed: () => _showAddEventSheet(context, vm),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: vm.isLoading && vm.accounts.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: _primaryPurple))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(vm, s),
                    const SizedBox(height: 20),
                    _buildCalendarGrid(vm, s),
                    const SizedBox(height: 24),
                    _buildCalendarsSection(vm),
                    const SizedBox(height: 20),
                    _buildConnectButton(vm, s),
                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _buildErrorBanner(vm.errorMessage!),
                    ],
                    const SizedBox(height: 28),
                    _buildScheduleSection(vm, s),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Header — mismo patrón que TasksScreen / HomeScreen ─────────────────

  Widget _buildHeader(CalendarViewModel vm, AppStrings s) {
    final connectedCount = vm.accounts.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calendario',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: _primaryPurple.withOpacity(0.3)),
              ),
              child: Text(
                connectedCount == 0
                    ? s.get('not_connected')
                    : s.get('accounts_visible')
                        .replaceFirst('%d', '$connectedCount')
                        .replaceFirst('%s', connectedCount > 1 ? 'S' : '')
                        .replaceFirst('%d', '${vm.allCalendars.where((c) => c.isVisible).length}'),
                style: const TextStyle(
                  color: _primaryPurple,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        if (vm.isSignedIn)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _textSecondary.withOpacity(0.3)),
            ),
            child: GestureDetector(
              onTap: vm.isLoading ? null : vm.refresh,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh,
                      color: vm.isLoading
                          ? _textMuted
                          : _textSecondary,
                      size: 16),
                  const SizedBox(width: 4),
                  Text(
                    s.get('sync'),
                    style: TextStyle(
                      color: _textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Calendar grid ─────────────────────────────────────────────────────────

  Widget _buildCalendarGrid(CalendarViewModel vm, AppStrings s) {
    final fm = vm.focusedMonth;
    final offset = _firstWeekday(fm);
    final daysCount = _daysInMonth(fm);
    final totalCells = ((offset + daysCount) / 7).ceil() * 7;
    final prevMonthDays = DateTime(fm.year, fm.month, 0).day;

    return Column(
      children: [
        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => vm.onMonthChanged(
                  DateTime(fm.year, fm.month - 1)),
              child: const Icon(Icons.chevron_left,
                  color: _textSecondary, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              _monthName(fm, s),
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => vm.onMonthChanged(
                  DateTime(fm.year, fm.month + 1)),
              child: const Icon(Icons.chevron_right,
                  color: _textSecondary, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: s.get('weekday_initials').split(',')
              .map((d) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(
                            color: _textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          )),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),

        // Day grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final isGrey = index < offset || index >= offset + daysCount;
            final day = isGrey
                ? (index < offset
                    ? prevMonthDays - (offset - index - 1)
                    : index - offset - daysCount + 1)
                : index - offset + 1;

            final isToday = !isGrey &&
                day == vm.selectedDate.day &&
                fm.month == vm.selectedDate.month &&
                fm.year == vm.selectedDate.year;

            final dots = isGrey
                ? const <Color>[]
                : (vm.eventDayColors[day] ?? const <Color>[]);

            return GestureDetector(
              onTap: isGrey
                  ? null
                  : () => vm.onDateSelected(
                      DateTime(fm.year, fm.month, day)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isToday ? _primaryPurple : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: isToday
                          ? [BoxShadow(
                              color: _primaryPurple.withOpacity(0.45),
                              blurRadius: 10)]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isGrey
                            ? _textMuted.withOpacity(0.35)
                            : isToday
                                ? Colors.white
                                : _textPrimary,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final c in dots.take(3))
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 1.5),
                            child: Container(
                              width: 5, height: 5,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Calendars — una cajita por cuenta ────────────────────────────────────

  Widget _buildCalendarsSection(CalendarViewModel vm) {
    if (!vm.isSignedIn) return const SizedBox.shrink();

    return Column(
      children: [
        for (final account in vm.accounts)
          _buildAccountCard(account, vm),
      ],
    );
  }

  Widget _buildAccountCard(CalendarAccount account, CalendarViewModel vm) {
    final color = account.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: email + disconnect
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.5), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  account.email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    vm.disconnectGoogleCalendar(email: account.email),
                child: const Icon(Icons.link_off,
                    color: Color(0xFFFF8A8A), size: 16),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white10, height: 1),
          ),
          // Calendar rows
          ...account.calendars.map((cal) {
            final calColor = cal.parsedBackgroundColor ?? color;
            return InkWell(
              onTap: () => vm.toggleCalendarVisibility(cal.id),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: Row(
                  children: [
                    // Color square
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: calColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: calColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cal.summary,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Checkbox
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: cal.isVisible
                            ? calColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: cal.isVisible
                              ? calColor
                              : _textMuted.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: cal.isVisible
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Connect button ────────────────────────────────────────────────────────

  Widget _buildConnectButton(CalendarViewModel vm, AppStrings s) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
        label: Text(
          vm.isSignedIn
              ? s.get('connect_another')
              : s.get('connect_calendar'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 1.0,
          ),
        ),
        onPressed: vm.isLoading ? null : vm.connectGoogleCalendar,
      ),
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFFBABA),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TODAY'S SCHEDULE ──────────────────────────────────────────────────────

  Widget _buildScheduleSection(CalendarViewModel vm, AppStrings s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.get('todays_schedule'),
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _dayMonthLabel(vm.selectedDate),
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (!vm.isSignedIn)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  s.get('connect_to_see'),
                  style: const TextStyle(color: _textMuted, fontSize: 13),
                ),
              ),
            )
          else if (vm.events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  s.get('no_events_day'),
                  style: const TextStyle(color: _textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ...vm.events.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildEventCard(e, vm),
                )),

        ],
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event, CalendarViewModel vm) {
    final color = vm.calendarColor(event.calendarId);

    return Dismissible(
      key: Key('${event.accountEmail}_${event.id}'),
      direction:
          event.isOwned ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _cardColor,
            title: const Text('Eliminar evento',
                style: TextStyle(color: _textPrimary)),
            content: Text('¿Eliminar "${event.title}"?',
                style: const TextStyle(color: _textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar',
                    style: TextStyle(color: _textMuted)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => vm.deleteEvent(event),
      child: Container(
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored left bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Title + location
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (event.location != null &&
                          event.location!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          event.location!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Time range
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  event.formattedTimeRange,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// ── Helper widget ─────────────────────────────────────────────────────────────

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h = time.hour == 0
        ? 12
        : (time.hour > 12 ? time.hour - 12 : time.hour);
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF120E1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF8F82A3), fontSize: 11)),
            const SizedBox(height: 4),
            Text('$h:$m $period',
                style: const TextStyle(
                  color: Color(0xFFF4EEFC),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )),
          ],
        ),
      ),
    );
  }
}
