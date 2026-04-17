// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/task_model.dart';
import '../viewmodel/task_viewmodel.dart';

class AllTasksScreen extends StatelessWidget {
  const AllTasksScreen({super.key});

  static const _bgColor = Color(0xFF120E1A);
  static const _cardColor = Color(0xFF1E1926);
  static const _primaryPurple = Color(0xFF7B2CBF);
  static const _neonCyan = Color(0xFF00E5FF);
  static const _neonPink = Color(0xFFFF4081);
  static const _cyanAccent = Color(0xFFDEB7FF);

  @override
  Widget build(BuildContext context) {
    final taskVM = context.watch<TasksViewModel>();
    final s = context.watch<AppStrings>();
    final pending = taskVM.pending;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _primaryPurple.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.get('pending_quests'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pending.length} ${s.get('active_quests').toLowerCase()}',
                          style: TextStyle(
                            color: _neonCyan.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Neon divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _neonCyan.withOpacity(0.4),
                    _primaryPurple.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Task list
            Expanded(
              child: pending.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.grey.shade700, size: 56),
                          const SizedBox(height: 12),
                          Text(
                            s.get('no_pending_quests'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: pending.length,
                      itemBuilder: (context, index) {
                        final task = pending[index];
                        return _buildTaskItem(context, task, taskVM, s);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    TaskModel task,
    TasksViewModel taskVM,
    AppStrings s,
  ) {
    final taskColor = _parseColor(task.color);
    final priorityColor = task.priority == 'HIGH'
        ? _neonPink
        : task.priority == 'MED'
            ? Colors.orange
            : Colors.grey;
    final dueDateColor =
        task.isOverdue ? Colors.redAccent : Colors.grey.shade500;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: taskColor?.withOpacity(0.4) ??
              (task.isOverdue
                  ? Colors.redAccent.withOpacity(0.3)
                  : Colors.white.withOpacity(0.04)),
        ),
        boxShadow: taskColor != null
            ? [
                BoxShadow(
                  color: taskColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Color bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: taskColor ?? priorityColor,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (task.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              task.subtitle,
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildPill(
                                  _priorityLabel(task.priority, s), priorityColor),
                              if (task.dueDate != null) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.schedule,
                                    size: 12, color: dueDateColor),
                                const SizedBox(width: 3),
                                Text(
                                  task.formattedDueDate,
                                  style: TextStyle(
                                      color: dueDateColor, fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _cyanAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _cyanAccent.withOpacity(0.3)),
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
    );
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
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

  static Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceFirst('#', '');
    if (clean.length != 6) return null;
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}
