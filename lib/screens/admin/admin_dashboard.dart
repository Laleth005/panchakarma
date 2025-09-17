import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/admin_model.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  AdminModel? _adminData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final userData = await _authService.getCurrentUserData();
      if (userData is AdminModel) {
        setState(() {
          _adminData = userData;
          _isLoading = false;
        });
      } else {
        // Handle case where user is not an admin
        _signOut();
      }
    } catch (e) {
      print('Error loading admin data: $e');
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
      appBar: AppBar(
        title: Text('Admin Dashboard'),
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
                      _adminData?.fullName.substring(0, 1) ?? 'A',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _adminData?.fullName ?? 'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    _adminData?.email ?? '',
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
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Practitioner Management'),
              onTap: () {
                Navigator.pop(context);
                // Removed practitioner approval screen as it's no longer needed
              },
            ),
            ListTile(
              leading: Icon(Icons.healing),
              title: Text('Therapy Management'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to therapy management screen
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Scheduling'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to scheduling screen
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Patient Management'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to patient management screen
              },
            ),
            ListTile(
              leading: Icon(Icons.bar_chart),
              title: Text('Reports & Analytics'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to reports screen
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings screen
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
              'Welcome, ${_adminData?.fullName ?? "Admin"}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_adminData?.clinicName ?? "Panchakarma Clinic"}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24),
            
            // Overview Cards
            Row(
              children: [
                _buildOverviewCard(
                  'Total Patients',
                  '0',
                  Icons.people,
                  Colors.blue,
                ),
                SizedBox(width: 16),
                _buildOverviewCard(
                  'Practitioners',
                  '0',
                  Icons.medical_services,
                  Colors.green,
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildOverviewCard(
                  'Today\'s Sessions',
                  '0',
                  Icons.calendar_today,
                  Colors.orange,
                ),
                SizedBox(width: 16),
                _buildOverviewCard(
                  'Pending Approvals',
                  '0',
                  Icons.approval,
                  Colors.red,
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