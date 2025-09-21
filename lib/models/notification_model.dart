import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  sessionReminder,
  patientAlert,
  procedurePrecaution,
  general,
}

extension NotificationTypeExtension on NotificationType {
  String get name {
    switch (this) {
      case NotificationType.sessionReminder:
        return 'Session Reminder';
      case NotificationType.patientAlert:
        return 'Patient Alert';
      case NotificationType.procedurePrecaution:
        return 'Procedure Note';
      case NotificationType.general:
        return 'General';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.sessionReminder:
        return 'calendar_today';
      case NotificationType.patientAlert:
        return 'warning';
      case NotificationType.procedurePrecaution:
        return 'medical_information';
      case NotificationType.general:
        return 'notifications';
    }
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? patientId;
  final String? patientName;
  final String? sessionId;
  final String practitionerId;
  final Map<String, dynamic>? additionalData;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.isRead,
    required this.practitionerId,
    this.patientId,
    this.patientName,
    this.sessionId,
    this.additionalData,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.general,
      ),
      isRead: json['isRead'] as bool,
      practitionerId: json['practitionerId'] as String,
      patientId: json['patientId'] as String?,
      patientName: json['patientName'] as String?,
      sessionId: json['sessionId'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString().split('.').last,
      'isRead': isRead,
      'practitionerId': practitionerId,
      'patientId': patientId,
      'patientName': patientName,
      'sessionId': sessionId,
      'additionalData': additionalData,
    };
  }
}
