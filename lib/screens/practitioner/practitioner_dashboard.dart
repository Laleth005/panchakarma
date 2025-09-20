import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/practitioner_model.dart';
import 'practitioner_home_screen.dart';
import 'consultations_screen.dart';
import 'appointments_screen.dart';
import 'slots_page.dart';
import 'practitioner_profile_screen.dart';

class PractitionerMainDashboard extends StatefulWidget {
  final String practitionerId;
  
  const PractitionerMainDashboard({
    Key? key,
    required this.practitionerId,
  }) : super(key: key);

  @override
  _PractitionerMainDashboardState createState() => _PractitionerMainDashboardState();
}

class _PractitionerMainDashboardState extends State<PractitionerMainDashboard> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Dashboard metrics
  int _totalPatients = 0;
  int _upcomingAppointments = 0;
  int _totalConsultations = 0;
  int _completedAppointments = 0;
  int _pendingApprovals = 0;
  int _todayAppointments = 0;

  // Current practitioner data
  PractitionerModel? _practitionerData;
  bool _isLoading = true;

  // Ayurvedic Green theme
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color ayurvedicGold = Color(0xFFFFA000);
  static const Color ayurvedicLightBeige = Color(0xFFF5F5DC);

  // Page controllers for each tab
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _initializePages();
    _loadDashboardData();
  }

  void _initializePages() {
    _pages.addAll([
      PractitionerHomeScreen(practitionerId: widget.practitionerId),
      ConsultationsScreen(practitionerId: widget.practitionerId),
      AppointmentsScreen(),
      SlotsPage(practitionerId: widget.practitionerId),
      PractitionerProfileScreen(practitionerId: widget.practitionerId),
    ]);
  }

  Future<void> _loadDashboardData() async {
    try {
      print('Loading dashboard data...');
      setState(() {
        _isLoading = true;
      });

      final User? user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Loading practitioner data for ID: ${widget.practitionerId}');
      
      // Get practitioner data
      await _loadPractitionerData();
      
      // Load all metrics in parallel
      await Future.wait([
        _loadPatientsCount(),
        _loadAppointmentsData(),
        _loadConsultationsCount(),
        _loadTodayAppointments(),
      ]);

      setState(() {
        _isLoading = false;
      });
      
      print('Dashboard loading completed');
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPractitionerData() async {
    try {
      final practitionerDoc = await _firestore
          .collection('practitioners')
          .doc(widget.practitionerId)
          .get()
          .timeout(Duration(seconds: 10));
          
      if (practitionerDoc.exists) {
        Map<String, dynamic> data = practitionerDoc.data() as Map<String, dynamic>;
        data['uid'] = widget.practitionerId;
        setState(() {
          _practitionerData = PractitionerModel.fromJson(data);
        });
        print('Practitioner data loaded successfully: ${_practitionerData?.fullName}');
      } else {
        print('Practitioner document does not exist');
      }
    } catch (e) {
      print('Error loading practitioner data: $e');
    }
  }

  Future<void> _loadPatientsCount() async {
    try {
      final patientSnapshot = await _firestore
          .collection('patients')
          .where('practitionerId', isEqualTo: widget.practitionerId)
          .get()
          .timeout(Duration(seconds: 5));
      
      setState(() {
        _totalPatients = patientSnapshot.size;
      });
      print('Loaded ${_totalPatients} patients');
    } catch (e) {
      print('Error loading patients: $e');
      setState(() {
        _totalPatients = 0;
      });
    }
  }

  Future<void> _loadAppointmentsData() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Upcoming appointments (today and future)
      final upcomingSnapshot = await _firestore
          .collection('appointments')
          .where('practitionerId', isEqualTo: widget.practitionerId)
          .where('date', isGreaterThanOrEqualTo: today)
          .where('status', whereIn: ['scheduled', 'confirmed'])
          .get()
          .timeout(Duration(seconds: 10));
      
      // Completed appointments
      final completedSnapshot = await _firestore
          .collection('appointments')
          .where('practitionerId', isEqualTo: widget.practitionerId)
          .where('status', isEqualTo: 'completed')
          .get()
          .timeout(Duration(seconds: 10));

      // Pending approvals
      final pendingSnapshot = await _firestore
          .collection('appointments')
          .where('practitionerId', isEqualTo: widget.practitionerId)
          .where('status', isEqualTo: 'pending')
          .get()
          .timeout(Duration(seconds: 10));

      setState(() {
        _upcomingAppointments = upcomingSnapshot.size;
        _completedAppointments = completedSnapshot.size;
        _pendingApprovals = pendingSnapshot.size;
      });

      print('Loaded appointments: upcoming=${_upcomingAppointments}, completed=${_completedAppointments}, pending=${_pendingApprovals}');
    } catch (e) {
      print('Error loading appointments: $e');
      setState(() {
        _upcomingAppointments = 0;
        _completedAppointments = 0;
        _pendingApprovals = 0;
      });
    }
  }

  Future<void> _loadConsultationsCount() async {
    try {
      final consultationSnapshot = await _firestore
          .collection('consultations')
          .where('practitionerId', isEqualTo: widget.practitionerId)
          .get()
          .timeout(Duration(seconds: 5));
      
      setState(() {
        _totalConsultations = consultationSnapshot.size;
      });
      print('Loaded ${_totalConsultations} consultations');
    } catch (e) {
      print('Error loading consultations: $e');
      setState(() {
        _totalConsultations = 0;
      });
    }
  }

  Future<void> _loadTodayAppointments() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(Duration(days: 1));

      final todaySnapshot = await _firestore
          .collection('appointments')
          .where('practitionerId', isEqualTo: widget.practitionerId)
          .where('date', isGreaterThanOrEqualTo: todayStart)
          .where('date', isLessThan: todayEnd)
          .where('status', whereIn: ['scheduled', 'confirmed'])
          .get()
          .timeout(Duration(seconds: 10));

      setState(() {
        _todayAppointments = todaySnapshot.size;
      });
      print('Loaded ${_todayAppointments} today appointments');
    } catch (e) {
      print('Error loading today appointments: $e');
      setState(() {
        _todayAppointments = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: primaryGreen,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading Dashboard...',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa_outlined),
            activeIcon: Icon(Icons.spa),
            label: "Consultations",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: "Appointments",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: "Slots",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
