// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
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
    // watch: rebuild cuando el VM actualice `pending` / `completed`.
    final taskViewModel = context.watch<TasksViewModel>();
    final user = context.watch<UserViewModel>().user;
    final s = context.watch<AppStrings>();

    final pendingAll = taskViewModel.pending;
    final completedAll = taskViewModel.completed;
    final totalAll = pendingAll.length + completedAll.length;
    final progressAll = totalAll > 0 ? completedAll.length / totalAll : 0.0;

    return Scaffold(
      backgroundColor: _bgColor,
      // Posicionamos el FAB por encima de la cápsula de navegación inferior
      // (el MainScreen usa extendBody con una bottomNavigationBar flotante).
      floatingActionButtonLocation: _BottomNavFabLocation(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryPurple,
        shape: const CircleBorder(),
        elevation: 8,
        onPressed: () => _showTaskDialog(context, taskViewModel, s),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
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
                          color: _primaryPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _primaryPurple.withOpacity(0.3),
                          ),
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
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _cyanAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flash_on,
                          color: _cyanAccent,
                          size: 16,
                        ),
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
              Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.get('daily_progress'),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '${completedAll.length} / $totalAll ${s.get('completed_count')}',
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
                        widthFactor: progressAll,
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
              ),
              const SizedBox(height: 24),

              // --- PESTAÑAS ---
              Row(
                children: [
                  _buildTab(s.get('all'), 0),
                  const SizedBox(width: 24),
                  _buildTab(s.get('high_priority'), 1),
                  const SizedBox(width: 24),
                  _buildTab(s.get('completed'), 2),
                ],
              ),
              const SizedBox(height: 28),

              // --- ACTIVE QUESTS (tabs 0 y 1) ---
              if (_selectedTab != 2) ...[
                Row(
                  children: [
                    Text(
                      s.get('active_quests'),
                      style: const TextStyle(
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
                      color: Colors.grey.shade800,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    if (taskViewModel.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: _primaryPurple),
                      );
                    }

                    var tasks = pendingAll;
                    if (_selectedTab == 1) {
                      tasks = tasks.where((t) => t.priority == 'HIGH').toList();
                    }

                    if (tasks.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.grey.shade700,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                s.get('no_pending_quests'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
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
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return TweenAnimationBuilder<double>(
                          key: ValueKey('anim_${task.id}'),
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
                          child: _buildActiveTaskItem(
                            context: context,
                            task: task,
                            taskViewModel: taskViewModel,
                            s: s,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],

              // --- COMPLETED QUESTS (tab 2) ---
              if (_selectedTab == 2) ...[
                Text(
                  s.get('completed_quests'),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    if (taskViewModel.isLoading) {
                      return const SizedBox.shrink();
                    }
                    if (completedAll.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          s.get('no_completed_quests'),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: completedAll.length,
                      itemBuilder: (context, index) =>
                          _buildCompletedTaskItem(completedAll[index], s),
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
              color: _primaryPurple,
            ),
        ],
      ),
    );
  }

  Widget _buildActiveTaskItem({
    required BuildContext context,
    required TaskModel task,
    required TasksViewModel taskViewModel,
    required AppStrings s,
  }) {
    Color priorityColor = const Color(0xFF8A2BE2);
    if (task.priority == 'HIGH') priorityColor = const Color(0xFFE53935);
    if (task.priority == 'LOW') priorityColor = Colors.grey;
    if (task.priority == 'MED') priorityColor = Colors.orange;

    final taskColor = _parseHexColor(task.color);
    final barColor = taskColor ?? priorityColor;

    final dueDateColor = task.isOverdue
        ? Colors.redAccent
        : Colors.grey.shade500;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final didLevelUp = await taskViewModel.toggleTaskCompletion(
          task.id,
          task.xpReward,
        );
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${s.get('quest_completed')} +${task.xpReward} XP',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: _primaryPurple,
            duration: const Duration(seconds: 2),
          ),
        );
        if (didLevelUp) _showLevelUpDialog(context, s);
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
          color: Colors.greenAccent,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: () =>
            _showTaskDialog(context, taskViewModel, s, existingTask: task),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  taskColor?.withOpacity(0.3) ??
                  (task.isOverdue
                      ? Colors.redAccent.withOpacity(0.3)
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
                        GestureDetector(
                          onTap: () async {
                            final didLevelUp = await taskViewModel
                                .toggleTaskCompletion(task.id, task.xpReward);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${s.get('quest_completed')} +${task.xpReward} XP',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: _primaryPurple,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            if (didLevelUp) _showLevelUpDialog(context, s);
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _primaryPurple,
                                width: 2,
                              ),
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
                                  _buildPill(task.priority, priorityColor, s),
                                  if (task.subtitle.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        task.subtitle,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (task.dueDate != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 11,
                                      color: dueDateColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      task.formattedDueDate,
                                      style: TextStyle(
                                        color: dueDateColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (task.isOverdue) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        s.get('overdue'),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _cyanAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _cyanAccent.withOpacity(0.3),
                            ),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedTaskItem(TaskModel task, AppStrings s) {
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
                _buildPill(task.priority, Colors.grey.shade700, s),
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

  static String _priorityLabel(String priority, AppStrings s) {
    switch (priority) {
      case 'HIGH':
        return s.get('priority_high');
      case 'MED':
        return s.get('priority_med');
      case 'LOW':
        return s.get('priority_low');
      default:
        return priority;
    }
  }

  Widget _buildPill(String priority, Color color, AppStrings s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _priorityLabel(priority, s),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showLevelUpDialog(BuildContext context, AppStrings s) {
    final user = context.read<UserViewModel>().user;
    if (user == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1A29),
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
            const Icon(Icons.military_tech, color: _cyanAccent, size: 64),
            const SizedBox(height: 16),
            Text(
              '${s.get('level')} ${user.level} · ${user.rank}',
              style: const TextStyle(
                color: _cyanAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.get('keep_completing'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
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

  void _showTaskDialog(
    BuildContext context,
    TasksViewModel viewModel,
    AppStrings s, {
    TaskModel? existingTask,
  }) {
    final isEditing = existingTask != null;
    final titleCtrl = TextEditingController(text: existingTask?.title ?? '');
    final subCtrl = TextEditingController(text: existingTask?.subtitle ?? '');
    String selectedPriority = existingTask?.priority ?? 'HIGH';
    DateTime? selectedDueDate = existingTask?.dueDate;
    String? selectedColor = existingTask?.color;

    const colorOptions = [
      null, // Sin color
      '#FF5252', // Rojo neon
      '#FF4081', // Rosa neon
      '#E040FB', // Morado neon
      '#7C4DFF', // Indigo neon
      '#448AFF', // Azul neon
      '#00E5FF', // Cyan neon
      '#69F0AE', // Verde neon
      '#FFD740', // Amarillo neon
      '#FF6E40', // Naranja neon
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1A29),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isEditing ? s.get('edit_quest') : s.get('new_quest'),
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
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: s.get('quest_title'),
                        hintStyle: TextStyle(color: Colors.grey.shade600),
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
                        hintText: s.get('notes_optional'),
                        hintStyle: TextStyle(color: Colors.grey.shade600),
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
                          lastDate: now.add(const Duration(days: 365 * 2)),
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
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF120E1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: selectedDueDate != null
                                  ? _cyanAccent
                                  : Colors.grey.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedDueDate != null
                                  ? '${selectedDueDate!.day}/${selectedDueDate!.month}  ${selectedDueDate!.hour.toString().padLeft(2, '0')}:${selectedDueDate!.minute.toString().padLeft(2, '0')}'
                                  : s.get('date_time_optional'),
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
                                  () => selectedDueDate = null,
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
                            onTap: () =>
                                setDialogState(() => selectedPriority = p),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? c.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? c : Colors.grey.shade800,
                                ),
                              ),
                              child: Text(
                                _priorityLabel(p, s),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? c : Colors.grey.shade600,
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

                    // --- Selector de color ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        s.isSpanish ? 'Color' : 'Color',
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
                        final isSelected = selectedColor == hex;
                        final color = hex != null
                            ? Color(
                                0xFF000000 |
                                    int.parse(hex.substring(1), radix: 16),
                              )
                            : null;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedColor = hex),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color ?? const Color(0xFF120E1A),
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
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    s.get('cancel'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (titleCtrl.text.isNotEmpty) {
                      final xp = selectedPriority == 'HIGH'
                          ? 250
                          : selectedPriority == 'MED'
                          ? 100
                          : 50;
                      if (isEditing) {
                        await viewModel.updateTask(
                          existingTask.id,
                          titleCtrl.text.trim(),
                          subCtrl.text.trim(),
                          selectedPriority,
                          xp,
                          dueDate: selectedDueDate,
                          color: selectedColor,
                        );
                      } else {
                        await viewModel.createTask(
                          titleCtrl.text.trim(),
                          subCtrl.text.trim(),
                          selectedPriority,
                          xp,
                          dueDate: selectedDueDate,
                          color: selectedColor,
                        );
                      }
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      // Tras crear una quest, navegar a la pestaña "Todas"
                      if (!isEditing) {
                        setState(() => _selectedTab = 0);
                      }
                    }
                  },
                  child: Text(
                    isEditing ? s.get('save') : s.get('add_quest'),
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

  static Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceFirst('#', '');
    if (clean.length != 6) return null;
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

/// Coloca el FAB en la esquina inferior derecha pero levantado por encima de
/// la cápsula flotante de navegación inferior del [MainScreen]. Sin esto el
/// botón queda solapado (o incluso tapado) por la cápsula, porque el
/// [Scaffold] interno no sabe nada de la barra del Scaffold padre.
class _BottomNavFabLocation extends FloatingActionButtonLocation {
  static const double _bottomOffset = 88.0;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final right =
        scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        16.0;
    final bottom =
        scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        _bottomOffset;
    return Offset(right, bottom);
  }

  @override
  String toString() => 'FloatingActionButtonLocation.bottomNavFloat';
}
