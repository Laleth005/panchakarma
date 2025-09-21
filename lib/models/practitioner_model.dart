import 'package:cloud_firestore/cloud_firestore.dart';

class PractitionerModel {
  final String uid;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Professional Information
  final List<String>? specialties;
  final int? experienceYears;
  final String? licenseNumber;
  final List<String>? qualifications;
  final String? clinicAddress;
  final String? bio;

  // Added missing fields
  final String? experience;
  final String? qualification;

  // Contact & Availability
  final String? emergencyContact;
  final double? consultationFee;
  final String? availableHours;
  final List<String>? languages;

  // Additional fields that might be used
  final String? clinicName;
  final String? websiteUrl;
  final bool? isVerified;
  final Map<String, dynamic>? socialLinks;

  PractitionerModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.profileImageUrl,
    this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
    this.specialties,
    this.experienceYears,
    this.licenseNumber,
    this.qualifications,
    this.clinicAddress,
    this.bio,
    this.emergencyContact,
    this.consultationFee,
    this.availableHours,
    this.languages,
    this.clinicName,
    this.websiteUrl,
    this.isVerified,
    this.socialLinks,
    this.experience,
    this.qualification,
  });

  factory PractitionerModel.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to safely parse DateTime
      DateTime? parseDateTime(dynamic value) {
        if (value == null) return null;
        if (value is Timestamp) return value.toDate();
        if (value is DateTime) return value;
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            print('Error parsing date string: $value');
            return null;
          }
        }
        return null;
      }

      // Helper function to safely parse list of strings
      List<String>? parseStringList(dynamic value) {
        if (value == null) return null;
        if (value is List) {
          return value.map((item) => item.toString()).toList();
        }
        if (value is String) {
          // Handle comma-separated string
          return value
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
        return null;
      }

      // Helper function to safely parse double
      double? parseDouble(dynamic value) {
        if (value == null) return null;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          try {
            return double.parse(value);
          } catch (e) {
            return null;
          }
        }
        return null;
      }

      // Helper function to safely parse int
      int? parseInt(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) {
          try {
            return int.parse(value);
          } catch (e) {
            return null;
          }
        }
        return null;
      }

      return PractitionerModel(
        uid: json['uid'] as String? ?? '',
        email: json['email'] as String? ?? '',
        fullName:
            json['fullName'] as String? ??
            json['full_name'] as String? ??
            'Unknown Doctor',
        phoneNumber:
            json['phoneNumber'] as String? ?? json['phone_number'] as String?,
        profileImageUrl:
            json['profileImageUrl'] as String? ??
            json['profile_image_url'] as String?,
        dateOfBirth: parseDateTime(
          json['dateOfBirth'] ?? json['date_of_birth'],
        ),
        createdAt:
            parseDateTime(json['createdAt'] ?? json['created_at']) ??
            DateTime.now(),
        updatedAt:
            parseDateTime(json['updatedAt'] ?? json['updated_at']) ??
            DateTime.now(),

        // Professional Information
        specialties: parseStringList(
          json['specialization'] ?? json['specialty'] ?? json['specialties'],
        ),
        experienceYears: parseInt(
          json['experienceYears'] ?? json['experience_years'],
        ),
        licenseNumber:
            json['licenseNumber'] as String? ??
            json['license_number'] as String?,
        qualifications: parseStringList(json['qualifications']),
        clinicAddress:
            json['clinicAddress'] as String? ??
            json['clinic_address'] as String?,
        bio: json['bio'] as String? ?? json['description'] as String?,
        experience: json['experience'] as String?,
        qualification: json['qualification'] as String?,

        // Contact & Availability
        emergencyContact:
            json['emergencyContact'] as String? ??
            json['emergency_contact'] as String?,
        consultationFee: parseDouble(
          json['consultationFee'] ?? json['consultation_fee'],
        ),
        availableHours:
            json['availableHours'] as String? ??
            json['available_hours'] as String?,
        languages: parseStringList(json['languages']),

        // Additional fields
        clinicName:
            json['clinicName'] as String? ?? json['clinic_name'] as String?,
        websiteUrl:
            json['websiteUrl'] as String? ?? json['website_url'] as String?,
        isVerified:
            json['isVerified'] as bool? ??
            json['is_verified'] as bool? ??
            false,
        socialLinks:
            json['socialLinks'] as Map<String, dynamic>? ??
            json['social_links'] as Map<String, dynamic>?,
      );
    } catch (e) {
      print('Error in PractitionerModel.fromJson: $e');
      print('JSON data: $json');

      // Create a minimal valid practitioner model with default values
      return PractitionerModel(
        uid: json['uid'] as String? ?? 'unknown',
        email: json['email'] as String? ?? 'unknown@example.com',
        fullName:
            json['fullName'] as String? ??
            json['full_name'] as String? ??
            'Unknown Doctor',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        specialties: ['General Practice'],
        isVerified: false,
        experience: '5+ years',
        qualification: 'BAMS',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),

      // Professional Information
      'specialties': specialties,
      'experienceYears': experienceYears,
      'licenseNumber': licenseNumber,
      'qualifications': qualifications,
      'clinicAddress': clinicAddress,
      'bio': bio,
      'experience': experience,
      'qualification': qualification,

      // Contact & Availability
      'emergencyContact': emergencyContact,
      'consultationFee': consultationFee,
      'availableHours': availableHours,
      'languages': languages,

      // Additional fields
      'clinicName': clinicName,
      'websiteUrl': websiteUrl,
      'isVerified': isVerified,
      'socialLinks': socialLinks,
    };
  }

  // Helper method to get display name with title
  String get displayName => 'Dr. $fullName';

  // Helper method to get formatted experience
  String get formattedExperience {
    if (experienceYears == null) return 'N/A';
    return '$experienceYears year${experienceYears! > 1 ? 's' : ''} experience';
  }

  // Helper method to get formatted consultation fee
  String get formattedConsultationFee {
    if (consultationFee == null) return 'N/A';
    return '₹${consultationFee!.toStringAsFixed(0)}';
  }

  // Helper method to check if profile is complete
  bool get isProfileComplete {
    return fullName.isNotEmpty &&
        email.isNotEmpty &&
        phoneNumber != null &&
        specialties != null &&
        licenseNumber != null;
  }

  // Helper method to get qualification string
  String get qualificationString {
    if (qualifications == null || qualifications!.isEmpty) return 'N/A';
    return qualifications!.join(', ');
  }

  // Helper method to get language string
  String get languageString {
    if (languages == null || languages!.isEmpty) return 'N/A';
    return languages!.join(', ');
  }

  // Helper method to format date of birth
  String get formattedDateOfBirth {
    if (dateOfBirth == null) return 'N/A';
    return '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}';
  }

  // Copy with method for updating the model
  PractitionerModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? specialization,
    int? experienceYears,
    String? licenseNumber,
    List<String>? qualifications,
    String? clinicAddress,
    String? bio,
    String? emergencyContact,
    double? consultationFee,
    String? availableHours,
    List<String>? languages,
    String? clinicName,
    String? websiteUrl,
    bool? isVerified,
    Map<String, dynamic>? socialLinks,
  }) {
    return PractitionerModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      specialties: specialties ?? this.specialties,
      experienceYears: experienceYears ?? this.experienceYears,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      qualifications: qualifications ?? this.qualifications,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      bio: bio ?? this.bio,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      consultationFee: consultationFee ?? this.consultationFee,
      availableHours: availableHours ?? this.availableHours,
      languages: languages ?? this.languages,
      clinicName: clinicName ?? this.clinicName,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      isVerified: isVerified ?? this.isVerified,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }

  @override
  String toString() {
    return 'PractitionerModel{uid: $uid, fullName: $fullName, email: $email, specialization: $specialties}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PractitionerModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
