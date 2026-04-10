// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/calendar_event.dart';
import '../models/calendar_info.dart';
import '../viewmodel/calendar_viewmodel.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  static const bgColor = Color(0xFF120E1A);
  static const cardColor = Color(0xFF1E1926);
  static const primaryPurple = Color(0xFF7B2CBF);
  static const cyanAccent = Color(0xFFDEB7FF);

  // Month shown in the grid (independent of selectedDate in ViewModel).
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  /// Weekday index of the 1st (0 = Sun … 6 = Sat).
  int _firstWeekday(DateTime month) =>
      DateTime(month.year, month.month, 1).weekday % 7;

  String _monthName(DateTime month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  Color _calendarColor(CalendarInfo cal) {
    if (cal.backgroundColor != null) {
      try {
        final hex = cal.backgroundColor!.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return cal.isOwned ? primaryPurple : Colors.blueGrey;
  }

  // ── Add event bottom sheet ────────────────────────────────────────────────

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
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
              // Handle
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
                'New Event',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Event title',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: bgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Calendar selector (only owned)
              if (ownedCals.length > 1) ...[
                DropdownButtonFormField<CalendarInfo>(
                  value: selectedCal,
                  dropdownColor: cardColor,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: bgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ownedCals
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.summary),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheetState(() => selectedCal = v);
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Time row
              Row(
                children: [
                  Expanded(
                    child: _TimeButton(
                      label: 'Start',
                      time: startTime,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: startTime,
                        );
                        if (t != null) setSheetState(() => startTime = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeButton(
                      label: 'End',
                      time: endTime,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: endTime,
                        );
                        if (t != null) setSheetState(() => endTime = t);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final base = vm.selectedDate;
                    final start = DateTime(
                      base.year, base.month, base.day,
                      startTime.hour, startTime.minute,
                    );
                    final end = DateTime(
                      base.year, base.month, base.day,
                      endTime.hour, endTime.minute,
                    );

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    final ok = await vm.createEvent(
                      calendarId: selectedCal.id,
                      title: title,
                      start: start,
                      end: end,
                    );
                    if (!ok && mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(vm.errorMessage ?? 'Error'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Create Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: primaryPurple, size: 26),
            SizedBox(width: 10),
            Text(
              'Calendar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          if (vm.isSignedIn)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: vm.isLoading ? null : vm.refresh,
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),

      // FAB — only visible when signed in and has owned calendars (RF-09)
      floatingActionButton: vm.isSignedIn && vm.ownedCalendars.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: primaryPurple,
              onPressed: () => _showAddEventSheet(context, vm),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,

      body: vm.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryPurple),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCalendarGrid(vm),
                  const SizedBox(height: 28),
                  _buildCalendarFilters(vm),
                  const SizedBox(height: 20),
                  _buildGoogleConnectButton(vm),
                  const SizedBox(height: 28),
                  _buildSchedule(vm),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  // ── Calendar grid ─────────────────────────────────────────────────────────

  Widget _buildCalendarGrid(CalendarViewModel vm) {
    final totalCells = _firstWeekday(_focusedMonth) + _daysInMonth(_focusedMonth);
    final rows = (totalCells / 7).ceil();
    final cellCount = rows * 7;

    // Days in prev month (for grey padding cells)
    final prevMonthDays = DateTime(_focusedMonth.year, _focusedMonth.month, 0).day;

    // Set of days in focused month that have events
    final eventDays = vm.events
        .where((e) =>
            e.start?.month == _focusedMonth.month &&
            e.start?.year == _focusedMonth.year)
        .map((e) => e.start!.day)
        .toSet();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: Colors.grey.shade400),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() {
                  _focusedMonth =
                      DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                }),
              ),
              Text(
                _monthName(_focusedMonth),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() {
                  _focusedMonth =
                      DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) {
              return Text(
                d,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Days grid
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final offset = _firstWeekday(_focusedMonth);
              final isGrey = index < offset ||
                  index >= offset + _daysInMonth(_focusedMonth);
              final day = isGrey
                  ? (index < offset
                      ? prevMonthDays - (offset - index - 1)
                      : index - offset - _daysInMonth(_focusedMonth) + 1)
                  : index - offset + 1;

              final isSelected = !isGrey &&
                  day == vm.selectedDate.day &&
                  _focusedMonth.month == vm.selectedDate.month &&
                  _focusedMonth.year == vm.selectedDate.year;

              final hasDot = !isGrey && eventDays.contains(day);

              return GestureDetector(
                onTap: isGrey
                    ? null
                    : () => vm.onDateSelected(DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month,
                          day,
                        )),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isSelected ? primaryPurple : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryPurple.withOpacity(0.4),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isGrey
                              ? Colors.grey.shade700
                              : isSelected
                                  ? Colors.white
                                  : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    hasDot
                        ? Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: cyanAccent,
                              shape: BoxShape.circle,
                            ),
                          )
                        : const SizedBox(height: 4),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Calendar filters ──────────────────────────────────────────────────────

  Widget _buildCalendarFilters(CalendarViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Calendars',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (vm.isSignedIn)
              TextButton(
                onPressed: vm.disconnectGoogleCalendar,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  'Disconnect',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (!vm.isSignedIn)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Connect Google Calendar to see your calendars here.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          )
        else
          ...vm.calendars.map((cal) => _buildCalendarFilter(cal, vm)),
      ],
    );
  }

  Widget _buildCalendarFilter(CalendarInfo cal, CalendarViewModel vm) {
    final color = _calendarColor(cal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                cal.summary,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              // Read-only badge for RF-10 (Classroom / non-owned)
              if (cal.isReadOnly)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Read-only',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          GestureDetector(
            onTap: () => vm.toggleCalendarVisibility(cal.id),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: cal.isVisible ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: cal.isVisible ? color : Colors.grey.shade700,
                  width: 2,
                ),
              ),
              child: cal.isVisible
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Connect / disconnect button ───────────────────────────────────────────

  Widget _buildGoogleConnectButton(CalendarViewModel vm) {
    if (vm.isSignedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: primaryPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryPurple.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: primaryPurple, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Google Calendar connected',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (vm.connectedEmail != null)
                    Text(
                      vm.connectedEmail!,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
            label: const Text(
              'Connect Google Calendar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            onPressed: vm.connectGoogleCalendar,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Sync your events across all your devices automatically.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ),
        if (vm.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            vm.errorMessage!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  Widget _buildSchedule(CalendarViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          vm.isSignedIn
              ? "Schedule · ${vm.selectedDate.day}/${vm.selectedDate.month}"
              : "Today's Schedule",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        if (!vm.isSignedIn)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Connect Google Calendar to see your schedule.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          )
        else if (vm.events.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No events for this day.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          )
        else
          ...vm.events.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEventCard(e, vm),
              )),
      ],
    );
  }

  Widget _buildEventCard(CalendarEvent event, CalendarViewModel vm) {
    final color = _eventColor(event);
    return Dismissible(
      key: Key(event.id),
      // Only allow swipe-to-delete on owned events (RF-09/RF-10)
      direction: event.isOwned
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: cardColor,
            title: const Text('Delete event',
                style: TextStyle(color: Colors.white)),
            content: Text(
              'Delete "${event.title}"?',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => vm.deleteEvent(event),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Color bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              // Time
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 18.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.formattedHour,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      event.meridian,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, color: Colors.white.withOpacity(0.05)),
              // Title + badges
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (event.isAllDay)
                            _badge('All day', Colors.white38),
                          if (!event.isOwned) ...[
                            if (event.isAllDay) const SizedBox(width: 6),
                            _badge('Read-only', Colors.blueGrey),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Color _eventColor(CalendarEvent event) {
    if (!event.isOwned) return Colors.blueGrey;
    final cal = context
        .read<CalendarViewModel>()
        .calendars
        .where((c) => c.id == event.calendarId)
        .firstOrNull;
    if (cal == null) return primaryPurple;
    return _calendarColor(cal);
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
    final h = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
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
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              '$h:$m $period',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
