// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/calendar_event.dart';
import '../models/calendar_info.dart';
import '../l10n/app_strings.dart';
import '../viewmodel/calendar_viewmodel.dart';
import '../theme/app_colors.dart';
import '../utils/tutorial_keys.dart';
import 'main_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  int _diasDelMes(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  int _primerDiaSemana(DateTime month) =>
      DateTime(month.year, month.month, 1).weekday % 7;

  String _monthName(DateTime month, AppStrings s) {
    final names = s.get('months_long').split(',');
    return '${names[month.month - 1]} ${month.year}';
  }

  String _etiquetaDiaMes(DateTime d) {
    const months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  void _hojaNuevoEvento(BuildContext context, CalendarViewModel vm) {
    final calendariosPropios = vm.ownedCalendars;
    if (calendariosPropios.isEmpty) return;

    final controladorTitulo = TextEditingController();
    CalendarInfo calElegido = calendariosPropios.first;
    DateTime fechaElegida = vm.selectedDate;
    TimeOfDay horaInicio = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay horaFin = const TimeOfDay(hour: 18, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
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
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controladorTitulo,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Título del evento',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (calendariosPropios.length > 1) ...[
                DropdownButtonFormField<CalendarInfo>(
                  value: calElegido,
                  dropdownColor: AppColors.card,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  isExpanded: true,
                  items: calendariosPropios.map((c) {
                    final isSameAsEmail =
                        c.summary.trim().toLowerCase() ==
                        c.accountEmail.trim().toLowerCase();
                    final label = isSameAsEmail
                        ? c.accountEmail
                        : '${c.summary}  ·  ${c.accountEmail}';
                    return DropdownMenuItem(
                      value: c,
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setSheetState(() => calElegido = v);
                  },
                ),
                const SizedBox(height: 14),
              ],
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: fechaElegida,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primaryPurple,
                          surface: AppColors.card,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (d != null) setSheetState(() => fechaElegida = d);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Fecha',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      Text(
                        '${fechaElegida.day.toString().padLeft(2, '0')}/'
                        '${fechaElegida.month.toString().padLeft(2, '0')}/'
                        '${fechaElegida.year}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _BotonHora(
                      label: 'Inicio',
                      time: horaInicio,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: horaInicio,
                        );
                        if (t != null) setSheetState(() => horaInicio = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BotonHora(
                      label: 'Fin',
                      time: horaFin,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: horaFin,
                        );
                        if (t != null) setSheetState(() => horaFin = t);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final titulo = controladorTitulo.text.trim();
                    if (titulo.isEmpty) return;
                    final inicio = DateTime(
                      fechaElegida.year,
                      fechaElegida.month,
                      fechaElegida.day,
                      horaInicio.hour,
                      horaInicio.minute,
                    );
                    final fin = DateTime(
                      fechaElegida.year,
                      fechaElegida.month,
                      fechaElegida.day,
                      horaFin.hour,
                      horaFin.minute,
                    );
                    Navigator.pop(ctx);
                    await vm.createEvent(
                      calendarId: calElegido.id,
                      title: titulo,
                      start: inicio,
                      end: fin,
                    );
                  },
                  child: const Text(
                    'Crear Evento',
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

  @override
  Widget build(BuildContext context) {
    //final s = context.watch<AppStrings>();
    final isLoading = context.select((CalendarViewModel vm) => vm.isLoading);
    final isAccountsEmpty = context.select(
      (CalendarViewModel vm) => vm.accounts.isEmpty,
    );
    final errorMessage = context.select(
      (CalendarViewModel vm) => vm.errorMessage,
    );
    final needsReconnect = context.select(
      (CalendarViewModel vm) => vm.needsReconnect,
    );
    final navHeight = MainScreen.navBarHeight(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isLoading && isAccountsEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _CabeceraCalendario(
                      onAddEvent: (vm) => _hojaNuevoEvento(context, vm),
                    ),

                    const SizedBox(height: 12),
                    _CuadriculaCalendario(
                      daysInMonth: _diasDelMes,
                      firstWeekday: _primerDiaSemana,
                      monthName: _monthName,
                    ),
                    const SizedBox(height: 16),
                    const _SeccionAgenda(),
                    const SizedBox(height: 16),
                    const _SeccionCalendarios(),
                    const SizedBox(height: 12),
                    const _SeccionBotonConectar(),
                    if (needsReconnect) ...[
                      const SizedBox(height: 12),
                      const _BannerReconexion(),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _bannerError(errorMessage),
                    ],
                    SizedBox(height: navHeight + 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _bannerError(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
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
}

class _BotonHora extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _BotonHora({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted)),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CabeceraCalendario extends StatelessWidget {
  final void Function(CalendarViewModel) onAddEvent;

  const _CabeceraCalendario({required this.onAddEvent});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final connectedCount = context.select(
      (CalendarViewModel vm) => vm.accounts.length,
    );
    final visibleCount = context.select(
      (CalendarViewModel vm) =>
          vm.allCalendars.where((c) => c.isVisible).length,
    );
    final isSignedIn = context.select(
      (CalendarViewModel vm) => vm.isSignedIn,
    );
    final isLoading = context.select((CalendarViewModel vm) => vm.isLoading);
    final vm = context.read<CalendarViewModel>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.get('calendar_title'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryPurple.withOpacity(0.3),
                ),
              ),
              child: Text(
                connectedCount == 0
                    ? s.get('not_connected')
                    : s
                          .get('accounts_visible')
                          .replaceFirst('%d', '$connectedCount')
                          .replaceFirst('%s', connectedCount > 1 ? 'S' : '')
                          .replaceFirst('%d', '$visibleCount'),
                style: const TextStyle(
                  color: AppColors.primaryPurple,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        if (isSignedIn) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.3),
              ),
            ),
            child: GestureDetector(
              onTap: isLoading ? null : vm.refresh,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    color: isLoading
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s.get('sync'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: GestureDetector(
              onTap: () => onAddEvent(vm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    s.get('add_event'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CuadriculaCalendario extends StatefulWidget {
  final int Function(DateTime) daysInMonth;
  final int Function(DateTime) firstWeekday;
  final String Function(DateTime, AppStrings) monthName;

  const _CuadriculaCalendario({
    required this.daysInMonth,
    required this.firstWeekday,
    required this.monthName,
  });

  @override
  State<_CuadriculaCalendario> createState() => _CuadriculaCalendarioState();
}

class _CuadriculaCalendarioState extends State<_CuadriculaCalendario> {
  double _scale = 1.0;
  double _baseScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final s = context.watch<AppStrings>();
    final fm = vm.focusedMonth;
    final selectedDate = vm.selectedDate;
    final eventDayColors = vm.eventDayColors;

    final offset = widget.firstWeekday(fm);
    final daysCount = widget.daysInMonth(fm);
    final totalCells = ((offset + daysCount) / 7).ceil() * 7;
    final prevMonthDays = DateTime(fm.year, fm.month, 0).day;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => vm.onMonthChanged(DateTime(fm.year, fm.month - 1)),
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              widget.monthName(fm, s),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => vm.onMonthChanged(DateTime(fm.year, fm.month + 1)),
              child: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: s
              .get('weekday_initials')
              .split(',')
              .map(
                (d) => SizedBox(
                  width: 36,
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),

        GestureDetector(
          onScaleStart: (_) => _baseScale = _scale,
          onScaleUpdate: (d) => setState(
            () => _scale = (_baseScale * d.scale).clamp(1.0, 2.0),
          ),
          onDoubleTap: () => setState(() => _scale = 1.0),
          child: ClipRect(
            child: Transform.scale(
              scale: _scale,
              alignment: Alignment.topCenter,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final isGrey = index < offset || index >= offset + daysCount;
                  final day = isGrey
                      ? (index < offset
                            ? prevMonthDays - (offset - index - 1)
                            : index - offset - daysCount + 1)
                      : index - offset + 1;

                  final isToday =
                      !isGrey &&
                      day == selectedDate.day &&
                      fm.month == selectedDate.month &&
                      fm.year == selectedDate.year;

                  final dots = isGrey
                      ? const <Color>[]
                      : (eventDayColors[day] ?? const <Color>[]);

                  return GestureDetector(
                    onTap: isGrey
                        ? null
                        : () =>
                              vm.onDateSelected(DateTime(fm.year, fm.month, day)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primaryPurple
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: isToday
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryPurple.withOpacity(
                                        0.45,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: isGrey
                                  ? AppColors.textMuted.withOpacity(0.5)
                                  : isToday
                                  ? Colors.white
                                  : AppColors.textPrimary,
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
                                    horizontal: 1.5,
                                  ),
                                  child: Container(
                                    width: 5,
                                    height: 5,
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
            ),
          ),
        ),
      ],
    );
  }
}

class _SeccionCalendarios extends StatelessWidget {
  const _SeccionCalendarios();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final isSignedIn = vm.isSignedIn;
    final accounts = vm.accounts;

    if (!isSignedIn) return const SizedBox.shrink();

    return Column(
      children: [
        for (final cuenta in accounts) _tarjetaCuenta(context, cuenta, vm),
      ],
    );
  }

  Future<void> _confirmarDesconexion(
    BuildContext context,
    CalendarAccount account,
    CalendarViewModel vm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Desconectar cuenta',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Quieres desconectar ${account.email} de Notova?\n\nSus eventos dejarán de aparecer en el calendario.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Desconectar',
              style: TextStyle(
                color: Color(0xFFFF8A8A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      vm.disconnectGoogleCalendar(email: account.email);
    }
  }

  Widget _tarjetaCuenta(
    BuildContext context,
    CalendarAccount account,
    CalendarViewModel vm,
  ) {
    final color = account.color;

    // Deduplicate calendars by name within this account, and also skip
    // calendars whose name already appeared in a previous account so that
    // shared subscriptions (e.g. "Festivos en España") are shown only once
    // across the whole list.
    final shownSummaries = _shownSummariesAcrossAccounts(vm, account);
    final uniqueCals = <CalendarInfo>[];
    final seen = <String>{};
    for (final cal in account.calendars) {
      final key = cal.summary.trim().toLowerCase();
      if (seen.add(key) && !shownSummaries.contains(key)) {
        uniqueCals.add(cal);
      }
    }

    // If this account only had duplicates, skip rendering the card entirely.
    if (uniqueCals.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
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
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _confirmarDesconexion(context, account, vm),
                icon: const Icon(
                  Icons.person_remove_rounded,
                  color: Color(0xFFFF8A8A),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Desconectar cuenta',
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white10, height: 1),
          ),
          ...uniqueCals.map((cal) {
            final calColor = cal.parsedBackgroundColor ?? color;
            return InkWell(
              onTap: () => vm.toggleCalendarVisibility(cal.id),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: calColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Container(
                          width: 12,
                          height: 12,
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
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: cal.isVisible ? calColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: cal.isVisible
                              ? calColor
                              : AppColors.textMuted.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: cal.isVisible
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
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

  /// Returns the set of calendar summary keys already rendered by accounts
  /// that come BEFORE [current] in the accounts list.
  Set<String> _shownSummariesAcrossAccounts(
    CalendarViewModel vm,
    CalendarAccount current,
  ) {
    final result = <String>{};
    for (final a in vm.accounts) {
      if (a.email == current.email) break;
      for (final cal in a.calendars) {
        result.add(cal.summary.trim().toLowerCase());
      }
    }
    return result;
  }
}

class _SeccionBotonConectar extends StatelessWidget {
  const _SeccionBotonConectar();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final isSignedIn = context.select(
      (CalendarViewModel vm) => vm.isSignedIn,
    );
    final isLoading = context.select((CalendarViewModel vm) => vm.isLoading);
    final vm = context.read<CalendarViewModel>();

    return SizedBox(
      key: TutorialKeys.calAddEvent,
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: () {
          if (isLoading) return;
          _onConnectPressed(context, vm, isSignedIn);
        },
        child: isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Conectando...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSignedIn
                        ? s.get('connect_another')
                        : s.get('connect_calendar'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _onConnectPressed(
    BuildContext context,
    CalendarViewModel vm,
    bool isSignedIn,
  ) async {
    await vm.connectGoogleCalendar();
  }
}

class _SeccionAgenda extends StatelessWidget {
  const _SeccionAgenda();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final isSignedIn = context.select(
      (CalendarViewModel vm) => vm.isSignedIn,
    );
    final events = context.select((CalendarViewModel vm) => vm.events);
    final selectedDate = context.select(
      (CalendarViewModel vm) => vm.selectedDate,
    );
    final isSavingEvent = context.select(
      (CalendarViewModel vm) => vm.isSavingEvent,
    );
    final vm = context.read<CalendarViewModel>();

    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    final dateLabel = isToday
        ? 'HOY'
        : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
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
                s.get('day_schedule'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                dateLabel,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (isSavingEvent) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: AppColors.primaryPurple,
                minHeight: 2,
              ),
            ),
          ],
          const SizedBox(height: 18),

          if (!isSignedIn)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  s.get('connect_to_see'),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  s.get('no_events_selected_day'),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...events.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _tarjetaEvento(context, e, vm),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tarjetaEvento(
    BuildContext context,
    CalendarEvent event,
    CalendarViewModel vm,
  ) {
    final color = vm.calendarColor(event.calendarId);

    return Dismissible(
      key: Key('${event.accountEmail}_${event.id}'),
      direction: event.isOwned
          ? DismissDirection.endToStart
          : DismissDirection.none,
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
            backgroundColor: AppColors.card,
            title: const Text(
              'Eliminar evento',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              '¿Eliminar "${event.title}"?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => vm.deleteEvent(event),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            event.isAllDay
                                ? 'Todo el día'
                                : event.formattedTime,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (event.isOwned) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppColors.card,
                                    title: const Text(
                                      'Eliminar evento',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    content: Text(
                                      '¿Eliminar "${event.title}"?',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text(
                                          'Cancelar',
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text(
                                          'Eliminar',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) vm.deleteEvent(event);
                              },
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (event.end != null && !event.isAllDay) ...[
                        const SizedBox(height: 4),
                        Text(
                          'hasta ${event.formattedTimeRange.split(' - ').last}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
}

class _BannerReconexion extends StatelessWidget {
  const _BannerReconexion();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<CalendarViewModel>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3E2723),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFFB74D),
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Sesión expirada. Vuelve a conectar para sincronizar eventos.',
              style: TextStyle(
                color: Color(0xFFFFCC80),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => vm.reconnectExpired(),
            child: const Text(
              'Reconectar',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
