import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/patient_model.dart';
import '../auth/login_screen_new.dart';

class ProfilePage extends StatefulWidget {
  final String? patientId;

  const ProfilePage({Key? key, this.patientId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  PatientModel? _patientData;
  bool _isLoading = true;
  Map<String, dynamic>? _doshaInfo;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    try {
      print("ProfilePage: Loading patient data");

      // Priority 1: Use provided patientId from widget
      if (widget.patientId != null) {
        print("ProfilePage: Using provided patientId: ${widget.patientId}");

        try {
          final patientDoc = await FirebaseFirestore.instance
              .collection('patients')
              .doc(widget.patientId)
              .get();

          if (patientDoc.exists) {
            print("ProfilePage: Found patient doc using patientId");
            final data = patientDoc.data()!;
            data['uid'] = widget.patientId;

            // Ensure role is in the data
            if (!data.containsKey('role')) {
              data['role'] = 'patient';
            }

            // Create patient model with safe handling of timestamps
            DateTime createdAt = DateTime.now();
            DateTime updatedAt = DateTime.now();

            if (data.containsKey('createdAt') && data['createdAt'] != null) {
              if (data['createdAt'] is Timestamp) {
                createdAt = (data['createdAt'] as Timestamp).toDate();
              }
            }

            if (data.containsKey('updatedAt') && data['updatedAt'] != null) {
              if (data['updatedAt'] is Timestamp) {
                updatedAt = (data['updatedAt'] as Timestamp).toDate();
              }
            }

            final patient = PatientModel(
              uid: widget.patientId!,
              email: data['email'] as String? ?? '',
              fullName: data['fullName'] as String? ?? 'Patient',
              createdAt: createdAt,
              updatedAt: updatedAt,
              // Optional fields
              dateOfBirth: data['dateOfBirth'] as String?,
              gender: data['gender'] as String?,
              address: data['address'] as String?,
              phoneNumber: data['phoneNumber'] as String?,
              medicalHistory: data['medicalHistory'] as String?,
              allergies: data['allergies'] as String?,
              doshaType: data['doshaType'] as String?,
              profileImageUrl: data['profileImageUrl'] as String?,
              primaryPractitionerId: data['primaryPractitionerId'] as String?,
            );

            setState(() {
              _patientData = patient;
            });

            if (data['doshaType'] != null) {
              await _getDoshaInfo(data['doshaType'] as String);
            }

            return; // Successfully loaded patient data, exit early
          }
        } catch (e) {
          print("ProfilePage: Error loading patient with provided ID: $e");
          // Continue to next approach
        }
      }

      // Priority 2: Try using AuthService
      final userData = await _authService.getCurrentUserData();

      if (userData is PatientModel) {
        print(
          "ProfilePage: Got patient data from AuthService - ${userData.fullName}",
        );
        setState(() {
          _patientData = userData;
        });

        // Get dosha information if available
        if (userData.doshaType != null) {
          await _getDoshaInfo(userData.doshaType!);
        }

        return; // Successfully loaded patient data, exit early
      }

      print("ProfilePage: User data is not a PatientModel - $userData");

      // Priority 3: Try getting current user from Firebase Auth
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        print(
          "ProfilePage: Firebase Auth has current user: ${firebaseUser.uid}",
        );

        // Try to get patient data directly from Firestore
        try {
          final patientDoc = await FirebaseFirestore.instance
              .collection('patients')
              .doc(firebaseUser.uid)
              .get();

          if (patientDoc.exists) {
            print("ProfilePage: Found patient doc in Firestore");
            final data = patientDoc.data()!;
            data['uid'] = firebaseUser.uid;

            // Ensure role is in the data
            if (!data.containsKey('role')) {
              data['role'] = 'patient';
            }

            // Create patient model with safe handling of timestamps
            DateTime createdAt = DateTime.now();
            DateTime updatedAt = DateTime.now();

            if (data.containsKey('createdAt') && data['createdAt'] != null) {
              if (data['createdAt'] is Timestamp) {
                createdAt = (data['createdAt'] as Timestamp).toDate();
              }
            }

            if (data.containsKey('updatedAt') && data['updatedAt'] != null) {
              if (data['updatedAt'] is Timestamp) {
                updatedAt = (data['updatedAt'] as Timestamp).toDate();
              }
            }

            final patient = PatientModel(
              uid: firebaseUser.uid,
              email: data['email'] as String? ?? firebaseUser.email ?? '',
              fullName: data['fullName'] as String? ?? 'Patient',
              createdAt: createdAt,
              updatedAt: updatedAt,
              // Optional fields
              dateOfBirth: data['dateOfBirth'] as String?,
              gender: data['gender'] as String?,
              address: data['address'] as String?,
              phoneNumber: data['phoneNumber'] as String?,
              medicalHistory: data['medicalHistory'] as String?,
              allergies: data['allergies'] as String?,
              doshaType: data['doshaType'] as String?,
              profileImageUrl: data['profileImageUrl'] as String?,
              primaryPractitionerId: data['primaryPractitionerId'] as String?,
            );

            setState(() {
              _patientData = patient;
            });

            if (data['doshaType'] != null) {
              await _getDoshaInfo(data['doshaType'] as String);
            }
          } else {
            print("ProfilePage: No patient doc found");

            // Create a basic placeholder patient
            setState(() {
              _patientData = PatientModel(
                uid: firebaseUser.uid,
                email: firebaseUser.email ?? '',
                fullName: firebaseUser.displayName ?? 'Patient',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            });
          }
        } catch (e) {
          print("ProfilePage: Error getting patient data from Firestore: $e");
        }
      } else {
        print("ProfilePage: No current user found");
      }
    } catch (e) {
      print('ProfilePage: Error loading patient data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getDoshaInfo(String doshaType) async {
    try {
      // In a real app, this would come from Firestore
      // For now, hardcoding some dosha information
      final Map<String, dynamic> doshaInfo = {
        'Vata': {
          'description':
              'Vata represents the elements of space and air. It governs movement and is responsible for basic body processes such as breathing, cell division, and circulation.',
          'characteristics': [
            'Thin, light frame',
            'Quick mind, creative',
            'Irregular appetite and digestion',
            'Dry skin',
            'Restless nature',
            'Cold hands and feet',
          ],
          'balancingPractices': [
            'Regular routine',
            'Warm, cooked foods',
            'Meditation and calming activities',
            'Regular oil massage',
            'Early bedtime',
          ],
        },
        'Pitta': {
          'description':
              'Pitta represents the elements of fire and water. It governs metabolism and transformation in the body and mind.',
          'characteristics': [
            'Medium build with good muscle development',
            'Sharp intellect, good concentration',
            'Strong digestion and appetite',
            'Sensitive to heat',
            'Tendency toward reddish skin or hair',
            'Natural leaders',
          ],
          'balancingPractices': [
            'Cool, refreshing foods',
            'Avoiding excessive heat and sun',
            'Regular exercise that\'s not too intense',
            'Cooling activities in nature',
            'Maintaining a relaxed attitude',
          ],
        },
        'Kapha': {
          'description':
              'Kapha represents the elements of earth and water. It provides structure and lubrication to the body and is responsible for strength and immunity.',
          'characteristics': [
            'Solid, strong build',
            'Calm, steady nature',
            'Slow digestion but regular appetite',
            'Smooth, oily skin',
            'Sound sleeper',
            'Loyal and supportive personality',
          ],
          'balancingPractices': [
            'Regular vigorous exercise',
            'Warm, light, and spicy foods',
            'Variation and stimulation in routine',
            'Dry massage',
            'Rising early',
          ],
        },
        'Vata-Pitta': {
          'description':
              'A combination of Vata and Pitta doshas, with characteristics of both air/space and fire elements.',
          'characteristics': [
            'Light to medium frame',
            'Quick, sharp intellect',
            'Variable digestion',
            'Combination of dry and warm tendencies',
            'Creative and analytical',
          ],
          'balancingPractices': [
            'Moderate routine with flexibility',
            'Warm but not spicy foods',
            'Moderate exercise',
            'Balance between creative and analytical activities',
            'Regular self-care',
          ],
        },
        'Pitta-Kapha': {
          'description':
              'A combination of Pitta and Kapha doshas, combining fire/water with earth/water elements.',
          'characteristics': [
            'Medium to solid build',
            'Strong intellect with steadiness',
            'Strong digestion',
            'Combination of oily and warm tendencies',
            'Determined and methodical',
          ],
          'balancingPractices': [
            'Regular but not too intense exercise',
            'Moderate diet avoiding too heavy or spicy foods',
            'Balance between rest and activity',
            'Cooling activities for Pitta, stimulating for Kapha',
            'Finding middle ground in self-care practices',
          ],
        },
        'Vata-Kapha': {
          'description':
              'A combination of Vata and Kapha doshas, combining air/space with earth/water elements.',
          'characteristics': [
            'Variable build - can be thin or solid',
            'Combination of quick thoughts and steady emotions',
            'Irregular digestion',
            'Mix of dry and oily tendencies',
            'Both restless and lethargic tendencies',
          ],
          'balancingPractices': [
            'Regular, moderate exercise',
            'Warm, easily digestible foods',
            'Stimulating yet grounding activities',
            'Finding balance between movement and stability',
            'Consistent routine with some variation',
          ],
        },
        'Tri-Dosha': {
          'description':
              'A relatively equal balance of all three doshas - Vata, Pitta, and Kapha.',
          'characteristics': [
            'Balanced physical build',
            'Adaptable mind and body',
            'Generally good digestion',
            'Balanced skin - neither too dry nor too oily',
            'Balanced energy and sleep patterns',
          ],
          'balancingPractices': [
            'Seasonal adjustments to routine and diet',
            'Moderate, regular exercise',
            'Balanced diet with seasonal variations',
            'Addressing specific imbalances as they arise',
            'Regular but flexible routine',
          ],
        },
      };

      setState(() {
        // Try to find an exact match
        if (doshaInfo.containsKey(doshaType)) {
          _doshaInfo = doshaInfo[doshaType];
        } else {
          // Default to Tri-Dosha if no match found
          _doshaInfo = doshaInfo['Tri-Dosha'];
        }
      });
    } catch (e) {
      print('Error getting dosha information: $e');
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit profile screen
            },
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            SizedBox(height: 24),
            _buildPersonalInfoCard(),
            SizedBox(height: 16),
            if (_doshaInfo != null) _buildDoshaInfoCard(),
            SizedBox(height: 16),
            _buildSettingsCard(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    // Guard against null patient data
    if (_patientData == null) {
      return Center(
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFF2E7D32).withOpacity(0.1),
              child: Text(
                "P",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Patient",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Color(0xFF2E7D32).withOpacity(0.1),
            child: _patientData?.profileImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.network(
                      _patientData!.profileImageUrl!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Text(
                        _patientData!.fullName.isNotEmpty
                            ? _patientData!.fullName
                                  .substring(0, 1)
                                  .toUpperCase()
                            : "P",
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  )
                : Text(
                    _patientData!.fullName.isNotEmpty
                        ? _patientData!.fullName.substring(0, 1).toUpperCase()
                        : "P",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
          ),
          SizedBox(height: 16),
          Text(
            _patientData?.fullName ?? "Patient",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            _patientData?.email ?? "No email available",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (_patientData?.doshaType != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Chip(
                label: Text(
                  'Dosha: ${_patientData!.doshaType}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Color(0xFF2E7D32),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    // Guard against null patient data
    if (_patientData == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(height: 16),
              Text('No patient information available'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow('Phone', _patientData?.phoneNumber ?? 'Not provided'),
            _buildInfoRow('Gender', _patientData?.gender ?? 'Not provided'),
            _buildInfoRow(
              'Date of Birth',
              _patientData?.dateOfBirth ?? 'Not provided',
            ),
            _buildInfoRow('Address', _patientData?.address ?? 'Not provided'),
          ],
        ),
      ),
    );
  }

  Widget _buildDoshaInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.spa, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'Your Dosha Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              _doshaInfo!['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Characteristics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            SizedBox(height: 8),
            ...(_doshaInfo!['characteristics'] as List)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            SizedBox(height: 16),
            Text(
              'Balancing Practices',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            SizedBox(height: 8),
            ...(_doshaInfo!['balancingPractices'] as List)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF2E7D32),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings & Privacy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            SizedBox(height: 16),
            _buildSettingsTile('Change Password', Icons.lock_outline, () {
              // Navigate to change password screen
            }),
            Divider(),
            _buildSettingsTile(
              'Notification Preferences',
              Icons.notifications_none,
              () {
                // Navigate to notification settings
              },
            ),
            Divider(),
            _buildSettingsTile(
              'Privacy Policy',
              Icons.privacy_tip_outlined,
              () {
                // Show privacy policy
              },
            ),
            Divider(),
            _buildSettingsTile(
              'Terms of Service',
              Icons.description_outlined,
              () {
                // Show terms of service
              },
            ),
            Divider(),
            _buildSettingsTile('Delete Account', Icons.delete_outline, () {
              // Show delete account confirmation
            }, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.grey[700], size: 20),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: color ?? Colors.grey[800]),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }
}
