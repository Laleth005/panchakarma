import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/practitioner_model.dart';
import '../auth/login_screen_new.dart';
import 'appointments_screen.dart';
import 'patients_screen.dart';
import 'practitioner_profile_screen.dart';

class PractitionerDashboardNew extends StatefulWidget {
  const PractitionerDashboardNew({Key? key}) : super(key: key);

  @override
  _PractitionerDashboardNewState createState() => _PractitionerDashboardNewState();
}

class _PractitionerDashboardNewState extends State<PractitionerDashboardNew> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Dashboard metrics
  int _totalPatients = 0;
  int _upcomingAppointments = 0;
  int _clearedAppointments = 0;
  
  // Current practitioner data
  PractitionerModel? _practitionerData;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // No approval process needed

  // Sign out method
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out. Please try again.')),
      );
    }
  }
  
  // Show logout confirmation dialog
  Future<void> _showLogoutConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout Confirmation'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm logout
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
    
    if (result == true) {
      await _signOut();
    } else {
      // Reset the bottom navigation to Home
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get current user ID
      final User? user = _auth.currentUser;
      if (user == null) {
        // Handle not logged in
        return;
      }

      // Get practitioner data
      final practitionerDoc = await _firestore.collection('practitioners').doc(user.uid).get();
      if (practitionerDoc.exists) {
        Map<String, dynamic> data = practitionerDoc.data() as Map<String, dynamic>;
        
        setState(() {
          // Include uid in the data map before passing to fromJson
          data['uid'] = user.uid;
          _practitionerData = PractitionerModel.fromJson(data);
        });
      }

      // Get patients count
      final patientSnapshot = await _firestore.collection('patients').get();
      setState(() {
        _totalPatients = patientSnapshot.size;
      });

      // Get current date for appointments filtering
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Query for upcoming appointments (where date >= today)
      final upcomingSnapshot = await _firestore
          .collection('appointments')
          .where('practitionerId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: today)
          .where('status', isEqualTo: 'scheduled')
          .get();
      
      // Query for cleared appointments
      final clearedSnapshot = await _firestore
          .collection('appointments')
          .where('practitionerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();
      
      setState(() {
        _upcomingAppointments = upcomingSnapshot.size;
        _clearedAppointments = clearedSnapshot.size;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Aayur Sutra',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF2E7D32), // Green theme
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            color: Colors.white,
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PractitionerProfileScreen(),
                ),
              );
            },
            color: Colors.white,
            tooltip: 'My Profile',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
            color: Colors.white,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
              ),
            )
          : _buildDashboardContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          
          // Navigate based on selected index
          if (index == 0) {
            // Already on home/dashboard, do nothing
          } else if (index == 1) {
            // Navigate to Appointments
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AppointmentsScreen()),
            );
          } else if (index == 2) {
            // Navigate to Patients
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PatientsScreen()),
            );
          } else if (index == 3) {
            // Navigate to Messages (to be implemented)
          } else if (index == 4) {
            // Show logout confirmation dialog
            _showLogoutConfirmation();
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          _buildMetricsCards(),
          _buildUpcomingAppointments(),
          _buildRecentPatients(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    String practitionerName = _practitionerData?.fullName ?? 'Practitioner';
    String greeting = _getGreeting();
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2E7D32),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting,',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Dr. $practitionerName',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          Text(
            'Welcome to your dashboard',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
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

  Widget _buildMetricsCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Patients',
                  _totalPatients.toString(),
                  Icons.people,
                  Colors.blue.shade700,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Upcoming',
                  _upcomingAppointments.toString(),
                  Icons.calendar_today,
                  Colors.amber.shade700,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Completed',
                  _clearedAppointments.toString(),
                  Icons.check_circle,
                  Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Appointments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to Appointments screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AppointmentsScreen()),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          FutureBuilder<QuerySnapshot>(
            future: _getTodayAppointments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error loading appointments'));
              }
              
              final appointments = snapshot.data?.docs ?? [];
              
              if (appointments.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No appointments scheduled for today',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: appointments.length > 3 ? 3 : appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index].data() as Map<String, dynamic>;
                  return _buildAppointmentCard(
                    appointment['patientName'] ?? 'Unknown Patient',
                    appointment['time'] ?? 'No time set',
                    appointment['therapyType'] ?? 'General Consultation',
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<QuerySnapshot> _getTodayAppointments() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    
    return _firestore
        .collection('appointments')
        .where('practitionerId', isEqualTo: _auth.currentUser?.uid)
        .where('date', isGreaterThanOrEqualTo: today)
        .where('date', isLessThan: tomorrow)
        .where('status', isEqualTo: 'scheduled')
        .limit(3)
        .get();
  }

  Widget _buildAppointmentCard(String patientName, String time, String therapyType) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFF2E7D32).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.person,
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
                    patientName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    therapyType,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Today',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPatients() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Patients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to Patients screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PatientsScreen()),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          FutureBuilder<QuerySnapshot>(
            future: _getRecentPatients(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error loading patients'));
              }
              
              final patients = snapshot.data?.docs ?? [];
              
              if (patients.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No patients yet',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: patients.length > 3 ? 3 : patients.length,
                itemBuilder: (context, index) {
                  final patient = patients[index].data() as Map<String, dynamic>;
                  final lastVisit = patient['lastVisitDate'] != null 
                      ? '${patient['lastVisitDate'].toDate().day}/${patient['lastVisitDate'].toDate().month}/${patient['lastVisitDate'].toDate().year}'
                      : 'No visits yet';
                  
                  return _buildPatientCard(
                    patient['fullName'] ?? 'Unknown Patient',
                    'Last visit: $lastVisit',
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<QuerySnapshot> _getRecentPatients() async {
    return _firestore
        .collection('patients')
        .orderBy('lastVisitDate', descending: true)
        .limit(3)
        .get();
  }

  Widget _buildPatientCard(String patientName, String lastVisit) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF2E7D32).withOpacity(0.2),
              child: Text(
                patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    lastVisit,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2E7D32)),
              onPressed: () {
                // Navigate to patient details
              },
            ),
          ],
        ),
      ),
    );
  }
}