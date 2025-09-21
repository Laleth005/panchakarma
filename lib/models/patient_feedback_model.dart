import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType { general, therapySpecific, patientReport, systemFeedback }

class PatientFeedbackModel {
  final String id;
  final String patientId;
  final String patientName;
  final String? sessionId;
  final String? therapyType;
  final DateTime dateTime;
  final String feedback;
  final int rating; // 1-5 star rating
  final FeedbackType type;
  final bool isAcknowledged;
  final String? practitionerResponse;
  final DateTime? respondedAt;

  PatientFeedbackModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.sessionId,
    this.therapyType,
    required this.dateTime,
    required this.feedback,
    required this.rating,
    required this.type,
    this.isAcknowledged = false,
    this.practitionerResponse,
    this.respondedAt,
  });

  factory PatientFeedbackModel.fromJson(Map<String, dynamic> json) {
    return PatientFeedbackModel(
      id: json['id'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      sessionId: json['sessionId'],
      therapyType: json['therapyType'],
      dateTime: (json['dateTime'] as Timestamp).toDate(),
      feedback: json['feedback'],
      rating: json['rating'],
      type: FeedbackType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => FeedbackType.general,
      ),
      isAcknowledged: json['isAcknowledged'] ?? false,
      practitionerResponse: json['practitionerResponse'],
      respondedAt: json['respondedAt'] != null
          ? (json['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'sessionId': sessionId,
      'therapyType': therapyType,
      'dateTime': Timestamp.fromDate(dateTime),
      'feedback': feedback,
      'rating': rating,
      'type': type.toString().split('.').last,
      'isAcknowledged': isAcknowledged,
      'practitionerResponse': practitionerResponse,
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
    };
  }

  PatientFeedbackModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? sessionId,
    String? therapyType,
    DateTime? dateTime,
    String? feedback,
    int? rating,
    FeedbackType? type,
    bool? isAcknowledged,
    String? practitionerResponse,
    DateTime? respondedAt,
  }) {
    return PatientFeedbackModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      sessionId: sessionId ?? this.sessionId,
      therapyType: therapyType ?? this.therapyType,
      dateTime: dateTime ?? this.dateTime,
      feedback: feedback ?? this.feedback,
      rating: rating ?? this.rating,
      type: type ?? this.type,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      practitionerResponse: practitionerResponse ?? this.practitionerResponse,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
