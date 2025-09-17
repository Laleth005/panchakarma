import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/practitioner_model.dart';
import '../auth/login_screen.dart';

class PractitionerDashboard extends StatefulWidget {
  const PractitionerDashboard({Key? key}) : super(key: key);

  @override
  _PractitionerDashboardState createState() => _PractitionerDashboardState();
}

class _PractitionerDashboardState extends State<PractitionerDashboard> {
  final AuthService _authService = AuthService();
  PractitionerModel? _practitionerData;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPractitionerData();
  }

  Future<void> _loadPractitionerData() async {
    try {
      final userData = await _authService.getCurrentUserData();
      if (userData is PractitionerModel) {
        setState(() {
          _practitionerData = userData;
          _isLoading = false;
        });
        
        // Check if practitioner is approved
        if (!_practitionerData!.isApproved) {
          _showPendingApprovalDialog();
        }
      } else {
        // Handle case where user is not a practitioner
        _signOut();
      }
    } catch (e) {
      print('Error loading practitioner data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPendingApprovalDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Account Pending Approval'),
            content: Text(
                'Your account is still pending approval from the admin. You\'ll be notified once your account is approved.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _signOut();
                },
                child: Text('Logout'),
              ),
            ],
          );
        },
      );
    });
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
      appBar: AppBar(
        title: Text('Practitioner Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
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
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      _practitionerData?.fullName.substring(0, 1) ?? 'P',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _practitionerData?.fullName ?? 'Practitioner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    _practitionerData?.email ?? '',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Patient Profiles'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
                // Navigate to patient profiles screen
              },
            ),
            ListTile(
              leading: Icon(Icons.healing),
              title: Text('Therapy Prescription'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
                // Navigate to therapy prescription screen
              },
            ),
            ListTile(
              leading: Icon(Icons.track_changes),
              title: Text('Therapy Tracking'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
                // Navigate to therapy tracking screen
              },
            ),
            ListTile(
              leading: Icon(Icons.feedback),
              title: Text('Feedback Monitoring'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() {
                  _selectedIndex = 4;
                });
                Navigator.pop(context);
                // Navigate to feedback monitoring screen
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              selected: _selectedIndex == 5,
              onTap: () {
                setState(() {
                  _selectedIndex = 5;
                });
                Navigator.pop(context);
                // Navigate to notifications screen
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Dr. ${_practitionerData?.fullName ?? "Practitioner"}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Specialties: ${_practitionerData?.specialties.join(", ") ?? "None"}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24),
            
            // Overview Cards
            Row(
              children: [
                _buildOverviewCard(
                  'Today\'s Patients',
                  '0',
                  Icons.people,
                  Colors.blue,
                ),
                SizedBox(width: 16),
                _buildOverviewCard(
                  'Pending Feedback',
                  '0',
                  Icons.feedback,
                  Colors.orange,
                ),
              ],
            ),
            
            SizedBox(height: 32),
            Text(
              'Today\'s Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Center(
                child: Text('No scheduled sessions for today'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                  ),
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}