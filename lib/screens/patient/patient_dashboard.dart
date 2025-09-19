import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/patient_model.dart';
import '../auth/login_screen_new.dart';
import 'consulting_page.dart'; // Correct import

import 'appointments_page.dart';
import 'profile_page.dart';

class PatientDashboard extends StatefulWidget {
  final String? patientId;

  const PatientDashboard({Key? key, this.patientId}) : super(key: key);

  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  PatientModel? _patientData;
  Map<String, dynamic>? _nextAppointment;
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _currentIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Enhanced color palette for AyurSutra
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color surfaceGreen = Color(0xFFE8F5E8);
  static const Color backgroundGreen = Color(0xFFF1F8E9);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _loadPatientData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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

  /// ✅ Corrected version: Fetches patient data by UID directly from `patients` collection
  Future<void> _loadPatientData() async {
    try {
      print("========== LOADING PATIENT DATA ==========");
      String? userId;

      // Check if patientId was passed from login screen
      if (widget.patientId != null && widget.patientId!.isNotEmpty) {
        userId = widget.patientId;
      } else {
        // Use Firebase Auth to get current user
        final firebaseUser = _authService.currentUser;

        if (firebaseUser == null) {
          print("No user is currently signed in.");
          _signOut();
          return;
        }

        userId = firebaseUser.uid;
      }

      // Fetch patient data directly from Firestore
      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(userId)
          .get();

      if (!patientDoc.exists) {
        print("No patient document found for UID: $userId");
        _signOut();
        return;
      }

      // Create data map with UID included
      final data = patientDoc.data()!;
      data['uid'] = userId;

      // Create patient model with safe handling of timestamps
      final patient = _createPatientFromFirestore(data);

      setState(() {
        _patientData = patient;
        _isLoading = false;
        _isRefreshing = false;
      });

      _fadeController.forward();

      // Fetch next appointment if userId is not null
      if (userId != null) {
        await _fetchNextAppointment(userId);
      }
    } catch (e) {
      print('Error loading patient data: $e');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  /// Refresh dashboard data from Firebase
  Future<void> _refreshDashboard() async {
    // Don't do anything if already refreshing
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // Show a temporary "refreshing" message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Refreshing data...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await _loadPatientData();

      // Only show success message if still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Dashboard refreshed successfully'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: primaryGreen,
          ),
        );
      }
    } catch (error) {
      print('Error during refresh: $error');

      // Only show error message if still mounted
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Failed to refresh dashboard'),
              ],
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((data) =>
              data['status'] == 'scheduled' &&
              data['appointmentDate'] != null &&
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
          _nextAppointment = scheduledAppointments[0];
        });
      }
    } catch (e) {
      print('Error fetching appointment: $e');
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
        backgroundColor: backgroundGreen,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  color: primaryGreen,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'AyurSutra',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Loading your wellness journey...',
                style: TextStyle(
                  fontSize: 16,
                  color: accentGreen,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Handle the case when patient data couldn't be loaded
    if (_patientData == null) {
      return Scaffold(
        backgroundColor: backgroundGreen,
        appBar: _buildAppBar(),
        body: Center(
          child: Container(
            margin: EdgeInsets.all(24),
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.healing,
                    size: 60,
                    color: primaryGreen,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Connection Issue',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'We couldn\'t load your wellness profile.\nPlease try signing in again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                  ),
                  onPressed: _signOut,
                  child: Text(
                    'Return to Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundGreen,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              // Hero Section
              _buildHeroSection(),

              // Main Content
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Next appointment reminder
                    if (_nextAppointment != null) ...[
                      _buildNextAppointmentCard(),
                      SizedBox(height: 20),
                    ],

                    // Quick Actions
                    _buildQuickActions(),

                    SizedBox(height: 24),

                    // About AyurSutra Section
                    _buildAboutSection(),

                    SizedBox(height: 20),

                    // Panchakarma Information
                    _buildPanchakarmaSection(),

                    SizedBox(height: 20),

                    // Benefits Section
                    _buildBenefitsSection(),

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.spa,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'AyurSutra',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      backgroundColor: primaryGreen,
      elevation: 0,
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: _isRefreshing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ))
                : Icon(Icons.refresh, color: Colors.white, size: 20),
          ),
          onPressed: _isRefreshing ? null : _refreshDashboard,
          tooltip: 'Refresh',
        ),
        SizedBox(width: 8),
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_outlined,
                color: Colors.white, size: 20),
          ),
          onPressed: () {
            // Navigate to notifications screen
          },
        ),
        SizedBox(width: 8),
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.logout, color: Colors.white, size: 20),
          ),
          onPressed: _signOut,
        ),
        SizedBox(width: 16),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryGreen, accentGreen],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryGreen, accentGreen.withOpacity(0.8)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: surfaceGreen,
                      child: Text(
                        _patientData?.fullName.isNotEmpty ?? false
                            ? _patientData!.fullName.substring(0, 1)
                            : 'P',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _patientData?.fullName ?? 'Patient',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _patientData?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.home, 'Home', 0),
            _buildDrawerItem(Icons.medical_services, 'Consulting', 1),
            _buildDrawerItem(Icons.calendar_today, 'Appointments', 2),
            _buildDrawerItem(Icons.healing, 'Panchakarma', 3),
            _buildDrawerItem(Icons.trending_up, 'My Progress', 4),
            Divider(color: Colors.white.withOpacity(0.3)),
            _buildDrawerItem(Icons.person, 'Profile', -1),
            _buildDrawerItem(Icons.settings, 'Settings', -2),
            _buildDrawerItem(Icons.logout, 'Logout', -3),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    bool isSelected = index == _currentIndex;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white.withOpacity(isSelected ? 1.0 : 0.8),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(isSelected ? 1.0 : 0.8),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          if (index >= 0) {
            setState(() {
              _currentIndex = index;
            });
          }
          Navigator.pop(context);

          if (index == -1) {
            // Profile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(patientId: _patientData?.uid),
              ),
            );
          } else if (index == -2) {
            // Settings
          } else if (index == -3) {
            _signOut();
          }
        },
      ),
    );
  }

  String _getDateSuffix(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Book Consultation',
                Icons.medical_services,
                () {
                  // ===============================================
                  // 1. THIS IS THE FIRST FIX
                  // ===============================================
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ConsultingPage(patientId: _patientData?.uid),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'My Appointments',
                Icons.calendar_today,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AppointmentsPage()),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'View Profile',
                Icons.person,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfilePage(patientId: _patientData?.uid),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Progress Report',
                Icons.trending_up,
                () {
                  // Navigate to progress screen
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.08),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: primaryGreen,
                size: 28,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, surfaceGreen.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.spa,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'About AyurSutra',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'AyurSutra is dedicated to reintroducing the authentic tenets of Ayurveda to the modern world. We focus on producing organic remedies without compromising on the quality and quantity of traditional ingredients.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceGreen.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.eco, color: primaryGreen, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Experience authentic Ayurvedic healing with our organic, traditional remedies',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanchakarmaSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGreen, accentGreen],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.healing,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Panchakarma Therapy',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Panchakarma, meaning "five actions," is Ayurveda\'s most powerful purification and rejuvenation program for the body, mind, and consciousness.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          SizedBox(height: 20),
          _buildPanchakarmaSteps(),
        ],
      ),
    );
  }

  Widget _buildPanchakarmaSteps() {
    final steps = [
      {
        'name': 'Purvakarma',
        'description':
            'Preparatory treatments including oil massage and steam therapy',
        'icon': Icons.spa,
      },
      {
        'name': 'Panchakarma',
        'description':
            'Five main purification procedures tailored to your constitution',
        'icon': Icons.spa,
      },
      {
        'name': 'Paschatkarma',
        'description':
            'Post-treatment care with diet and lifestyle recommendations',
        'icon': Icons.restaurant_menu,
      },
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final step = entry.value;

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: entry.key % 2 == 0
                ? surfaceGreen.withOpacity(0.3)
                : lightGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  step['icon'] as IconData,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['name'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      step['description'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = [
      {
        'title': 'Detoxification',
        'description': 'Eliminates toxins and impurities from the body',
        'icon': Icons.water_drop,
      },
      {
        'title': 'Enhanced Immunity',
        'description': 'Strengthens natural defense mechanisms',
        'icon': Icons.shield,
      },
      {
        'title': 'Mental Clarity',
        'description': 'Improves focus and cognitive function',
        'icon': Icons.psychology,
      },
      {
        'title': 'Stress Relief',
        'description': 'Promotes deep relaxation and inner peace',
        'icon': Icons.self_improvement,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benefits of Panchakarma',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: benefits
              .map((benefit) => Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.08),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: surfaceGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            benefit['icon'] as IconData,
                            color: primaryGreen,
                            size: 28,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          benefit['title'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          benefit['description'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 0,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex > 3 ? 0 : _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;

          switch (index) {
            case 0: // Home
              setState(() {
                _currentIndex = 0;
              });
              break;
            case 1: // Consulting
              // ===============================================
              // 2. THIS IS THE SECOND FIX
              // ===============================================
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                     ConsultingPage(patientId: _patientData?.uid),
                ),
              ).then((_) {
                // After returning from the consulting page, set the index back to home
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
                  builder: (context) =>
                      ProfilePage(patientId: _patientData?.uid),
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
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _currentIndex == 0 ? surfaceGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.home),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _currentIndex == 1 ? surfaceGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.medical_services),
            ),
            label: 'Consulting',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _currentIndex == 2 ? surfaceGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.calendar_today),
            ),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _currentIndex == 3 ? surfaceGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.person),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildNextAppointmentCard() {
    if (_nextAppointment == null) {
      return SizedBox.shrink();
    }

    final appointmentDate =
        (_nextAppointment!['appointmentDate'] as Timestamp).toDate();
    final formattedDate =
        '${_getMonthName(appointmentDate.month)} ${_getDateSuffix(appointmentDate.day)}, ${appointmentDate.year}';

    final time = _nextAppointment!['time'] ?? 'Time not specified';
    final therapy = _nextAppointment!['therapyType'] ?? 'Consultation';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen, accentGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Appointment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        therapy,
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
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: accentGreen),
                          SizedBox(width: 8),
                          Text(
                            time.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.event, size: 18, color: accentGreen),
                          SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to appointment details
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'View Details',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final String patientName =
        _patientData != null ? _patientData!.fullName : 'Patient';
    final String greeting = _getGreeting();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryGreen, accentGreen],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 40),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: surfaceGreen,
                        radius: 35,
                        child: Text(
                          patientName.isNotEmpty
                              ? patientName[0].toUpperCase()
                              : 'P',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            patientName,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (_patientData != null &&
                              _patientData!.doshaType != null)
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Dosha: ${_patientData!.doshaType}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.spa,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Your Journey to Authentic Ayurvedic Wellness',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Experience the power of organic remedies and traditional wisdom',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: backgroundGreen,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}