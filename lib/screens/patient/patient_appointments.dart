import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  @override
  _PatientAppointmentsScreenState createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen>
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
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.green.shade800,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.green.shade800,
          tabs: [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentList('upcoming'),
              _buildAppointmentList('completed'),
              _buildAppointmentList('cancelled'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentList(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getAppointmentsStream(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Colors.green.shade700),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
                SizedBox(height: 16),
                Text(
                  'Error loading appointments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(type);
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            return _buildAppointmentCard(doc);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getAppointmentsStream(String type) {
    String? currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      return Stream.empty();
    }

    DateTime now = DateTime.now();
    Query query = _firestore
        .collection('consultations')
        .where('patientId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'confirmed');

    // Filter based on appointment type
    if (type == 'upcoming') {
      query = query.where(
        'confirmedDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(now),
      );
    } else if (type == 'completed') {
      query = query.where('confirmedDate', isLessThan: Timestamp.fromDate(now));
    } else if (type == 'cancelled') {
      query = _firestore
          .collection('consultations')
          .where('patientId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'cancelled');
    }

    return query
        .orderBy('confirmedDate', descending: type == 'completed')
        .snapshots();
  }

  Widget _buildAppointmentCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(data['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                    style: TextStyle(
                      color: _getStatusColor(data['status']),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  'ID: ${doc.id.substring(0, 8)}...',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Practitioner Details
            FutureBuilder<DocumentSnapshot>(
              future: _firestore
                  .collection('users')
                  .doc(data['practitionerId'])
                  .get(),
              builder: (context, practitionerSnapshot) {
                if (practitionerSnapshot.hasData &&
                    practitionerSnapshot.data!.exists) {
                  Map<String, dynamic> practitionerData =
                      practitionerSnapshot.data!.data() as Map<String, dynamic>;
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green.shade100,
                        backgroundImage:
                            practitionerData['profileImage'] != null
                            ? NetworkImage(practitionerData['profileImage'])
                            : null,
                        child: practitionerData['profileImage'] == null
                            ? Icon(
                                Icons.person,
                                color: Colors.green.shade700,
                                size: 30,
                              )
                            : null,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. ${practitionerData['name'] ?? 'Unknown Doctor'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              practitionerData['specialization'] ??
                                  'General Practice',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            if (practitionerData['hospital'] != null)
                              Text(
                                practitionerData['hospital'],
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade300,
                        child: Icon(
                          Icons.person,
                          color: Colors.grey.shade600,
                          size: 30,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Loading doctor details...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),

            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),

            // Appointment Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Date',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDate(data['confirmedDate']),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Time',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        data['confirmedTime'] ?? 'Not specified',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (data['consultationType'] != null) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    data['consultationType'] == 'video'
                        ? Icons.video_call
                        : Icons.chat,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${data['consultationType'].toString().toUpperCase()} Consultation',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],

            if (data['symptoms'] != null && data['symptoms'].isNotEmpty) ...[
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.medical_services,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Symptoms',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          data['symptoms'].join(', '),
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
            ],

            // Action buttons for upcoming appointments
            if (data['status'] == 'confirmed' &&
                data['confirmedDate'] != null) ...[
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelAppointment(doc.id),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _joinConsultation(doc.id, data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isAppointmentToday(data['confirmedDate'])
                            ? 'Join Now'
                            : 'View Details',
                        style: TextStyle(color: Colors.white),
                      ),
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

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getIconForType(type), size: 80, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            _getMessageForType(type),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your ${type} appointments will appear here',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          if (type == 'upcoming')
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to book appointment screen
                  Navigator.pushNamed(context, '/book-appointment');
                },
                child: Text('Book an Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'upcoming':
        return Icons.event;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.calendar_today;
    }
  }

  String _getMessageForType(String type) {
    switch (type) {
      case 'upcoming':
        return 'No upcoming appointments';
      case 'completed':
        return 'No completed appointments';
      case 'cancelled':
        return 'No cancelled appointments';
      default:
        return 'No appointments found';
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Date not specified';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Invalid date';
    }

    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool _isAppointmentToday(dynamic timestamp) {
    if (timestamp == null) return false;

    DateTime appointmentDate;
    if (timestamp is Timestamp) {
      appointmentDate = timestamp.toDate();
    } else if (timestamp is DateTime) {
      appointmentDate = timestamp;
    } else {
      return false;
    }

    DateTime today = DateTime.now();
    return appointmentDate.year == today.year &&
        appointmentDate.month == today.month &&
        appointmentDate.day == today.day;
  }

  void _cancelAppointment(String appointmentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Appointment'),
          content: Text('Are you sure you want to cancel this appointment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _firestore
                      .collection('consultations')
                      .doc(appointmentId)
                      .update({
                        'status': 'cancelled',
                        'cancelledAt': FieldValue.serverTimestamp(),
                        'cancelledBy': 'patient',
                      });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Appointment cancelled successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel appointment'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _joinConsultation(String appointmentId, Map<String, dynamic> data) {
    // Implement navigation to consultation screen
    // Navigator.pushNamed(context, '/consultation', arguments: {
    //   'appointmentId': appointmentId,
    //   'data': data,
    // });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joining consultation...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
