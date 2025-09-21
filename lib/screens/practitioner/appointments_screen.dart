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

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: AppColors.primaryGreen,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryGreen,
          secondary: AppColors.accentGreen,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundGreen,
        appBar: AppBar(
          title: Text(
            'My Appointments',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryGreen,
          elevation: 4,
          shadowColor: AppColors.primaryGreen.withOpacity(0.3),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.upcoming), text: 'Upcoming'),
              Tab(icon: Icon(Icons.history), text: 'Completed'),
              Tab(icon: Icon(Icons.cancel_outlined), text: 'Cancelled'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {}); // Trigger rebuild to refresh data
              },
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAppointmentsList(
              'confirmed',
            ), // Upcoming confirmed appointments
            _buildAppointmentsList('completed'), // Completed appointments
            _buildAppointmentsList(
              'rejected',
            ), // Cancelled/Rejected appointments
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(String status) {
    // Only show appointments confirmed by this practitioner
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('appointments')
          .where('practitionerId', isEqualTo: _auth.currentUser?.uid)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading appointments',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
                SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final appointments = snapshot.data?.docs ?? [];

        if (appointments.isEmpty) {
          return _buildEmptyState(status);
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            final data = appointment.data() as Map<String, dynamic>;
            data['id'] = appointment.id;
            return _buildAppointmentCard(data);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    IconData icon;
    String title;
    String message;

    switch (status) {
      case 'confirmed':
        icon = Icons.calendar_today;
        title = 'No Upcoming Appointments';
        message = 'Your confirmed appointments will appear here';
        break;
      case 'completed':
        icon = Icons.check_circle_outline;
        title = 'No Completed Appointments';
        message = 'Completed treatments will appear here';
        break;
      case 'rejected':
        icon = Icons.cancel_outlined;
        title = 'No Cancelled Appointments';
        message = 'Cancelled appointments will appear here';
        break;
      default:
        icon = Icons.event_note;
        title = 'No Appointments';
        message = 'No appointments found';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: AppColors.primaryGreen),
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> data) {
    final status = data['status'] ?? 'confirmed';
    final patientName = data['patientName'] ?? 'Unknown Patient';
    final age = data['patientAge'] ?? 0;
    final gender = data['patientGender'] ?? 'Not specified';
    final healthCondition = data['healthCondition'] ?? 'Not specified';
    final confirmedDate = data['confirmedDate'] as Timestamp?;
    final confirmedTime = data['confirmedTime'] ?? '';
    final phoneNumber = data['phoneNumber'] ?? '';
    final treatmentPlan = data['treatmentPlan'] as Map<String, dynamic>?;

    DateTime? appointmentDateTime;
    if (confirmedDate != null) {
      appointmentDateTime = confirmedDate.toDate();
    }

    Color statusColor = _getStatusColor(status);
    IconData statusIcon = _getStatusIcon(status);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border(left: BorderSide(color: statusColor, width: 5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with patient info and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.cardGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.person,
                              color: AppColors.primaryGreen,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                                Text(
                                  '$age years, $gender',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Appointment details
            if (appointmentDateTime != null) ...[
              _buildInfoRow(
                Icons.calendar_today,
                'Appointment Date',
                '${appointmentDateTime.day}/${appointmentDateTime.month}/${appointmentDateTime.year}',
              ),
              SizedBox(height: 8),
            ],

            if (confirmedTime.isNotEmpty) ...[
              _buildInfoRow(Icons.access_time, 'Time', confirmedTime),
              SizedBox(height: 8),
            ],

            _buildInfoRow(
              Icons.health_and_safety,
              'Health Condition',
              healthCondition,
            ),

            if (phoneNumber.isNotEmpty) ...[
              SizedBox(height: 8),
              _buildInfoRow(Icons.phone, 'Contact', phoneNumber),
            ],

            // Treatment plan section
            if (treatmentPlan != null) ...[
              SizedBox(height: 16),
              _buildTreatmentPlanSection(treatmentPlan),
            ],

            // Action buttons
            SizedBox(height: 20),
            _buildActionButtons(data),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 16),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.darkGreen,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: AppColors.darkGreen, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentPlanSection(Map<String, dynamic> treatmentPlan) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa, color: AppColors.primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Treatment Plan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          if (treatmentPlan['treatmentType'] != null) ...[
            _buildTreatmentDetail(
              'Treatment Type',
              treatmentPlan['treatmentType'],
            ),
          ],

          if (treatmentPlan['duration'] != null) ...[
            _buildTreatmentDetail(
              'Duration',
              '${treatmentPlan['duration']} days',
            ),
          ],

          if (treatmentPlan['description'] != null) ...[
            _buildTreatmentDetail('Description', treatmentPlan['description']),
          ],

          if (treatmentPlan['dietPlan'] != null) ...[
            _buildTreatmentDetail('Diet Plan', treatmentPlan['dietPlan']),
          ],

          if (treatmentPlan['medicines'] != null) ...[
            _buildTreatmentDetail('Medicines', treatmentPlan['medicines']),
          ],
        ],
      ),
    );
  }

  Widget _buildTreatmentDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: AppColors.darkGreen, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> data) {
    final status = data['status'] ?? 'confirmed';
    final appointmentId = data['id'];
    final treatmentPlan = data['treatmentPlan'] as Map<String, dynamic>?;

    if (status == 'confirmed') {
      return Row(
        children: [
          if (treatmentPlan == null) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showTreatmentPlanDialog(appointmentId, data),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.medical_services, size: 18),
                label: Text(
                  'Add Treatment Plan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showTreatmentPlanDialog(appointmentId, data),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: BorderSide(color: AppColors.primaryGreen),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.edit, size: 18),
                label: Text(
                  'Edit Treatment',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _markAsCompleted(appointmentId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.check_circle, size: 18),
                label: Text(
                  'Complete',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      );
    } else {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 'completed' ? Icons.check_circle : Icons.cancel,
                color: AppColors.primaryGreen,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                status == 'completed'
                    ? 'Treatment Completed'
                    : 'Appointment Cancelled',
                style: TextStyle(
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.primaryGreen;
      case 'completed':
        return Colors.blue;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  void _showTreatmentPlanDialog(
    String appointmentId,
    Map<String, dynamic> data,
  ) {
    // Treatment plan dialog implementation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Treatment plan feature will be implemented next'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _markAsCompleted(String appointmentId) async {
    // Mark treatment as completed implementation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mark as completed feature will be implemented next'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }
}
