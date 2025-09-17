import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/practitioner_model.dart';
import 'practitioner_edit_profile_screen.dart';

class PractitionerProfileScreen extends StatefulWidget {
  const PractitionerProfileScreen({Key? key}) : super(key: key);

  @override
  _PractitionerProfileScreenState createState() => _PractitionerProfileScreenState();
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

  // Helper method to get the current user ID from shared preferences
  Future<String?> _getUserIdFromLocalStorage() async {
    // In a real app, you would use SharedPreferences to get the stored user ID
    // For now, we'll check if there's a user in Firestore with the email we logged in with
    try {
      // This is a temporary solution for testing
      // You would normally use SharedPreferences.getInstance()
      // and then prefs.getString('userId')
      
      // Since we don't have access to the login info here,
      // we'll try to find the user by their email in the practitioners collection
      final QuerySnapshot querySnapshot = await _firestore
          .collection('practitioners')
          .where('email', isEqualTo: 'rockey1533@gmail.com') // Hardcoded for testing
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final String userId = querySnapshot.docs.first.id;
        print('Found practitioner ID from query: $userId');
        return userId;
      }
      return null;
    } catch (e) {
      print('Error getting user ID from local storage: $e');
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
      
      // Get current user ID - check if we're using Firebase Auth or direct login
      String? userId;
      User? user;
      
      // Try to get the current user from Firebase Auth first
      user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
        print('Current user ID from Firebase Auth: $userId');
      } else {
        // If Firebase Auth doesn't have a current user, try to get it from local storage
        userId = await _getUserIdFromLocalStorage();
        if (userId == null) {
          print('No current user found in Firebase Auth or local storage');
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Not logged in. Please login again.';
          });
          return;
        }
        print('Current user ID from local storage: $userId');
      }
      
      // Get practitioner data
      final practitionerDoc = await _firestore.collection('practitioners').doc(userId).get();
      print('Document exists: ${practitionerDoc.exists}');
      
      if (practitionerDoc.exists) {
        Map<String, dynamic> data = practitionerDoc.data() as Map<String, dynamic>;
        print('Retrieved data: $data');
        
        try {
          // Include uid in the data map before passing to fromJson
          data['uid'] = userId; // Use the userId we confirmed earlier
          
          // Make sure all required fields are present
          final requiredFields = ['email', 'fullName', 'role', 'createdAt', 'updatedAt', 'specialties'];
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
            if (!data.containsKey('email')) data['email'] = user?.email ?? 'practitioner@example.com';
            if (!data.containsKey('fullName')) data['fullName'] = 'Doctor';
            if (!data.containsKey('role')) data['role'] = 'practitioner';
            if (!data.containsKey('specialties')) data['specialties'] = [];
            if (!data.containsKey('createdAt')) {
              // Convert server timestamp to DateTime
              data['createdAt'] = Timestamp.now();
            }
            if (!data.containsKey('updatedAt')) {
              // Convert server timestamp to DateTime
              data['updatedAt'] = Timestamp.now();
            }
          }
          
          _practitionerData = PractitionerModel.fromJson(data);
          print('Successfully created practitioner model: ${_practitionerData!.fullName}');
          
          setState(() {
            _isLoading = false;
          });
        } catch (parseError) {
          print('Error parsing practitioner data: $parseError');
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Error parsing profile data. Please contact support.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF2E7D32), // Green theme
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: _practitionerData == null ? null : () async {
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
            CircularProgressIndicator(
              color: Color(0xFF2E7D32),
            ),
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
            Text(_errorMessage, textAlign: TextAlign.center),
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
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Dr.',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey[800],
                  )
                : null,
          ),
          SizedBox(height: 16),
          Text(
            'Dr. ${_practitionerData!.fullName}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _practitionerData!.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    if (_practitionerData == null) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text('Profile data not available'),
          ),
        ),
      );
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Phone', _practitionerData!.phoneNumber ?? 'Not provided'),
            _buildDivider(),
            _buildDetailItem(
              'Specialties', 
              _practitionerData!.specialties.isNotEmpty
                ? _practitionerData!.specialties.join(', ') 
                : 'None specified'
            ),
            _buildDivider(),
            _buildDetailItem('Qualification', _practitionerData!.qualification ?? 'Not specified'),
            _buildDivider(),
            _buildDetailItem('Experience', _practitionerData!.experience ?? 'Not specified'),
            _buildDivider(),
            _buildDetailItem('Bio', _practitionerData!.bio ?? 'No bio available'),
            _buildDivider(),
            _buildDetailItem('Account Created', _formatDate(_practitionerData!.createdAt)),
            _buildDivider(),
            _buildDetailItem('Last Updated', _formatDate(_practitionerData!.updatedAt)),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[300],
      thickness: 1,
    );
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