import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
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
  
  // Helper method to extract DateTime from appointment data
  DateTime? _getAppointmentDate(Map<String, dynamic> appointment) {
    if (appointment.containsKey('appointmentDate') && appointment['appointmentDate'] is Timestamp) {
      return (appointment['appointmentDate'] as Timestamp).toDate();
    } else if (appointment.containsKey('dateTime') && appointment['dateTime'] is Timestamp) {
      return (appointment['dateTime'] as Timestamp).toDate();
    } else if (appointment.containsKey('date') && appointment['date'] is Timestamp) {
      return (appointment['date'] as Timestamp).toDate();
    } else {
      try {
        String dateStr = appointment['dateStr'] ?? appointment['date']?.toString() ?? '';
        if (dateStr.isNotEmpty) {
          return intl.DateFormat('yyyy-MM-dd').parse(dateStr);
        }
      } catch (e) {
        print('Error parsing date string: $e');
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appointments',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF2E7D32),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsList('upcoming'),
          _buildAppointmentsList('past'),
          _buildAppointmentsList('cancelled'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create appointment screen
        },
        backgroundColor: Color(0xFF2E7D32),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppointmentsList(String type) {
    // Get all appointments for this practitioner without complex queries requiring indexes
    final query = _firestore.collection('appointments')
        .where('practitionerId', isEqualTo: _auth.currentUser?.uid);
    
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading appointments: ${snapshot.error}'));
        }

        final allAppointments = snapshot.data?.docs ?? [];
        if (allAppointments.isEmpty) {
          return _buildEmptyState(type);
        }
        
        // Filter and sort appointments in memory based on type
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // Filter appointments based on type
        final filteredAppointments = allAppointments.where((doc) {
          final appointmentData = doc.data() as Map<String, dynamic>;
          final status = appointmentData['status'] as String? ?? 'scheduled';
          
          // Get the appointment date
          final appointmentDate = _getAppointmentDate(appointmentData);
          if (appointmentDate == null) return false;
          
          if (type == 'upcoming') {
            // Show scheduled appointments from today onwards
            return status == 'scheduled' && (appointmentDate.isAfter(now) || 
                   appointmentDate.year == today.year && 
                   appointmentDate.month == today.month && 
                   appointmentDate.day == today.day);
          } else if (type == 'past') {
            // Show completed appointments or past scheduled ones
            return status == 'completed' || 
                  (status == 'scheduled' && appointmentDate.isBefore(today));
          } else if (type == 'cancelled') {
            return status == 'cancelled';
          }
          return false;
        }).toList();
        
        // Sort appointments
        if (type == 'upcoming') {
          filteredAppointments.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            
            final aDate = _getAppointmentDate(aData);
            final bDate = _getAppointmentDate(bData);
            
            if (aDate == null || bDate == null) return 0;
            return aDate.compareTo(bDate); // Ascending for upcoming
          });
        } else {
          filteredAppointments.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            
            final aDate = _getAppointmentDate(aData);
            final bDate = _getAppointmentDate(bData);
            
            if (aDate == null || bDate == null) return 0;
            return bDate.compareTo(aDate); // Descending for past/cancelled
          });
        }
        
        if (filteredAppointments.isEmpty) {
          return _buildEmptyState(type);
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filteredAppointments.length,
          itemBuilder: (context, index) {
            final appointment = filteredAppointments[index].data() as Map<String, dynamic>;
            
            // Get formatted date using multiple possible fields
            String formattedDate = 'No date';
            if (appointment.containsKey('formattedDate') && appointment['formattedDate'] != null) {
              formattedDate = appointment['formattedDate'];
            } else {
              DateTime? date = _getAppointmentDate(appointment);
              if (date != null) {
                final formatter = intl.DateFormat('MMM d, yyyy');
                formattedDate = formatter.format(date);
              }
            }
            
            // Use the time field if available, otherwise extract from date
            String timeStr = appointment['time'] ?? 'No time set';
            
            return _buildAppointmentCard(
              appointment['patientName'] ?? 'Unknown Patient',
              appointment['therapyType'] ?? 'General Consultation',
              formattedDate,
              timeStr,
              appointment['status'] ?? 'scheduled',
              filteredAppointments[index].id,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String type) {
    IconData icon;
    String message;

    switch (type) {
      case 'upcoming':
        icon = Icons.event_available;
        message = 'No upcoming appointments';
        break;
      case 'past':
        icon = Icons.history;
        message = 'No past appointments';
        break;
      case 'cancelled':
        icon = Icons.cancel;
        message = 'No cancelled appointments';
        break;
      default:
        icon = Icons.calendar_today;
        message = 'No appointments found';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24),
          if (type == 'upcoming')
            ElevatedButton(
              onPressed: () {
                // Navigate to create appointment
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Create New Appointment'),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
    String patientName,
    String therapyType,
    String date,
    String time,
    String status,
    String appointmentId,
  ) {
    Color statusColor;
    switch (status) {
      case 'scheduled':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    patientName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.capitalize(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.medical_services, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  therapyType,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (status == 'scheduled')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _updateAppointmentStatus(appointmentId, 'cancelled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _updateAppointmentStatus(appointmentId, 'completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Complete'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment ${status.capitalize()}'),
          backgroundColor: status == 'completed' ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}