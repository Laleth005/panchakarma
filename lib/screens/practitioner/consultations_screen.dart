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

class ConsultationsScreen extends StatefulWidget {
  final String practitionerId;

  const ConsultationsScreen({Key? key, required this.practitionerId})
    : super(key: key);

  @override
  _ConsultationsScreenState createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    try {
      _tabController = TabController(length: 2, vsync: this);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing tab controller: $e');
      // Retry initialization after a short delay
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          _initializeController();
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _tabController == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundGreen,
        appBar: AppBar(
          title: Text('Consultations'),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ),
      );
    }

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
                    'Ayur Sutra',
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
                if (mounted) setState(() {});
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
                controller: _tabController!,
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
          controller: _tabController!,
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
        print(
          'Pending consultations snapshot state: ${snapshot.connectionState}',
        );
        print('Has data: ${snapshot.hasData}');
        print('Data length: ${snapshot.data?.docs.length ?? 0}');
        if (snapshot.hasError) print('Error: ${snapshot.error}');

        return _buildConsultationList(snapshot, 'pending');
      },
    );
  }

  Widget _buildConfirmedConsultations() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getConfirmedConsultationsStream(),
      builder: (context, snapshot) {
        print(
          'Confirmed consultations snapshot state: ${snapshot.connectionState}',
        );
        print('Has data: ${snapshot.hasData}');
        print('Data length: ${snapshot.data?.docs.length ?? 0}');
        if (snapshot.hasError) print('Error: ${snapshot.error}');

        return _buildConsultationList(snapshot, 'confirmed');
      },
    );
  }

  Stream<QuerySnapshot> _getPendingConsultationsStream() {
    print('Getting pending consultations from consultations collection');

    // Get all consultations with pending status
    return FirebaseFirestore.instance
        .collection('consultations')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error in pending consultations stream: $error');
        });
  }

  Stream<QuerySnapshot> _getConfirmedConsultationsStream() {
    print('Getting confirmed consultations from consultations collection');

    // Get all consultations with confirmed or completed status
    return FirebaseFirestore.instance
        .collection('consultations')
        .where('status', whereIn: ['confirmed', 'completed'])
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error in confirmed consultations stream: $error');

          // Fallback: get all consultations and filter in code
          return FirebaseFirestore.instance
              .collection('consultations')
              .orderBy('createdAt', descending: true)
              .snapshots();
        });
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
            SizedBox(height: 8),
            Text(
              'Fetching from consultations collection',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (snapshot.hasError) {
      print('Snapshot error: ${snapshot.error}');
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
              'Error: ${snapshot.error}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (mounted) setState(() {});
              },
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

    final allConsultations = snapshot.data?.docs ?? [];
    print('Total consultations found: ${allConsultations.length}');

    // Filter consultations based on status and list type
    List<QueryDocumentSnapshot> consultations = [];

    if (listType == 'pending') {
      consultations = allConsultations.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status']?.toString().toLowerCase() ?? '';
        return status == 'pending';
      }).toList();
    } else {
      consultations = allConsultations.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status']?.toString().toLowerCase() ?? '';
        return status == 'confirmed' || status == 'completed';
      }).toList();
    }

    print('Filtered consultations for $listType: ${consultations.length}');

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
            SizedBox(height: 16),
            Text(
              'Total docs checked: ${allConsultations.length}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Sort consultations by date
    consultations.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      final aTimestamp = listType == 'pending'
          ? aData['createdAt'] as Timestamp?
          : aData['updatedAt'] as Timestamp?;
      final bTimestamp = listType == 'pending'
          ? bData['createdAt'] as Timestamp?
          : bData['updatedAt'] as Timestamp?;

      if (aTimestamp == null && bTimestamp == null) return 0;
      if (aTimestamp == null) return 1;
      if (bTimestamp == null) return -1;

      return bTimestamp.compareTo(aTimestamp); // Descending order
    });

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: consultations.length,
      itemBuilder: (context, index) {
        final consultation = consultations[index];
        final consultationData = consultation.data() as Map<String, dynamic>;
        consultationData['consultationId'] = consultation.id;

        print(
          'Building consultation card for: ${consultationData['name']} - Status: ${consultationData['status']}',
        );

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
    final additionalNotes =
        consultationData['additionalNotes']?.toString() ?? '';
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

            if (additionalNotes.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildInfoSection(
                'Additional Notes',
                additionalNotes,
                Icons.note_outlined,
                maxLines: 3,
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
                Column(
                  children: [
                    if (preferredDate != null)
                      _buildInfoChip(
                        Icons.calendar_today,
                        'Patient Preferred Date',
                        '${preferredDate.toDate().day}/${preferredDate.toDate().month}/${preferredDate.toDate().year}',
                        isHighlighted: true,
                      ),
                    if (preferredDate != null && preferredTime.isNotEmpty)
                      SizedBox(height: 12),
                    if (preferredTime.isNotEmpty)
                      _buildInfoChip(
                        Icons.schedule,
                        'Patient Preferred Time',
                        preferredTime,
                        isHighlighted: true,
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

            // Debug info
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ID: ${consultationData['consultationId'] ?? 'Unknown'} | Status: ${status}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
            ),
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

    if (listType == 'pending' && status.toLowerCase() == 'pending') {
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
    } else if (listType == 'confirmed' && status.toLowerCase() == 'confirmed') {
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
    } else if (status.toLowerCase() == 'completed') {
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

  Future<void> _rejectConsultation(String consultationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('consultations')
          .doc(consultationId)
          .update({
            'status': 'rejected',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consultation rejected successfully.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error rejecting consultation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting consultation.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsCompleted(String consultationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('consultations')
          .doc(consultationId)
          .update({
            'status': 'completed',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consultation marked as completed.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      print('Error marking consultation as completed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating consultation.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConfirmDialog(Map<String, dynamic> consultationData) {
    final consultationId = consultationData['consultationId'];

    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Consultation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    labelText: 'Confirmed Date (DD/MM/YYYY)',
                    hintText: 'e.g., 25/09/2025',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      dateController.text =
                          '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
                    }
                  },
                  readOnly: true,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: 'Confirmed Time',
                    hintText: 'e.g., 10:30 AM',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      timeController.text = pickedTime.format(context);
                    }
                  },
                  readOnly: true,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Practitioner Notes (Optional)',
                    hintText: 'Any additional instructions or notes...',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text('Confirm'),
              onPressed: () async {
                if (dateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select a date'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (timeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select a time'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Parse the date string
                  final dateParts = dateController.text.split('/');
                  if (dateParts.length != 3) {
                    throw FormatException('Invalid date format');
                  }

                  final day = int.parse(dateParts[0]);
                  final month = int.parse(dateParts[1]);
                  final year = int.parse(dateParts[2]);
                  final confirmedDate = DateTime(year, month, day);

                  await FirebaseFirestore.instance
                      .collection('consultations')
                      .doc(consultationId)
                      .update({
                        'status': 'confirmed',
                        'confirmedDate': Timestamp.fromDate(confirmedDate),
                        'confirmedTime': timeController.text,
                        'practitionerNotes': notesController.text,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Consultation confirmed successfully.'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error confirming consultation: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error confirming consultation. Please check the date format.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return AppColors.primaryGreen;
      case 'completed':
        return AppColors.lightGreen;
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
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
