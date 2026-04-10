// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../viewmodel/task_viewmodel.dart';
import '../viewmodel/user_viewmodel.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  TasksScreenState createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> {
  int _selectedTab = 0;

  static const _bgColor = Color(0xFF120E1A);
  static const _cardColor = Color(0xFF1E1A29);
  static const _primaryPurple = Color(0xFF7B2CBF);
  static const _accentPurple = Color(0xFF8A2BE2);
  static const _cyanAccent = Color(0xFFDEB7FF);

  @override
  void initState() {
    super.initState();
    // RF-06: visitar la pantalla de Tasks mantiene la racha viva
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksViewModel>().checkStreakOnView();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskViewModel = context.read<TasksViewModel>();
    final user = context.watch<UserViewModel>().user;

    return Scaffold(
      backgroundColor: _bgColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: _primaryPurple,
          shape: const CircleBorder(),
          elevation: 8,
          onPressed: () => _showTaskDialog(context, taskViewModel),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CABECERA ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Mis Quests",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _primaryPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _primaryPurple.withOpacity(0.3)),
                        ),
                        child: Text(
                          'NIVEL ${user?.level ?? 1} · ${(user?.rank ?? 'NOVATO').toUpperCase()}',
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _cyanAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on,
                            color: _cyanAccent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatNumber(user?.totalXpEver ?? 0)} XP',
                          style: const TextStyle(
                            color: _cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- TARJETA DE PROGRESO DIARIO ---
              StreamBuilder<List<TaskModel>>(
                stream: taskViewModel.pendingTasksStream,
                builder: (context, pendingSnap) {
                  return StreamBuilder<List<TaskModel>>(
                    stream: taskViewModel.completedTasksStream,
                    builder: (context, completedSnap) {
                      final pending = pendingSnap.data?.length ?? 0;
                      final completed = completedSnap.data?.length ?? 0;
                      final total = pending + completed;
                      final progress =
                          total > 0 ? completed / total : 0.0;

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5C1A99), _accentPurple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryPurple.withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'PROGRESO DIARIO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  '$completed / $total Completadas',
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
                                widthFactor: progress,
                                child: Container(
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
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // --- PESTAÑAS ---
              Row(
                children: [
                  _buildTab('Todas', 0),
                  const SizedBox(width: 24),
                  _buildTab('Alta Prioridad', 1),
                  const SizedBox(width: 24),
                  _buildTab('Completadas', 2),
                ],
              ),
              const SizedBox(height: 28),

              // --- ACTIVE QUESTS (tabs 0 y 1) ---
              if (_selectedTab != 2) ...[
                Row(
                  children: [
                    const Text(
                      'QUESTS ACTIVAS',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                        width: 1,
                        height: 12,
                        color: Colors.grey.shade800),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<TaskModel>>(
                  stream: taskViewModel.pendingTasksStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: _primaryPurple),
                      );
                    }

                    var tasks = snapshot.data ?? [];
                    if (_selectedTab == 1) {
                      tasks = tasks
                          .where((t) => t.priority == 'HIGH')
                          .toList();
                    }

                    if (tasks.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  color: Colors.grey.shade700, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                '¡Sin quests pendientes!\nPulsa + para añadir una nueva.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) =>
                          _buildActiveTaskItem(
                        context: context,
                        task: tasks[index],
                        taskViewModel: taskViewModel,
                      ),
                    );
                  },
                ),
              ],

              // --- COMPLETED QUESTS (tab 2) ---
              if (_selectedTab == 2) ...[
                const Text(
                  'QUESTS COMPLETADAS',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<TaskModel>>(
                  stream: taskViewModel.completedTasksStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    final tasks = snapshot.data ?? [];
                    if (tasks.isEmpty) {
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Aún no has completado ninguna quest.',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) =>
                          _buildCompletedTaskItem(tasks[index]),
                    );
                  },
                ),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? _primaryPurple : Colors.grey.shade500,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(
                height: 2,
                width: label.length * 7.5,
                color: _primaryPurple),
        ],
      ),
    );
  }

  Widget _buildActiveTaskItem({
    required BuildContext context,
    required TaskModel task,
    required TasksViewModel taskViewModel,
  }) {
    Color priorityColor = const Color(0xFF8A2BE2);
    if (task.priority == 'HIGH') priorityColor = const Color(0xFFE53935);
    if (task.priority == 'LOW') priorityColor = Colors.grey;
    if (task.priority == 'MED') priorityColor = Colors.orange;

    final dueDateColor =
        task.isOverdue ? Colors.redAccent : Colors.grey.shade500;

    return GestureDetector(
      onTap: () => _showTaskDialog(context, taskViewModel, existingTask: task),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isOverdue
              ? Colors.redAccent.withOpacity(0.3)
              : Colors.white.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final didLevelUp = await taskViewModel.toggleTaskCompletion(
                  task.id, task.xpReward);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '¡Quest completada! +${task.xpReward} XP',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: _primaryPurple,
                  duration: const Duration(seconds: 2),
                ),
              );
              if (didLevelUp) {
                final user = context.read<UserViewModel>().user;
                if (user == null) return;
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1A29),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('🎉 ¡Subiste de Nivel!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.military_tech,
                            color: _cyanAccent, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Nivel ${user.level} · ${user.rank}',
                          style: const TextStyle(
                              color: _cyanAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¡Sigue completando quests para avanzar!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                        ),
                      ],
                    ),
                    actions: [
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryPurple,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('¡Genial!',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _primaryPurple, width: 2),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildPill(task.priority, priorityColor),
                    if (task.subtitle.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          task.subtitle,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
                if (task.dueDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 11, color: dueDateColor),
                      const SizedBox(width: 3),
                      Text(
                        task.formattedDueDate,
                        style:
                            TextStyle(color: dueDateColor, fontSize: 11),
                      ),
                      if (task.isOverdue) ...[
                        const SizedBox(width: 4),
                        Text(
                          '¡VENCIDA!',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _cyanAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: _cyanAccent.withOpacity(0.3)),
            ),
            child: Text(
              '+${task.xpReward} XP',
              style: const TextStyle(
                color: _cyanAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildCompletedTaskItem(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _primaryPurple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check, color: _primaryPurple, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                _buildPill(task.priority, Colors.grey.shade700),
              ],
            ),
          ),
          Text(
            '+${task.xpReward} XP',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showTaskDialog(BuildContext context, TasksViewModel viewModel,
      {TaskModel? existingTask}) {
    final isEditing = existingTask != null;
    final titleCtrl = TextEditingController(text: existingTask?.title ?? '');
    final subCtrl = TextEditingController(text: existingTask?.subtitle ?? '');
    String selectedPriority = existingTask?.priority ?? 'HIGH';
    DateTime? selectedDueDate = existingTask?.dueDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1A29),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEditing ? 'Editar Quest' : 'Nueva Quest',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Título de la Quest',
                        hintStyle:
                            TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: const Color(0xFF120E1A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Notas (opcional)',
                        hintStyle:
                            TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: const Color(0xFF120E1A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- Selector de fecha/hora ---
                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: now,
                          firstDate: now,
                          lastDate:
                              now.add(const Duration(days: 365 * 2)),
                          builder: (c, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: _primaryPurple,
                                surface: Color(0xFF1E1A29),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (date == null) return;
                        if (!ctx.mounted) return;
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.now(),
                          builder: (c, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: _primaryPurple,
                                surface: Color(0xFF1E1A29),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (time == null) return;
                        setDialogState(() {
                          selectedDueDate = DateTime(
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
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF120E1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: selectedDueDate != null
                                    ? _cyanAccent
                                    : Colors.grey.shade600,
                                size: 16),
                            const SizedBox(width: 8),
                            Text(
                              selectedDueDate != null
                                  ? '${selectedDueDate!.day}/${selectedDueDate!.month}  ${selectedDueDate!.hour.toString().padLeft(2, '0')}:${selectedDueDate!.minute.toString().padLeft(2, '0')}'
                                  : 'Fecha y hora (opcional)',
                              style: TextStyle(
                                color: selectedDueDate != null
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            if (selectedDueDate != null) ...[
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setDialogState(
                                    () => selectedDueDate = null),
                                child: Icon(Icons.close,
                                    color: Colors.grey.shade600,
                                    size: 16),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- Selector de prioridad ---
                    Row(
                      children: ['HIGH', 'MED', 'LOW'].map((p) {
                        final c = p == 'HIGH'
                            ? const Color(0xFFE53935)
                            : p == 'MED'
                                ? Colors.orange
                                : Colors.grey;
                        final isSelected = selectedPriority == p;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(
                                () => selectedPriority = p),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 3),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? c.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: Border.all(
                                    color: isSelected
                                        ? c
                                        : Colors.grey.shade800),
                              ),
                              child: Text(
                                p,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? c
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty) {
                      final xp = selectedPriority == 'HIGH'
                          ? 250
                          : selectedPriority == 'MED'
                              ? 100
                              : 50;
                      if (isEditing) {
                        viewModel.updateTask(
                          existingTask.id,
                          titleCtrl.text.trim(),
                          subCtrl.text.trim(),
                          selectedPriority,
                          xp,
                          dueDate: selectedDueDate,
                        );
                      } else {
                        viewModel.createTask(
                          titleCtrl.text.trim(),
                          subCtrl.text.trim(),
                          selectedPriority,
                          xp,
                          dueDate: selectedDueDate,
                        );
                      }
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(
                    isEditing ? 'Guardar' : 'Añadir Quest',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
