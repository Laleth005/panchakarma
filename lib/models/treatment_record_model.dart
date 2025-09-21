import 'package:cloud_firestore/cloud_firestore.dart';

class TreatmentRecordModel {
  final String id;
  final String patientId;
  final String practitionerId;
  final String treatmentName;
  final DateTime treatmentDate;
  final String status; // scheduled, completed, canceled
  final String? practitionerNotes;
  final double? patientFeedbackScore; // 1-5 rating
  final String? patientFeedbackNotes;
  final double? healthImprovementScore; // 1-10 scale measuring improvement

  // Additional fields for progress tracking
  final String? treatmentType;
  final DateTime? date;
  final String? notes;
  final String? treatmentStage; // initial, detox, rejuvenation, post-care
  final double? progressPercentage; // 0-100%

  TreatmentRecordModel({
    required this.id,
    required this.patientId,
    required this.practitionerId,
    required this.treatmentName,
    required this.treatmentDate,
    required this.status,
    this.practitionerNotes,
    this.patientFeedbackScore,
    this.patientFeedbackNotes,
    this.healthImprovementScore,
    this.treatmentType,
    this.date,
    this.notes,
    this.treatmentStage,
    this.progressPercentage,
  });

  factory TreatmentRecordModel.fromJson(Map<String, dynamic> json) {
    DateTime treatmentDate;
    if (json['treatmentDate'] is Timestamp) {
      treatmentDate = (json['treatmentDate'] as Timestamp).toDate();
    } else {
      treatmentDate = DateTime.now(); // Fallback
    }

    DateTime? date;
    if (json['date'] is Timestamp) {
      date = (json['date'] as Timestamp).toDate();
    } else if (json['date'] != null) {
      date = DateTime.parse(json['date'].toString());
    }

    return TreatmentRecordModel(
      id: json['id'],
      patientId: json['patientId'],
      practitionerId: json['practitionerId'],
      treatmentName: json['treatmentName'],
      treatmentDate: treatmentDate,
      status: json['status'],
      practitionerNotes: json['practitionerNotes'],
      patientFeedbackScore: json['patientFeedbackScore']?.toDouble(),
      patientFeedbackNotes: json['patientFeedbackNotes'],
      healthImprovementScore: json['healthImprovementScore']?.toDouble(),
      // Additional fields
      treatmentType: json['treatmentType'] ?? json['treatmentName'],
      date: date ?? treatmentDate,
      notes: json['notes'] ?? json['practitionerNotes'],
      treatmentStage: json['treatmentStage'],
      progressPercentage: json['progressPercentage']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'practitionerId': practitionerId,
      'treatmentName': treatmentName,
      'treatmentDate': treatmentDate,
      'status': status,
      'practitionerNotes': practitionerNotes,
      'patientFeedbackScore': patientFeedbackScore,
      'patientFeedbackNotes': patientFeedbackNotes,
      'treatmentType': treatmentType,
      'date': date,
      'notes': notes,
      'treatmentStage': treatmentStage,
      'progressPercentage': progressPercentage,
      'healthImprovementScore': healthImprovementScore,
    };
  }
}
