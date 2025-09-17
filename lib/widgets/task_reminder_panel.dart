import 'package:flutter/material.dart';
import '../models/task_reminder_model.dart';
import '../services/practitioner_repository.dart';
import 'package:intl/intl.dart';

class TaskReminderPanel extends StatefulWidget {
  final String practitionerId;
  final Function() onAddTask;
  
  const TaskReminderPanel({
    Key? key,
    required this.practitionerId,
    required this.onAddTask,
  }) : super(key: key);

  @override
  _TaskReminderPanelState createState() => _TaskReminderPanelState();
}

class _TaskReminderPanelState extends State<TaskReminderPanel> {
  final PractitionerRepository _repository = PractitionerRepository();
  List<TaskReminderModel> _tasks = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final tasks = await _repository.getTaskReminders(widget.practitionerId);
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _toggleTaskStatus(TaskReminderModel task) async {
    final newStatus = !task.isCompleted;
    final success = await _repository.updateTaskStatus(task.id, newStatus);
    
    if (success) {
      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task.copyWith(isCompleted: newStatus);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks & Reminders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.green),
                      onPressed: _loadTasks,
                      tooltip: 'Refresh',
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: Colors.green),
                      onPressed: widget.onAddTask,
                      tooltip: 'Add Task',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasError)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    SizedBox(height: 16),
                    Text(
                      'Error loading tasks',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    TextButton(
                      onPressed: _loadTasks,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade300),
                    SizedBox(height: 16),
                    Text(
                      'No pending tasks',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Add New Task'),
                      onPressed: widget.onAddTask,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _tasks.length,
                padding: EdgeInsets.symmetric(vertical: 8),
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return _buildTaskItem(task);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskReminderModel task) {
    final bool isOverdue = task.dueDate.isBefore(DateTime.now()) && !task.isCompleted;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: task.isCompleted,
              onChanged: (_) => _toggleTaskStatus(task),
              activeColor: Colors.green.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? Colors.grey : Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: task.isCompleted ? Colors.grey : Colors.grey.shade700,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.priority.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.priority.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: task.priority.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    if (task.patientName != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.patientName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isOverdue ? Colors.red : Colors.grey.shade600,
                        ),
                        SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d').format(task.dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isOverdue ? FontWeight.bold : null,
                            color: isOverdue ? Colors.red : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}