import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/therapy_session_model.dart';
import '../models/patient_feedback_model.dart';
import '../models/task_reminder_model.dart';
import '../utils/dummy_session_data.dart';

class PractitionerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch today's therapy sessions for a practitioner
  Future<List<TherapySessionModel>> getTodaySessions(
    String practitionerId,
  ) async {
    try {
      // Comment out the Firestore implementation for now and use dummy data
      /*
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('therapy_sessions')
          .where('practitionerId', isEqualTo: practitionerId)
          .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
          .where('dateTime', isLessThanOrEqualTo: endOfDay)
          .orderBy('dateTime')
          .get();
      
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return TherapySessionModel.fromJson(data);
          })
          .toList();
      */

      // Use dummy data for testing purposes
      return DummySessionData.getTodaySessions(practitionerId);
    } catch (e) {
      debugPrint('Error fetching today\'s sessions: $e');
      return [];
    }
  }

  // Update a therapy session status
  Future<bool> updateSessionStatus(
    String sessionId,
    SessionStatus newStatus,
  ) async {
    try {
      await _firestore.collection('therapy_sessions').doc(sessionId).update({
        'status': newStatus.toString().split('.').last,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating session status: $e');
      return false;
    }
  }

  // Get pending feedback for a practitioner
  Future<List<PatientFeedbackModel>> getPendingFeedback(
    String practitionerId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('patient_feedback')
          .where('isAcknowledged', isEqualTo: false)
          .where('practitionerId', isEqualTo: practitionerId)
          .orderBy('dateTime', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PatientFeedbackModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching pending feedback: $e');
      return [];
    }
  }

  // Acknowledge patient feedback
  Future<bool> acknowledgeFeedback(String feedbackId, String? response) async {
    try {
      final data = {
        'isAcknowledged': true,
        'respondedAt': FieldValue.serverTimestamp(),
      };

      if (response != null && response.isNotEmpty) {
        data['practitionerResponse'] = response;
      }

      await _firestore
          .collection('patient_feedback')
          .doc(feedbackId)
          .update(data);
      return true;
    } catch (e) {
      debugPrint('Error acknowledging feedback: $e');
      return false;
    }
  }

  // Get practitioner's task reminders
  Future<List<TaskReminderModel>> getTaskReminders(
    String practitionerId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('task_reminders')
          .where('practitionerId', isEqualTo: practitionerId)
          .orderBy('dueDate')
          .orderBy('priority', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        // Convert priority string to enum
        final priorityStr = data['priority'] as String;
        final priority = Priority.values.firstWhere(
          (e) => e.toString().split('.').last == priorityStr,
          orElse: () => Priority.medium,
        );

        return TaskReminderModel(
          id: data['id'],
          title: data['title'],
          description: data['description'],
          isCompleted: data['isCompleted'] ?? false,
          dueDate: (data['dueDate'] as Timestamp).toDate(),
          patientId: data['patientId'],
          patientName: data['patientName'],
          priority: priority,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching task reminders: $e');
      return [];
    }
  }

  // Add a new task reminder
  Future<bool> addTaskReminder(
    TaskReminderModel task,
    String practitionerId,
  ) async {
    try {
      await _firestore.collection('task_reminders').add({
        'title': task.title,
        'description': task.description,
        'isCompleted': task.isCompleted,
        'dueDate': Timestamp.fromDate(task.dueDate),
        'patientId': task.patientId,
        'patientName': task.patientName,
        'priority': task.priority.toString().split('.').last,
        'practitionerId': practitionerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding task reminder: $e');
      return false;
    }
  }

  // Update task reminder completion status
  Future<bool> updateTaskStatus(String taskId, bool isCompleted) async {
    try {
      await _firestore.collection('task_reminders').doc(taskId).update({
        'isCompleted': isCompleted,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating task status: $e');
      return false;
    }
  }

  // Get analytics data
  Future<Map<String, dynamic>> getPractitionerAnalytics(
    String practitionerId,
  ) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    try {
      // Today's completed sessions
      final todaySessionsSnapshot = await _firestore
          .collection('therapy_sessions')
          .where('practitionerId', isEqualTo: practitionerId)
          .where('dateTime', isGreaterThanOrEqualTo: startOfToday)
          .where(
            'status',
            isEqualTo: SessionStatus.completed.toString().split('.').last,
          )
          .get();

      // Weekly completed sessions
      final weeklySessionsSnapshot = await _firestore
          .collection('therapy_sessions')
          .where('practitionerId', isEqualTo: practitionerId)
          .where('dateTime', isGreaterThanOrEqualTo: startOfWeek)
          .where(
            'status',
            isEqualTo: SessionStatus.completed.toString().split('.').last,
          )
          .get();

      // Recent feedback for satisfaction rate calculation
      final recentFeedbackSnapshot = await _firestore
          .collection('patient_feedback')
          .where('practitionerId', isEqualTo: practitionerId)
          .orderBy('dateTime', descending: true)
          .limit(50)
          .get();

      double averageRating = 0;
      if (recentFeedbackSnapshot.docs.isNotEmpty) {
        int totalRating = recentFeedbackSnapshot.docs
            .map((doc) => doc.data()['rating'] as int)
            .reduce((a, b) => a + b);
        averageRating = totalRating / recentFeedbackSnapshot.docs.length;
      }

      // Completion rate
      final allRecentSessionsSnapshot = await _firestore
          .collection('therapy_sessions')
          .where('practitionerId', isEqualTo: practitionerId)
          .where('dateTime', isGreaterThanOrEqualTo: startOfWeek)
          .get();

      int totalSessions = allRecentSessionsSnapshot.docs.length;
      int completedSessions = weeklySessionsSnapshot.docs.length;
      double completionRate = totalSessions > 0
          ? (completedSessions / totalSessions) * 100
          : 0;

      return {
        'patientsToday': todaySessionsSnapshot.docs.length,
        'patientsWeek': weeklySessionsSnapshot.docs.length,
        'satisfactionScore': averageRating,
        'completionRate': completionRate,
      };
    } catch (e) {
      debugPrint('Error fetching practitioner analytics: $e');
      return {
        'patientsToday': 0,
        'patientsWeek': 0,
        'satisfactionScore': 0,
        'completionRate': 0,
      };
    }
  }
}
