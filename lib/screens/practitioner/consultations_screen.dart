import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/practitioner_model.dart';

class ConsultationsScreen extends StatefulWidget {
  final String practitionerId;
  
  const ConsultationsScreen({Key? key, required this.practitionerId}) : super(key: key);

  @override
  _ConsultationsScreenState createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen> {
  List<Map<String, dynamic>> _consultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('practitionerId', isEqualTo: widget.practitionerId)
          .where('status', isEqualTo: 'confirmed')
          .orderBy('appointmentDateTime', descending: true)
          .get();

      List<Map<String, dynamic>> consultations = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> consultation = doc.data() as Map<String, dynamic>;
        consultation['id'] = doc.id;
        consultations.add(consultation);
      }

      setState(() {
        _consultations = consultations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading consultations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : _consultations.isEmpty
              ? _buildEmptyState()
              : _buildConsultationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Consultations Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your consultations will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _consultations.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> consultation = _consultations[index];
        return _buildConsultationCard(consultation);
      },
    );
  }

  Widget _buildConsultationCard(Map<String, dynamic> consultation) {
    DateTime appointmentDate;
    if (consultation['appointmentDateTime'] is Timestamp) {
      appointmentDate = (consultation['appointmentDateTime'] as Timestamp).toDate();
    } else {
      appointmentDate = DateTime.parse(consultation['appointmentDateTime'].toString());
    }

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Patient: ${consultation['patientName'] ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[800],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Confirmed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 16),
                Icon(Icons.access_time, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  consultation['appointmentTime'] ?? '',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            if (consultation['healthCondition'] != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.medical_services, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Condition: ${consultation['healthCondition']}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _viewDetails(consultation),
                  child: Text('View Details'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _markCompleted(consultation['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Mark Completed'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewDetails(Map<String, dynamic> consultation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Consultation Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: ${consultation['patientName'] ?? 'Unknown'}'),
            SizedBox(height: 8),
            Text('Condition: ${consultation['healthCondition'] ?? 'Not specified'}'),
            SizedBox(height: 8),
            if (consultation['conditionDescription'] != null)
              Text('Description: ${consultation['conditionDescription']}'),
            if (consultation['additionalNotes'] != null)
              Text('Notes: ${consultation['additionalNotes']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _markCompleted(String consultationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(consultationId)
          .update({'status': 'completed'});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Consultation marked as completed'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadConsultations(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update consultation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}