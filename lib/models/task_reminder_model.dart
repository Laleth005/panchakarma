import 'package:flutter/material.dart';

class TaskReminderModel {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime dueDate;
  final String? patientId;
  final String? patientName;
  final Priority priority;

  TaskReminderModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.dueDate,
    this.patientId,
    this.patientName,
    required this.priority,
  });

  TaskReminderModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    String? patientId,
    String? patientName,
    Priority? priority,
  }) {
    return TaskReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      priority: priority ?? this.priority,
    );
  }
}

enum Priority {
  low,
  medium,
  high,
  urgent
}

extension PriorityExtension on Priority {
  String get name {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.urgent:
        return 'Urgent';
    }
  }
  
  Color get color {
    switch (this) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.blue;
      case Priority.high:
        return Colors.orange;
      case Priority.urgent:
        return Colors.red;
    }
  }
}