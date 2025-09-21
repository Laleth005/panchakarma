import '../models/therapy_progress_model.dart';

class DummyTherapyProgressData {
  static List<TherapyProgressModel> getTherapyProgressData() {
    return [
      TherapyProgressModel(
        id: '1',
        patientId: 'p1',
        patientName: 'Rajesh Kumar',
        therapyName: 'Abhyanga',
        status: TherapyStatus.inProgress,
        totalSessions: 7,
        completedSessions: 4,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        progressPercentage: 57.1,
        profileImageUrl:
            'https://xsgames.co/randomusers/assets/avatars/male/46.jpg',
      ),
      TherapyProgressModel(
        id: '2',
        patientId: 'p2',
        patientName: 'Sunita Sharma',
        therapyName: 'Shirodhara',
        status: TherapyStatus.inProgress,
        totalSessions: 5,
        completedSessions: 3,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        progressPercentage: 60.0,
        profileImageUrl:
            'https://xsgames.co/randomusers/assets/avatars/female/31.jpg',
      ),
      TherapyProgressModel(
        id: '3',
        patientId: 'p3',
        patientName: 'Anand Patel',
        therapyName: 'Swedana',
        status: TherapyStatus.completed,
        totalSessions: 3,
        completedSessions: 3,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().subtract(const Duration(days: 2)),
        progressPercentage: 100.0,
        profileImageUrl:
            'https://xsgames.co/randomusers/assets/avatars/male/22.jpg',
      ),
      TherapyProgressModel(
        id: '4',
        patientId: 'p4',
        patientName: 'Meera Nair',
        therapyName: 'Nasya',
        status: TherapyStatus.notStarted,
        totalSessions: 4,
        completedSessions: 0,
        startDate: DateTime.now().add(const Duration(days: 2)),
        progressPercentage: 0.0,
        profileImageUrl:
            'https://xsgames.co/randomusers/assets/avatars/female/45.jpg',
      ),
      TherapyProgressModel(
        id: '5',
        patientId: 'p5',
        patientName: 'Vikram Singh',
        therapyName: 'Basti',
        status: TherapyStatus.inProgress,
        totalSessions: 8,
        completedSessions: 2,
        startDate: DateTime.now().subtract(const Duration(days: 4)),
        progressPercentage: 25.0,
        notes: 'Patient reported feeling better after second session',
        profileImageUrl:
            'https://xsgames.co/randomusers/assets/avatars/male/67.jpg',
      ),
    ];
  }
}
