import '../models/notification_model.dart';

// This class provides dummy data for testing the Notifications panel
class DummyNotificationData {
  // Generate dummy notifications for a practitioner
  static List<NotificationModel> getNotifications(String practitionerId) {
    final now = DateTime.now();

    return [
      NotificationModel(
        id: 'notif1',
        title: 'Next Session in 15 Minutes',
        message:
            'You have an Abhyanga therapy session with John Smith at 2:00 PM in Room 101.',
        timestamp: now.subtract(const Duration(minutes: 15)),
        type: NotificationType.sessionReminder,
        isRead: false,
        practitionerId: practitionerId,
        patientId: 'patient1',
        patientName: 'John Smith',
        sessionId: 'session1',
      ),
      NotificationModel(
        id: 'notif2',
        title: 'Post-Procedure Instructions',
        message:
            'Remember to advise patient Sarah Johnson to drink warm water and avoid cold foods after Shirodhara therapy.',
        timestamp: now.subtract(const Duration(hours: 1)),
        type: NotificationType.procedurePrecaution,
        isRead: true,
        practitionerId: practitionerId,
        patientId: 'patient2',
        patientName: 'Sarah Johnson',
      ),
      NotificationModel(
        id: 'notif3',
        title: 'Patient Reported Side Effect',
        message:
            'Robert Brown has reported mild headache after Swedana therapy session yesterday.',
        timestamp: now.subtract(const Duration(hours: 3)),
        type: NotificationType.patientAlert,
        isRead: false,
        practitionerId: practitionerId,
        patientId: 'patient3',
        patientName: 'Robert Brown',
      ),
      NotificationModel(
        id: 'notif4',
        title: 'Pre-Therapy Note',
        message:
            'Emily Davis is scheduled for her first Pinda Sweda therapy. Check for allergies before session.',
        timestamp: now.subtract(const Duration(hours: 5)),
        type: NotificationType.procedurePrecaution,
        isRead: false,
        practitionerId: practitionerId,
        patientId: 'patient4',
        patientName: 'Emily Davis',
      ),
      NotificationModel(
        id: 'notif5',
        title: 'Staff Meeting Reminder',
        message:
            'Weekly practitioner meeting scheduled for tomorrow at 9:00 AM in the conference room.',
        timestamp: now.subtract(const Duration(days: 1)),
        type: NotificationType.general,
        isRead: true,
        practitionerId: practitionerId,
      ),
    ];
  }
}
