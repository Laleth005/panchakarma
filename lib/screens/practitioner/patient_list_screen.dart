import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/patient_model.dart';
import 'patient_progress_report.dart';

class PatientListScreen extends StatefulWidget {
  final String? practitionerId;
  final bool forProgressReport;

  const PatientListScreen({
    Key? key, 
    this.practitionerId, 
    this.forProgressReport = false
  }) : super(key: key);

  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  bool _isLoading = true;
  List<PatientModel> _patients = [];
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    try {
      Query query = FirebaseFirestore.instance.collection('patients');
      
      // If practitioner ID is provided, only load their patients
      if (widget.practitionerId != null) {
        query = query.where('primaryPractitionerId', isEqualTo: widget.practitionerId);
      }
      
      final snapshot = await query.get();
      
      List<PatientModel> patients = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        
        // Handle timestamps
        DateTime createdAt = DateTime.now();
        DateTime updatedAt = DateTime.now();
        
        if (data.containsKey('createdAt') && data['createdAt'] != null) {
          if (data['createdAt'] is Timestamp) {
            createdAt = (data['createdAt'] as Timestamp).toDate();
          }
        }
        
        if (data.containsKey('updatedAt') && data['updatedAt'] != null) {
          if (data['updatedAt'] is Timestamp) {
            updatedAt = (data['updatedAt'] as Timestamp).toDate();
          }
        }
        
        final patient = PatientModel(
          uid: doc.id,
          email: data['email'] as String? ?? '',
          fullName: data['fullName'] as String? ?? 'Patient',
          createdAt: createdAt,
          updatedAt: updatedAt,
          // Optional fields
          dateOfBirth: data['dateOfBirth'] as String?,
          gender: data['gender'] as String?,
          address: data['address'] as String?,
          phoneNumber: data['phoneNumber'] as String?,
          medicalHistory: data['medicalHistory'] as String?,
          allergies: data['allergies'] as String?,
          doshaType: data['doshaType'] as String?,
          profileImageUrl: data['profileImageUrl'] as String?,
          primaryPractitionerId: data['primaryPractitionerId'] as String?,
        );
        
        patients.add(patient);
      }
      
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading patients: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  List<PatientModel> get _filteredPatients {
    if (_searchQuery.isEmpty) {
      return _patients;
    }
    
    return _patients.where((patient) {
      final fullName = patient.fullName.toLowerCase();
      final email = patient.email.toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return fullName.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.forProgressReport ? 'Select Patient for Progress Report' : 'Patients',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredPatients.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No patients found'
                              : 'No patients match your search',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = _filteredPatients[index];
                          return _buildPatientCard(patient);
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPatientCard(PatientModel patient) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (widget.forProgressReport) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientProgressReportScreen(
                  patientId: patient.uid,
                ),
              ),
            );
          } else {
            // Navigate to patient details screen or another appropriate screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientProgressReportScreen(
                  patientId: patient.uid,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.shade100,
                radius: 24,
                child: Text(
                  patient.fullName.isNotEmpty
                      ? patient.fullName.substring(0, 1).toUpperCase()
                      : 'P',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      patient.email,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}