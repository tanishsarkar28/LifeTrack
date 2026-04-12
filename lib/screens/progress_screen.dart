import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/data_providers.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    });
  }

  Future<void> _pickMonthYear() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(now.year - 10, 1, 1),
      lastDate: DateTime(now.year + 10, 12, 31),
      helpText: 'Select month and year',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTasks = ref.watch(taskProvider);
    final workouts = ref.watch(workoutProvider);
    final progressHistory = ref.watch(taskProgressProvider);
    final progressDetails = ref.watch(taskProgressDetailsProvider);
    final workoutInclusion = ref.watch(workoutCalendarInclusionProvider);
    
    final today = DateTime.now();
    final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final daysCount = monthEnd.day;
    
    final days = List.generate(daysCount, (index) => DateTime(monthStart.year, monthStart.month, index + 1));
    
    int activeDaysThisMonth = 0;
    double totalProgressThisMonth = 0.0;
    for (var day in days) {
      final progress = progressHistory[day] ?? 0.0;
      if (progress > 0) {
        activeDaysThisMonth++;
        totalProgressThisMonth += progress;
      }
    }
    
    final offset = monthStart.weekday - 1; // Monday=1
    final trailing = (7 - (offset + days.length) % 7) % 7;
    
    final averageCompletion = activeDaysThisMonth == 0
        ? 0.0
        : totalProgressThisMonth / activeDaysThisMonth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Calendar'),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).cardColor, Theme.of(context).canvasColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _prevMonth,
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                  InkWell(
                    onTap: _pickMonthYear,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                          child: Text(
                            DateFormat.yMMMM().format(selectedMonth),
                            key: ValueKey(selectedMonth),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryCard('Tracked Days', '$activeDaysThisMonth'),
                const SizedBox(width: 12),
                _buildSummaryCard('Average', '${(averageCompletion * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Completion Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildLegend(context),
            const SizedBox(height: 16),
            _buildWeekHeader(context),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: GridView.builder(
                  key: ValueKey(selectedMonth),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: offset + days.length + trailing,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    if (index < offset || index >= offset + days.length) {
                      return _buildEmptyTile(context);
                    }
                    final day = days[index - offset];
                    final progress = progressHistory[day];
                    final details = progressDetails[day];
                    final isToday = DateTime(day.year, day.month, day.day) == DateTime(today.year, today.month, today.day);
                    final workoutIncluded = workoutInclusion[day] ?? true;
                    return _buildDayTile(context, day, progress, details, currentTasks, workouts, workoutIncluded, isToday);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).canvasColor, Theme.of(context).cardColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekHeader(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildLegendChip(context, Colors.green, '90-100%'),
        _buildLegendChip(context, Colors.lightGreen, '65-89%'),
        _buildLegendChip(context, Colors.orange, '35-64%'),
        _buildLegendChip(context, Colors.red, '0-34%'),
      ],
    );
  }

  Widget _buildLegendChip(BuildContext context, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildEmptyTile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
    );
  }

  Widget _buildDayTile(BuildContext context, DateTime day, double? progress, Map<String, dynamic>? details, List<TaskModel> currentTasks, List<dynamic> workouts, bool workoutIncluded, bool isToday) {
    final bgColor = progress == null
        ? Theme.of(context).canvasColor
        : progress >= 0.9
            ? Colors.green
            : progress >= 0.65
                ? Colors.lightGreen
                : progress >= 0.35
                    ? Colors.orange
                    : Colors.red;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? Colors.blueAccent : (progress == null ? Colors.white10 : Colors.transparent),
          width: isToday ? 2 : 1,
        ),
        boxShadow: [
          if (progress != null)
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white24,
          onTap: () => _showDayDetailsDialog(context, day, details, currentTasks, workouts, workoutIncluded, isToday),
          child: Padding(
            padding: const EdgeInsets.all(4.0), // Reduced from 8 to prevent constraints
            child: FittedBox( // NEW: Guarantees no overflow by scaling down text if needed
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 4), // Reduced from 8
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDayDetailsDialog(BuildContext context, DateTime day, Map<String, dynamic>? details, List<TaskModel> currentTasks, List<dynamic> workouts, bool workoutIncluded, bool isToday) {
    late final int completedCount;
    late final int totalCount;
    late final List<String> incompleteTasks;
    late final List<String> completedTasks;

    if (isToday) {
      completedTasks = currentTasks.where((t) => t.isCompleted).map((t) => t.title).toList();
      incompleteTasks = currentTasks.where((t) => !t.isCompleted).map((t) => t.title).toList();
      completedCount = completedTasks.length;
      totalCount = currentTasks.length;
    } else if (details != null) {
      completedCount = details['completedCount'] as int? ?? 0;
      totalCount = details['totalCount'] as int? ?? 0;
      completedTasks = List<String>.from(details['completedTitles'] as List? ?? []);
      incompleteTasks = List<String>.from(details['incompleteTitles'] as List? ?? []);
    } else {
      completedCount = 0;
      totalCount = 0;
      completedTasks = [];
      incompleteTasks = [];
    }

    final dayWorkouts = workouts.where((w) {
      try {
        final date = (w as dynamic).date as DateTime;
        return DateTime(date.year, date.month, date.day) == day;
      } catch (_) {
        return false;
      }
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(DateFormat.yMMMMd().format(day)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Completed tasks: $completedCount / $totalCount'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Workout counts toward calendar: ${workoutIncluded ? 'Yes' : 'No'}')),
                  ],
                ),
                const SizedBox(height: 12),
                if (dayWorkouts.isNotEmpty) ...[
                  Text('Workout entries: ${dayWorkouts.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                ],
                if (incompleteTasks.isNotEmpty) ...[
                  const Text('Incomplete tasks:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...incompleteTasks.map(
                    (title) => Text('• $title', style: const TextStyle(fontSize: 13)),
                  ),
                ] else ...[
                  const Text('No incomplete tasks recorded.'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(workoutCalendarInclusionProvider.notifier).toggle(day);
                Navigator.of(context).pop();
              },
              child: Text(workoutIncluded ? 'Exclude Workout' : 'Include Workout'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}