import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/practitioner_model.dart';
import 'practitioner_edit_profile_screen.dart';
import '../auth/login_screen_new.dart';

class PractitionerProfileScreen extends StatefulWidget {
  final String? practitionerId;

  const PractitionerProfileScreen({Key? key, this.practitionerId})
    : super(key: key);

  @override
  _PractitionerProfileScreenState createState() =>
      _PractitionerProfileScreenState();
}

class _PractitionerProfileScreenState extends State<PractitionerProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  PractitionerModel? _practitionerData;

  @override
  void initState() {
    super.initState();
    // Delay to avoid context issues
    Future.microtask(() => _loadPractitionerProfile());
  }

  // Helper method to get the current user ID from Firebase Auth or fallback
  Future<String?> _getCurrentUserId() async {
    try {
      // First priority: Use the practitionerId passed to this widget
      if (widget.practitionerId != null && widget.practitionerId!.isNotEmpty) {
        print('Using provided practitioner ID: ${widget.practitionerId}');
        return widget.practitionerId;
      }

      // Second priority: try to get from Firebase Auth
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        print('Found current user from Firebase Auth: ${firebaseUser.uid}');
        return firebaseUser.uid;
      }

      // Third priority: try to find in practitioners collection
      // Look for the most recently active practitioner (from recent login)
      print(
        'No Firebase Auth user found, searching in practitioners collection',
      );

      // Try to find a practitioner with a recent login or activity
      final QuerySnapshot querySnapshot = await _firestore
          .collection('practitioners')
          .where('role', isEqualTo: 'practitioner')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final String userId = querySnapshot.docs.first.id;
        print('Found practitioner ID from recent activity: $userId');
        return userId;
      }

      // As a final fallback, try to find any practitioner that exists
      final QuerySnapshot allPractitioners = await _firestore
          .collection('practitioners')
          .limit(1)
          .get();

      if (allPractitioners.docs.isNotEmpty) {
        final String userId = allPractitioners.docs.first.id;
        print('Found any practitioner ID as fallback: $userId');
        return userId;
      }

      print('No practitioner found in database');
      return null;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  Future<void> _loadPractitionerProfile() async {
    try {
      print('Starting to load practitioner profile');
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Get current user ID
      String? userId = await _getCurrentUserId();

      if (userId == null) {
        print('No current user found');
        print('Widget practitionerId: ${widget.practitionerId}');
        print('Firebase Auth current user: ${_auth.currentUser?.uid}');

        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              'Authentication error: Unable to determine practitioner ID. Please log out and log in again.';
        });
        return;
      }

      print('Current user ID: $userId');

      // Get practitioner data
      final practitionerDoc = await _firestore
          .collection('practitioners')
          .doc(userId)
          .get();
      print('Document exists: ${practitionerDoc.exists}');

      if (practitionerDoc.exists) {
        Map<String, dynamic> data =
            practitionerDoc.data() as Map<String, dynamic>;
        print('Retrieved data: $data');

        try {
          // Include uid in the data map before passing to fromJson
          data['uid'] = userId;

          // Make sure all required fields are present
          final requiredFields = [
            'email',
            'fullName',
            'role',
            'createdAt',
            'updatedAt',
            'specialties',
          ];
          bool missingFields = false;
          String missingFieldsList = '';

          for (String field in requiredFields) {
            if (!data.containsKey(field)) {
              missingFields = true;
              missingFieldsList += '$field, ';
            }
          }

          if (missingFields) {
            print('Missing required fields: $missingFieldsList');
            // Add default values for missing fields
            if (!data.containsKey('email'))
              data['email'] = 'practitioner@example.com';
            if (!data.containsKey('fullName')) data['fullName'] = 'Doctor';
            if (!data.containsKey('role')) data['role'] = 'practitioner';
            if (!data.containsKey('specialties')) data['specialties'] = [];
            if (!data.containsKey('createdAt')) {
              data['createdAt'] = Timestamp.now();
            }
            if (!data.containsKey('updatedAt')) {
              data['updatedAt'] = Timestamp.now();
            }
          }

          _practitionerData = PractitionerModel.fromJson(data);
          print(
            'Successfully created practitioner model: ${_practitionerData!.fullName}',
          );

          setState(() {
            _isLoading = false;
          });
        } catch (parseError) {
          print('Error parsing practitioner data: $parseError');
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage =
                'Error parsing profile data. Please contact support.';
          });
        }
      } else {
        print('Practitioner document does not exist');
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Practitioner profile not found';
        });
      }
    } catch (e) {
      print('Error loading practitioner profile: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load profile. Please try again.';
      });
    }
  }

  // Sign out function
  Future<void> _signOut() async {
    try {
      // Show confirmation dialog
      bool? shouldSignOut = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Sign Out'),
            content: Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text('Sign Out'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (shouldSignOut == true) {
        // Sign out from Firebase Auth
        await _auth.signOut();

        // Navigate to login screen and clear all routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error signing out: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF2E7D32), // Green theme
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: _practitionerData == null
                ? null
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PractitionerEditProfileScreen(
                          practitioner: _practitionerData!,
                        ),
                      ),
                    );

                    // If profile was updated, reload the profile data
                    if (result == true) {
                      _loadPractitionerProfile();
                    }
                  },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2E7D32)),
            SizedBox(height: 16),
            Text('Loading profile...'),
          ],
        ),
      );
    } else if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _loadPractitionerProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                  child: Text('Try Again'),
                ),
                SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () {
                    // Navigate back to login screen
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF2E7D32),
                  ),
                  child: Text('Log Out'),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_practitionerData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 50, color: Colors.grey),
            SizedBox(height: 16),
            Text('Profile not available'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPractitionerProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
              ),
              child: Text('Try Again'),
            ),
          ],
        ),
      );
    } else {
      return _buildProfileContent();
    }
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          SizedBox(height: 20),
          _buildProfileDetails(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_practitionerData == null) {
      return Center(
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: Icon(Icons.person, size: 60, color: Colors.grey[800]),
            ),
            SizedBox(height: 16),
            Text(
              'Dr.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              image: _practitionerData!.profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_practitionerData!.profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _practitionerData!.profileImageUrl == null
                ? Icon(Icons.person, size: 60, color: Colors.grey[800])
                : null,
          ),
          SizedBox(height: 16),
          Text(
            'Dr. ${_practitionerData!.fullName}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            _practitionerData!.email,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    if (_practitionerData == null) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(child: Text('Profile data not available')),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem(
              'Phone',
              _practitionerData!.phoneNumber ?? 'Not provided',
            ),
            _buildDivider(),
            _buildDetailItem(
              'Specialties',
              _practitionerData!.specialties != null &&
                      _practitionerData!.specialties!.isNotEmpty
                  ? _practitionerData!.specialties!.join(', ')
                  : 'None specified',
            ),
            _buildDivider(),
            _buildDetailItem(
              'Qualification',
              _practitionerData!.qualification ?? 'Not specified',
            ),
            _buildDivider(),
            _buildDetailItem(
              'Experience',
              _practitionerData!.experience ?? 'Not specified',
            ),
            _buildDivider(),
            _buildDetailItem(
              'Bio',
              _practitionerData!.bio ?? 'No bio available',
            ),
            _buildDivider(),
            _buildDetailItem(
              'Account Created',
              _formatDate(_practitionerData!.createdAt),
            ),
            _buildDivider(),
            _buildDetailItem(
              'Last Updated',
              _formatDate(_practitionerData!.updatedAt),
            ),
            SizedBox(height: 24),

            // Sign out section
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: Icon(Icons.logout, color: Colors.white),
                label: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[300], thickness: 1);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';

    // Format the date nicely
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    String year = date.year.toString();
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
