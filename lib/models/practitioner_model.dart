import 'user_model.dart';

class PractitionerModel extends UserModel {
  final List<String> specialties;
  final String? qualification;
  final String? experience;
  final String? bio;
  
  PractitionerModel({
    required super.uid,
    required super.email,
    required super.fullName,
    required this.specialties,
    this.qualification,
    this.experience,
    this.bio,
    super.phoneNumber,
    super.profileImageUrl,
    required super.createdAt,
    required super.updatedAt,
  }) : super(role: UserRole.practitioner);
  
  factory PractitionerModel.fromJson(Map<String, dynamic> json) {
    try {
      final userModel = UserModel.fromJson(json);
      
      // Handle specialties more safely
      List<String> specialties = [];
      if (json['specialties'] != null) {
        if (json['specialties'] is List) {
          specialties = List<String>.from(
            (json['specialties'] as List).map((item) => item.toString())
          );
        }
      }
      
      return PractitionerModel(
        uid: userModel.uid,
        email: userModel.email,
        fullName: userModel.fullName,
        specialties: specialties,
        qualification: json['qualification'] as String?,
        experience: json['experience'] as String?,
        bio: json['bio'] as String?,
        phoneNumber: userModel.phoneNumber,
        profileImageUrl: userModel.profileImageUrl,
        createdAt: userModel.createdAt,
        updatedAt: userModel.updatedAt,
      );
    } catch (e) {
      print('Error in PractitionerModel.fromJson: $e');
      print('JSON data: $json');
      
      // Create a minimal valid practitioner model with default values
      return PractitionerModel(
        uid: json['uid'] as String? ?? 'unknown',
        email: json['email'] as String? ?? 'unknown@example.com',
        fullName: json['fullName'] as String? ?? 'Unknown Doctor',
        specialties: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
  
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'specialties': specialties,
      'qualification': qualification,
      'experience': experience,
      'bio': bio,
    });
    return json;
  }
}