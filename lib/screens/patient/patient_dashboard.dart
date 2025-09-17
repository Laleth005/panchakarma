import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/patient_model.dart';
import '../auth/login_screen.dart';
import 'patient_home.dart';
import 'patient_consulting.dart';
import 'patient_appointments.dart';
import 'patient_profile.dart';
import 'patient_notifications.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final AuthService _authService = AuthService();
  PatientModel? _patientData;
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _showNotifications = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final List<Widget> _screens = [
    PatientHomeScreen(),
    PatientConsultingScreen(),
    PatientAppointmentsScreen(),
    PatientProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    try {
      final userData = await _authService.getCurrentUserData();
      if (userData is PatientModel) {
        setState(() {
          _patientData = userData;
          _isLoading = false;
        });
      } else {
        // Handle case where user is not a patient
        _signOut();
      }
    } catch (e) {
      print('Error loading patient data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          'AyurSutra',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  setState(() {
                    _showNotifications = !_showNotifications;
                  });
                },
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Main content based on bottom navigation
          _showNotifications 
              ? PatientNotificationsScreen() 
              : _screens[_currentIndex],
              
          // Green gradient overlay at the top
          if (!_showNotifications)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.green.shade700,
                      Colors.green.shade700.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _showNotifications = false;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
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
  
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            color: Colors.green.shade700,
            child: Container(
              padding: EdgeInsets.all(16),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 40,
                    child: Text(
                      _patientData?.fullName.substring(0, 1) ?? 'P',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _patientData?.fullName ?? 'Patient',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _patientData?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _patientData?.doshaType ?? 'Dosha Unknown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: Colors.green.shade700),
            title: Text('Home'),
            onTap: () {
              setState(() {
                _currentIndex = 0;
                _showNotifications = false;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.description, color: Colors.green.shade700),
            title: Text('My Treatment Plans'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to treatment plans
            },
          ),
          ListTile(
            leading: Icon(Icons.food_bank, color: Colors.green.shade700),
            title: Text('Diet & Lifestyle'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to diet & lifestyle
            },
          ),
          ListTile(
            leading: Icon(Icons.assessment, color: Colors.green.shade700),
            title: Text('Health Progress'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to health progress
            },
          ),
          ListTile(
            leading: Icon(Icons.library_books, color: Colors.green.shade700),
            title: Text('Ayurveda Knowledge Base'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to knowledge base
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.grey.shade600),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings
            },
          ),
          ListTile(
            leading: Icon(Icons.help, color: Colors.grey.shade600),
            title: Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to help & support
            },
          ),
          Spacer(),
          Divider(height: 0),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
            onTap: _signOut,
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}