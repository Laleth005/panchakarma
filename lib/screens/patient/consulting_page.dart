import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/practitioner_model.dart';
import 'book_appointment_screen.dart';

class ConsultingPage extends StatefulWidget {
  const ConsultingPage({Key? key}) : super(key: key);

  @override
  _ConsultingPageState createState() => _ConsultingPageState();
}

class _ConsultingPageState extends State<ConsultingPage> {
  final AuthService _authService = AuthService();
  List<PractitionerModel> _practitioners = [];
  List<PractitionerModel> _filteredPractitioners = [];
  bool _isLoading = true;
  String _selectedSpecialization = 'All';
  
  // Fixed list of specializations
  final List<String> _predefinedSpecializations = [
    'All', 
    'Vamana', 
    'Virechana', 
    'Basti', 
    'Nasya', 
    'Raktamokshana',
    'Panchakarma',
    'Ayurveda',
  ];
  
  List<String> _specializations = ['All'];
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadPractitioners();
  }

  Future<void> _loadPractitioners() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get practitioners from Firestore
      final practitionersSnapshot = await FirebaseFirestore.instance
          .collection('practitioners')
          .get();
      
      // Convert snapshots to PractitionerModel objects
      final practitioners = practitionersSnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['uid'] = doc.id; // Use 'uid' instead of 'id'
            try {
              return PractitionerModel.fromJson(data);
            } catch (e) {
              print('Error creating PractitionerModel: $e');
              return null;
            }
          })
          .where((practitioner) => practitioner != null)
          .cast<PractitionerModel>()
          .toList();

      // We'll use our predefined specializations list instead of extracting from practitioners
      setState(() {
        _practitioners = practitioners;
        _filteredPractitioners = practitioners;
        _specializations = _predefinedSpecializations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading practitioners: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _filterPractitioners() {
    setState(() {
      _filteredPractitioners = _practitioners.where((practitioner) {
        // Filter by specialization
        final matchesSpecialization = _selectedSpecialization == 'All' || 
            practitioner.specialties.contains(_selectedSpecialization);
            
        // Filter by search query
        final matchesQuery = _searchQuery.isEmpty ||
            practitioner.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (practitioner.bio != null && practitioner.bio!.toLowerCase().contains(_searchQuery.toLowerCase()));
            
        return matchesSpecialization && matchesQuery;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Find a Practitioner',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : Column(
              children: [
                _buildSearchAndFilter(),
                Expanded(
                  child: _filteredPractitioners.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No practitioners found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters or search query',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredPractitioners.length,
                          itemBuilder: (context, index) {
                            return _buildPractitionerCard(_filteredPractitioners[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterPractitioners();
            },
            decoration: InputDecoration(
              hintText: 'Search practitioners...',
              prefixIcon: Icon(Icons.search, color: Color(0xFF2E7D32)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF2E7D32)),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          SizedBox(height: 16),
          
          // Specialization filter
          Container(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
              value: _selectedSpecialization,
              decoration: InputDecoration(
                labelText: 'Filter by Specialization',
                labelStyle: TextStyle(color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF2E7D32)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                prefixIcon: Icon(Icons.medical_services, color: Color(0xFF2E7D32)),
              ),
              icon: Icon(Icons.arrow_drop_down, color: Color(0xFF2E7D32)),
              dropdownColor: Colors.white,
              items: _specializations.map((String specialization) {
                return DropdownMenuItem<String>(
                  value: specialization,
                  child: Text(specialization),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedSpecialization = newValue;
                  });
                  _filterPractitioners();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPractitionerCard(PractitionerModel practitioner) {
    // Hard-coded rating for now - in a real app, you'd fetch this from Firestore
    final double rating = 4.8;
    final int totalReviews = 12;
    
    final String displayRating = rating.toStringAsFixed(1);
        
    final bool hasRatings = totalReviews > 0;
    
    final String reviewText = hasRatings
        ? '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}'
        : 'No reviews yet';
    
    // We'll display specialties using chips instead of a single text line
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Practitioner info section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFF2E7D32).withOpacity(0.1),
                  child: practitioner.profileImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.network(
                            practitioner.profileImageUrl!,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              size: 40,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 40,
                          color: Color(0xFF2E7D32),
                        ),
                ),
                SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${practitioner.fullName}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: practitioner.specialties.isEmpty
                            ? [
                                Chip(
                                  label: Text('Ayurvedic Practitioner'),
                                  backgroundColor: Colors.green.withOpacity(0.1),
                                  labelStyle: TextStyle(color: Colors.green[800]),
                                )
                              ]
                            : practitioner.specialties.map((specialty) {
                                return Chip(
                                  label: Text(specialty),
                                  backgroundColor: Colors.green.withOpacity(0.1),
                                  labelStyle: TextStyle(color: Colors.green[800]),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  labelPadding: EdgeInsets.symmetric(horizontal: 8),
                                );
                              }).toList(),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            displayRating,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '($reviewText)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (practitioner.experience != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${practitioner.experience} experience',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      if (practitioner.qualification != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            practitioner.qualification!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bio
          if (practitioner.bio != null && practitioner.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                practitioner.bio!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
          // Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.chat_bubble_outline),
                    label: Text('Chat'),
                    onPressed: () {
                      // Start chat with practitioner
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF2E7D32),
                      side: BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.calendar_today),
                    label: Text('Book'),
                    onPressed: () async {
                      // Try to get the current patient ID from session info
                      String? patientId;
                      
                      try {
                        // First check if we already have patient data loaded
                        if (_authService.currentUser != null) {
                          patientId = _authService.currentUser!.uid;
                          print('Using Firebase Auth user ID: $patientId');
                        } else {
                          // Get the most recently accessed patient ID from Firestore
                          final prefs = await FirebaseFirestore.instance
                              .collection('system_preferences')
                              .doc('active_sessions')
                              .get();
                              
                          if (prefs.exists && prefs.data()!.containsKey('last_patient_id')) {
                            patientId = prefs.data()!['last_patient_id'];
                            print('Using last active patient ID: $patientId');
                          } else {
                            // If no active patient, try to find one
                            final patientQuery = await FirebaseFirestore.instance
                                .collection('patients')
                                .limit(1)
                                .get();
                                
                            if (patientQuery.docs.isNotEmpty) {
                              patientId = patientQuery.docs.first.id;
                              print('Using first patient from Firestore: $patientId');
                            }
                          }
                        }
                      } catch (e) {
                        print('Error getting patient ID: $e');
                      }
                      
                      // Navigate to booking screen with patient ID if available
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookAppointmentScreen(
                            practitioner: practitioner,
                            patientId: patientId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}