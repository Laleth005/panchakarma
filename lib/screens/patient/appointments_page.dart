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

// Placeholder FeedbackPage class - you can replace this with your actual implementation
class FeedbackPage extends StatelessWidget {
  final Map<String, dynamic> appointmentData;
  
  const FeedbackPage({Key? key, required this.appointmentData}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: Center(
        child: Text('Feedback page for appointment'),
      ),
    );
  }
}

class PatientAppointmentsPage extends StatefulWidget {
  const PatientAppointmentsPage({Key? key}) : super(key: key);

  @override
  _PatientAppointmentsPageState createState() => _PatientAppointmentsPageState();
}

class _PatientAppointmentsPageState extends State<PatientAppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? currentPatientId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundGreen,
        appBar: AppBar(
          title: Text('My Appointments',
            style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 4,
          shadowColor: AppColors.primaryGreen.withOpacity(0.3),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {}); // Trigger rebuild to refresh data
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
            tabs: [
              Tab(
                icon: Icon(Icons.upcoming),
                text: 'Upcoming',
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'Past',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildUpcomingAppointments(),
            _buildPastAppointments(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/consultation_form');
          },
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          icon: Icon(Icons.add),
          label: Text('New Request'),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: currentPatientId)
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
          return _buildErrorWidget('Error loading appointments');
        }

        final appointments = snapshot.data?.docs ?? [];
        
        // Filter for upcoming appointments (pending, confirmed)
        final upcomingAppointments = appointments.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';
          return status == 'pending' || status == 'confirmed';
        }).toList();
        
        // Sort by createdAt descending
        upcomingAppointments.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aCreated = aData['createdAt'] as Timestamp?;
          final bCreated = bData['createdAt'] as Timestamp?;
          if (aCreated == null && bCreated == null) return 0;
          if (aCreated == null) return 1;
          if (bCreated == null) return -1;
          return bCreated.compareTo(aCreated);
        });

        if (upcomingAppointments.isEmpty) {
          return _buildEmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'No Upcoming Appointments',
            message: 'You don\'t have any upcoming appointments.\nTap the + button to request a consultation.',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: upcomingAppointments.length,
          itemBuilder: (context, index) {
            final appointment = upcomingAppointments[index];
            final data = appointment.data() as Map<String, dynamic>;
            data['id'] = appointment.id;
            return _buildUpcomingAppointmentCard(data);
          },
        );
      },
    );
  }

  Widget _buildPastAppointments() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: currentPatientId)
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
          return _buildErrorWidget('Error loading past appointments');
        }

        final appointments = snapshot.data?.docs ?? [];
        
        // Filter for past appointments (completed, rejected, cancelled)
        final pastAppointments = appointments.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';
          return status == 'completed' || status == 'rejected' || status == 'cancelled';
        }).toList();
        
        // Sort by updatedAt descending
        pastAppointments.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aUpdated = aData['updatedAt'] as Timestamp?;
          final bUpdated = bData['updatedAt'] as Timestamp?;
          if (aUpdated == null && bUpdated == null) return 0;
          if (aUpdated == null) return 1;
          if (bUpdated == null) return -1;
          return bUpdated.compareTo(aUpdated);
        });

        if (pastAppointments.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'No Past Appointments',
            message: 'You don\'t have any past appointments yet.\nCompleted consultations will appear here.',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: pastAppointments.length,
          itemBuilder: (context, index) {
            final appointment = pastAppointments[index];
            final data = appointment.data() as Map<String, dynamic>;
            data['id'] = appointment.id;
            return _buildPastAppointmentCard(data);
          },
        );
      },
    );
  }

  Widget _buildUpcomingAppointmentCard(Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final healthCondition = data['healthCondition'] ?? 'Not specified';
    final practitionerName = data['practitionerName'] ?? 'Practitioner';
    final createdAt = data['createdAt'] as Timestamp?;
    final confirmedDate = data['confirmedDate'] as Timestamp?;
    final confirmedTime = data['confirmedTime'] ?? '';
    final preferredDate = data['preferredDate'] as Timestamp?;
    final preferredTime = data['preferredTime'] ?? '';

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
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and condition
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
                            child: Icon(Icons.health_and_safety,
                              color: AppColors.primaryGreen, size: 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              healthCondition,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.darkGreen,
                              ),
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
           
            // Appointment details based on status
            if (status == 'confirmed' && confirmedDate != null) ...[
              _buildConfirmedAppointmentDetails(confirmedDate, confirmedTime, practitionerName),
            ] else if (status == 'pending') ...[
              _buildPendingAppointmentDetails(preferredDate, preferredTime),
            ],
           
            SizedBox(height: 16),
           
            // Action buttons
            _buildUpcomingActionButtons(data),
           
            // Request date
            if (createdAt != null) ...[
              SizedBox(height: 12),
              Text(
                'Requested on ${_formatDate(createdAt.toDate())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPastAppointmentCard(Map<String, dynamic> data) {
    final status = data['status'] ?? 'completed';
    final healthCondition = data['healthCondition'] ?? 'Not specified';
    final practitionerName = data['practitionerName'] ?? 'Practitioner';
    final completedAt = data['completedAt'] as Timestamp?;
    final confirmedDate = data['confirmedDate'] as Timestamp?;
    final confirmedTime = data['confirmedTime'] ?? '';

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
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.health_and_safety,
                          color: AppColors.primaryGreen, size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          healthCondition,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.darkGreen,
                          ),
                        ),
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
            if (status == 'completed' && confirmedDate != null) ...[
              _buildCompletedAppointmentDetails(confirmedDate, confirmedTime, practitionerName),
            ] else if (status == 'rejected') ...[
              _buildRejectedAppointmentDetails(),
            ],
           
            SizedBox(height: 16),
           
            // Action buttons for past appointments
            _buildPastActionButtons(data),
           
            // Completion date
            if (completedAt != null) ...[
              SizedBox(height: 12),
              Text(
                'Completed on ${_formatDate(completedAt.toDate())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmedAppointmentDetails(Timestamp confirmedDate, String confirmedTime, String practitionerName) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.cardGreen, AppColors.backgroundGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 24),
              SizedBox(width: 12),
              Text(
                'Appointment Confirmed!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.calendar_today,
                  'Date',
                  _formatDate(confirmedDate.toDate()),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  Icons.access_time,
                  'Time',
                  confirmedTime,
                ),
              ),
            ],
          ),
          if (practitionerName != 'Practitioner') ...[
            SizedBox(height: 8),
            _buildDetailItem(
              Icons.person,
              'Practitioner',
              practitionerName,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingAppointmentDetails(Timestamp? preferredDate, String preferredTime) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text(
                'Waiting for Confirmation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'A practitioner will review your request and confirm the appointment with exact date and time.',
            style: TextStyle(
              color: Colors.orange.shade600,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (preferredDate != null) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.calendar_today_outlined,
                    'Preferred Date',
                    _formatDate(preferredDate.toDate()),
                  ),
                ),
                if (preferredTime.isNotEmpty) ...[
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.access_time_outlined,
                      'Preferred Time',
                      preferredTime,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedAppointmentDetails(Timestamp confirmedDate, String confirmedTime, String practitionerName) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text(
                'Consultation Completed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.calendar_today,
                  'Date',
                  _formatDate(confirmedDate.toDate()),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  Icons.access_time,
                  'Time',
                  confirmedTime,
                ),
              ),
            ],
          ),
          if (practitionerName != 'Practitioner') ...[
            SizedBox(height: 8),
            _buildDetailItem(
              Icons.person,
              'Practitioner',
              practitionerName,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectedAppointmentDetails() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request Not Approved',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Unfortunately, this consultation request was not approved. You can submit a new request anytime.',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 16),
        SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingActionButtons(Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';

    if (status == 'confirmed') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _cancelAppointment(data['id']),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.cancel_outlined, size: 18),
              label: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showAppointmentDetails(data),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.info_outline, size: 18),
              label: Text('Details', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    } else if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _cancelAppointment(data['id']),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.cancel_outlined, size: 18),
              label: Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showAppointmentDetails(data),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: BorderSide(color: AppColors.primaryGreen),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.info_outline, size: 18),
              label: Text('Details', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildPastActionButtons(Map<String, dynamic> data) {
    final status = data['status'] ?? 'completed';

    if (status == 'completed') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showAppointmentDetails(data),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: BorderSide(color: AppColors.primaryGreen),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.info_outline, size: 18),
              label: Text('View Details', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _navigateToFeedbackPage(data),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.feedback_outlined, size: 18),
              label: Text('Feedback', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    } else {
      return OutlinedButton.icon(
        onPressed: () => _showAppointmentDetails(data),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: BorderSide(color: AppColors.primaryGreen),
          padding: EdgeInsets.symmetric(vertical: 12),
          minimumSize: Size(double.infinity, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(Icons.info_outline, size: 18),
        label: Text('View Details', style: TextStyle(fontWeight: FontWeight.w600)),
      );
    }
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String message}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: AppColors.primaryGreen,
              ),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
          SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return AppColors.primaryGreen;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAppointmentDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Appointment Details',
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Condition', data['healthCondition'] ?? 'Not specified'),
                _buildDetailRow('Status', (data['status'] ?? 'pending').toUpperCase()),
                if (data['practitionerName'] != null)
                  _buildDetailRow('Practitioner', data['practitionerName']),
                if (data['confirmedDate'] != null) ...[
                  _buildDetailRow('Date', _formatDate((data['confirmedDate'] as Timestamp).toDate())),
                  _buildDetailRow('Time', data['confirmedTime'] ?? 'Not specified'),
                ],
                if (data['conditionDescription'] != null && data['conditionDescription'].isNotEmpty)
                  _buildDetailRow('Description', data['conditionDescription'], multiline: true),
                if (data['panchakarmaExperience'] != null)
                  _buildDetailRow('Experience', data['panchakarmaExperience']),
                if (data['additionalNotes'] != null && data['additionalNotes'].isNotEmpty)
                  _buildDetailRow('Notes', data['additionalNotes'], multiline: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool multiline = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.darkGreen,
                fontSize: 14,
                height: multiline ? 1.4 : 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Cancel Appointment',
            style: TextStyle(color: AppColors.darkGreen),
          ),
          content: Text(
            'Are you sure you want to cancel this appointment?',
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Keep'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      try {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .update({
          'status': 'cancelled',
          'cancelledAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: AppColors.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Error cancelling appointment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling appointment. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateToFeedbackPage(Map<String, dynamic> appointmentData) {
    _showFeedbackDialog(appointmentData);
  }

  void _showFeedbackDialog(Map<String, dynamic> appointmentData) {
    TextEditingController feedbackController = TextEditingController();
    int rating = 5;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cardGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.feedback_outlined, color: AppColors.primaryGreen, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Consultation Feedback',
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How was your consultation experience?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Rating',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            rating = index + 1;
                          });
                        },
                        child: Icon(
                          Icons.star,
                          color: index < rating ? Colors.amber : Colors.grey[300],
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Comments (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: feedbackController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share your experience, suggestions, or any concerns...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.accentGreen),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _submitFeedback(appointmentData['id'], rating, feedbackController.text);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: Text('Submit Feedback'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitFeedback(String appointmentId, int rating, String comments) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .collection('feedback')
          .add({
        'rating': rating,
        'comments': comments,
        'submittedAt': Timestamp.now(),
        'patientId': currentPatientId,
      });

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'hasFeedback': true,
        'updatedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error submitting feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting feedback. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
