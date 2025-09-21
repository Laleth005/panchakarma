import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:panchakarma/models/therapy_session_model.dart';

// This class provides dummy data for testing the Today's Schedule panel
class DummySessionData {
  // Generate dummy therapy sessions for today
  static List<TherapySessionModel> getTodaySessions(String practitionerId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      TherapySessionModel(
        id: 'session1',
        patientId: 'patient1',
        patientName: 'John Smith',
        therapyType: 'Abhyanga',
        dateTime: DateTime(today.year, today.month, today.day, 9, 0), // 9:00 AM
        durationMinutes: 60,
        roomNumber: '101',
        bedNumber: '1',
        status: SessionStatus.completed,
        notes: 'Patient mentioned back pain relief after last session',
        practitionerId: practitionerId,
        practitionerName: 'Dr. Ayurveda',
        hasSpecialInstructions: true,
        specialInstructions: [
          'Use gentle pressure on lower back',
          'Use extra sesame oil',
        ],
      ),
      TherapySessionModel(
        id: 'session2',
        patientId: 'patient2',
        patientName: 'Sarah Johnson',
        therapyType: 'Shirodhara',
        dateTime: DateTime(
          today.year,
          today.month,
          today.day,
          10,
          30,
        ), // 10:30 AM
        durationMinutes: 45,
        roomNumber: '102',
        bedNumber: '2',
        status: SessionStatus.inProgress,
        practitionerId: practitionerId,
        practitionerName: 'Dr. Ayurveda',
      ),
      TherapySessionModel(
        id: 'session3',
        patientId: 'patient3',
        patientName: 'Robert Brown',
        therapyType: 'Swedana',
        dateTime: DateTime(
          today.year,
          today.month,
          today.day,
          13,
          0,
        ), // 1:00 PM
        durationMinutes: 30,
        roomNumber: '103',
        bedNumber: '1',
        status: SessionStatus.pending,
        practitionerId: practitionerId,
        practitionerName: 'Dr. Ayurveda',
        hasSpecialInstructions: false,
      ),
      TherapySessionModel(
        id: 'session4',
        patientId: 'patient4',
        patientName: 'Emily Davis',
        therapyType: 'Pinda Sweda',
        dateTime: DateTime(
          today.year,
          today.month,
          today.day,
          14,
          30,
        ), // 2:30 PM
        durationMinutes: 90,
        roomNumber: '104',
        bedNumber: '3',
        status: SessionStatus.pending,
        notes: 'First time therapy, explain procedure in detail',
        practitionerId: practitionerId,
        practitionerName: 'Dr. Ayurveda',
        hasSpecialInstructions: true,
        specialInstructions: [
          'Check for oil allergies',
          'Use medium temperature',
        ],
      ),
      TherapySessionModel(
        id: 'session5',
        patientId: 'patient5',
        patientName: 'Michael Wilson',
        therapyType: 'Navara Kizhi',
        dateTime: DateTime(
          today.year,
          today.month,
          today.day,
          16,
          0,
        ), // 4:00 PM
        durationMinutes: 75,
        roomNumber: '101',
        bedNumber: '2',
        status: SessionStatus.pending,
        practitionerId: practitionerId,
        practitionerName: 'Dr. Ayurveda',
      ),
    ];
  }
}
