import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/patient_model.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({Key? key}) : super(key: key);

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  PatientModel? _patientData;
  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _pastAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userData = await _authService.getCurrentUserData();
      if (userData is PatientModel) {
        setState(() {
          _patientData = userData;
        });
        await _fetchAppointments(userData.uid);
      } else {
        print('Current user is not a patient');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading patient data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAppointments(String patientId) async {
    try {
      // Get all appointments for this patient without complex queries requiring indexes
      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .get();

      final now = DateTime.now();
      final upcoming = <Map<String, dynamic>>[];
      final past = <Map<String, dynamic>>[];

      // Process the appointments
      for (var doc in appointmentsSnapshot.docs) {
        final appointmentData = doc.data();
        appointmentData['id'] = doc.id;
        
        // Get practitioner data
        if (appointmentData.containsKey('practitionerId')) {
          final practitionerId = appointmentData['practitionerId'];
          final practitionerDoc = await FirebaseFirestore.instance
              .collection('practitioners')
              .doc(practitionerId)
              .get();
              
          if (practitionerDoc.exists) {
            final practitionerData = practitionerDoc.data()!;
            appointmentData['practitionerName'] = practitionerData['fullName'] ?? 'Unknown Doctor';
            appointmentData['practitionerSpecialty'] = 
                practitionerData['specialties'] != null && (practitionerData['specialties'] as List).isNotEmpty
                ? (practitionerData['specialties'] as List).first
                : 'Ayurvedic Practitioner';
          }
        }

        // Categorize as upcoming or past
        // Handle different date field formats for compatibility
        DateTime appointmentDate;
        if (appointmentData.containsKey('appointmentDate') && appointmentData['appointmentDate'] is Timestamp) {
          appointmentDate = (appointmentData['appointmentDate'] as Timestamp).toDate();
        } else if (appointmentData.containsKey('dateTime') && appointmentData['dateTime'] is Timestamp) {
          appointmentDate = (appointmentData['dateTime'] as Timestamp).toDate();
        } else if (appointmentData.containsKey('date') && appointmentData['date'] is Timestamp) {
          appointmentDate = (appointmentData['date'] as Timestamp).toDate();
        } else {
          // Fallback to string date if timestamp is not available
          try {
            String dateStr = appointmentData['dateStr'] ?? 
                            appointmentData['date']?.toString() ?? 
                            DateFormat('yyyy-MM-dd').format(DateTime.now());
            appointmentDate = DateFormat('yyyy-MM-dd').parse(dateStr);
          } catch (e) {
            print('Error parsing date: $e');
            appointmentDate = DateTime.now(); // Default fallback
          }
        }
        
        if (appointmentDate.isAfter(now) || appointmentDate.day == now.day) {
          upcoming.add(appointmentData);
        } else {
          past.add(appointmentData);
        }
      }

      // Sort upcoming by date ascending and past by date descending
      upcoming.sort((a, b) {
        DateTime getDate(Map<String, dynamic> data) {
          if (data.containsKey('appointmentDate') && data['appointmentDate'] is Timestamp) {
            return (data['appointmentDate'] as Timestamp).toDate();
          } else if (data.containsKey('dateTime') && data['dateTime'] is Timestamp) {
            return (data['dateTime'] as Timestamp).toDate();
          } else if (data.containsKey('date') && data['date'] is Timestamp) {
            return (data['date'] as Timestamp).toDate();
          } else {
            try {
              String dateStr = data['dateStr'] ?? 
                              data['date']?.toString() ?? 
                              DateFormat('yyyy-MM-dd').format(DateTime.now());
              return DateFormat('yyyy-MM-dd').parse(dateStr);
            } catch (e) {
              return DateTime.now(); // Default fallback
            }
          }
        }
        
        return getDate(a).compareTo(getDate(b));
      });

      past.sort((a, b) {
        DateTime getDate(Map<String, dynamic> data) {
          if (data.containsKey('appointmentDate') && data['appointmentDate'] is Timestamp) {
            return (data['appointmentDate'] as Timestamp).toDate();
          } else if (data.containsKey('dateTime') && data['dateTime'] is Timestamp) {
            return (data['dateTime'] as Timestamp).toDate();
          } else if (data.containsKey('date') && data['date'] is Timestamp) {
            return (data['date'] as Timestamp).toDate();
          } else {
            try {
              String dateStr = data['dateStr'] ?? 
                              data['date']?.toString() ?? 
                              DateFormat('yyyy-MM-dd').format(DateTime.now());
              return DateFormat('yyyy-MM-dd').parse(dateStr);
            } catch (e) {
              return DateTime.now(); // Default fallback
            }
          }
        }
        
        return getDate(b).compareTo(getDate(a)); // Descending order for past
      });

      setState(() {
        _upcomingAppointments = upcoming;
        _pastAppointments = past;
      });
    } catch (e) {
      print('Error fetching appointments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'My Appointments',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : TabBarView(
              controller: _tabController,
              children: [
                // Upcoming Appointments Tab
                _upcomingAppointments.isEmpty
                    ? _buildEmptyState('No upcoming appointments', 'Schedule an appointment with a practitioner to get started')
                    : _buildAppointmentsList(_upcomingAppointments, isUpcoming: true),
                
                // Past Appointments Tab
                _pastAppointments.isEmpty
                    ? _buildEmptyState('No past appointments', 'Your completed appointments will appear here')
                    : _buildAppointmentsList(_pastAppointments, isUpcoming: false),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to book appointment screen
        },
        backgroundColor: Color(0xFF2E7D32),
        child: Icon(Icons.add),
        tooltip: 'Book Appointment',
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          if (title.contains('upcoming'))
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Book Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                // Navigate to find practitioners screen to select a practitioner for booking
                Navigator.pushNamed(context, '/consulting');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(List<Map<String, dynamic>> appointments, {required bool isUpcoming}) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment, isUpcoming: isUpcoming);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, {required bool isUpcoming}) {
    // Get appointment date from any available field
    DateTime appointmentDate;
    final now = DateTime.now();
    
    // First try to get the date from the stored formatted date if available
    if (appointment.containsKey('formattedDate') && appointment['formattedDate'] != null) {
      // If we have a pre-formatted date string, use it directly later
      appointmentDate = now; // Default to today, but we'll use formattedDate directly
    }
    // Then try various timestamp fields
    else if (appointment.containsKey('appointmentDate') && appointment['appointmentDate'] is Timestamp) {
      appointmentDate = (appointment['appointmentDate'] as Timestamp).toDate();
    } else if (appointment.containsKey('dateTime') && appointment['dateTime'] is Timestamp) {
      appointmentDate = (appointment['dateTime'] as Timestamp).toDate();
    } else if (appointment.containsKey('date') && appointment['date'] is Timestamp) {
      appointmentDate = (appointment['date'] as Timestamp).toDate();
    } else {
      // Fallback to string date if timestamp is not available
      try {
        String dateStr = appointment['dateStr'] ?? 
                      appointment['date']?.toString() ?? 
                      DateFormat('yyyy-MM-dd').format(now);
        appointmentDate = DateFormat('yyyy-MM-dd').parse(dateStr);
      } catch (e) {
        print('Error parsing date: $e');
        appointmentDate = now; // Default fallback
      }
    }
    
    // Check if appointment is today
    final isToday = appointmentDate.day == now.day && 
                   appointmentDate.month == now.month && 
                   appointmentDate.year == now.year;
                   
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');
    
    // Use pre-formatted date if available, otherwise format the date
    final formattedDate = appointment.containsKey('formattedDate') ? 
                         appointment['formattedDate'] :
                         isToday ? 'Today' : dateFormatter.format(appointmentDate);
    // Get the time from the dedicated time field if available, otherwise format from date
    final formattedTime = appointment.containsKey('time') && appointment['time'] != null ?
                        appointment['time'] :
                        timeFormatter.format(appointmentDate);
    
    final appointmentType = appointment['therapyType'] ?? 'Consultation';
    final practitionerName = appointment['practitionerName'] ?? 'Dr. Unknown';
    final practitionerSpecialty = appointment['practitionerSpecialty'] ?? 'Ayurvedic Practitioner';
    final status = appointment['status'] ?? 'scheduled';
    
    // Determine card color based on status and time
    Color statusColor;
    String statusText;
    
    if (isUpcoming) {
      if (isToday) {
        statusColor = Colors.amber;
        statusText = 'Today';
      } else {
        statusColor = Color(0xFF2E7D32);
        statusText = 'Upcoming';
      }
    } else {
      if (status.toLowerCase() == 'completed') {
        statusColor = Colors.blue;
        statusText = 'Completed';
      } else if (status.toLowerCase() == 'cancelled') {
        statusColor = Colors.red;
        statusText = 'Cancelled';
      } else {
        statusColor = Colors.grey;
        statusText = 'Missed';
      }
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isToday ? Icons.today : Icons.event,
                      color: statusColor,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF2E7D32).withOpacity(0.1),
                      child: Icon(
                        Icons.medical_services,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointmentType,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'at $formattedTime',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '$practitionerName | $practitionerSpecialty',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Action buttons
                if (isUpcoming)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.edit_calendar),
                          label: Text('Reschedule'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF2E7D32),
                            side: BorderSide(color: Color(0xFF2E7D32)),
                          ),
                          onPressed: () {
                            // Handle reschedule
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.cancel_outlined),
                          label: Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                          ),
                          onPressed: () {
                            // Handle cancel
                          },
                        ),
                      ),
                    ],
                  )
                else if (status.toLowerCase() == 'completed')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.feedback_outlined),
                          label: Text('Feedback'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: BorderSide(color: Colors.blue),
                          ),
                          onPressed: () {
                            // Handle feedback
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.restore),
                          label: Text('Book Again'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF2E7D32),
                            side: BorderSide(color: Color(0xFF2E7D32)),
                          ),
                          onPressed: () {
                            // Handle book again
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}