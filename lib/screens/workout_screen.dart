import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutProvider);
    final categories = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final currentDayIndex = DateTime.now().weekday - 1;

    return DefaultTabController(
      length: categories.length,
      initialIndex: currentDayIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Workout Tracker'),
          bottom: TabBar(
            isScrollable: true,
            indicatorPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            tabs: categories.map((c) => Tab(text: c)).toList(),
          ),
        ),
        body: TabBarView(
          children: categories.map((category) {
            final categoryWorkouts = workouts.where((w) => w.category == category).toList();
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categoryWorkouts.isEmpty ? 1 : categoryWorkouts.length,
              itemBuilder: (context, index) {
                if (categoryWorkouts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/rest.png', width: 200),
                          const SizedBox(height: 24),
                          Text('Rest day! Chill out on $category.', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                }
                final workout = categoryWorkouts[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onLongPress: () => _showExerciseGifDialog(context, workout.exerciseName),
                      leading: const Icon(Icons.fitness_center, color: Colors.white70),
                      title: Text(
                        workout.exerciseName,
                        style: TextStyle(
                          decoration: workout.isCompleted ? TextDecoration.lineThrough : null,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text('${workout.setsCompleted} Sets', style: const TextStyle(color: Colors.white70)),
                      trailing: Checkbox(
                        value: workout.isCompleted,
                        onChanged: (val) {
                          ref.read(workoutProvider.notifier).toggleWorkoutCompletion(workout.id);
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showExerciseGifDialog(BuildContext context, String exerciseName) {
    String gifPath = _getGifPath(exerciseName);
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      exerciseName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        gifPath,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('Animation missing from bundle', style: TextStyle(color: Colors.white54)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(color: Colors.blueAccent)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getGifPath(String name) {
    name = name.toLowerCase();
    
    // Curls
    if (name.contains('backpack curl')) return 'assets/gif/backpack_curls.gif';
    if (name.contains('towel curl')) return 'assets/gif/towel_curls.gif';
    if (name.contains('curl')) return 'assets/gif/backpack_curls.gif';
    
    // Push-ups
    if (name.contains('decline push')) return 'assets/gif/decline_pushup.gif';
    if (name.contains('incline push')) return 'assets/gif/incline_pushup.gif';
    if (name.contains('diamond push')) return 'assets/gif/diamond_pushup.gif';
    if (name.contains('push')) return 'assets/gif/pushup.gif';

    // Core
    if (name.contains('bicycle crunch')) return 'assets/gif/bicycle_crunch.gif';
    if (name.contains('crunch')) return 'assets/gif/crunches.gif';
    if (name.contains('leg raise')) return 'assets/gif/leg_raises.gif';
    if (name.contains('plank')) return 'assets/gif/plank.gif';
    
    // Lower body / Cardio
    if (name.contains('jump squat')) return 'assets/gif/jump_squats.gif';
    if (name.contains('squat')) return 'assets/gif/squats.gif';
    if (name.contains('calf raise')) return 'assets/gif/calf_raises.gif';
    if (name.contains('lunge')) return 'assets/gif/lunges.gif';
    if (name.contains('mountain')) return 'assets/gif/mountain_climbers.gif';

    // Default missing
    return 'assets/gif/pushup.gif';
  }
}
