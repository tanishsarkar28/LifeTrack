import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildBadge(icon: Icons.military_tech, title: 'First Step', subtitle: 'Completed 1 Day', isUnlocked: true),
          _buildBadge(icon: Icons.local_fire_department, title: '3 Day Warrior', subtitle: '3 Day Streak', isUnlocked: true),
          _buildBadge(icon: Icons.workspace_premium, title: 'Week Champion', subtitle: '7 Day Streak', isUnlocked: false),
          _buildBadge(icon: Icons.code, title: 'Code Master', subtitle: 'Solve 50 DSA', isUnlocked: false),
          _buildBadge(icon: Icons.fitness_center, title: 'Fitness Beginner', subtitle: '10 Workouts', isUnlocked: false),
          _buildBadge(icon: Icons.star, title: 'Discipline Pro', subtitle: '90+ Daily Score', isUnlocked: false),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isUnlocked,
  }) {
    return Card(
      color: isUnlocked ? const Color(0xFF1E1E1E) : Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUnlocked ? Colors.amber : Colors.grey.shade800,
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 50,
            color: isUnlocked ? Colors.amber : Colors.grey,
          ),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isUnlocked ? Colors.white : Colors.grey)),
          const SizedBox(height: 5),
          Text(subtitle, style: TextStyle(color: isUnlocked ? Colors.white70 : Colors.grey, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
