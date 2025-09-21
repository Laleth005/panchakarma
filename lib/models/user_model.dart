import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, practitioner, patient }

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? isApproved;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isApproved,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.patient,
      ),
      phoneNumber: json['phoneNumber'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: (json['createdAt'] != null)
          ? (json['createdAt'] is Timestamp
                ? (json['createdAt'] as Timestamp).toDate()
                : DateTime.parse(json['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: (json['updatedAt'] != null)
          ? (json['updatedAt'] is Timestamp
                ? (json['updatedAt'] as Timestamp).toDate()
                : DateTime.parse(json['updatedAt'].toString()))
          : DateTime.now(),
      isApproved: json['isApproved'] as bool?,
    );
  }

  // Add fromFirestore method for Firestore document data
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String? ?? '',
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      role: _parseRole(data['role']),
      phoneNumber: data['phoneNumber'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
      isApproved: data['isApproved'] as bool?,
    );
  }

  static UserRole _parseRole(dynamic roleData) {
    if (roleData == null) return UserRole.patient;

    final String roleStr = roleData.toString().toLowerCase();
    if (roleStr.contains('admin')) return UserRole.admin;
    if (roleStr.contains('practitioner')) return UserRole.practitioner;
    return UserRole.patient;
  }

  static DateTime? _parseDateTime(dynamic dateData) {
    if (dateData == null) return null;
    if (dateData is Timestamp) return dateData.toDate();
    if (dateData is DateTime) return dateData;
    try {
      return DateTime.parse(dateData.toString());
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role.toString().split('.').last,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isApproved': isApproved,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    UserRole? role,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isApproved,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
