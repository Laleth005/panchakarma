import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/practitioner_model.dart';

class PractitionerApprovalScreen extends StatefulWidget {
  const PractitionerApprovalScreen({Key? key}) : super(key: key);

  @override
  _PractitionerApprovalScreenState createState() => _PractitionerApprovalScreenState();
}

class _PractitionerApprovalScreenState extends State<PractitionerApprovalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingPractitioners = [];
  List<Map<String, dynamic>> _approvedPractitioners = [];

  @override
  void initState() {
    super.initState();
    _loadPractitioners();
  }

  Future<void> _loadPractitioners() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all practitioners
      QuerySnapshot snapshot = await _firestore.collection('practitioners').get();
      
      List<Map<String, dynamic>> pendingList = [];
      List<Map<String, dynamic>> approvedList = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID
        
        bool isApproved = data['isApproved'] ?? false;
        if (isApproved) {
          approvedList.add(data);
        } else {
          pendingList.add(data);
        }
      }
      
      setState(() {
        _pendingPractitioners = pendingList;
        _approvedPractitioners = approvedList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading practitioners: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approvePractitioner(String practitionerId) async {
    try {
      await _firestore.collection('practitioners').doc(practitionerId).update({
        'isApproved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Reload practitioners after approval
      _loadPractitioners();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Practitioner approved successfully')),
      );
    } catch (e) {
      print('Error approving practitioner: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve practitioner: $e')),
      );
    }
  }

  Future<void> _rejectPractitioner(String practitionerId) async {
    try {
      // Show confirmation dialog
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Reject Practitioner'),
          content: Text('Are you sure you want to reject this practitioner? This will delete their account.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;
      
      if (!confirm) return;
      
      // Delete from practitioners collection
      await _firestore.collection('practitioners').doc(practitionerId).delete();
      
      // Delete from users collection too
      await _firestore.collection('users').doc(practitionerId).delete();
      
      // Reload practitioners after rejection
      _loadPractitioners();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Practitioner rejected successfully')),
      );
    } catch (e) {
      print('Error rejecting practitioner: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject practitioner: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Practitioner Approval', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF2E7D32),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Pending Approval (${_pendingPractitioners.length})'),
              Tab(text: 'Approved (${_approvedPractitioners.length})'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadPractitioners,
              color: Colors.white,
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
            : TabBarView(
                children: [
                  _buildPractitionerList(_pendingPractitioners, isPending: true),
                  _buildPractitionerList(_approvedPractitioners, isPending: false),
                ],
              ),
      ),
    );
  }

  Widget _buildPractitionerList(List<Map<String, dynamic>> practitioners, {required bool isPending}) {
    if (practitioners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.pending_actions : Icons.check_circle_outline,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              isPending
                  ? 'No pending practitioners'
                  : 'No approved practitioners',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: practitioners.length,
      itemBuilder: (context, index) {
        final practitioner = practitioners[index];
        return _buildPractitionerCard(practitioner, isPending);
      },
    );
  }

  Widget _buildPractitionerCard(Map<String, dynamic> practitioner, bool isPending) {
    final String name = practitioner['fullName'] ?? 'Unknown';
    final String email = practitioner['email'] ?? 'No email';
    final String phone = practitioner['phoneNumber'] ?? 'No phone';
    final List<dynamic> specialties = practitioner['specialties'] ?? [];
    final String qualification = practitioner['qualification'] ?? 'Not specified';
    final String experience = practitioner['experience'] ?? 'Not specified';
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          email,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: Color(0xFF2E7D32).withOpacity(0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'P',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.phone, 'Phone', phone),
                SizedBox(height: 8),
                _buildInfoRow(Icons.medical_services, 'Specialties', 
                    specialties.isEmpty ? 'None specified' : specialties.join(', ')),
                SizedBox(height: 8),
                _buildInfoRow(Icons.school, 'Qualification', qualification),
                SizedBox(height: 8),
                _buildInfoRow(Icons.work, 'Experience', experience),
                SizedBox(height: 16),
                if (isPending) 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _rejectPractitioner(practitioner['id']),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                        ),
                        child: Text('Reject'),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _approvePractitioner(practitioner['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Approve'),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}