import 'user_model.dart';

class PatientModel extends UserModel {
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? medicalHistory;
  final String? allergies;
  final String? doshaType; // Vata, Pitta, Kapha, or combination
  final String? primaryPractitionerId;
  
  PatientModel({
    required super.uid,
    required super.email,
    required super.fullName,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.medicalHistory,
    this.allergies,
    this.doshaType,
    this.primaryPractitionerId,
    super.phoneNumber,
    super.profileImageUrl,
    required super.createdAt,
    required super.updatedAt,
  }) : super(role: UserRole.patient);
  
  factory PatientModel.fromJson(Map<String, dynamic> json) {
    final userModel = UserModel.fromJson(json);
    return PatientModel(
      uid: userModel.uid,
      email: userModel.email,
      fullName: userModel.fullName,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      medicalHistory: json['medicalHistory'] as String?,
      allergies: json['allergies'] as String?,
      doshaType: json['doshaType'] as String?,
      primaryPractitionerId: json['primaryPractitionerId'] as String?,
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
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'doshaType': doshaType,
      'primaryPractitionerId': primaryPractitionerId,
    });
    return json;
  }
}