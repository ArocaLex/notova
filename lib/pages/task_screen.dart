// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/task_model.dart';
import '../viewmodel/task_viewmodel.dart';
import '../viewmodel/user_viewmodel.dart';
import '../theme/app_colors.dart';
import '../utils/tutorial_keys.dart';
import 'main_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  TasksScreenState createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> {
  int _pestanaSeleccionada = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksViewModel>().checkStreakOnView();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final fabBottom = MainScreen.fabBottom(context);
    final navHeight = MainScreen.navBarHeight(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 20.0,
                bottom: navHeight + 80.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TaskHeader(),
                  const SizedBox(height: 24),
                  const _DailyProgressCard(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _crearPestana(s.get('all'), 0),
                      const SizedBox(width: 24),
                      _crearPestana(s.get('high_priority'), 1),
                      const SizedBox(width: 24),
                      _crearPestana(s.get('completed'), 2),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (_pestanaSeleccionada != 2) _SeccionTareasPendientes(pestana: _pestanaSeleccionada),
                  if (_pestanaSeleccionada == 2) const _SeccionTareasHechas(),
                ],
              ),
            ),
          ),
          if (_pestanaSeleccionada != 2)
          Positioned(
            bottom: fabBottom,
            right: 16,
            child: FloatingActionButton(
              key: TutorialKeys.tasksFab,
              backgroundColor: AppColors.primaryPurple,
              shape: const CircleBorder(),
              elevation: 8,
              onPressed: () => abrirDialogoTarea(context, context.read<TasksViewModel>(), s),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _crearPestana(String etiqueta, int indice) {
    final activo = _pestanaSeleccionada == indice;
    return GestureDetector(
      onTap: () => setState(() => _pestanaSeleccionada = indice),
      child: Column(
        children: [
          Text(
            etiqueta,
            style: TextStyle(
              color: activo ? AppColors.primaryPurple : Colors.grey.shade500,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          if (activo)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: etiqueta.length * 7.5,
              color: AppColors.primaryPurple,
            ),
        ],
      ),
    );
  }

  void abrirDialogoTarea(
    BuildContext context,
    TasksViewModel gestor,
    AppStrings s, {
    TaskModel? tareaAntigua,
  }) {
    final editando = tareaAntigua != null;
    final controladorTitulo = TextEditingController(text: tareaAntigua?.title ?? '');
    final controladorNota = TextEditingController(text: tareaAntigua?.subtitle ?? '');
    String prioridadElegida = tareaAntigua?.priority ?? 'HIGH';
    DateTime? fechaElegida = tareaAntigua?.dueDate;
    String? colorElegido = tareaAntigua?.color;

    const colorOptions = [
      null,
      '#FF5252',
      '#FF4081',
      '#E040FB',
      '#7C4DFF',
      '#448AFF',
      '#00E5FF',
      '#69F0AE',
      '#FFD740',
      '#FF6E40',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                editando ? s.get('edit_quest') : s.get('new_quest'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controladorTitulo,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: s.get('quest_title'),
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controladorNota,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: s.get('notes_optional'),
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate: now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365 * 2)),
                          builder: (pickerContext, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.primaryPurple,
                                surface: AppColors.card,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (date == null) return;
                        if (!dialogContext.mounted) return;
                        final time = await showTimePicker(
                          context: dialogContext,
                          initialTime: TimeOfDay.now(),
                          builder: (pickerContext, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.primaryPurple,
                                surface: AppColors.card,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (time == null) return;
                        setDialogState(() {
                          fechaElegida = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: fechaElegida != null
                                  ? AppColors.cyanAccent
                                  : AppColors.textMuted,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              fechaElegida != null
                                  ? '${fechaElegida!.day}/${fechaElegida!.month}  ${fechaElegida!.hour.toString().padLeft(2, '0')}:${fechaElegida!.minute.toString().padLeft(2, '0')}'
                                  : s.get('date_time_optional'),
                              style: TextStyle(
                                color: fechaElegida != null
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                            if (fechaElegida != null) ...[
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setDialogState(
                                  () => fechaElegida = null,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.grey.shade600,
                                  size: 16,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: ['HIGH', 'MED', 'LOW'].map((p) {
                        final priorityAccentColor = p == 'HIGH'
                            ? AppColors.priorityHigh
                            : p == 'MED'
                            ? AppColors.priorityMed
                            : AppColors.priorityLow;
                        final isSelected = prioridadElegida == p;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setDialogState(() => prioridadElegida = p),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? priorityAccentColor.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? priorityAccentColor
                                      : Colors.grey.shade800,
                                ),
                              ),
                              child: Text(
                                _AyudaTareas.textoPrioridad(p, s),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? priorityAccentColor
                                      : AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Color',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colorOptions.map((hex) {
                        final isSelected = colorElegido == hex;
                        final color = hex != null
                            ? Color(
                                0xFF000000 |
                                    int.parse(hex.substring(1), radix: 16),
                              )
                            : null;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => colorElegido = hex),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color ?? AppColors.background,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : (color?.withOpacity(0.5) ??
                                          Colors.grey.shade700),
                                width: isSelected ? 2.5 : 1.5,
                              ),
                              boxShadow: isSelected && color != null
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.5),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: hex == null
                                ? Icon(
                                    Icons.block,
                                    color: Colors.grey.shade600,
                                    size: 16,
                                  )
                                : isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                if (editando)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 18),
                    label: Text(
                      s.get('delete'),
                      style: const TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: dialogContext,
                        builder: (confirmCtx) => AlertDialog(
                          backgroundColor: AppColors.card,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: Text(s.get('delete_quest_title'),
                              style: const TextStyle(color: Colors.white)),
                          content: Text(
                            s.get('delete_quest_confirm'),
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(confirmCtx, false),
                              child: Text(s.get('cancel'),
                                  style: TextStyle(
                                      color: AppColors.textMuted)),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(confirmCtx, true),
                              child: Text(s.get('delete'),
                                  style: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      await gestor.deleteTask(tareaAntigua.id);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                    },
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    s.get('cancel'),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (controladorTitulo.text.isNotEmpty) {
                      final xp = prioridadElegida == 'HIGH'
                          ? 250
                          : prioridadElegida == 'MED'
                          ? 100
                          : 50;
                      if (editando) {
                        await gestor.updateTask(
                          tareaAntigua.id,
                          controladorTitulo.text.trim(),
                          controladorNota.text.trim(),
                          prioridadElegida,
                          xp,
                          dueDate: fechaElegida,
                          color: colorElegido,
                        );
                      } else {
                        await gestor.createTask(
                          controladorTitulo.text.trim(),
                          controladorNota.text.trim(),
                          prioridadElegida,
                          xp,
                          dueDate: fechaElegida,
                          color: colorElegido,
                        );
                      }
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      if (!editando) {
                        setState(() => _pestanaSeleccionada = 0);
                      }
                    }
                  },
                  child: Text(
                    editando ? s.get('save') : s.get('add_quest'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final user = context.select((UserViewModel vm) => vm.user);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.get('my_quests'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'NIVEL ${user?.level ?? 1} · ${(user?.rank ?? 'NOVATO').toUpperCase()}',
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
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cyanAccent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.flash_on,
                color: AppColors.cyanAccent,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatearNumero(user?.totalXpEver ?? 0)} XP',
                style: const TextStyle(
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatearNumero(int numero) {
    return numero.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final completedTodayCount =
        context.select((TasksViewModel vm) => vm.completedTodayProgressCount);
    final totalParaBarra =
        context.select((TasksViewModel vm) => vm.totalDailyProgressCount);
    final progresoGlobal = context.select((TasksViewModel vm) => vm.dailyProgress);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C1A99), AppColors.accentPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.35),
            blurRadius: 18,
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
              Text(
                s.get('daily_progress'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '$completedTodayCount / $totalParaBarra ${s.get('completed_count')}',
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
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progresoGlobal,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionTareasPendientes extends StatelessWidget {
  final int pestana;

  const _SeccionTareasPendientes({required this.pestana});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final isLoading = context.select((TasksViewModel vm) => vm.isLoading);
    var tareas = context.select((TasksViewModel vm) => vm.pending);

    if (pestana == 1) {
      tareas = tareas.where((t) => t.priority == 'HIGH').toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.get('active_quests'),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 12,
              color: Colors.white.withOpacity(0.10),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
        else if (tareas.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.textMuted,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.get('no_pending_quests'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tareas.length,
            itemBuilder: (context, index) {
              final t = tareas[index];
              return TweenAnimationBuilder<double>(
                key: ValueKey('anim_${t.id}'),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - value)),
                    child: child,
                  ),
                ),
                child: _filaTareaPendiente(
                  context: context,
                  tarea: t,
                  gestor: context.read<TasksViewModel>(),
                  s: s,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _filaTareaPendiente({
    required BuildContext context,
    required TaskModel tarea,
    required TasksViewModel gestor,
    required AppStrings s,
  }) {
    Color priorityColor = AppColors.accentPurple;
    if (tarea.priority == 'MED') priorityColor = AppColors.priorityMed;

    final taskColor = _AyudaTareas.leerColorHex(tarea.color);
    final barColor = taskColor ?? priorityColor;

    final dueDateColor = tarea.isOverdue ? AppColors.error : AppColors.textMuted;

    return Dismissible(
      key: Key(tarea.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final subioNivel = await gestor.toggleTaskCompletion(
          tarea.id,
          tarea.xpReward,
        );
        if (!context.mounted) return false;
        if (subioNivel) _AyudaTareas.dialogoNivel(context, s);
        return true;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          final state = context.findAncestorStateOfType<TasksScreenState>();
          if (state != null) {
            state.abrirDialogoTarea(context, gestor, s, tareaAntigua: tarea);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: taskColor?.withOpacity(0.3) ??
                  (tarea.isOverdue
                      ? AppColors.error.withOpacity(0.3)
                      : Colors.white.withOpacity(0.04)),
            ),
            boxShadow: taskColor != null
                ? [
                    BoxShadow(
                      color: taskColor.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: barColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tarea.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _AyudaTareas.dibujarEtiqueta(tarea.priority, priorityColor, s),
                                    if (tarea.subtitle.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          tarea.subtitle,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              if (tarea.dueDate != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 11,
                                      color: dueDateColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            tarea.formattedDueDate,
                                            style: TextStyle(
                                              color: dueDateColor,
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (tarea.isOverdue) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              s.get('overdue'),
                                              style: const TextStyle(
                                                color: AppColors.error,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cyanAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.cyanAccent.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '+${tarea.xpReward} XP',
                            style: const TextStyle(
                              color: AppColors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeccionTareasHechas extends StatelessWidget {
  const _SeccionTareasHechas();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final hechasTodas = context.select((TasksViewModel vm) => vm.completed);
    final gestor = context.read<TasksViewModel>();
    final isLoading = context.select((TasksViewModel vm) => vm.isLoading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.get('completed_quests'),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            if (hechasTodas.isNotEmpty)
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'Borrar todas',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: Text(
                        '¿Eliminar las ${hechasTodas.length} quests completadas?',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(s.get('cancel'),
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Borrar',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    context.read<TasksViewModel>().deleteAllCompleted();
                  }
                },
                icon: const Icon(Icons.delete_sweep_rounded,
                    color: AppColors.error, size: 16),
                label: const Text('Borrar todas',
                    style: TextStyle(color: AppColors.error, fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const SizedBox.shrink()
        else if (hechasTodas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              s.get('no_completed_quests'),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: hechasTodas.length,
            itemBuilder: (context, index) =>
                _filaTareaHecha(context, hechasTodas[index], s, gestor),
          ),
      ],
    );
  }

  Widget _filaTareaHecha(
    BuildContext context,
    TaskModel t,
    AppStrings s,
    TasksViewModel gestor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check, color: AppColors.primaryPurple, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _AyudaTareas.dibujarEtiqueta(t.priority, AppColors.textMuted, s),
                    if (t.completedAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${t.completedAt!.day}/${t.completedAt!.month}/${t.completedAt!.year}',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.card),
            ),
            child: Text(
              '+${t.xpReward} XP',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => gestor.deleteTask(t.id),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AyudaTareas {
  static String textoPrioridad(String prioridad, AppStrings s) {
    switch (prioridad) {
      case 'HIGH':
        return s.get('priority_high');
      case 'MED':
        return s.get('priority_med');
      case 'LOW':
        return s.get('priority_low');
      default:
        return prioridad;
    }
  }

  static Widget dibujarEtiqueta(String prioridad, Color color, AppStrings s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        textoPrioridad(prioridad, s),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static Color? leerColorHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final limpio = hex.replaceFirst('#', '');
    if (limpio.length != 6) return null;
    final valor = int.tryParse(limpio, radix: 16);
    if (valor == null) return null;
    return Color(0xFF000000 | valor);
  }

  static void dialogoNivel(BuildContext context, AppStrings s) {
    final user = context.read<UserViewModel>().user;
    if (user == null) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                s.get('great'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

