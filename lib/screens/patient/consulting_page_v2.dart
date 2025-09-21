import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/practitioner_model.dart';

// The main consulting page with green theme
class ConsultingPage extends StatefulWidget {
  final String? patientId;
  const ConsultingPage({Key? key, this.patientId}) : super(key: key);

  @override
  _ConsultingPageState createState() => _ConsultingPageState();
}

class _ConsultingPageState extends State<ConsultingPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filters = [];
  bool _isLoading = true;
  List<PractitionerModel> _practitioners = [];
  List<PractitionerModel> _filteredPractitioners = [];

  // Green theme colors
  final Color primaryGreen = Color(0xFF1B5E20);
  final Color secondaryGreen = Color(0xFF2E7D32);
  final Color lightGreen = Color(0xFF4CAF50);
  final Color paleGreen = Color(0xFFE8F5E9);

  // Dummy practitioners data for testing if Firestore query fails
  final List<PractitionerModel> _dummyPractitioners = [
    PractitionerModel(
      uid: '1',
      email: 'ayush.sharma@example.com',
      fullName: 'Dr. Ayush Sharma',
      specialties: ['Vamana', 'Panchakarma', 'Herbal Medicine'],
      qualification: 'BAMS, MD (Ayurveda)',
      experience: '15',
      bio:
          'Specializing in traditional Panchakarma therapies with focus on Vata-Pitta imbalances.',
      phoneNumber: '+91 9876543210',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PractitionerModel(
      uid: '2',
      email: 'priya.patel@example.com',
      fullName: 'Dr. Priya Patel',
      specialties: ['Virechana', 'Ayurvedic Diet', 'Pulse Diagnosis'],
      qualification: 'BAMS, PhD',
      experience: '12',
      bio:
          'Expert in Ayurvedic dietary recommendations and lifestyle modifications for chronic conditions.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PractitionerModel(
      uid: '3',
      email: 'rajesh.gupta@example.com',
      fullName: 'Dr. Rajesh Gupta',
      specialties: ['Basti', 'Nasya', 'Panchakarma'],
      qualification: 'BAMS, MSc Medicinal Plants',
      experience: '20',
      bio:
          'Specializing in Ayurvedic herbs and formulations for respiratory and digestive disorders.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPractitioners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPractitioners() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get practitioners from Firestore
      final QuerySnapshot practitionerSnapshot = await FirebaseFirestore
          .instance
          .collection('practitioners')
          .where('isVerified', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      if (practitionerSnapshot.docs.isEmpty) {
        // Use dummy data if no practitioners found
        setState(() {
          _practitioners = _dummyPractitioners;
          _filteredPractitioners = _dummyPractitioners;
          _isLoading = false;
        });
        return;
      }

      final List<PractitionerModel> practitioners = practitionerSnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['uid'] = doc.id; // Add UID to the data
            return PractitionerModel.fromJson(data);
          })
          .toList();

      setState(() {
        _practitioners = practitioners;
        _filteredPractitioners = practitioners;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading practitioners: $e');

      // Use dummy data if error occurs
      setState(() {
        _practitioners = _dummyPractitioners;
        _filteredPractitioners = _dummyPractitioners;
        _isLoading = false;
      });
    }
  }

  void _filterPractitioners() {
    if (_searchController.text.isEmpty && _filters.isEmpty) {
      setState(() {
        _filteredPractitioners = _practitioners;
      });
      return;
    }

    setState(() {
      _filteredPractitioners = _practitioners.where((practitioner) {
        bool matchesSearch = true;
        bool matchesFilters = true;

        // Apply search filter
        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          matchesSearch =
              practitioner.fullName.toLowerCase().contains(searchLower) ||
              (practitioner.specialties != null &&
                  practitioner.specialties!.any(
                    (spec) => spec.toLowerCase().contains(searchLower),
                  ));
        }

        // Apply specialization filters
        if (_filters.isNotEmpty) {
          matchesFilters =
              practitioner.specialties != null &&
              _filters.every(
                (filter) => practitioner.specialties!.contains(filter),
              );
        }

        return matchesSearch && matchesFilters;
      }).toList();
    });
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_filters.contains(filter)) {
        _filters.remove(filter);
      } else {
        _filters.add(filter);
      }
      _filterPractitioners();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find Practitioners',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
      ),
      backgroundColor: paleGreen.withOpacity(0.3),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : Column(
              children: [
                _buildSearchBar(),
                _buildFilterChips(),
                _filteredPractitioners.isEmpty
                    ? _buildNoResults()
                    : Expanded(child: _buildPractitionerList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ConsultationRequestScreen(patientId: widget.patientId),
            ),
          );
        },
        backgroundColor: primaryGreen,
        icon: Icon(Icons.add_circle_outline),
        label: Text('New Consultation'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search practitioners',
          prefixIcon: Icon(Icons.search, color: primaryGreen),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: primaryGreen),
                  onPressed: () {
                    _searchController.clear();
                    _filterPractitioners();
                  },
                )
              : null,
          filled: true,
          fillColor: paleGreen.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryGreen),
          ),
        ),
        onChanged: (value) {
          _filterPractitioners();
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    const List<String> specializations = [
      'Vamana',
      'Virechana',
      'Basti',
      'Nasya',
      'Raktamokshana',
      'Panchakarma',
      'Ayurveda',
    ];

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specializations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specializations.map((spec) {
              final isSelected = _filters.contains(spec);
              return FilterChip(
                label: Text(spec),
                selected: isSelected,
                onSelected: (selected) {
                  _toggleFilter(spec);
                },
                backgroundColor: paleGreen,
                selectedColor: primaryGreen.withOpacity(0.2),
                checkmarkColor: primaryGreen,
                labelStyle: TextStyle(
                  color: isSelected ? primaryGreen : Colors.black87,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'No practitioners found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _filters.isNotEmpty
                  ? 'Try removing some filters'
                  : 'Try a different search term',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPractitionerList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredPractitioners.length,
      itemBuilder: (context, index) {
        final practitioner = _filteredPractitioners[index];
        return _buildPractitionerCard(practitioner);
      },
    );
  }

  Widget _buildPractitionerCard(PractitionerModel practitioner) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryGreen.withOpacity(0.2),
                  backgroundImage: practitioner.profileImageUrl != null
                      ? NetworkImage(practitioner.profileImageUrl!)
                      : null,
                  child: practitioner.profileImageUrl == null
                      ? Icon(Icons.person, color: primaryGreen, size: 30)
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        practitioner.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        practitioner.qualification ?? 'Ayurveda Practitioner',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      // Show experience if available
                      if (practitioner.experience != null)
                        Text(
                          '${practitioner.experience} years of experience',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (practitioner.bio != null && practitioner.bio!.isNotEmpty)
              Text(
                practitioner.bio!,
                style: TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: 8),
            if (practitioner.specialties != null &&
                practitioner.specialties!.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: practitioner.specialties!.map((spec) {
                  return Chip(
                    label: Text(spec),
                    backgroundColor: paleGreen,
                    labelStyle: TextStyle(color: primaryGreen, fontSize: 12),
                    visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to practitioner profile
                      _navigateToPractitionerProfile(practitioner);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: BorderSide(color: primaryGreen),
                    ),
                    child: Text('View Profile'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to consultation form
                      _navigateToConsultationForm(practitioner);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Schedule'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPractitionerProfile(PractitionerModel practitioner) {
    // TODO: Implement navigation to practitioner profile
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile view coming soon'),
        backgroundColor: primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToConsultationForm(PractitionerModel practitioner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsultationFormScreen(
          practitioner: practitioner,
          patientId: widget.patientId,
        ),
      ),
    );
  }
}

// Screen for scheduling a consultation with a specific practitioner
class ConsultationFormScreen extends StatefulWidget {
  final PractitionerModel practitioner;
  final String? patientId;

  const ConsultationFormScreen({
    Key? key,
    required this.practitioner,
    this.patientId,
  }) : super(key: key);

  @override
  _ConsultationFormScreenState createState() => _ConsultationFormScreenState();
}

class _ConsultationFormScreenState extends State<ConsultationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Green theme colors
  final Color primaryGreen = Color(0xFF1B5E20);
  final Color secondaryGreen = Color(0xFF2E7D32);
  final Color lightGreen = Color(0xFF4CAF50);
  final Color paleGreen = Color(0xFFE8F5E9);

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _medicalHistoryController =
      TextEditingController();
  final TextEditingController _conditionController = TextEditingController();

  // Form state
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay(hour: 10, minute: 0);
  String _selectedGender = 'Male';
  String _selectedPatientType = 'New Patient';
  String _selectedCondition = '';
  bool _isSubmitting = false;

  // Common health conditions in Ayurveda
  final List<String> _commonConditions = [
    'Digestive Issues',
    'Joint Pain',
    'Skin Problems',
    'Respiratory Issues',
    'Stress & Anxiety',
    'Weight Management',
    'Allergies',
    'Sleep Disorders',
    'Other (Please specify)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _medicalHistoryController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: primaryGreen)),
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
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: primaryGreen)),
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create consultation request data
      final Map<String, dynamic> consultationData = {
        'patientName': _nameController.text,
        'patientAge': int.tryParse(_ageController.text) ?? 0,
        'patientGender': _selectedGender,
        'patientType': _selectedPatientType,
        'condition': _selectedCondition == 'Other (Please specify)'
            ? _conditionController.text
            : _selectedCondition,
        'medicalHistory': _medicalHistoryController.text,
        'appointmentDate': Timestamp.fromDate(_selectedDate),
        'appointmentTime':
            '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'practitionerId': widget.practitioner.uid,
        'practitionerName': widget.practitioner.fullName,
        'status': 'pending',
        'isApproved': false, // Default is not approved
        'createdAt': Timestamp.now(),
      };

      // Add patientId if available
      if (widget.patientId != null) {
        consultationData['patientId'] = widget.patientId;
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('consultation_requests')
          .add(consultationData);

      // Show success and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Consultation request submitted successfully'),
          backgroundColor: primaryGreen,
        ),
      );

      // Delay navigation slightly to show the snackbar
      await Future.delayed(Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error submitting consultation request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Schedule Consultation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
      ),
      backgroundColor: paleGreen.withOpacity(0.3),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Practitioner info
                _buildPractitionerInfo(),

                SizedBox(height: 24),
                _buildSectionTitle('Patient Information'),
                SizedBox(height: 16),

                // Patient type selection
                _buildSectionSubtitle('Are you new to Panchakarma?'),
                SizedBox(height: 8),
                _buildPatientTypeSelector(),
                SizedBox(height: 16),

                // Patient name
                _buildTextField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Row for age and gender
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Age field
                    Expanded(
                      child: _buildTextField(
                        controller: _ageController,
                        labelText: 'Age',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter age';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    // Gender dropdown
                    Expanded(
                      child: _buildDropdown<String>(
                        value: _selectedGender,
                        labelText: 'Gender',
                        items: ['Male', 'Female', 'Other'],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedGender = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                _buildSectionTitle('Health Condition'),
                SizedBox(height: 16),

                // Condition selection
                _buildSectionSubtitle(
                  'What condition are you seeking help with?',
                ),
                SizedBox(height: 8),
                _buildConditionSelector(),
                SizedBox(height: 16),

                // Additional condition details if "Other" is selected
                if (_selectedCondition == 'Other (Please specify)')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _conditionController,
                        labelText: 'Please specify your condition',
                        validator: (value) {
                          if (_selectedCondition == 'Other (Please specify)' &&
                              (value == null || value.isEmpty)) {
                            return 'Please describe your condition';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                    ],
                  ),

                // Medical history
                _buildTextField(
                  controller: _medicalHistoryController,
                  labelText: 'Medical History',
                  hintText: 'Any existing conditions, medications, etc.',
                  maxLines: 3,
                ),
                SizedBox(height: 24),

                // PDF upload section (commented out for future use)
                _buildSectionTitle('Medical Reports'),
                SizedBox(height: 8),
                _buildSectionSubtitle(
                  'Upload any relevant medical reports (Coming soon)',
                  fontSize: 14,
                ),
                SizedBox(height: 8),

                // PDF upload button (commented out for future use)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.upload_file, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Upload PDF Reports',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Feature coming soon',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      // IMPORTANT: PDF upload functionality is commented out for future implementation
                      // To implement this feature in the future:
                      // 1. Add file_picker dependency to pubspec.yaml
                      // 2. Use FilePickerResult to select PDF files
                      // 3. Implement Firebase Storage upload for PDFs
                      // 4. Store the download URLs in the consultation request
                    ],
                  ),
                ),
                SizedBox(height: 24),

                _buildSectionTitle('Appointment Details'),
                SizedBox(height: 16),

                // Date and time selection
                Row(
                  children: [
                    // Date picker
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            labelText: 'Date',
                            suffixIcon: Icons.calendar_today,
                            controller: TextEditingController(
                              text: DateFormat(
                                'dd/MM/yyyy',
                              ).format(_selectedDate),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select date';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Time picker
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectTime(context),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            labelText: 'Time',
                            suffixIcon: Icons.access_time,
                            controller: TextEditingController(
                              text: _selectedTime.format(context),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select time';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Request Consultation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPractitionerInfo() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: primaryGreen.withOpacity(0.2),
              backgroundImage: widget.practitioner.profileImageUrl != null
                  ? NetworkImage(widget.practitioner.profileImageUrl!)
                  : null,
              child: widget.practitioner.profileImageUrl == null
                  ? Icon(Icons.person, color: primaryGreen, size: 30)
                  : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.practitioner.fullName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.practitioner.qualification ??
                        'Ayurveda Practitioner',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  if (widget.practitioner.specialties != null &&
                      widget.practitioner.specialties!.isNotEmpty)
                    Text(
                      'Specialties: ${widget.practitioner.specialties!.join(", ")}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryGreen,
      ),
    );
  }

  Widget _buildSectionSubtitle(String subtitle, {double fontSize = 15}) {
    return Text(
      subtitle,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    IconData? suffixIcon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: primaryGreen)
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryGreen),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String labelText,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryGreen),
        ),
      ),
      items: items.map<DropdownMenuItem<T>>((T value) {
        return DropdownMenuItem<T>(value: value, child: Text(value.toString()));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPatientTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSelectionTile(
              title: 'New Patient',
              isSelected: _selectedPatientType == 'New Patient',
              onTap: () => setState(() => _selectedPatientType = 'New Patient'),
              icon: Icons.person_add_outlined,
            ),
          ),
          Expanded(
            child: _buildSelectionTile(
              title: 'Returning Patient',
              isSelected: _selectedPatientType == 'Returning Patient',
              onTap: () =>
                  setState(() => _selectedPatientType = 'Returning Patient'),
              icon: Icons.person_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: _commonConditions.map((condition) {
          return RadioListTile<String>(
            title: Text(condition),
            value: condition,
            groupValue: _selectedCondition,
            activeColor: primaryGreen,
            onChanged: (value) {
              setState(() {
                _selectedCondition = value!;
              });
            },
          );
        }).toList(),
      ),
    );
  }
}

// Screen for submitting a general consultation request (not tied to a specific practitioner)
class ConsultationRequestScreen extends StatefulWidget {
  final String? patientId;

  const ConsultationRequestScreen({Key? key, this.patientId}) : super(key: key);

  @override
  _ConsultationRequestScreenState createState() =>
      _ConsultationRequestScreenState();
}

class _ConsultationRequestScreenState extends State<ConsultationRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // Green theme colors
  final Color primaryGreen = Color(0xFF1B5E20);
  final Color secondaryGreen = Color(0xFF2E7D32);
  final Color lightGreen = Color(0xFF4CAF50);
  final Color paleGreen = Color(0xFFE8F5E9);

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Form state
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  String _selectedGender = 'Male';
  String _selectedPatientType = 'New Patient';
  String _selectedCondition = '';
  List<String> _selectedSpecializations = [];
  bool _isSubmitting = false;

  // Common health conditions in Ayurveda
  final List<String> _commonConditions = [
    'Digestive Issues',
    'Joint Pain',
    'Skin Problems',
    'Respiratory Issues',
    'Stress & Anxiety',
    'Weight Management',
    'Allergies',
    'Sleep Disorders',
    'Other (Please specify)',
  ];

  // Specializations
  final List<String> _specializations = [
    'Vamana',
    'Virechana',
    'Basti',
    'Nasya',
    'Raktamokshana',
    'Panchakarma',
    'Ayurveda',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _conditionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: primaryGreen)),
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

  void _toggleSpecialization(String specialization) {
    setState(() {
      if (_selectedSpecializations.contains(specialization)) {
        _selectedSpecializations.remove(specialization);
      } else {
        _selectedSpecializations.add(specialization);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create consultation request data
      final Map<String, dynamic> consultationData = {
        'patientName': _nameController.text,
        'patientAge': int.tryParse(_ageController.text) ?? 0,
        'patientGender': _selectedGender,
        'patientType': _selectedPatientType,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'condition': _selectedCondition == 'Other (Please specify)'
            ? _conditionController.text
            : _selectedCondition,
        'description': _descriptionController.text,
        'preferredSpecializations': _selectedSpecializations,
        'preferredDate': Timestamp.fromDate(_selectedDate),
        'status': 'pending',
        'isApproved': false, // Default is not approved
        'createdAt': Timestamp.now(),
      };

      // Add patientId if available
      if (widget.patientId != null) {
        consultationData['patientId'] = widget.patientId;
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('general_consultations')
          .add(consultationData);

      // Show success and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Consultation request submitted successfully'),
          backgroundColor: primaryGreen,
        ),
      );

      // Delay navigation slightly to show the snackbar
      await Future.delayed(Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error submitting consultation request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Consultation Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
      ),
      backgroundColor: paleGreen.withOpacity(0.3),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Introduction card
                _buildIntroCard(),
                SizedBox(height: 24),

                _buildSectionTitle('Personal Information'),
                SizedBox(height: 16),

                // Patient type selection
                _buildSectionSubtitle('Are you new to Panchakarma?'),
                SizedBox(height: 8),
                _buildPatientTypeSelector(),
                SizedBox(height: 16),

                // Patient name
                _buildTextField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Row for age and gender
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Age field
                    Expanded(
                      child: _buildTextField(
                        controller: _ageController,
                        labelText: 'Age',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter age';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    // Gender dropdown
                    Expanded(
                      child: _buildDropdown<String>(
                        value: _selectedGender,
                        labelText: 'Gender',
                        items: ['Male', 'Female', 'Other'],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedGender = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Contact info - email and phone
                _buildTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                _buildTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                _buildSectionTitle('Health Condition'),
                SizedBox(height: 16),

                // Condition selection
                _buildSectionSubtitle(
                  'What condition are you seeking help with?',
                ),
                SizedBox(height: 8),
                _buildConditionSelector(),
                SizedBox(height: 16),

                // Additional condition details if "Other" is selected
                if (_selectedCondition == 'Other (Please specify)')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _conditionController,
                        labelText: 'Please specify your condition',
                        validator: (value) {
                          if (_selectedCondition == 'Other (Please specify)' &&
                              (value == null || value.isEmpty)) {
                            return 'Please describe your condition';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                    ],
                  ),

                // Detailed description
                _buildTextField(
                  controller: _descriptionController,
                  labelText: 'Describe your condition in detail',
                  hintText:
                      'Include symptoms, duration, and any previous treatments',
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please describe your condition';
                    }
                    if (value.length < 20) {
                      return 'Please provide more details (at least 20 characters)';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // PDF upload section (commented out for future use)
                _buildSectionTitle('Medical Reports'),
                SizedBox(height: 8),
                _buildSectionSubtitle(
                  'Upload any relevant medical reports (Coming soon)',
                  fontSize: 14,
                ),
                SizedBox(height: 8),

                // PDF upload button (commented out for future use)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.upload_file, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Upload PDF Reports',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Feature coming soon',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      // IMPORTANT: PDF upload functionality is commented out for future implementation
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Preferred specialization
                _buildSectionTitle('Treatment Preferences'),
                SizedBox(height: 16),
                _buildSectionSubtitle(
                  'Preferred treatment specializations (optional)',
                ),
                SizedBox(height: 8),
                _buildSpecializationSelector(),
                SizedBox(height: 16),

                // Preferred date
                _buildSectionSubtitle('Preferred date for consultation'),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: _buildTextField(
                      labelText: 'Select Date',
                      suffixIcon: Icons.calendar_today,
                      controller: TextEditingController(
                        text: DateFormat('dd/MM/yyyy').format(_selectedDate),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Submit Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.spa_outlined, size: 48, color: primaryGreen),
            SizedBox(height: 8),
            Text(
              'Request a Consultation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fill out this form to request a consultation with one of our Ayurvedic practitioners. We will match you with the most suitable practitioner based on your needs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryGreen,
      ),
    );
  }

  Widget _buildSectionSubtitle(String subtitle, {double fontSize = 15}) {
    return Text(
      subtitle,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    IconData? suffixIcon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: primaryGreen)
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryGreen),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String labelText,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryGreen),
        ),
      ),
      items: items.map<DropdownMenuItem<T>>((T value) {
        return DropdownMenuItem<T>(value: value, child: Text(value.toString()));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPatientTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSelectionTile(
              title: 'New Patient',
              isSelected: _selectedPatientType == 'New Patient',
              onTap: () => setState(() => _selectedPatientType = 'New Patient'),
              icon: Icons.person_add_outlined,
            ),
          ),
          Expanded(
            child: _buildSelectionTile(
              title: 'Returning Patient',
              isSelected: _selectedPatientType == 'Returning Patient',
              onTap: () =>
                  setState(() => _selectedPatientType = 'Returning Patient'),
              icon: Icons.person_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: _commonConditions.map((condition) {
          return RadioListTile<String>(
            title: Text(condition),
            value: condition,
            groupValue: _selectedCondition,
            activeColor: primaryGreen,
            onChanged: (value) {
              setState(() {
                _selectedCondition = value!;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpecializationSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Wrap(
        spacing: 8,
        children: _specializations.map((specialization) {
          final bool isSelected = _selectedSpecializations.contains(
            specialization,
          );
          return FilterChip(
            label: Text(specialization),
            selected: isSelected,
            onSelected: (selected) {
              _toggleSpecialization(specialization);
            },
            backgroundColor: paleGreen.withOpacity(0.5),
            selectedColor: primaryGreen.withOpacity(0.2),
            checkmarkColor: primaryGreen,
            labelStyle: TextStyle(
              color: isSelected ? primaryGreen : Colors.black87,
            ),
          );
        }).toList(),
      ),
    );
  }
}
