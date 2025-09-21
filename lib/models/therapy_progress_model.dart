import 'package:cloud_firestore/cloud_firestore.dart';

enum TherapyStatus { notStarted, inProgress, completed, cancelled }

class TherapyProgressModel {
  final String id;
  final String patientId;
  final String patientName;
  final String therapyName;
  final TherapyStatus status;
  final int totalSessions;
  final int completedSessions;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final double progressPercentage;
  final String? profileImageUrl;

  TherapyProgressModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.therapyName,
    required this.status,
    required this.totalSessions,
    required this.completedSessions,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.progressPercentage,
    this.profileImageUrl,
  });

  factory TherapyProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TherapyProgressModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      therapyName: data['therapyName'] ?? '',
      status: TherapyStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => TherapyStatus.notStarted,
      ),
      totalSessions: data['totalSessions'] ?? 0,
      completedSessions: data['completedSessions'] ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      progressPercentage: data['progressPercentage'] ?? 0.0,
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'therapyName': therapyName,
      'status': status.toString(),
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'notes': notes,
      'progressPercentage': progressPercentage,
      'profileImageUrl': profileImageUrl,
    };
  }
}
