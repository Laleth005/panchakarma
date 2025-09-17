import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/patient_model.dart';
import '../auth/login_screen_new.dart';
import 'consulting_page.dart';
import 'appointments_page.dart';
import 'profile_page.dart';

class PatientDashboard extends StatefulWidget {
  final String? patientId;
  
  const PatientDashboard({Key? key, this.patientId}) : super(key: key);

  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final AuthService _authService = AuthService();
  PatientModel? _patientData;
  Map<String, dynamic>? _nextAppointment;
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  // Helper method to create a PatientModel from Firestore data
  PatientModel _createPatientFromFirestore(Map<String, dynamic> data) {
    // Handle timestamps for PatientModel constructor
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
    
    // Create a minimum patient model if missing critical data
    if (!data.containsKey('fullName') || data['fullName'] == null) {
      data['fullName'] = 'Patient';
    }
    
    if (!data.containsKey('email') || data['email'] == null) {
      data['email'] = '';
    }
    
    // Create patient model with the data
    return PatientModel(
      uid: data['uid'] as String,
      email: data['email'] as String,
      fullName: data['fullName'] as String,
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
  }

  Future<void> _loadPatientData() async {
    try {
      print("========== LOADING PATIENT DATA ==========");
      String? userId;
      
      // Step 0: Check if patientId was passed from login screen
      if (widget.patientId != null && widget.patientId!.isNotEmpty) {
        print("Patient ID provided from login: ${widget.patientId}");
        userId = widget.patientId;
        
        // Try to load directly with this ID
        try {
          final patientDoc = await FirebaseFirestore.instance
              .collection('patients')
              .doc(userId)
              .get();
              
          if (patientDoc.exists) {
            print("Successfully loaded patient with provided ID");
            final data = patientDoc.data()!;
            data['uid'] = userId;
            
            // Create patient model with safe handling of timestamps
            final patient = _createPatientFromFirestore(data);
            
            setState(() {
              _patientData = patient;
              _isLoading = false;
            });
            
            // Safe null check before calling fetchNextAppointment
            if (userId != null) {
              await _fetchNextAppointment(userId);
            }
            return;
          }
        } catch (e) {
          print("Error loading patient with provided ID: $e");
        }
      }
      
      // Step 1: Try to load patient data using AuthService
      print("Step 1: Trying to get patient data from AuthService");
      final userData = await _authService.getCurrentUserData();
      print("AuthService returned user data: $userData");
      
      if (userData is PatientModel) {
        print("Success: User is a PatientModel with uid: ${userData.uid}");
        setState(() {
          _patientData = userData;
          _isLoading = false;
        });
        
        // Now try to fetch next appointment
        await _fetchNextAppointment(userData.uid);
        return;
      }
      
      // Step 2: If AuthService failed, check Firebase Auth directly
      print("Step 2: Checking Firebase Auth current user");
      final firebaseUser = _authService.currentUser;
      
      if (firebaseUser != null) {
        print("Firebase Auth has current user: ${firebaseUser.uid}");
        userId = firebaseUser.uid;
        
        // Step 3: Try to get patient data directly from Firestore
        print("Step 3: Getting patient data directly from Firestore");
        try {
          final patientDoc = await FirebaseFirestore.instance
              .collection('patients')
              .doc(firebaseUser.uid)
              .get();
          
          if (patientDoc.exists) {
            print("Success: Found patient doc in Firestore");
            final data = patientDoc.data()!;
            
            // Ensure uid is in the data
            data['uid'] = firebaseUser.uid;
            
            // Ensure role is in the data
            if (!data.containsKey('role')) {
              data['role'] = 'patient';
            }
            
            // Create patient model using our helper
            final patient = _createPatientFromFirestore(data);
            
            setState(() {
              _patientData = patient;
              _isLoading = false;
            });
            
            await _fetchNextAppointment(firebaseUser.uid);
            return;
          } else {
            print("No patient doc found in Firestore for uid: ${firebaseUser.uid}");
            print("Creating new patient document");
            
            // Create a new patient document if it doesn't exist
            await FirebaseFirestore.instance.collection('patients').doc(firebaseUser.uid).set({
              'uid': firebaseUser.uid,
              'email': firebaseUser.email ?? '',
              'fullName': firebaseUser.displayName ?? 'Patient',
              'role': 'patient',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            // Create a basic patient model without waiting for Firestore
            final patient = PatientModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              fullName: firebaseUser.displayName ?? 'Patient',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            setState(() {
              _patientData = patient;
              _isLoading = false;
            });
            
            return;
          }
        } catch (firestoreError) {
          print("Error fetching patient doc from Firestore: $firestoreError");
        }
      } else {
        // Step 2.5: Try to get user ID from the authenticated session
        print("No Firebase Auth user, checking auth state");
        
        // Check if there's user information in Firestore's authentication data
        try {
          final userQuery = await FirebaseFirestore.instance
              .collection('users')
              .limit(20)
              .get();
              
          print("Found ${userQuery.docs.length} users in Firestore users collection");
          
          for (final doc in userQuery.docs) {
            print("Checking user: ${doc.id} - ${doc.data()['email']}");
          }
        } catch (e) {
          print("Error listing users: $e");
        }
      }
      
      // Step 4: Try creating a test patient for demo purposes
      print("Step 4: Creating a demo patient for testing");
      
      try {
        final demoUid = 'demo-${DateTime.now().millisecondsSinceEpoch}';
        print("Creating demo patient with ID: $demoUid");
        
        // Create a demo document in Firestore
        try {
          await FirebaseFirestore.instance.collection('patients').doc(demoUid).set({
            'uid': demoUid,
            'email': 'demo@ayursutra.com',
            'fullName': 'Demo Patient',
            'role': 'patient',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print("Created demo patient document in Firestore");
        } catch (e) {
          print("Failed to create demo patient in Firestore: $e");
        }
        
        // Create a basic patient model for the UI
        final demoPatient = PatientModel(
          uid: demoUid,
          email: 'demo@ayursutra.com',
          fullName: 'Demo Patient',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        setState(() {
          _patientData = demoPatient;
          _isLoading = false;
        });
        
        return;
      } catch (e) {
        print("Error creating demo patient: $e");
      }
      
      // If we got here, we couldn't get or create patient data
      print("Failed to load or create patient data");
      setState(() {
        _isLoading = false;
      });
      
      // Show a simplified UI with a retry button instead of error dialog
      // This will display in the build method when _patientData is null
    } catch (e) {
      print('Error in _loadPatientData: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // No replacement - removing unused method
  
  Future<void> _fetchNextAppointment(String patientId) async {
    try {
      // Simplified query that doesn't require a composite index
      final appointmentSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .get();

      // Filter in memory to avoid needing composite indexes
      final now = DateTime.now();
      final scheduledAppointments = appointmentSnapshot.docs
          .map((doc) => doc.data()..['id'] = doc.id)
          .where((data) => 
              data['status'] == 'scheduled' && 
              (data['appointmentDate'] as Timestamp).toDate().isAfter(now))
          .toList();
      
      // Sort by date
      scheduledAppointments.sort((a, b) {
        final aDate = (a['appointmentDate'] as Timestamp).toDate();
        final bDate = (b['appointmentDate'] as Timestamp).toDate();
        return aDate.compareTo(bDate);
      });
      
      if (scheduledAppointments.isNotEmpty) {
        setState(() {
          _nextAppointment = appointmentSnapshot.docs[0].data();
        });
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching appointment: $e');
      setState(() {
        _isLoading = false;
      });
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
    
    // Handle the case when patient data couldn't be loaded
    if (_patientData == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            'Ayur Sutra',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Color(0xFF2E7D32),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Color(0xFF2E7D32),
              ),
              SizedBox(height: 20),
              Text(
                'Could not load patient data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Please try logging in again',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D32),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: _signOut,
                child: Text(
                  'Return to Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Ayur Sutra',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF2E7D32), // Dark green color
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // Navigate to notifications screen
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF2E7D32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      _patientData?.fullName.isNotEmpty ?? false 
                          ? _patientData!.fullName.substring(0, 1) 
                          : 'P',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _patientData?.fullName ?? 'Patient',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    _patientData?.email ?? '',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: _currentIndex == 0 ? Color(0xFF2E7D32) : null),
              title: Text('Home'),
              selected: _currentIndex == 0,
              selectedColor: Color(0xFF2E7D32),
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.medical_services, color: _currentIndex == 1 ? Color(0xFF2E7D32) : null),
              title: Text('Consulting'),
              selected: _currentIndex == 1,
              selectedColor: Color(0xFF2E7D32),
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
                Navigator.pop(context);
                // Navigate to consulting screen
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today, color: _currentIndex == 2 ? Color(0xFF2E7D32) : null),
              title: Text('Appointments'),
              selected: _currentIndex == 2,
              selectedColor: Color(0xFF2E7D32),
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
                Navigator.pop(context);
                // Navigate to appointments screen
              },
            ),
            ListTile(
              leading: Icon(Icons.medical_information_outlined, color: _currentIndex == 3 ? Color(0xFF2E7D32) : null),
              title: Text('Panchakarma Info'),
              selected: _currentIndex == 3,
              selectedColor: Color(0xFF2E7D32),
              onTap: () {
                setState(() {
                  _currentIndex = 3;
                });
                Navigator.pop(context);
                // Navigate to Panchakarma info screen
              },
            ),
            ListTile(
              leading: Icon(Icons.show_chart, color: _currentIndex == 4 ? Color(0xFF2E7D32) : null),
              title: Text('My Progress'),
              selected: _currentIndex == 4,
              selectedColor: Color(0xFF2E7D32),
              onTap: () {
                setState(() {
                  _currentIndex = 4;
                });
                Navigator.pop(context);
                // Navigate to progress visualization screen
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              selectedColor: Color(0xFF2E7D32),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile screen
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              selectedColor: Color(0xFF2E7D32),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings screen
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              selectedColor: Color(0xFF2E7D32),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            _buildWelcomeCard(),
            
            SizedBox(height: 20),
            
            // Next appointment reminder
            if (_nextAppointment != null) _buildNextAppointmentCard(),
            
            SizedBox(height: 20),
            
            // Panchakarma Info Card
            _buildInfoCard(
              'What is Panchakarma?',
              'Panchakarma is a Sanskrit term that means "five actions" or "five treatments". '
              'It is a purification and rejuvenation program for the body, mind, and consciousness.',
              Icons.spa,
            ),
            
            SizedBox(height: 16),
            
            // Steps in Panchakarma
            _buildPanchakarmaStepsCard(),
            
            SizedBox(height: 16),
            
            // Benefits Card
            _buildInfoCard(
              'Benefits of Panchakarma',
              'Panchakarma therapy eliminates toxins, restores metabolic processes, '
              'enhances immunity and vitality, and creates harmony of Mind, Body, and Spirit.',
              Icons.health_and_safety,
            ),
            
            SizedBox(height: 16),
            
            // Preparations Card
            _buildInfoCard(
              'Preparing for Panchakarma',
              'Before beginning Panchakarma, a proper diet, adequate rest, and mental preparation are essential. '
              'Your practitioner will guide you through specific pre-therapy protocols.',
              Icons.checklist,
            ),
            
            SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex > 3 ? 0 : _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return; // Don't navigate if already on the selected tab
          
          switch (index) {
            case 0: // Home - already on this page
              setState(() {
                _currentIndex = 0;
              });
              break;
            case 1: // Consulting
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConsultingPage()),
              ).then((_) {
                setState(() {
                  _currentIndex = 0;
                });
              });
              break;
            case 2: // Appointments
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppointmentsPage()),
              ).then((_) {
                setState(() {
                  _currentIndex = 0;
                });
              });
              break;
            case 3: // Profile
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(patientId: _patientData?.uid),
                ),
              ).then((_) {
                setState(() {
                  _currentIndex = 0;
                });
              });
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey.shade600,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Consulting',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final String patientName = _patientData != null ? _patientData!.fullName : 'Patient';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Text(
                    patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome,',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        patientName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_patientData != null && _patientData!.doshaType != null)
                        Text(
                          'Dosha Type: ${_patientData!.doshaType}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Begin your journey to holistic wellness with Ayur Sutra personalized Panchakarma therapy.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextAppointmentCard() {
    if (_nextAppointment == null) return SizedBox();
    
    final appointmentDate = _nextAppointment!['appointmentDate'] as Timestamp?;
    final date = appointmentDate?.toDate() ?? DateTime.now();
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    final time = _nextAppointment!['appointmentTime'] ?? '10:00 AM';
    final therapy = _nextAppointment!['therapyType'] ?? 'Panchakarma Session';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'Your Next Appointment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        therapy,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$formattedDate • $time',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to appointment details
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
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
                Icon(icon, color: Color(0xFF2E7D32), size: 24),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanchakarmaStepsCard() {
    final steps = [
      {
        'name': 'Purvakarma (Preparatory Procedures)',
        'description': 'Prepares the body for the main treatments through oil massage and steam therapy.'
      },
      {
        'name': 'Vamana (Therapeutic Emesis)',
        'description': 'Eliminates excess Kapha dosha from the body.'
      },
      {
        'name': 'Virechana (Therapeutic Purgation)',
        'description': 'Removes excess Pitta dosha from the small intestine and liver.'
      },
      {
        'name': 'Basti (Therapeutic Enema)',
        'description': 'Addresses Vata dosha imbalances through medicated enemas.'
      },
      {
        'name': 'Nasya (Nasal Administration)',
        'description': 'Eliminates toxins from the head and neck region.'
      },
      {
        'name': 'Raktamokshana (Bloodletting)',
        'description': 'Purifies the blood (not commonly practiced in modern settings).'
      },
      {
        'name': 'Paschatkarma (Post-Procedure Care)',
        'description': 'Includes dietary and lifestyle recommendations to maintain the benefits.'
      },
    ];

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
                Icon(Icons.format_list_numbered, color: Color(0xFF2E7D32), size: 24),
                SizedBox(width: 8),
                Text(
                  'Steps in Panchakarma',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFF2E7D32),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['name']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            step['description']!,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}