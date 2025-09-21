import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/practitioner_model.dart';
import '../../services/auth_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final PractitionerModel practitioner;
  final String?
  patientId; // Optional patient ID to use when Firebase Auth fails

  const BookAppointmentScreen({
    Key? key,
    required this.practitioner,
    this.patientId,
  }) : super(key: key);

  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final AuthService _authService = AuthService();

  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay(hour: 10, minute: 0);

  String? _selectedSpecialty;
  List<String> _availableTimeSlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize the selected specialty with the first specialty from the practitioner
    if (widget.practitioner.specialties != null &&
        widget.practitioner.specialties!.isNotEmpty) {
      _selectedSpecialty = widget.practitioner.specialties!.first;
    } else {
      _selectedSpecialty = 'General Consultation';
    }

    // Calculate available time slots
    _calculateAvailableTimeSlots();
  }

  void _calculateAvailableTimeSlots() {
    // Example time slots - in a real app, this would fetch from the practitioner's availability
    _availableTimeSlots = [
      '9:00 AM',
      '10:00 AM',
      '11:00 AM',
      '2:00 PM',
      '3:00 PM',
      '4:00 PM',
    ];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF2E7D32),
            colorScheme: ColorScheme.light(primary: Color(0xFF2E7D32)),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF2E7D32),
            colorScheme: ColorScheme.light(primary: Color(0xFF2E7D32)),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _bookAppointment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to get patient ID from multiple sources
      String? patientId;
      String patientName = 'Patient';
      String patientEmail = '';

      // First try from widget parameter
      if (widget.patientId != null && widget.patientId!.isNotEmpty) {
        patientId = widget.patientId;

        // Try to get patient details from Firestore
        try {
          final patientDoc = await FirebaseFirestore.instance
              .collection('patients')
              .doc(patientId)
              .get();

          if (patientDoc.exists) {
            final data = patientDoc.data()!;
            patientName = data['fullName'] ?? 'Patient';
            patientEmail = data['email'] ?? '';
          }
        } catch (e) {
          print("Error loading patient details: $e");
        }
      }

      // If not found, try Firebase Auth
      if (patientId == null) {
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          patientId = currentUser.uid;
          patientName = currentUser.displayName ?? 'Patient';
          patientEmail = currentUser.email ?? '';
        }
      }

      // If still not found, use a generated ID as last resort
      if (patientId == null) {
        // For demo purposes - in production you'd want proper authentication
        patientId = 'patient-${DateTime.now().millisecondsSinceEpoch}';

        // Create a temporary patient entry
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .set({
              'uid': patientId,
              'email': 'guest@example.com',
              'fullName': 'Guest Patient',
              'role': 'patient',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        patientName = 'Guest Patient';
        patientEmail = 'guest@example.com';
      }

      // Format date and time
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create appointment data with standardized fields to ensure consistent querying
      final appointmentData = {
        'patientId': patientId,
        'practitionerId': widget.practitioner.uid,
        'practitionerName': widget.practitioner.fullName,
        'patientName': patientName,
        'patientEmail': patientEmail,
        // Store dates in multiple formats to ensure compatibility with existing queries
        'appointmentDate': appointmentDateTime, // Timestamp for UI display
        'dateTime': appointmentDateTime, // Alias used by some queries
        'date': appointmentDateTime, // Simple date field for basic queries
        'dateStr': DateFormat(
          'yyyy-MM-dd',
        ).format(appointmentDateTime), // String date for text-based filtering
        'formattedDate': DateFormat(
          'EEEE, MMMM d, yyyy',
        ).format(appointmentDateTime), // For UI display
        'time': '${_selectedTime.format(context)}',
        'therapyType': _selectedSpecialty ?? 'General Consultation',
        'status': 'scheduled',
        'notes': '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      final appointmentRef = await FirebaseFirestore.instance
          .collection('appointments')
          .add(appointmentData);

      // Store the current patient ID in session data for future reference
      try {
        await FirebaseFirestore.instance
            .collection('system_preferences')
            .doc('active_sessions')
            .set({
              'last_patient_id': patientId,
              'last_appointment_id': appointmentRef.id,
              'last_activity': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (e) {
        print('Error storing session data: $e');
      }

      // Log appointment data for debugging
      print("Appointment booked successfully with data:");
      print("Patient ID: $patientId");
      print("Patient Name: $patientName");
      print("Appointment ID: ${appointmentRef.id}");
      print("Date: ${DateFormat('yyyy-MM-dd').format(appointmentDateTime)}");
      print("Time: ${_selectedTime.format(context)}");

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Allow some time for data to sync before popping
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted)
          Navigator.of(context).pop(true); // Return true to indicate success
      });
    } catch (e) {
      print('Error booking appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book appointment. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Appointment'),
        backgroundColor: Color(0xFF2E7D32),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Practitioner info card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Color(0xFF2E7D32).withOpacity(0.1),
                            child: widget.practitioner.profileImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.network(
                                      widget.practitioner.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      width: 60,
                                      height: 60,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Color(0xFF2E7D32),
                                          ),
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Color(0xFF2E7D32),
                                  ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.practitioner.fullName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children:
                                      widget.practitioner.specialties == null ||
                                          widget
                                              .practitioner
                                              .specialties!
                                              .isEmpty
                                      ? [
                                          Chip(
                                            label: Text(
                                              'Ayurvedic Practitioner',
                                            ),
                                            backgroundColor: Colors.green
                                                .withOpacity(0.1),
                                            labelStyle: TextStyle(
                                              color: Colors.green[800],
                                            ),
                                          ),
                                        ]
                                      : widget.practitioner.specialties!.map((
                                          specialty,
                                        ) {
                                          return Chip(
                                            label: Text(specialty),
                                            backgroundColor: Colors.green
                                                .withOpacity(0.1),
                                            labelStyle: TextStyle(
                                              color: Colors.green[800],
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            labelPadding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                          );
                                        }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Specialty selection
                  Text(
                    'Select Therapy Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSpecialty,
                        isExpanded: true,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        items: [
                          ...(widget.practitioner.specialties != null
                              ? widget.practitioner.specialties!.map(
                                  (specialty) => DropdownMenuItem<String>(
                                    value: specialty,
                                    child: Text(specialty),
                                  ),
                                )
                              : []),
                          DropdownMenuItem<String>(
                            value: 'General Consultation',
                            child: Text('General Consultation'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSpecialty = value;
                          });
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Date selection
                  Text(
                    'Select Date',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                          SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'EEEE, MMMM d, yyyy',
                            ).format(_selectedDate),
                            style: TextStyle(fontSize: 16),
                          ),
                          Spacer(),
                          Icon(Icons.arrow_drop_down, color: Color(0xFF2E7D32)),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Time selection
                  Text(
                    'Select Time',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectTime(context),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Color(0xFF2E7D32)),
                          SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: TextStyle(fontSize: 16),
                          ),
                          Spacer(),
                          Icon(Icons.arrow_drop_down, color: Color(0xFF2E7D32)),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Book button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _bookAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Confirm Appointment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
