import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/patient_model.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailScreen({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  _PatientDetailScreenState createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _patientData;
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _therapies = [];
  List<Map<String, dynamic>> _medicalRecords = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load patient profile data
      final patientDoc = await _firestore.collection('patients').doc(widget.patientId).get();
      
      if (patientDoc.exists) {
        setState(() {
          _patientData = patientDoc.data() as Map<String, dynamic>;
        });

        // Load appointments for this patient
        final appointmentsSnapshot = await _firestore
            .collection('appointments')
            .where('patientId', isEqualTo: widget.patientId)
            .orderBy('appointmentDate', descending: true)
            .limit(10)
            .get();

        // Load therapies for this patient
        final therapiesSnapshot = await _firestore
            .collection('therapies')
            .where('patientId', isEqualTo: widget.patientId)
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();

        // Load medical records for this patient
        final recordsSnapshot = await _firestore
            .collection('medicalRecords')
            .where('patientId', isEqualTo: widget.patientId)
            .orderBy('recordDate', descending: true)
            .limit(10)
            .get();

        setState(() {
          _appointments = appointmentsSnapshot.docs
              .map((doc) => {
                    ...doc.data(),
                    'id': doc.id,
                  })
              .toList();

          _therapies = therapiesSnapshot.docs
              .map((doc) => {
                    ...doc.data(),
                    'id': doc.id,
                  })
              .toList();

          _medicalRecords = recordsSnapshot.docs
              .map((doc) => {
                    ...doc.data(),
                    'id': doc.id,
                  })
              .toList();
        });
      }
    } catch (e) {
      print('Error loading patient data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load patient details')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Patient Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              // Navigate to edit patient screen
              // Will implement later
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Profile'),
            Tab(text: 'Medical History'),
            Tab(text: 'Appointments'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          : _patientData == null
              ? Center(child: Text('Patient not found'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProfileTab(),
                    _buildMedicalHistoryTab(),
                    _buildAppointmentsTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Will implement scheduling/adding new appointment
        },
        backgroundColor: Color(0xFF2E7D32),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientHeader(),
          SizedBox(height: 24),
          _buildInfoSection('Personal Information', [
            _buildInfoRow('Email', _patientData!['email'] ?? 'Not provided'),
            _buildInfoRow('Phone', _patientData!['phoneNumber'] ?? 'Not provided'),
            _buildInfoRow('Gender', _patientData!['gender'] ?? 'Not specified'),
            _buildInfoRow('Date of Birth', _patientData!['dateOfBirth'] != null 
                ? _formatTimestamp(_patientData!['dateOfBirth'])
                : 'Not provided'),
            _buildInfoRow('Blood Group', _patientData!['bloodGroup'] ?? 'Not provided'),
            _buildInfoRow('Height', _patientData!['height'] != null 
                ? '${_patientData!['height']} cm' 
                : 'Not provided'),
            _buildInfoRow('Weight', _patientData!['weight'] != null 
                ? '${_patientData!['weight']} kg' 
                : 'Not provided'),
          ]),
          SizedBox(height: 16),
          _buildInfoSection('Medical Information', [
            _buildInfoRow('Allergies', _formatFieldValue(_patientData!['allergies'])),
            _buildInfoRow('Current Medications', _formatFieldValue(_patientData!['currentMedications'])),
            _buildInfoRow('Medical Conditions', _formatFieldValue(_patientData!['medicalConditions'])),
          ]),
          SizedBox(height: 16),
          _buildInfoSection('Emergency Contact', [
            _buildInfoRow('Name', _patientData!['emergencyContactName'] ?? 'Not provided'),
            _buildInfoRow('Phone', _patientData!['emergencyContactPhone'] ?? 'Not provided'),
            _buildInfoRow('Relationship', _patientData!['emergencyContactRelation'] ?? 'Not provided'),
          ]),
        ],
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildPatientAvatar(
              _patientData!['fullName'] ?? 'Unknown',
              _patientData!['profileImageUrl'],
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _patientData!['fullName'] ?? 'Unknown Patient',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _patientData!['email'] ?? 'No email',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Patient ID: ${widget.patientId}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryTab() {
    if (_medicalRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_information_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No medical records found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Will implement adding medical record
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: Text('Add Medical Record'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _medicalRecords.length,
      itemBuilder: (context, index) {
        final record = _medicalRecords[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record['recordType'] ?? 'Medical Record',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Text(
                      record['recordDate'] != null
                          ? _formatTimestamp(record['recordDate'])
                          : 'Unknown date',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(record['diagnosis'] ?? 'No diagnosis recorded'),
                SizedBox(height: 8),
                Text(
                  'Notes: ${record['notes'] ?? 'No notes provided'}',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsTab() {
    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No appointments found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Will implement scheduling appointment
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: Text('Schedule Appointment'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appointment['therapyType'] ?? 'Appointment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    _buildAppointmentStatusChip(appointment['status'] ?? 'scheduled'),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      appointment['appointmentDate'] != null
                          ? _formatTimestamp(appointment['appointmentDate'])
                          : 'Unknown date',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      appointment['appointmentTime'] ?? 'Unknown time',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Notes: ${appointment['notes'] ?? 'No notes provided'}',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentStatusChip(String status) {
    Color chipColor;
    IconData chipIcon;

    switch (status.toLowerCase()) {
      case 'completed':
        chipColor = Colors.green;
        chipIcon = Icons.check_circle;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        chipIcon = Icons.cancel;
        break;
      case 'rescheduled':
        chipColor = Colors.orange;
        chipIcon = Icons.schedule;
        break;
      case 'scheduled':
      default:
        chipColor = Colors.blue;
        chipIcon = Icons.event;
        break;
    }

    return Chip(
      label: Text(
        status.capitalize(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: chipColor,
      avatar: Icon(chipIcon, color: Colors.white, size: 16),
      padding: EdgeInsets.all(0),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPatientAvatar(String name, String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(imageUrl),
      );
    } else {
      return CircleAvatar(
        radius: 30,
        backgroundColor: Color(0xFF2E7D32).withOpacity(0.2),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      );
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        date = DateTime.parse(timestamp);
      } catch (e) {
        return 'Invalid date';
      }
    } else {
      return 'Invalid date';
    }
    
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _formatFieldValue(dynamic value) {
    if (value == null) return 'None recorded';
    
    if (value is List) {
      return value.isEmpty ? 'None recorded' : value.join(', ');
    } else if (value is String) {
      return value.isEmpty ? 'None recorded' : value;
    } else {
      return value.toString();
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}