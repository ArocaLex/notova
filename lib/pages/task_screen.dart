// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/task_model.dart';
import '../viewmodel/task_viewmodel.dart';
import '../viewmodel/user_viewmodel.dart';
import '../theme/app_colors.dart';
import 'main_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  TasksScreenState createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> {
  int _selectedTab = 0;

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
                      _buildTab(s.get('all'), 0),
                      const SizedBox(width: 24),
                      _buildTab(s.get('high_priority'), 1),
                      const SizedBox(width: 24),
                      _buildTab(s.get('completed'), 2),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (_selectedTab != 2) _ActiveTasksSection(selectedTab: _selectedTab),
                  if (_selectedTab == 2) const _CompletedTasksSection(),
                ],
              ),
            ),
          ),
          if (_selectedTab != 2)
          Positioned(
            bottom: fabBottom,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppColors.primaryPurple,
              shape: const CircleBorder(),
              elevation: 8,
              onPressed: () => _showTaskDialog(context, context.read<TasksViewModel>(), s),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ],
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
              color: isActive ? AppColors.primaryPurple : Colors.grey.shade500,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          if (isActive)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: label.length * 7.5,
              color: AppColors.primaryPurple,
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
                        fillColor: AppColors.background,
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
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: selectedDueDate != null
                                  ? AppColors.cyanAccent
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

                    Row(
                      children: ['HIGH', 'MED', 'LOW'].map((p) {
                        final priorityAccentColor = p == 'HIGH'
                            ? AppColors.priorityHigh
                            : p == 'MED'
                            ? AppColors.priorityMed
                            : AppColors.priorityLow;
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
                                _TasksHelper.priorityLabel(p, s),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? priorityAccentColor
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
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    s.get('cancel'),
                    style: const TextStyle(color: Colors.grey),
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
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
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
                '${_formatNumber(user?.totalXpEver ?? 0)} XP',
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

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
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
    final totalForProgress =
        context.select((TasksViewModel vm) => vm.totalDailyProgressCount);
    final progressAll = context.select((TasksViewModel vm) => vm.dailyProgress);

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
                '$completedTodayCount / $totalForProgress ${s.get('completed_count')}',
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

class _ActiveTasksSection extends StatelessWidget {
  final int selectedTab;

  const _ActiveTasksSection({required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final isLoading = context.select((TasksViewModel vm) => vm.isLoading);
    var tasks = context.select((TasksViewModel vm) => vm.pending);

    if (selectedTab == 1) {
      tasks = tasks.where((t) => t.priority == 'HIGH').toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        if (isLoading)
          const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
        else if (tasks.isEmpty)
          Center(
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
          )
        else
          ListView.builder(
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
                  taskViewModel: context.read<TasksViewModel>(),
                  s: s,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildActiveTaskItem({
    required BuildContext context,
    required TaskModel task,
    required TasksViewModel taskViewModel,
    required AppStrings s,
  }) {
    Color priorityColor = AppColors.accentPurple;
    if (task.priority == 'HIGH') priorityColor = AppColors.priorityHigh;
    if (task.priority == 'LOW') priorityColor = AppColors.priorityLow;
    if (task.priority == 'MED') priorityColor = AppColors.priorityMed;

    final taskColor = _TasksHelper.parseHexColor(task.color);
    final barColor = taskColor ?? priorityColor;

    final dueDateColor = task.isOverdue ? AppColors.error : Colors.grey.shade500;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final didLevelUp = await taskViewModel.toggleTaskCompletion(
          task.id,
          task.xpReward,
        );
        if (!context.mounted) return false;
        
        // Premium SnackBar Notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${s.get('quest_completed')} +${task.xpReward} XP',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.primaryPurple,
            duration: const Duration(seconds: 2),
          ),
        );
        
        if (didLevelUp) _TasksHelper.showLevelUpDialog(context, s);
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
            state._showTaskDialog(context, taskViewModel, s, existingTask: task);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: taskColor?.withOpacity(0.3) ??
                  (task.isOverdue
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
                                task.title,
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
                                  _TasksHelper.buildPill(task.priority, priorityColor, s),
                                  if (task.subtitle.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Expanded(
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
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            task.formattedDueDate,
                                            style: TextStyle(
                                              color: dueDateColor,
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (task.isOverdue) ...[
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
                            '+${task.xpReward} XP',
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

class _CompletedTasksSection extends StatelessWidget {
  const _CompletedTasksSection();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final completedAll = context.select((TasksViewModel vm) => vm.completed);
    final taskViewModel = context.read<TasksViewModel>();
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
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            if (completedAll.isNotEmpty)
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
                        '¿Eliminar las ${completedAll.length} quests completadas?',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(s.get('cancel'),
                              style: TextStyle(color: Colors.grey.shade400)),
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
        else if (completedAll.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              s.get('no_completed_quests'),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: completedAll.length,
            itemBuilder: (context, index) =>
                _buildCompletedTaskItem(context, completedAll[index], s, taskViewModel),
          ),
      ],
    );
  }

  Widget _buildCompletedTaskItem(
    BuildContext context,
    TaskModel task,
    AppStrings s,
    TasksViewModel taskViewModel,
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
                  task.title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _TasksHelper.buildPill(task.priority, Colors.grey.shade700, s),
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => taskViewModel.deleteTask(task.id),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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

class _TasksHelper {
  static String priorityLabel(String priority, AppStrings s) {
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

  static Widget buildPill(String priority, Color color, AppStrings s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priorityLabel(priority, s),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static Color? parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceFirst('#', '');
    if (clean.length != 6) return null;
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  static void showLevelUpDialog(BuildContext context, AppStrings s) {
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
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
