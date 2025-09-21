import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientAppointmentsPage extends StatefulWidget {
  final String? patientId;

  const PatientAppointmentsPage({Key? key, this.patientId}) : super(key: key);

  @override
  _PatientAppointmentsPageState createState() =>
      _PatientAppointmentsPageState();
}

class _PatientAppointmentsPageState extends State<PatientAppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Green theme colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color backgroundGreen = Color(0xFFF1F8E9);

  Map<String, dynamic>? _patientData;
  bool _isLoadingPatient = true;
  String? _currentPatientId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _determinePatientId();
  }

  Future<void> _determinePatientId() async {
    try {
      // Use provided patientId or try to get current user
      _currentPatientId = widget.patientId;

      if (_currentPatientId == null || _currentPatientId!.isEmpty) {
        // Try to get from Firebase Auth current user
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _currentPatientId = user.uid;
        }
      }

      if (_currentPatientId != null) {
        await _loadPatientData();
      } else {
        setState(() {
          _isLoadingPatient = false;
        });
      }
    } catch (e) {
      print('Error determining patient ID: $e');
      setState(() {
        _isLoadingPatient = false;
      });
    }
  }

  Future<void> _loadPatientData() async {
    if (_currentPatientId == null) return;

    try {
      setState(() {
        _isLoadingPatient = true;
      });

      // Try patients collection first
      DocumentSnapshot patientDoc = await _firestore
          .collection('patients')
          .doc(_currentPatientId!)
          .get();

      if (patientDoc.exists) {
        Map<String, dynamic> data = patientDoc.data() as Map<String, dynamic>;
        setState(() {
          _patientData = {
            'name': data['fullName'] ?? data['name'] ?? 'Patient',
            'email': data['email'] ?? '',
            'phone': data['phoneNumber'] ?? data['phone'] ?? '',
            'profileImage': data['profileImageUrl'] ?? data['profileImage'],
          };
          _isLoadingPatient = false;
        });
        return;
      }

      // Try users collection if not found in patients
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_currentPatientId!)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _patientData = {
            'name': data['fullName'] ?? data['name'] ?? 'Patient',
            'email': data['email'] ?? '',
            'phone': data['phoneNumber'] ?? data['phone'] ?? '',
            'profileImage': data['profileImageUrl'] ?? data['profileImage'],
          };
          _isLoadingPatient = false;
        });
        return;
      }

      // If not found in either collection
      setState(() {
        _patientData = null;
        _isLoadingPatient = false;
      });
    } catch (e) {
      print('Error loading patient data: $e');
      setState(() {
        _patientData = null;
        _isLoadingPatient = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGreen,
      appBar: AppBar(
        title: Text(
          'My Appointments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(120),
          child: Column(
            children: [
              _buildPatientHeader(),
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.green.shade200,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoadingPatient
          ? _buildLoadingState()
          : _patientData == null
          ? _buildPatientNotFoundState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList('upcoming'),
                _buildAppointmentsList('completed'),
                _buildAppointmentsList('cancelled'),
              ],
            ),
    );
  }

  Widget _buildPatientHeader() {
    if (_isLoadingPatient) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.green.shade100,
              child: CircularProgressIndicator(
                color: primaryGreen,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading patient details...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_patientData == null) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.red.shade100,
              child: Icon(Icons.error, color: Colors.red),
            ),
            SizedBox(width: 12),
            Text('Patient not found', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.green.shade100,
            backgroundImage:
                (_patientData!['profileImage'] != null &&
                    _patientData!['profileImage']!.isNotEmpty)
                ? NetworkImage(_patientData!['profileImage']!)
                : null,
            child:
                (_patientData!['profileImage'] == null ||
                    _patientData!['profileImage']!.isEmpty)
                ? Icon(Icons.person, color: primaryGreen, size: 25)
                : null,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patientData!['name'] ?? 'Patient',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_patientData!['email']?.isNotEmpty == true)
                  Text(
                    _patientData!['email']!,
                    style: TextStyle(
                      color: Colors.green.shade100,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryGreen, strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Loading appointments...',
            style: TextStyle(
              color: primaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Patient not found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Unable to load patient details',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPatientData,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(String type) {
    if (_currentPatientId == null) {
      return Center(
        child: Text(
          'No patient ID available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getAppointmentsStream(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryGreen));
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), type);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(type);
        }

        final appointments = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            return _buildAppointmentCard(appointments[index], type);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getAppointmentsStream(String type) {
    // Simplified queries to avoid composite index requirements
    Query baseQuery = _firestore
        .collection('consultations')
        .where('patientId', isEqualTo: _currentPatientId);

    switch (type) {
      case 'upcoming':
        // Simple status-based query for confirmed appointments
        return baseQuery.where('status', isEqualTo: 'confirmed').snapshots();

      case 'completed':
        // Simple status-based query for completed appointments
        return baseQuery.where('status', isEqualTo: 'completed').snapshots();

      case 'cancelled':
        // Simple status-based query for cancelled appointments
        return baseQuery.where('status', isEqualTo: 'cancelled').snapshots();

      default:
        return Stream.empty();
    }
  }

  Widget _buildAppointmentCard(DocumentSnapshot doc, String type) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryGreen.withOpacity(0.1)),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChip(data['status'] ?? 'unknown'),
                Text(
                  _formatDate(data['createdAt']),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: primaryGreen.withOpacity(0.1),
                  child: Icon(
                    Icons.medical_services,
                    color: primaryGreen,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['practitionerName'] ?? 'Dr. Practitioner',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        data['consultationType'] ?? 'General Consultation',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (data['symptoms']?.isNotEmpty == true) ...[
              Text(
                'Symptoms: ${data['symptoms']}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
            ],
            if (data['confirmedDate'] != null) ...[
              Row(
                children: [
                  Icon(Icons.schedule, color: primaryGreen, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Scheduled: ${_formatDateTime(data['confirmedDate'])}',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'confirmed':
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.check_circle;
        break;
      case 'completed':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        break;
      case 'pending':
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.schedule;
        break;
      default:
        chipColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    IconData icon;

    switch (type) {
      case 'upcoming':
        message = 'No upcoming appointments';
        icon = Icons.event_available;
        break;
      case 'completed':
        message = 'No completed appointments';
        icon = Icons.event_note;
        break;
      case 'cancelled':
        message = 'No cancelled appointments';
        icon = Icons.event_busy;
        break;
      default:
        message = 'No appointments found';
        icon = Icons.event;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your ${type} appointments will appear here',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
          SizedBox(height: 16),
          Text(
            'Error loading appointments',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Please check your internet connection and try again',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Trigger rebuild to retry the stream
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 18),
                SizedBox(width: 8),
                Text('Retry'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Invalid date';
      }

      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'Not scheduled';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Invalid date';
      }

      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
