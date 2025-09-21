import 'user_model.dart';

class AdminModel extends UserModel {
  final String clinicName;
  final String clinicAddress;
  final String? clinicLogo;

  AdminModel({
    required super.uid,
    required super.email,
    required super.fullName,
    required this.clinicName,
    required this.clinicAddress,
    this.clinicLogo,
    super.phoneNumber,
    super.profileImageUrl,
    required super.createdAt,
    required super.updatedAt,
  }) : super(role: UserRole.admin);

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    final userModel = UserModel.fromJson(json);
    return AdminModel(
      uid: userModel.uid,
      email: userModel.email,
      fullName: userModel.fullName,
      clinicName: json['clinicName'] as String,
      clinicAddress: json['clinicAddress'] as String,
      clinicLogo: json['clinicLogo'] as String?,
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
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'clinicLogo': clinicLogo,
    });
    return json;
  }
}
