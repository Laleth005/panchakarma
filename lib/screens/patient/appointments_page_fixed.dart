import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Green Theme Colors
class AppColors {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color backgroundGreen = Color(0xFFF1F8E9);
  static const Color cardGreen = Color(0xFFE8F5E8);
}

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({Key? key}) : super(key: key);

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? currentPatientId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _pastAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    if (currentPatientId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load appointments from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: currentPatientId)
          .orderBy('appointmentDateTime', descending: false)
          .get();

      List<Map<String, dynamic>> upcoming = [];
      List<Map<String, dynamic>> past = [];
      DateTime now = DateTime.now();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> appointment = doc.data() as Map<String, dynamic>;
        appointment['id'] = doc.id;

        // Parse appointment date
        DateTime appointmentDate;
        if (appointment['appointmentDateTime'] is Timestamp) {
          appointmentDate = (appointment['appointmentDateTime'] as Timestamp)
              .toDate();
        } else {
          appointmentDate = DateTime.parse(
            appointment['appointmentDateTime'].toString(),
          );
        }

        if (appointmentDate.isAfter(now)) {
          upcoming.add(appointment);
        } else {
          past.add(appointment);
        }
      }

      setState(() {
        _upcomingAppointments = upcoming;
        _pastAppointments = past;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading appointments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: AppBar(
        title: Text(
          'My Appointments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryGreen,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.upcoming, color: Colors.white),
              text: 'Upcoming',
            ),
            Tab(
              icon: Icon(Icons.history, color: Colors.white),
              text: 'Past',
            ),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryGreen,
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingAppointments(),
                _buildPastAppointments(),
              ],
            ),
    );
  }

  Widget _buildUpcomingAppointments() {
    if (_upcomingAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today,
        title: 'No Upcoming Appointments',
        subtitle: 'Book a consultation to see it here',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _upcomingAppointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(_upcomingAppointments[index], true);
      },
    );
  }

  Widget _buildPastAppointments() {
    if (_pastAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Past Appointments',
        subtitle: 'Your appointment history will appear here',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _pastAppointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(_pastAppointments[index], false);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.accentGreen),
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment,
    bool isUpcoming,
  ) {
    DateTime appointmentDate;
    if (appointment['appointmentDateTime'] is Timestamp) {
      appointmentDate = (appointment['appointmentDateTime'] as Timestamp)
          .toDate();
    } else {
      appointmentDate = DateTime.parse(
        appointment['appointmentDateTime'].toString(),
      );
    }

    String status = appointment['status'] ?? 'pending';
    String appointmentTime = appointment['appointmentTime'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: _getStatusColor(status), width: 4),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Consultation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.accentGreen,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppColors.accentGreen,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(appointmentTime, style: TextStyle(fontSize: 16)),
                ],
              ),
              if (appointment['healthCondition'] != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.medical_services,
                      color: AppColors.accentGreen,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment['healthCondition'],
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isUpcoming && status == 'pending')
                    ElevatedButton.icon(
                      onPressed: () => _cancelAppointment(appointment['id']),
                      icon: Icon(Icons.cancel, size: 20),
                      label: Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (!isUpcoming && status == 'completed')
                    ElevatedButton.icon(
                      onPressed: () => _showFeedbackDialog(appointment),
                      icon: Icon(Icons.rate_review, size: 20),
                      label: Text('Feedback'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'confirmed':
        backgroundColor = AppColors.primaryGreen;
        textColor = Colors.white;
        displayText = 'Confirmed';
        break;
      case 'completed':
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        displayText = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        displayText = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        displayText = 'Pending';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.primaryGreen;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Appointment'),
        content: Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .update({'status': 'cancelled'});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );

        _loadAppointments(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel appointment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFeedbackDialog(Map<String, dynamic> appointmentData) {
    // Placeholder for feedback functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Feedback'),
        content: Text('Feedback feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
