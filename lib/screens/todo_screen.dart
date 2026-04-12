import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider).where((t) => !t.id.startsWith('water_')).toList();
    tasks.sort(_compareTaskTime);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Checklist'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMMd().format(DateTime.now()),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${tasks.where((t) => t.isCompleted).length}/${tasks.length} Completed',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onLongPress: () => _showEditTaskDialog(context, ref, task),
                        child: CheckboxListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.isDaily ? '${task.title} (Daily)' : task.title,
                                  style: TextStyle(
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    color: task.isCompleted ? Colors.grey : Colors.white,
                                  ),
                                ),
                              ),
                              if (task.notificationHour != null && task.notificationMinute != null)
                                Text(
                                  '${task.notificationHour.toString().padLeft(2, '0')}:${task.notificationMinute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                            ],
                          ),
                          value: task.isCompleted,
                          onChanged: (val) {
                            ref.read(taskProvider.notifier).toggleTaskCompletion(task.id);
                          },
                          activeColor: Theme.of(context).primaryColor,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  int _compareTaskTime(TaskModel a, TaskModel b) {
    if (a.notificationHour == null && b.notificationHour == null) return 0;
    if (a.notificationHour == null) return 1;
    if (b.notificationHour == null) return -1;

    final minutesA = a.notificationHour! * 60 + (a.notificationMinute ?? 0);
    final minutesB = b.notificationHour! * 60 + (b.notificationMinute ?? 0);
    return minutesA.compareTo(minutesB);
  }

  void _showEditTaskDialog(BuildContext context, WidgetRef ref, TaskModel task) {
    String title = task.title;
    bool isDaily = task.isDaily;
    TimeOfDay? selectedTime = task.notificationHour != null && task.notificationMinute != null
        ? TimeOfDay(hour: task.notificationHour!, minute: task.notificationMinute!)
        : null;
    final TextEditingController controller = TextEditingController(text: title);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Task Title'),
                    controller: controller,
                    onChanged: (val) => title = val,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Repeat Everyday (1 AM)'),
                      Switch(
                        value: isDaily,
                        onChanged: (val) => setState(() => isDaily = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(selectedTime == null 
                          ? 'No Time Selected' 
                          : 'Time: ${selectedTime!.format(context)}'),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              selectedTime = time;
                            });
                          }
                        },
                        child: const Text('Time'),
                      ),
                      if (selectedTime != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => selectedTime = null),
                        )
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (task.notificationHour != null) {
                      NotificationService.cancelNotification(task.id.hashCode);
                    }
                    ref.read(taskProvider.notifier).removeTask(task.id);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (title.isNotEmpty) {
                      task.title = title;
                      task.isDaily = isDaily;
                      if (task.notificationHour != null) {
                         NotificationService.cancelNotification(task.id.hashCode);
                      }
                      task.notificationHour = selectedTime?.hour;
                      task.notificationMinute = selectedTime?.minute;
                      ref.read(taskProvider.notifier).updateTask(task);

                      if (selectedTime != null) {
                        NotificationService.scheduleDailyTaskNotification(
                          id: task.id.hashCode,
                          title: 'LifeTrack Task Reminder',
                          body: 'Time to do: $title',
                          hour: selectedTime!.hour,
                          minute: selectedTime!.minute,
                        );
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    String title = '';
    bool isDaily = true;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Task Title'),
                    onChanged: (val) => title = val,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Repeat Everyday (1 AM)'),
                      Switch(
                        value: isDaily,
                        onChanged: (val) => setState(() => isDaily = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(selectedTime == null 
                          ? 'No Time Selected' 
                          : 'Time: ${selectedTime!.format(context)}'),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              selectedTime = time;
                            });
                          }
                        },
                        child: const Text('Time'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (title.isNotEmpty) {
                      final newTask = TaskModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: title,
                        date: DateTime.now(),
                        isCustom: true,
                        isDaily: isDaily,
                        notificationHour: selectedTime?.hour,
                        notificationMinute: selectedTime?.minute,
                      );
                      
                      ref.read(taskProvider.notifier).addTask(newTask);

                      if (selectedTime != null) {
                        NotificationService.scheduleDailyTaskNotification(
                          id: newTask.id.hashCode,
                          title: 'LifeTrack Task Reminder',
                          body: 'Time to do: $title',
                          hour: selectedTime!.hour,
                          minute: selectedTime!.minute,
                        );
                      }

                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
