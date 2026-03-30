// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../viewmodel/task_viewmodel.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  TasksScreenState createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final taskViewModel = context.read<TasksViewModel>();
    final user = FirebaseAuth.instance.currentUser;

    const bgColor = Color(0xFF120E1A);
    const cardColor = Color(0xFF1E1A29);
    const primaryPurple = Color(0xFF7B2CBF);
    const accentPurple = Color(0xFF8A2BE2);
    const cyanAccent = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryPurple,
        shape: const CircleBorder(),
        elevation: 8,
        onPressed: () => _showAddTaskDialog(context, taskViewModel),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CABECERA CON DATOS REALES ---
              if (user != null)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int xp = 0;
                    int level = 1;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      xp = data['currentXp'] ?? 0;
                      level = data['level'] ?? 1;
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Quests",
                              style: TextStyle(
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
                                color: primaryPurple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: primaryPurple.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'LEVEL $level · ADVENTURER',
                                style: const TextStyle(
                                  color: Color(0xFF7B2CBF),
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
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: cyanAccent.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.flash_on,
                                color: cyanAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_formatNumber(xp)} XP',
                                style: const TextStyle(
                                  color: cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 24),

              // --- TARJETA DE PROGRESO DIARIO ---
              if (user != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('tasks')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int total = 0;
                    int completed = 0;
                    if (snapshot.hasData) {
                      final docs = snapshot.data!.docs;
                      total = docs.length;
                      completed = docs
                          .where((d) =>
                              (d.data() as Map<String, dynamic>)['isCompleted'] == true)
                          .length;
                    }
                    final double progress = total > 0 ? completed / total : 0.0;
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5C1A99), accentPurple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: primaryPurple.withOpacity(0.35),
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
                              const Text(
                                'DAILY PROGRESS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                '$completed / $total Completed',
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
                ),
              const SizedBox(height: 24),

              // --- PESTAÑAS ---
              Row(
                children: [
                  _buildTab('All', 0),
                  const SizedBox(width: 24),
                  _buildTab('High Priority', 1),
                  const SizedBox(width: 24),
                  _buildTab('Completed', 2),
                ],
              ),
              const SizedBox(height: 28),

              // --- ACTIVE QUESTS ---
              Row(
                children: [
                  const Text(
                    'ACTIVE QUESTS',
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
                    color: Colors.grey.shade800,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              StreamBuilder<QuerySnapshot>(
                stream: taskViewModel.pendingTasksStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryPurple),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                              'No pending quests!\nAdd a new one with the + button.',
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

                  final tasks = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final taskDoc = tasks[index];
                      final taskData = taskDoc.data() as Map<String, dynamic>;

                      return _buildActiveTaskItem(
                        context: context,
                        taskId: taskDoc.id,
                        title: taskData['title'] ?? 'Unknown Task',
                        subtitle: taskData['subtitle'] ?? '',
                        priority: taskData['priority'] ?? 'MED',
                        xpReward: taskData['xpReward'] ?? 0,
                        taskViewModel: taskViewModel,
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // --- COMPLETED QUESTS ---
              const Text(
                'COMPLETED QUESTS',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: taskViewModel.completedTasksStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No completed quests yet.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      return _buildCompletedTaskItem(
                        data['title'] ?? '',
                        data['priority'] ?? 'PERSONAL',
                        data['xpReward'] ?? 0,
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    const primaryPurple = Color(0xFF7B2CBF);
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? primaryPurple : Colors.grey.shade500,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(height: 2, width: label.length * 7.5, color: primaryPurple),
        ],
      ),
    );
  }

  Widget _buildActiveTaskItem({
    required BuildContext context,
    required String taskId,
    required String title,
    required String subtitle,
    required String priority,
    required int xpReward,
    required TasksViewModel taskViewModel,
  }) {
    const cyanAccent = Color(0xFF00E5FF);
    Color priorityColor = const Color(0xFF8A2BE2);
    if (priority == 'HIGH') priorityColor = const Color(0xFFE53935);
    if (priority == 'LOW') priorityColor = Colors.grey;
    if (priority == 'MED') priorityColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A29),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              taskViewModel.toggleTaskCompletion(taskId, xpReward);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '¡Quest completed! +$xpReward XP',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: const Color(0xFF7B2CBF),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF7B2CBF),
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
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildPill(
                      priority == 'HIGH' ? 'WORK' : 'PERSONAL',
                      priority == 'HIGH'
                          ? const Color(0xFF7B2CBF)
                          : const Color(0xFF00BFA5),
                    ),
                    const SizedBox(width: 6),
                    _buildPill(priority, priorityColor),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cyanAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cyanAccent.withOpacity(0.3)),
            ),
            child: Text(
              '+$xpReward XP',
              style: const TextStyle(
                color: cyanAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTaskItem(String title, String category, int xpReward) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A29).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF7B2CBF).withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.check,
              color: Color(0xFF7B2CBF),
              size: 16,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                _buildPill(category, Colors.grey.shade700),
              ],
            ),
          ),
          Text(
            '+$xpReward XP',
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

  void _showAddTaskDialog(BuildContext context, TasksViewModel viewModel) {
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    String selectedPriority = 'HIGH';

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
              title: const Text(
                'New Quest',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Quest Title',
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
                      hintText: 'Time (e.g., 5:00 PM)',
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
                  Row(
                    children: ['HIGH', 'MED', 'LOW'].map((p) {
                      Color c = p == 'HIGH'
                          ? const Color(0xFFE53935)
                          : p == 'MED'
                              ? Colors.orange
                              : Colors.grey;
                      bool isSelected = selectedPriority == p;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => selectedPriority = p),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? c.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? c : Colors.grey.shade800,
                              ),
                            ),
                            child: Text(
                              p,
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
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2CBF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty) {
                      viewModel.createTask(
                        titleCtrl.text.trim(),
                        subCtrl.text.trim(),
                        selectedPriority,
                        selectedPriority == 'HIGH' ? 250 : selectedPriority == 'MED' ? 100 : 50,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text(
                    'Add Quest',
                    style: TextStyle(
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

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
