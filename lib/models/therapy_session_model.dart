import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum SessionStatus { pending, inProgress, completed, cancelled }

extension SessionStatusExtension on SessionStatus {
  String get name {
    switch (this) {
      case SessionStatus.pending:
        return 'Pending';
      case SessionStatus.inProgress:
        return 'In Progress';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case SessionStatus.pending:
        return Colors.orange;
      case SessionStatus.inProgress:
        return Colors.blue;
      case SessionStatus.completed:
        return Colors.green;
      case SessionStatus.cancelled:
        return Colors.red;
    }
  }
}

class TherapySessionModel {
  final String id;
  final String patientId;
  final String patientName;
  final String therapyType;
  final DateTime dateTime;
  final int durationMinutes;
  final String roomNumber;
  final String bedNumber;
  final SessionStatus status;
  final String? notes;
  final String practitionerId;
  final String? practitionerName;
  final bool hasSpecialInstructions;
  final List<String>? specialInstructions;

  TherapySessionModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.therapyType,
    required this.dateTime,
    required this.durationMinutes,
    required this.roomNumber,
    required this.bedNumber,
    required this.status,
    this.notes,
    required this.practitionerId,
    this.practitionerName,
    this.hasSpecialInstructions = false,
    this.specialInstructions,
  });

  factory TherapySessionModel.fromJson(Map<String, dynamic> json) {
    return TherapySessionModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      therapyType: json['therapyType'] as String,
      dateTime: (json['dateTime'] as Timestamp).toDate(),
      durationMinutes: json['durationMinutes'] as int,
      roomNumber: json['roomNumber'] as String,
      bedNumber: json['bedNumber'] as String,
      status: SessionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => SessionStatus.pending,
      ),
      notes: json['notes'] as String?,
      practitionerId: json['practitionerId'] as String,
      practitionerName: json['practitionerName'] as String?,
      hasSpecialInstructions: json['hasSpecialInstructions'] as bool? ?? false,
      specialInstructions: json['specialInstructions'] != null
          ? List<String>.from(json['specialInstructions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'therapyType': therapyType,
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'roomNumber': roomNumber,
      'bedNumber': bedNumber,
      'status': status.toString().split('.').last,
      'notes': notes,
      'practitionerId': practitionerId,
      'practitionerName': practitionerName,
      'hasSpecialInstructions': hasSpecialInstructions,
      'specialInstructions': specialInstructions,
    };
  }

  bool isScheduledForToday() {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  bool isUpcoming() {
    final now = DateTime.now();
    return dateTime.isAfter(now) && status == SessionStatus.pending;
  }

  TherapySessionModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? therapyType,
    DateTime? dateTime,
    int? durationMinutes,
    String? roomNumber,
    String? bedNumber,
    SessionStatus? status,
    String? notes,
    String? practitionerId,
    String? practitionerName,
    bool? hasSpecialInstructions,
    List<String>? specialInstructions,
  }) {
    return TherapySessionModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      therapyType: therapyType ?? this.therapyType,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      roomNumber: roomNumber ?? this.roomNumber,
      bedNumber: bedNumber ?? this.bedNumber,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      practitionerId: practitionerId ?? this.practitionerId,
      practitionerName: practitionerName ?? this.practitionerName,
      hasSpecialInstructions:
          hasSpecialInstructions ?? this.hasSpecialInstructions,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}
