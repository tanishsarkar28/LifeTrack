import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../models/task_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all providers at the top level of the ConsumerWidget
    final score = ref.watch(dailyScoreProvider);
    final tasks = ref.watch(taskProvider);
    final profile = ref.watch(userProfileProvider);
    
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final totalTasks = tasks.length;
    final taskPercent = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    final streak = ref.watch(streakProvider);
    final currentDate = DateTime.now();

    final waterTasks = tasks.where((t) => t.title.toLowerCase().contains('water') && t.date.year == currentDate.year && t.date.month == currentDate.month && t.date.day == currentDate.day).toList();
    final waterCompleted = waterTasks.where((t) => t.isCompleted).length;
    const totalWaterGlasses = 8;
    final completedWaterGlasses = waterCompleted.clamp(0, totalWaterGlasses);
    final waterProgress = totalWaterGlasses == 0 ? 0.0 : completedWaterGlasses / totalWaterGlasses;
    final waterMl = (completedWaterGlasses * 250).clamp(0, 2000);
    final waterStatus = waterTasks.isEmpty
        ? 'Not started'
        : completedWaterGlasses == 0
            ? 'Not started'
            : completedWaterGlasses == totalWaterGlasses
                ? '2L goal complete'
                : '${completedWaterGlasses} of $totalWaterGlasses glasses';

    final motivationalQuotes = [
      'Build today what your future self will thank you for.',
      'Small steps every day lead to remarkable changes.',
      'Rise with purpose, rest with pride.',
      'Push your limits and surprise yourself.',
      'Progress is earned in the moments no one sees.',
      'Momentum grows when you keep showing up.',
      'Your best investment is the effort you make now.',
    ];
    final quote = motivationalQuotes[DateTime.now().day % motivationalQuotes.length];

    return Scaffold(
      appBar: AppBar(
        title: const Text('LifeTrack Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: const Color(0xFF151D36),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today’s motivation',
                    style: TextStyle(fontSize: 14, color: Colors.white70, letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    quote,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Score and Streak Card
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2552), Color(0xFF141A33)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min, // Fixed Layout Exception
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: score / 100,
                              strokeWidth: 8,
                              color: _getScoreColor(score),
                              backgroundColor: Colors.grey[800],
                            ),
                          ),
                          Text(
                            '$score',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text('Daily Score'),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min, // Fixed Layout Exception
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 60),
                      const SizedBox(height: 10),
                      Text('$streak Day Streak', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Task Progress Card
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF141B33),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(value: taskPercent, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Fixed Layout Exception
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Daily Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('$completedTasks of $totalTasks completed', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hydration Progress
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: const Color(0xFF151D36),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.water_drop, color: Colors.cyan, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Water Intake', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(height: 4),
                            Text('Daily goal: 2.0 L', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: waterCompleted == 0 ? null : () {
                              final lastCompleted = waterTasks.lastWhere((t) => t.isCompleted);
                              ref.read(taskProvider.notifier).removeTask(lastCompleted.id);
                            },
                            icon: Icon(Icons.remove_circle_outline, color: waterCompleted == 0 ? Colors.white30 : Colors.white70),
                            tooltip: 'Remove a glass',
                          ),
                          IconButton(
                            onPressed: () {
                              final task = TaskModel(
                                id: 'water_${DateTime.now().millisecondsSinceEpoch}',
                                title: 'Drink Water',
                                date: DateTime.now(),
                                isCustom: true,
                                isDaily: false,
                              )..isCompleted = true;
                              ref.read(taskProvider.notifier).addTask(task);
                            },
                            icon: const Icon(Icons.add_circle_outline, color: Colors.cyan),
                            tooltip: 'Add a glass',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: LinearProgressIndicator(
                      value: waterProgress,
                      minHeight: 14,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${waterMl} ml / 2000 ml',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    waterStatus,
                    style: TextStyle(color: waterProgress >= 1 ? Colors.greenAccent : Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Hydration reminders enabled from 09:00 to 23:59.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.yellow;
    return Colors.red;
  }

  Widget _buildOverviewCard({required String title, required IconData icon, required Color color, required String status, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF141A2E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            Text(status, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}