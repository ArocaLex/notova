// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../viewmodel/calendar_viewmodel.dart';
import '../models/calendar_event.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B2CBF)),
      );
    }

    const bgColor = Color(0xFF15111D);
    const cardColor = Color(0xFF1E1926);
    const primaryPurple = Color(0xFF7B2CBF);
    const accentPurple = Color(0xFF8A2BE2);
    const cyanAccent = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryPurple),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  'Creando tu perfil...',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;

            String name = userData['name'] ?? 'Usuario';
            int currentXp = userData['currentXp'] ?? 1310;
            int totalXp = userData['totalXp'] ?? 2000;
            int level = userData['level'] ?? 13;
            int streak = userData['dayStreak'] ?? 12;
            String rank = userData['rank'] ?? '#4';

            double progress = totalXp > 0 ? (currentXp / totalXp) : 0.0;
            if (progress > 1.0) progress = 1.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [primaryPurple, cyanAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPurple.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFF2A223E),
                          child: Icon(Icons.person, color: Colors.white70, size: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good morning, $name',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(DateTime.now()),
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- TARJETA XP ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5C1A99), primaryPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.4),
                          blurRadius: 20,
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
                            const Row(
                              children: [
                                Icon(Icons.flash_on, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Daily XP Progress',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_formatNumber(currentXp)} / ${_formatNumber(totalXp)} XP',
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
                            color: Colors.black.withOpacity(0.25),
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
                        const SizedBox(height: 12),
                        Text(
                          '${_formatNumber(totalXp - currentXp)} XP left to reach Level ${level + 1}! Keep it up.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- UP NEXT ---
                  _buildSectionHeader('Up Next', 'View Schedule'),
                  const SizedBox(height: 14),
                  _buildUpNextCard(context, cardColor, accentPurple, primaryPurple),
                  const SizedBox(height: 28),

                  // --- TOP PENDING TASKS ---
                  _buildSectionHeader('Top Pending Tasks', 'View All'),
                  const SizedBox(height: 14),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('tasks')
                        .where('isCompleted', isEqualTo: false)
                        .orderBy('createdAt', descending: true)
                        .limit(3)
                        .snapshots(),
                    builder: (context, taskSnap) {
                      if (!taskSnap.hasData || taskSnap.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'No pending tasks. Add one in the Quests tab!',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        );
                      }
                      return Column(
                        children: taskSnap.data!.docs.asMap().entries.map((entry) {
                          final data = entry.value.data() as Map<String, dynamic>;
                          final priority = data['priority'] as String? ?? 'MED';
                          Color priorityColor = accentPurple;
                          if (priority == 'HIGH') priorityColor = const Color(0xFFDEB7FF);
                          if (priority == 'LOW') priorityColor = Colors.grey;
                          return Column(
                            children: [
                              _buildTaskCard(
                                data['title'] ?? '',
                                data['subtitle'] ?? '',
                                priority,
                                priorityColor,
                              ),
                              if (entry.key < taskSnap.data!.docs.length - 1)
                                const SizedBox(height: 10),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // --- STATS ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          Icons.local_fire_department,
                          streak.toString(),
                          'Day Streak',
                          Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          Icons.emoji_events,
                          rank,
                          'Leaderboard',
                          cyanAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildSectionHeader(String title, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
          ),
          child: const Text(
            'View All',
            style: TextStyle(
              color: Color(0xFF7B2CBF),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(
    String title,
    String subtitle,
    String priority,
    Color priorityColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1926),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF7B2CBF), width: 2),
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
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              priority,
              style: TextStyle(
                color: priorityColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpNextCard(
    BuildContext context,
    Color cardColor,
    Color accentPurple,
    Color primaryPurple,
  ) {
    final calendarVM = context.watch<CalendarViewModel>();

    if (!calendarVM.isSignedIn) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: Colors.grey.shade600, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Connect Google Calendar to see upcoming events',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    CalendarEvent? nextEvent;
    for (final event in calendarVM.events) {
      if (event.isAllDay) continue;
      if (event.start != null && event.start!.isAfter(now)) {
        nextEvent = event;
        break;
      }
    }

    if (nextEvent == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(Icons.event_available, color: Colors.grey.shade600, size: 32),
            const SizedBox(width: 16),
            Text(
              'No upcoming events today',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final minutesUntil = nextEvent.start!.difference(now).inMinutes;
    final timeLabel = minutesUntil <= 60
        ? 'IN $minutesUntil MINUTES'
        : 'AT ${nextEvent.formattedTime}';

    String endFormatted = '';
    if (nextEvent.end != null) {
      final h = nextEvent.end!.hour;
      final m = nextEvent.end!.minute.toString().padLeft(2, '0');
      final period = h >= 12 ? 'PM' : 'AM';
      final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      endFormatted = '$displayH:$m $period';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  style: TextStyle(
                    color: accentPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  nextEvent.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Text(
                  endFormatted.isNotEmpty
                      ? '${nextEvent.formattedTime} - $endFormatted'
                      : nextEvent.formattedTime,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event,
              color: Color(0xFF7B2CBF),
              size: 38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1926),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
