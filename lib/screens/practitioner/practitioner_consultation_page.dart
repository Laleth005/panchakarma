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

class PractitionerConsultationPage extends StatefulWidget {
  const PractitionerConsultationPage({Key? key}) : super(key: key);

  @override
  _PractitionerConsultationPageState createState() => _PractitionerConsultationPageState();
}

class _PractitionerConsultationPageState extends State<PractitionerConsultationPage> {
  final String? currentPractitionerId = FirebaseAuth.instance.currentUser?.uid;
  String _selectedFilter = 'pending'; // pending, confirmed, completed, all

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
          title: Text('Consultation Requests',
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
        ),
        body: Column(
          children: [
            _buildFilterTabs(),
            Expanded(
              child: _buildConsultationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterTab('pending', 'Pending', Icons.schedule),
          _buildFilterTab('confirmed', 'Confirmed', Icons.check_circle_outline),
          _buildFilterTab('completed', 'Completed', Icons.check_circle),
          _buildFilterTab('all', 'All', Icons.list),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primaryGreen,
                size: 20,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getConsultationStream(),
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
                  'Error loading consultations',
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
                    Icons.event_note,
                    size: 60,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'No consultations found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _getEmptyMessage(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
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
            
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('patients')
                  .doc(consultationData['patientId'])
                  .get(),
              builder: (context, patientSnapshot) {
                if (patientSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingCard();
                }
                
                Map<String, dynamic> patientData = {};
                if (patientSnapshot.hasData && patientSnapshot.data!.exists) {
                  patientData = patientSnapshot.data!.data() as Map<String, dynamic>;
                } else {
                  // If patient data not found, try to use embedded patient data in consultation
                  patientData = {
                    'fullName': consultationData['patientName'] ?? 'Unknown Patient',
                    'age': consultationData['patientAge'] ?? 'N/A',
                    'gender': consultationData['patientGender'] ?? 'Not specified',
                    'phoneNumber': consultationData['patientPhone'] ?? '',
                    'email': consultationData['patientEmail'] ?? '',
                    'address': consultationData['patientAddress'] ?? '',
                  };
                }
                
                return _buildConsultationCard(consultationData, patientData);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
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
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getConsultationStream() {
    Query query;

    // Apply status filter
    if (_selectedFilter == 'confirmed') {
      // For confirmed consultations, fetch from confirmedConsultations collection
      query = FirebaseFirestore.instance
          .collection('confirmedConsultations')
          .where('practitionerId', isEqualTo: currentPractitionerId)
          .where('status', isEqualTo: 'confirmed')
          .orderBy('confirmedAt', descending: true);
    } else if (_selectedFilter == 'completed') {
      // For completed consultations, fetch from confirmedConsultations with completed status
      query = FirebaseFirestore.instance
          .collection('confirmedConsultations')
          .where('practitionerId', isEqualTo: currentPractitionerId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true);
    } else if (_selectedFilter == 'pending') {
      // For pending consultations, fetch from consultations with pending status
      query = FirebaseFirestore.instance
          .collection('consultations')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true);
    } else {
      // For all consultations, show pending consultations from consultations collection
      // Note: To show truly all consultations, you would need to combine streams
      query = FirebaseFirestore.instance
          .collection('consultations')
          .where('status', whereIn: ['pending', 'confirmed', 'completed', 'rejected'])
          .orderBy('createdAt', descending: true);
    }

    return query.snapshots();
  }

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 'pending':
        return 'No pending consultation requests';
      case 'confirmed':
        return 'No confirmed appointments';
      case 'completed':
        return 'No completed consultations';
      default:
        return 'No consultation requests available';
    }
  }

  Widget _buildConsultationCard(Map<String, dynamic> consultationData, Map<String, dynamic> patientData) {
    final status = consultationData['status'] ?? 'pending';
    final patientName = patientData['fullName'] ?? patientData['name'] ?? 'Unknown Patient';
    final age = patientData['age'] ?? 'N/A';
    final gender = patientData['gender'] ?? 'Not specified';
    final phoneNumber = patientData['phoneNumber'] ?? consultationData['phoneNumber'] ?? '';
    final email = patientData['email'] ?? '';
    final address = patientData['address'] ?? '';
    
    // Consultation specific data
    final healthCondition = consultationData['healthCondition'] ?? 'Not specified';
    final symptoms = consultationData['symptoms'] ?? '';
    final duration = consultationData['duration'] ?? '';
    final severity = consultationData['severity'] ?? '';
    final previousTreatment = consultationData['previousTreatment'] ?? '';
    final additionalNotes = consultationData['additionalNotes'] ?? '';
    final preferredDate = consultationData['preferredDate'] as Timestamp?;
    final preferredTime = consultationData['preferredTime'] ?? '';
    final createdAt = consultationData['createdAt'] as Timestamp?;
    final urgency = consultationData['urgency'] ?? 'normal';

    // For confirmed consultations
    final confirmedDate = consultationData['confirmedDate'] as Timestamp?;
    final confirmedTime = consultationData['confirmedTime'] ?? '';
    final practitionerNotes = consultationData['practitionerNotes'] ?? '';

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
                            child: Icon(Icons.person,
                              color: AppColors.primaryGreen, size: 20),
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
           
            // Urgency indicator for pending consultations
            if (urgency != 'normal' && status == 'pending') ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: urgency == 'urgent' ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: urgency == 'urgent' ? Colors.red : Colors.orange,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      urgency == 'urgent' ? Icons.priority_high : Icons.warning,
                      color: urgency == 'urgent' ? Colors.red : Colors.orange,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      urgency.toUpperCase(),
                      style: TextStyle(
                        color: urgency == 'urgent' ? Colors.red : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
           
            SizedBox(height: 16),
           
            // Health condition section
            _buildInfoSection(
              'Health Condition',
              healthCondition,
              Icons.health_and_safety_outlined,
            ),
           
            if (symptoms.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildInfoSection(
                'Symptoms',
                symptoms,
                Icons.sick_outlined,
                maxLines: 3,
              ),
            ],

            if (duration.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildInfoSection(
                'Duration',
                duration,
                Icons.access_time_outlined,
              ),
            ],

            if (severity.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildInfoSection(
                'Severity',
                severity,
                Icons.thermostat_outlined,
              ),
            ],

            if (previousTreatment.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildInfoSection(
                'Previous Treatment',
                previousTreatment,
                Icons.medical_services_outlined,
                maxLines: 2,
              ),
            ],
           
            // Contact info
            SizedBox(height: 16),
            Row(
              children: [
                if (phoneNumber.isNotEmpty)
                  Expanded(
                    child: _buildInfoChip(
                      Icons.phone,
                      'Phone',
                      phoneNumber,
                    ),
                  ),
                if (phoneNumber.isNotEmpty && email.isNotEmpty)
                  SizedBox(width: 12),
                if (email.isNotEmpty)
                  Expanded(
                    child: _buildInfoChip(
                      Icons.email,
                      'Email',
                      email,
                    ),
                  ),
              ],
            ),

            if (address.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildInfoSection(
                'Address',
                address,
                Icons.location_on_outlined,
                maxLines: 2,
              ),
            ],
           
            // Preferred date and time for pending consultations
            if (status == 'pending') ...[
              SizedBox(height: 12),
              Row(
                children: [
                  if (preferredDate != null)
                    Expanded(
                      child: _buildInfoChip(
                        Icons.calendar_today,
                        'Preferred Date',
                        '${preferredDate.toDate().day}/${preferredDate.toDate().month}/${preferredDate.toDate().year}',
                      ),
                    ),
                  if (preferredDate != null && preferredTime.isNotEmpty)
                    SizedBox(width: 12),
                  if (preferredTime.isNotEmpty)
                    Expanded(
                      child: _buildInfoChip(
                        Icons.schedule,
                        'Preferred Time',
                        preferredTime,
                      ),
                    ),
                ],
              ),
            ],

            // Confirmed date and time for confirmed/completed consultations
            if ((status == 'confirmed' || status == 'completed') && confirmedDate != null) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.calendar_today,
                      'Appointment Date',
                      '${confirmedDate.toDate().day}/${confirmedDate.toDate().month}/${confirmedDate.toDate().year}',
                    ),
                  ),
                  if (confirmedTime.isNotEmpty) ...[
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.schedule,
                        'Appointment Time',
                        confirmedTime,
                      ),
                    ),
                  ],
                ],
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

            if (practitionerNotes.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildInfoSection(
                'Practitioner Notes',
                practitionerNotes,
                Icons.medical_information_outlined,
                maxLines: 3,
              ),
            ],
           
            // Action buttons
            SizedBox(height: 20),
            _buildActionButtons(consultationData, patientData),
           
            // Creation/confirmation timestamp
            SizedBox(height: 12),
            if (createdAt != null && status == 'pending')
              Text(
                'Submitted on ${_formatDateTime(createdAt.toDate())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (consultationData['confirmedAt'] != null && (status == 'confirmed' || status == 'completed'))
              Text(
                'Confirmed on ${_formatDateTime((consultationData['confirmedAt'] as Timestamp).toDate())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (consultationData['completedAt'] != null && status == 'completed')
              Text(
                'Completed on ${_formatDateTime((consultationData['completedAt'] as Timestamp).toDate())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon, {int maxLines = 1}) {
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

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
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
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
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

  Widget _buildActionButtons(Map<String, dynamic> consultationData, Map<String, dynamic> patientData) {
    final status = consultationData['status'] ?? 'pending';
    final consultationId = consultationData['consultationId'];

    if (status == 'pending') {
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
              label: Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showConfirmDialog(consultationData, patientData),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.check, size: 18),
              label: Text('Confirm', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    } else if (status == 'confirmed') {
      return ElevatedButton.icon(
        onPressed: () => _markAsCompleted(consultationData['consultationId']),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightGreen,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          minimumSize: Size(double.infinity, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(Icons.check_circle, size: 18),
        label: Text('Mark as Completed', style: TextStyle(fontWeight: FontWeight.w600)),
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

  void _showConfirmDialog(Map<String, dynamic> consultationData, Map<String, dynamic> patientData) {
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
                    child: Icon(Icons.schedule, color: AppColors.primaryGreen, size: 20),
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
                    Text(
                      'Patient: ${patientData['fullName'] ?? patientData['name'] ?? 'Unknown Patient'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGreen,
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
                                lastDate: DateTime.now().add(Duration(days: 60)),
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
                                border: Border.all(color: AppColors.accentGreen),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                    color: AppColors.primaryGreen, size: 20),
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
                                border: Border.all(color: AppColors.accentGreen),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time,
                                    color: AppColors.primaryGreen, size: 20),
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
                        hintText: 'Add any notes or instructions for the patient...',
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
                    _confirmConsultation(consultationData, patientData, selectedDate, selectedTime, notesController.text.trim());
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

  Future<void> _confirmConsultation(Map<String, dynamic> consultationData, Map<String, dynamic> patientData, DateTime date, TimeOfDay time, String practitionerNotes) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
                SizedBox(width: 20),
                Text('Confirming appointment...'),
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

      // Create confirmed consultation document
      await FirebaseFirestore.instance
          .collection('confirmedConsultations')
          .add({
        // Consultation data
        'consultationId': consultationData['consultationId'],
        'patientId': consultationData['patientId'],
        'practitionerId': currentPractitionerId,
        'status': 'confirmed',
        
        // Patient information
        'patientName': patientData['fullName'] ?? patientData['name'] ?? 'Unknown Patient',
        'patientAge': patientData['age'] ?? 'N/A',
        'patientGender': patientData['gender'] ?? 'Not specified',
        'patientPhone': patientData['phoneNumber'] ?? consultationData['phoneNumber'] ?? '',
        'patientEmail': patientData['email'] ?? consultationData['email'] ?? '',
        'patientAddress': patientData['address'] ?? consultationData['address'] ?? '',
        
        // Practitioner information
        'practitionerName': practitionerInfo['fullName'] ?? practitionerInfo['name'] ?? 'Unknown Practitioner',
        'practitionerSpecialization': practitionerInfo['specialization'] ?? '',
        'practitionerExperience': practitionerInfo['experience'] ?? '',
        'practitionerPhone': practitionerInfo['phoneNumber'] ?? '',
        'practitionerEmail': practitionerInfo['email'] ?? '',
        
        // Consultation details
        'healthCondition': consultationData['healthCondition'] ?? '',
        'symptoms': consultationData['symptoms'] ?? '',
        'duration': consultationData['duration'] ?? '',
        'severity': consultationData['severity'] ?? '',
        'previousTreatment': consultationData['previousTreatment'] ?? '',
        'additionalNotes': consultationData['additionalNotes'] ?? '',
        'urgency': consultationData['urgency'] ?? 'normal',
        
        // Original request details
        'originalPreferredDate': consultationData['preferredDate'],
        'originalPreferredTime': consultationData['preferredTime'] ?? '',
        'originalCreatedAt': consultationData['createdAt'],
        
        // Confirmed appointment details
        'confirmedDate': Timestamp.fromDate(date),
        'confirmedTime': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        'practitionerNotes': practitionerNotes,
        'confirmedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      // Update original consultation status
      await FirebaseFirestore.instance
          .collection('consultations')
          .doc(consultationData['consultationId'])
          .update({
        'status': 'confirmed',
        'confirmedBy': currentPractitionerId,
        'confirmedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Appointment confirmed successfully!')),
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
              Expanded(child: Text('Error confirming appointment. Please try again.')),
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
              Text(
                'Reject Consultation',
                style: TextStyle(color: AppColors.darkGreen),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to reject this consultation request? This action cannot be undone.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
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
              child: Text('Reject'),
            ),
          ],
        );
      },
    );

    if (shouldReject == true) {
      try {
        await FirebaseFirestore.instance
            .collection('consultations')
            .doc(consultationId)
            .update({
          'status': 'rejected',
          'rejectedBy': currentPractitionerId,
          'rejectedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('Consultation request rejected'),
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
                child: Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20),
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
                  hintText: 'Add treatment summary, recommendations, follow-up instructions...',
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
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
        // Update the confirmed consultation document
        QuerySnapshot confirmedDocs = await FirebaseFirestore.instance
            .collection('confirmedConsultations')
            .where('consultationId', isEqualTo: consultationId)
            .where('practitionerId', isEqualTo: currentPractitionerId)
            .get();

        if (confirmedDocs.docs.isNotEmpty) {
          await confirmedDocs.docs.first.reference.update({
            'status': 'completed',
            'completionNotes': completionNotesController.text.trim(),
            'completedAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });
        }

        // Also update the original consultation
        await FirebaseFirestore.instance
            .collection('consultations')
            .doc(consultationId)
            .update({
          'status': 'completed',
          'completedBy': currentPractitionerId,
          'completedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Consultation marked as completed'),
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