import 'user_model.dart';

class PractitionerModel extends UserModel {
  final List<String> specialties;
  final String? qualification;
  final String? experience;
  final String? bio;
  final bool isApproved;
  
  PractitionerModel({
    required super.uid,
    required super.email,
    required super.fullName,
    required this.specialties,
    this.qualification,
    this.experience,
    this.bio,
    this.isApproved = false,
    super.phoneNumber,
    super.profileImageUrl,
    required super.createdAt,
    required super.updatedAt,
  }) : super(role: UserRole.practitioner);
  
  factory PractitionerModel.fromJson(Map<String, dynamic> json) {
    final userModel = UserModel.fromJson(json);
    return PractitionerModel(
      uid: userModel.uid,
      email: userModel.email,
      fullName: userModel.fullName,
      specialties: List<String>.from(json['specialties'] ?? []),
      qualification: json['qualification'] as String?,
      experience: json['experience'] as String?,
      bio: json['bio'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      phoneNumber: userModel.phoneNumber,
      profileImageUrl: userModel.profileImageUrl,
      createdAt: userModel.createdAt,
      updatedAt: userModel.updatedAt,
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'specialties': specialties,
      'qualification': qualification,
      'experience': experience,
      'bio': bio,
      'isApproved': isApproved,
    });
    return json;
  }
}