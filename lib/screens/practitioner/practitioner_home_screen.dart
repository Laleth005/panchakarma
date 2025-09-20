import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PractitionerHomeScreen extends StatefulWidget {
  final String practitionerId;

  const PractitionerHomeScreen({
    Key? key,
    required this.practitionerId,
  }) : super(key: key);

  @override
  _PractitionerHomeScreenState createState() => _PractitionerHomeScreenState();
}

class _PractitionerHomeScreenState extends State<PractitionerHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dashboard Data
  int _totalPatients = 0;
  int _totalAppointments = 0;
  int _totalConsultations = 0;
  int _confirmedConsultations = 0;
  bool _isLoading = true;

  // App Colors - Green Theme for Ayurveda Sutra
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color backgroundGreen = Color(0xFFF1F8E9);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      // Load all data in parallel
      await Future.wait([
        _fetchPractitionerData(),
        _fetchTotalPatients(),
        _fetchTotalAppointments(),
        _fetchTotalConsultations(),
        _fetchConsultationsBreakdown(),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPractitionerData() async {
    // No longer needed since we're not showing practitioner-specific data
  }

  Future<void> _fetchTotalPatients() async {
    try {
      final snapshot = await _firestore.collection('patients').get();
      setState(() => _totalPatients = snapshot.docs.length);
    } catch (e) {
      print('Error fetching total patients: $e');
    }
  }

  Future<void> _fetchTotalAppointments() async {
    try {
      final snapshot = await _firestore.collection('appointments').get();
      setState(() => _totalAppointments = snapshot.docs.length);
    } catch (e) {
      print('Error fetching total appointments: $e');
    }
  }

  Future<void> _fetchTotalConsultations() async {
    try {
      final snapshot = await _firestore.collection('consultations').get();
      setState(() => _totalConsultations = snapshot.docs.length);
    } catch (e) {
      print('Error fetching total consultations: $e');
    }
  }

  Future<void> _fetchConsultationsBreakdown() async {
    try {
      // Get confirmed consultations count
      final confirmedSnapshot = await _firestore
          .collection('confirmedConsultations')
          .get();

      setState(() {
        _confirmedConsultations = confirmedSnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching consultations breakdown: $e');
    }
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
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                strokeWidth: 3,
              ),
              SizedBox(height: 20),
              Text(
                '🌿 Loading Dashboard...',
                style: TextStyle(
                  fontSize: 18,
                  color: primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundGreen,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: primaryGreen,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppHeader(),
                SizedBox(height: 24),
                _buildWelcomeCard(),
                SizedBox(height: 24),
                _buildStatsSection(),
                SizedBox(height: 24),
                _buildConsultationsBreakdown(),
                SizedBox(height: 24),
                _buildQuickActions(),
                SizedBox(height: 100), // Space for bottom navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  // App Header with branding
  Widget _buildAppHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.spa,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ayurveda Sutra',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                Text(
                  'Practitioner Dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryGreen.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: primaryGreen,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // Welcome Card
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen, primaryGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Doctor! 🌿',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Manage your practice with Ayurveda Sutra',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_hospital,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // Stats Section
  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Practice Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Patients',
                _totalPatients.toString(),
                Icons.people,
                primaryGreen,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Appointments',
                _totalAppointments.toString(),
                Icons.calendar_today,
                primaryGreen,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Consultations',
                _totalConsultations.toString(),
                Icons.medical_services,
                primaryGreen,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Confirmed Consultations',
                _confirmedConsultations.toString(),
                Icons.check_circle,
                primaryGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Consultations Breakdown
  Widget _buildConsultationsBreakdown() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: primaryGreen),
              SizedBox(width: 8),
              Text(
                'Consultation Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildConsultationStat(
                'Pending',
                (_totalConsultations - _confirmedConsultations).toString(),
                Colors.orange,
              ),
              _buildConsultationStat(
                'Confirmed',
                _confirmedConsultations.toString(),
                Colors.green,
              ),
              _buildConsultationStat(
                'Total',
                _totalConsultations.toString(),
                primaryGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: primaryGreen),
              SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Consultations',
                  Icons.medical_services,
                  primaryGreen,
                  () => Navigator.pushNamed(context, '/consultations'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Appointments',
                  Icons.calendar_today,
                  primaryGreen,
                  () => Navigator.pushNamed(context, '/appointments'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}