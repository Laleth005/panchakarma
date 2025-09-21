import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Green Theme Colors
class AppColors {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color backgroundGreen = Color(0xFFF1F8E9);
  static const Color cardGreen = Color(0xFFE8F5E8);
}

class PractitionerConsultationPage extends StatefulWidget {
  const PractitionerConsultationPage({Key? key}) : super(key: key);

  @override
  _PractitionerConsultationPageState createState() =>
      _PractitionerConsultationPageState();
}

class _PractitionerConsultationPageState
    extends State<PractitionerConsultationPage>
    with SingleTickerProviderStateMixin {
  final String? currentPractitionerId = FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabController;

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
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          indicatorSize: TabBarIndicatorSize.tab,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundGreen,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.medical_services, size: 20),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aadhaar Sutra',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    'Consultation Management',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            ],
          ),
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
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(60),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 18),
                        SizedBox(width: 8),
                        Text('Pending'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Confirmed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPendingConsultations(),
            _buildConfirmedConsultations(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingConsultations() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getPendingConsultationsStream(),
      builder: (context, snapshot) {
        return _buildConsultationList(snapshot, 'pending');
      },
    );
  }

  Widget _buildConfirmedConsultations() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getConfirmedConsultationsStream(),
      builder: (context, snapshot) {
        return _buildConsultationList(snapshot, 'confirmed');
      },
    );
  }

  Stream<QuerySnapshot> _getPendingConsultationsStream() {
    return FirebaseFirestore.instance
        .collection('consultations')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _getConfirmedConsultationsStream() {
    return FirebaseFirestore.instance
        .collection('consultations')
        .where('status', whereIn: ['confirmed', 'completed'])
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Widget _buildConsultationList(
    AsyncSnapshot<QuerySnapshot> snapshot,
    String listType,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
            SizedBox(height: 16),
            Text(
              'Loading consultations...',
              style: TextStyle(color: AppColors.darkGreen, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 60, color: Colors.red),
            ),
            SizedBox(height: 16),
            Text(
              'Error loading consultations',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
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
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final consultations = snapshot.data?.docs ?? [];

    if (consultations.isEmpty) {
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
              child: Icon(
                listType == 'pending' ? Icons.schedule : Icons.check_circle,
                size: 60,
                color: AppColors.primaryGreen,
              ),
            ),
            SizedBox(height: 24),
            Text(
              listType == 'pending'
                  ? 'No Pending Consultations'
                  : 'No Confirmed Consultations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
            SizedBox(height: 8),
            Text(
              listType == 'pending'
                  ? 'New consultation requests will appear here'
                  : 'Your confirmed appointments will show here',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: consultations.length,
      itemBuilder: (context, index) {
        final consultation = consultations[index];
        final consultationData = consultation.data() as Map<String, dynamic>;
        consultationData['consultationId'] = consultation.id;

        return _buildConsultationCard(consultationData, listType);
      },
    );
  }

  Widget _buildConsultationCard(
    Map<String, dynamic> consultationData,
    String listType,
  ) {
    final status = consultationData['status']?.toString() ?? 'pending';
    final patientName =
        consultationData['name']?.toString() ?? 'Unknown Patient';
    final age = consultationData['age']?.toString() ?? 'N/A';
    final gender = consultationData['gender']?.toString() ?? 'Not specified';
    final phoneNumber = consultationData['phone']?.toString() ?? '';

    // Consultation specific data
    final healthCondition =
        consultationData['healthCondition']?.toString() ?? 'Not specified';
    final conditionDescription =
        consultationData['conditionDescription']?.toString() ?? '';
    final panchakarmaExperience =
        consultationData['panchakarmaExperience']?.toString() ?? '';
    final preferredDate = consultationData['preferredDate'] as Timestamp?;
    final preferredTime = consultationData['preferredTime']?.toString() ?? '';
    final createdAt = consultationData['createdAt'] as Timestamp?;

    // Confirmed appointment details (for confirmed tab)
    final confirmedDate = consultationData['confirmedDate'] as Timestamp?;
    final confirmedTime = consultationData['confirmedTime']?.toString() ?? '';
    final practitionerNotes =
        consultationData['practitionerNotes']?.toString() ?? '';

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
        border: Border(left: BorderSide(color: statusColor, width: 4)),
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
                  child: Row(
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

            // Health condition section
            _buildInfoSection(
              'Health Condition',
              healthCondition,
              Icons.health_and_safety_outlined,
            ),

            if (conditionDescription.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildInfoSection(
                'Condition Description',
                conditionDescription,
                Icons.description_outlined,
                maxLines: 3,
              ),
            ],

            if (panchakarmaExperience.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildInfoSection(
                'Panchakarma Experience',
                panchakarmaExperience,
                Icons.spa_outlined,
                maxLines: 2,
              ),
            ],

            // Contact info
            if (phoneNumber.isNotEmpty) ...[
              SizedBox(height: 16),
              _buildInfoChip(Icons.phone, 'Phone', phoneNumber),
            ],

            // Patient's preferred vs confirmed appointment details
            SizedBox(height: 12),
            if (listType == 'pending') ...[
              // Show patient's preferred date/time for pending consultations
              if (preferredDate != null || preferredTime.isNotEmpty) ...[
                Row(
                  children: [
                    if (preferredDate != null)
                      Expanded(
                        child: _buildInfoChip(
                          Icons.calendar_today,
                          'Patient Preferred Date',
                          '${preferredDate.toDate().day}/${preferredDate.toDate().month}/${preferredDate.toDate().year}',
                          isHighlighted: true,
                        ),
                      ),
                    if (preferredDate != null && preferredTime.isNotEmpty)
                      SizedBox(width: 12),
                    if (preferredTime.isNotEmpty)
                      Expanded(
                        child: _buildInfoChip(
                          Icons.schedule,
                          'Patient Preferred Time',
                          preferredTime,
                          isHighlighted: true,
                        ),
                      ),
                  ],
                ),
              ],
            ] else ...[
              // Show confirmed date/time for confirmed consultations
              if (confirmedDate != null || confirmedTime.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentGreen.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event_available,
                            color: AppColors.primaryGreen,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Confirmed Appointment',
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
                          if (confirmedDate != null)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: AppColors.primaryGreen,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '${confirmedDate.toDate().day}/${confirmedDate.toDate().month}/${confirmedDate.toDate().year}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (confirmedTime.isNotEmpty)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: AppColors.primaryGreen,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    confirmedTime,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (practitionerNotes.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Practitioner Notes:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                practitionerNotes,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.darkGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],

            // Action buttons
            SizedBox(height: 20),
            _buildActionButtons(consultationData, listType),

            // Creation timestamp
            if (createdAt != null) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    'Submitted on ${_formatDateTime(createdAt.toDate())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    String content,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 16),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: 14,
              height: 1.3,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.accentGreen.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted
              ? AppColors.accentGreen
              : AppColors.accentGreen.withOpacity(0.3),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 14),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isHighlighted
                      ? AppColors.primaryGreen
                      : Colors.grey[600],
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    Map<String, dynamic> consultationData,
    String listType,
  ) {
    final status = consultationData['status']?.toString() ?? 'pending';
    final consultationId = consultationData['consultationId'];

    if (listType == 'pending' && status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _rejectConsultation(consultationId),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.close, size: 18),
              label: Text(
                'Reject',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showConfirmDialog(consultationData),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.check, size: 18),
              label: Text(
                'Confirm',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    } else if (listType == 'confirmed' && status == 'confirmed') {
      return ElevatedButton.icon(
        onPressed: () => _markAsCompleted(consultationData['consultationId']),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightGreen,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          minimumSize: Size(double.infinity, 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(Icons.check_circle, size: 18),
        label: Text(
          'Mark as Completed',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    } else if (status == 'completed') {
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
              Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 18),
              SizedBox(width: 8),
              Text(
                'Consultation Completed',
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

    return SizedBox.shrink();
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showConfirmDialog(Map<String, dynamic> consultationData) {
    DateTime selectedDate = DateTime.now().add(Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay(hour: 10, minute: 0);
    TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    child: Icon(
                      Icons.schedule,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Confirm Appointment',
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
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient Details:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGreen,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${consultationData['name'] ?? 'Unknown Patient'} • ${consultationData['age'] ?? 'N/A'} years',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGreen,
                            ),
                          ),
                          Text(
                            'Health Issue: ${consultationData['healthCondition'] ?? 'Not specified'}',
                            style: TextStyle(color: AppColors.darkGreen),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Set appointment date and time:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Date selection
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  Duration(days: 60),
                                ),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: AppColors.primaryGreen,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.accentGreen,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: AppColors.primaryGreen,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                    style: TextStyle(
                                      color: AppColors.darkGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Time selection
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: AppColors.primaryGreen,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  selectedTime = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.accentGreen,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: AppColors.primaryGreen,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: AppColors.darkGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Practitioner notes
                    Text(
                      'Additional Notes (Optional):',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Add any notes or instructions for the patient...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.accentGreen),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primaryGreen),
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
                    Navigator.of(context).pop();
                    _confirmConsultation(
                      consultationData,
                      selectedDate,
                      selectedTime,
                      notesController.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Push notification service
  Future<void> _sendPushNotification(
    String patientId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      // Get patient's FCM token from Firestore
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance
          .collection(
            'users',
          ) // or 'patients' depending on your collection name
          .doc(patientId)
          .get();

      if (!patientDoc.exists) {
        print('Patient document not found');
        return;
      }

      Map<String, dynamic> patientData =
          patientDoc.data() as Map<String, dynamic>;
      String? fcmToken = patientData['fcmToken'];

      if (fcmToken == null || fcmToken.isEmpty) {
        print('FCM token not found for patient');
        return;
      }

      // Your Firebase Cloud Messaging server key
      const String serverKey =
          'YOUR_FCM_SERVER_KEY'; // Replace with your actual server key

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: json.encode({
          'to': fcmToken,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'badge': 1,
          },
          'data': data,
          'android': {
            'notification': {
              'channel_id': 'consultation_channel',
              'priority': 'high',
              'sound': 'default',
              'color': '#2E7D32', // AppColors.primaryGreen
              'icon': 'ic_notification',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {'title': title, 'body': body},
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Push notification sent successfully');

        // Store notification in Firestore for in-app notifications
        await _storeInAppNotification(patientId, title, body, data);
      } else {
        print('Failed to send push notification: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // Store notification in Firestore for in-app display
  Future<void> _storeInAppNotification(
    String patientId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': patientId,
        'title': title,
        'body': body,
        'data': data,
        'type': 'consultation_confirmed',
        'isRead': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Also update the user's notification count
      await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .update({
            'unreadNotificationCount': FieldValue.increment(1),
            'lastNotificationAt': Timestamp.now(),
          });

      print('In-app notification stored successfully');
    } catch (e) {
      print('Error storing in-app notification: $e');
    }
  }

  Future<void> _confirmConsultation(
    Map<String, dynamic> consultationData,
    DateTime date,
    TimeOfDay time,
    String practitionerNotes,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryGreen,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Confirming appointment...',
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Get practitioner details
      DocumentSnapshot practitionerDoc = await FirebaseFirestore.instance
          .collection('practitioners')
          .doc(currentPractitionerId)
          .get();

      Map<String, dynamic> practitionerInfo = {};
      if (practitionerDoc.exists) {
        practitionerInfo = practitionerDoc.data() as Map<String, dynamic>;
      }

      // Update consultation with confirmed details
      await FirebaseFirestore.instance
          .collection('consultations')
          .doc(consultationData['consultationId'])
          .update({
            'status': 'confirmed',
            'confirmedBy': currentPractitionerId,
            'confirmedAt': Timestamp.now(),
            'confirmedDate': Timestamp.fromDate(date),
            'confirmedTime':
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            'practitionerNotes': practitionerNotes,
            'practitionerName':
                practitionerInfo['fullName'] ??
                practitionerInfo['name'] ??
                'Unknown Practitioner',
            'practitionerPhone': practitionerInfo['phoneNumber'] ?? '',
            'practitionerSpecialization':
                practitionerInfo['specialization'] ?? '',
            'updatedAt': Timestamp.now(),
          });

      // Send push notification to patient
      String patientId = consultationData['patientId'] ?? '';
      if (patientId.isNotEmpty) {
        String notificationTitle = 'Appointment Confirmed! 🎉';
        String notificationBody =
            'Your consultation with ${practitionerInfo['fullName'] ?? 'Dr.'} has been confirmed for ${date.day}/${date.month}/${date.year} at ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

        Map<String, dynamic> notificationData = {
          'type': 'consultation_confirmed',
          'consultationId': consultationData['consultationId'],
          'practitionerId': currentPractitionerId,
          'confirmedDate': date.toIso8601String(),
          'confirmedTime':
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          'practitionerName':
              practitionerInfo['fullName'] ??
              practitionerInfo['name'] ??
              'Unknown Practitioner',
          'screen': 'consultation_details', // For navigation
        };

        await _sendPushNotification(
          patientId,
          notificationTitle,
          notificationBody,
          notificationData,
        );
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Switch to confirmed tab
      _tabController.animateTo(1);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 16),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Appointment Confirmed!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Patient has been notified',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error confirming appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Error confirming appointment. Please try again.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _rejectConsultation(String consultationId) async {
    // Show confirmation dialog
    final bool? shouldReject = await showDialog<bool>(
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.cancel, color: Colors.red, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Reject Consultation',
                  style: TextStyle(color: AppColors.darkGreen),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to reject this consultation request? The patient will be notified.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Reject'),
            ),
          ],
        );
      },
    );

    if (shouldReject == true) {
      try {
        // Get consultation data for notification
        DocumentSnapshot consultationDoc = await FirebaseFirestore.instance
            .collection('consultations')
            .doc(consultationId)
            .get();

        if (consultationDoc.exists) {
          Map<String, dynamic> consultationData =
              consultationDoc.data() as Map<String, dynamic>;

          await FirebaseFirestore.instance
              .collection('consultations')
              .doc(consultationId)
              .update({
                'status': 'rejected',
                'rejectedBy': currentPractitionerId,
                'rejectedAt': Timestamp.now(),
                'updatedAt': Timestamp.now(),
              });

          // Send notification to patient about rejection
          String patientId = consultationData['patientId'] ?? '';
          if (patientId.isNotEmpty) {
            String notificationTitle = 'Consultation Update';
            String notificationBody =
                'Your consultation request has been declined. Please try booking with another practitioner.';

            Map<String, dynamic> notificationData = {
              'type': 'consultation_rejected',
              'consultationId': consultationId,
              'screen': 'consultations',
            };

            await _sendPushNotification(
              patientId,
              notificationTitle,
              notificationBody,
              notificationData,
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('Consultation request rejected. Patient notified.'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        print('Error rejecting consultation: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Error rejecting consultation. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAsCompleted(String consultationId) async {
    // Show confirmation dialog with completion notes
    TextEditingController completionNotesController = TextEditingController();

    final bool? shouldComplete = await showDialog<bool>(
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
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Complete Consultation',
                  style: TextStyle(color: AppColors.darkGreen),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mark this consultation as completed. You can add completion notes below:',
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 16),
              TextField(
                controller: completionNotesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Add treatment summary, recommendations, follow-up instructions...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.accentGreen),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryGreen),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text('Complete'),
            ),
          ],
        );
      },
    );

    if (shouldComplete == true) {
      try {
        // Get consultation data for notification
        DocumentSnapshot consultationDoc = await FirebaseFirestore.instance
            .collection('consultations')
            .doc(consultationId)
            .get();

        if (consultationDoc.exists) {
          Map<String, dynamic> consultationData =
              consultationDoc.data() as Map<String, dynamic>;

          // Update the confirmed consultation document if it exists - not needed since we don't have this collection

          // Update the original consultation
          await FirebaseFirestore.instance
              .collection('consultations')
              .doc(consultationId)
              .update({
                'status': 'completed',
                'completedBy': currentPractitionerId,
                'completedAt': Timestamp.now(),
                'completionNotes': completionNotesController.text.trim(),
                'updatedAt': Timestamp.now(),
              });

          // Send notification to patient about completion
          String patientId = consultationData['patientId'] ?? '';
          if (patientId.isNotEmpty) {
            String notificationTitle = 'Consultation Completed ✅';
            String notificationBody =
                'Your consultation has been completed. Check your consultation history for details.';

            Map<String, dynamic> notificationData = {
              'type': 'consultation_completed',
              'consultationId': consultationId,
              'screen': 'consultation_history',
            };

            await _sendPushNotification(
              patientId,
              notificationTitle,
              notificationBody,
              notificationData,
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Consultation completed successfully!'),
                ],
              ),
              backgroundColor: AppColors.primaryGreen,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        print('Error marking consultation as completed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Error updating consultation. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
