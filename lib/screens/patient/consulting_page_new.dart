import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// TODO: Uncomment for future file upload feature
// import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../models/practitioner_model.dart';

// Green Theme Colors
class AppColors {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color backgroundGreen = Color(0xFFF1F8E9);
  static const Color cardGreen = Color(0xFFE8F5E8);
}

class ConsultingPage extends StatefulWidget {
  const ConsultingPage({Key? key}) : super(key: key);

  @override
  _ConsultingPageState createState() => _ConsultingPageState();
}

class _ConsultingPageState extends State<ConsultingPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filters = [];
  bool _isLoading = true;
  List<PractitionerModel> _practitioners = [];
  List<PractitionerModel> _filteredPractitioners = [];
  
  // Dummy practitioners data for testing
  final List<PractitionerModel> _dummyPractitioners = [
    PractitionerModel(
      uid: '1',
      email: 'ayush.sharma@example.com',
      fullName: 'Dr. Ayush Sharma',
      specialties: ['Vata Dosha', 'Panchakarma', 'Herbal Medicine'],
      qualification: 'BAMS, MD (Ayurveda)',
      experience: '15',
      bio: 'Specializing in traditional Panchakarma therapies with focus on Vata-Pitta imbalances.',
      phoneNumber: '+91 9876543210',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PractitionerModel(
      uid: '2',
      email: 'priya.patel@example.com',
      fullName: 'Dr. Priya Patel',
      specialties: ['Pitta Dosha', 'Ayurvedic Diet', 'Pulse Diagnosis'],
      qualification: 'BAMS, PhD',
      experience: '12',
      bio: 'Expert in Ayurvedic dietary recommendations and lifestyle modifications for chronic conditions.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PractitionerModel(
      uid: '3',
      email: 'rajesh.gupta@example.com',
      fullName: 'Dr. Rajesh Gupta',
      specialties: ['Kapha Dosha', 'Herbal Medicine', 'Panchakarma'],
      qualification: 'BAMS, MSc Medicinal Plants',
      experience: '20',
      bio: 'Specializing in Ayurvedic herbs and formulations for respiratory and digestive disorders.',
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
      final QuerySnapshot practitionerSnapshot = await FirebaseFirestore.instance
          .collection('practitioners')
          .where('isVerified', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      if (practitionerSnapshot.docs.isEmpty) {
        setState(() {
          _practitioners = _dummyPractitioners;
          _filteredPractitioners = _dummyPractitioners;
          _isLoading = false;
        });
        return;
      }

      final List<PractitionerModel> practitioners = practitionerSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return PractitionerModel.fromJson(data);
      }).toList();

      setState(() {
        _practitioners = practitioners;
        _filteredPractitioners = practitioners;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading practitioners: $e');
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

        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          matchesSearch = practitioner.fullName.toLowerCase().contains(searchLower) ||
              (practitioner.specialties.any((spec) => 
                spec.toLowerCase().contains(searchLower)));
        }

        if (_filters.isNotEmpty) {
          matchesFilters = _filters.every((filter) =>
              practitioner.specialties.contains(filter));
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
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: AppColors.primaryGreen,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryGreen,
          secondary: AppColors.accentGreen,
          surface: Colors.white,
          background: AppColors.backgroundGreen,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundGreen,
        appBar: AppBar(
          title: Text('Find Ayurveda Practitioners', 
            style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 4,
          shadowColor: AppColors.primaryGreen.withOpacity(0.3),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                )
              )
            : Column(
                children: [
                  _buildSearchBar(),
                  _buildFilterChips(),
                  _filteredPractitioners.isEmpty
                      ? _buildNoResults()
                      : Expanded(
                          child: _buildPractitionerList(),
                        ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search practitioners by name or specialty',
          hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(Icons.search, color: AppColors.primaryGreen),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.primaryGreen),
                  onPressed: () {
                    _searchController.clear();
                    _filterPractitioners();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: (value) => _filterPractitioners(),
      ),
    );
  }

  Widget _buildFilterChips() {
    const List<String> specializations = [
      'Vata Dosha',
      'Pitta Dosha', 
      'Kapha Dosha',
      'Panchakarma',
      'Ayurvedic Diet',
      'Herbal Medicine',
      'Pulse Diagnosis',
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Specializations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specializations.map((spec) {
              final isSelected = _filters.contains(spec);
              return FilterChip(
                label: Text(spec),
                selected: isSelected,
                onSelected: (selected) => _toggleFilter(spec),
                backgroundColor: Colors.white,
                selectedColor: AppColors.cardGreen,
                checkmarkColor: AppColors.primaryGreen,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.darkGreen : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
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
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 60,
                color: AppColors.primaryGreen,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No practitioners found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _filters.isNotEmpty
                  ? 'Try removing some filters'
                  : 'Try a different search term',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
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
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryGreen,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.cardGreen,
                    backgroundImage: practitioner.profileImageUrl != null 
                        ? NetworkImage(practitioner.profileImageUrl!) 
                        : null,
                    child: practitioner.profileImageUrl == null 
                        ? Icon(Icons.person, color: AppColors.primaryGreen, size: 32)
                        : null,
                  ),
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
                          fontSize: 18,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        practitioner.qualification ?? 'Ayurveda Practitioner',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (practitioner.experience != null) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.work_outline, 
                              size: 16, color: AppColors.accentGreen),
                            SizedBox(width: 4),
                            Text(
                              '${practitioner.experience} years experience',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (practitioner.bio != null && practitioner.bio!.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  practitioner.bio!,
                  style: TextStyle(fontSize: 14, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (practitioner.specialties.isNotEmpty) ...[
              SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: practitioner.specialties.map((spec) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardGreen,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      spec,
                      style: TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _navigateToPractitionerProfile(practitioner),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: BorderSide(color: AppColors.primaryGreen),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('View Profile', 
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _navigateToConsultationForm(practitioner),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: Text('Book Consultation', 
                      style: TextStyle(fontWeight: FontWeight.w600)),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile view coming soon'),
        backgroundColor: AppColors.primaryGreen,
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
          patientId: null, // This would come from your auth service
        ),
      ),
    );
  }
}

// Enhanced Consultation Form Screen with all requested features
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
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _customConditionController = TextEditingController();
  final TextEditingController _conditionDescriptionController = TextEditingController();
  final TextEditingController _additionalNotesController = TextEditingController();
  
  // Form state variables
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay(hour: 10, minute: 0);
  String _selectedGender = 'Male';
  String _selectedCondition = '';
  String _panchakarmaExperience = 'New to Panchakarma';
  bool _isSubmitting = false;
  
  // TODO: File handling variables - Commented for future implementation
  /*
  File? _selectedPDFReport;
  String? _pdfFileName;
  List<File> _selectedReports = [];
  List<String> _reportFileNames = [];
  
  // TODO: Future implementation - PDF file picker functionality
  Future<void> _pickPDFFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true, // Allow multiple file selection
      );

      if (result != null) {
        setState(() {
          _selectedReports.clear();
          _reportFileNames.clear();
          
          for (var file in result.files) {
            if (file.path != null) {
              _selectedReports.add(File(file.path!));
              _reportFileNames.add(file.name);
            }
          }
        });
      }
    } catch (e) {
      print('Error picking PDF files: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting files. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // TODO: Future implementation - Remove selected file
  void _removeSelectedFile(int index) {
    setState(() {
      _selectedReports.removeAt(index);
      _reportFileNames.removeAt(index);
    });
  }

  // TODO: Future implementation - File upload section widget
  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.upload_file, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text(
              'Medical Reports (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.accentGreen, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.backgroundGreen,
          ),
          child: Column(
            children: [
              if (_selectedReports.isEmpty) ...[
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
                SizedBox(height: 12),
                Text(
                  'Upload your medical reports',
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Supported formats: PDF only\nMaximum 5 files allowed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickPDFFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.add),
                  label: Text('Choose Files'),
                ),
              ] else ...[
                Column(
                  children: _selectedReports.asMap().entries.map((entry) {
                    int index = entry.key;
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, 
                            color: AppColors.primaryGreen, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _reportFileNames[index],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                                Text(
                                  'PDF Document',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red, size: 20),
                            onPressed: () => _removeSelectedFile(index),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12),
                if (_selectedReports.length < 5)
                  TextButton.icon(
                    onPressed: _pickPDFFile,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                    ),
                    icon: Icon(Icons.add),
                    label: Text('Add More Files'),
                  ),
              ],
            ],
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Note: File upload feature will be available in future updates',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
  */
  
  // Comprehensive health conditions list
  final List<String> _healthConditions = [
    'Digestive Issues',
    'Respiratory Problems', 
    'Joint Pain & Arthritis',
    'Stress & Anxiety',
    'Sleep Disorders',
    'Skin Conditions',
    'Diabetes',
    'High Blood Pressure',
    'Heart Disease',
    'Obesity',
    'Chronic Fatigue',
    'Migraine & Headaches',
    'Depression',
    'Hormonal Imbalance',
    'Thyroid Issues',
    'Kidney Problems',
    'Liver Issues',
    'Allergies',
    'Autoimmune Disorders',
    'Chronic Pain',
    'Menstrual Problems',
    'Infertility Issues',
    'Memory Problems',
    'Others',
  ];

  // Panchakarma experience options
  final List<String> _panchakarmaOptions = [
    'New to Panchakarma',
    'Previously tried Panchakarma (1-2 times)',
    'Regular Panchakarma patient (3+ times)',
    'Currently undergoing Panchakarma treatment',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _customConditionController.dispose();
    _conditionDescriptionController.dispose();
    _additionalNotesController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
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
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
            ),
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
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Scroll to the page with validation errors
      if (_currentPage != 0) {
        _pageController.animateToPage(0, 
          duration: Duration(milliseconds: 300), 
          curve: Curves.easeInOut);
      }
      return;
    }
    
    if (_selectedCondition.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a health condition'),
          backgroundColor: Colors.red,
        ),
      );
      // Navigate to health info page
      _pageController.animateToPage(1, 
        duration: Duration(milliseconds: 300), 
        curve: Curves.easeInOut);
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Prepare appointment data - Changed collection name to 'appointments'
      final Map<String, dynamic> appointmentData = {
        // Patient Information
        'patientName': _nameController.text.trim(),
        'patientAge': int.tryParse(_ageController.text) ?? 0,
        'patientGender': _selectedGender,
        'phoneNumber': _phoneController.text.trim(),
        
        // Health Information
        'healthCondition': _selectedCondition == 'Others' 
          ? _customConditionController.text.trim()
          : _selectedCondition,
        'conditionDescription': _conditionDescriptionController.text.trim(),
        'panchakarmaExperience': _panchakarmaExperience,
        
        // Appointment Details
        'appointmentDate': Timestamp.fromDate(_selectedDate),
        'appointmentTime': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'additionalNotes': _additionalNotesController.text.trim(),
        
        // Practitioner Information
        'practitionerId': widget.practitioner.uid,
        'practitionerName': widget.practitioner.fullName,
        'practitionerEmail': widget.practitioner.email,
        'practitionerQualification': widget.practitioner.qualification,
        
        // Appointment Status
        'status': 'pending', // pending, approved, rejected, completed
        'isApproved': false, // Will be changed to true when practitioner approves
        
        // Timestamps
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        
        // Additional metadata
        'appointmentType': 'consultation',
        'source': 'mobile_app',
      };
      
      // Add patient ID if available
      if (widget.patientId != null) {
        appointmentData['patientId'] = widget.patientId;
      }
      
      // TODO: Future implementation - Add file URLs when file upload is implemented
      /*
      if (_selectedReports.isNotEmpty) {
        // Upload files to Firebase Storage and get download URLs
        List<String> fileUrls = [];
        for (int i = 0; i < _selectedReports.length; i++) {
          // Upload logic will be implemented here
          // String downloadUrl = await uploadFileToStorage(_selectedReports[i], _reportFileNames[i]);
          // fileUrls.add(downloadUrl);
        }
        appointmentData['medicalReports'] = fileUrls;
        appointmentData['reportFileNames'] = _reportFileNames;
      }
      */
      
      // Save to Firestore - Changed collection name to 'appointments'
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('appointments') // Changed from 'consultation_requests' to 'appointments'
          .add(appointmentData);
      
      print('Appointment booked successfully with ID: ${docRef.id}');
      
      // Show success message
      _showSuccessDialog(docRef.id);
      
    } catch (e) {
      print('Error booking appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking appointment. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
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
  
  void _showSuccessDialog(String appointmentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: AppColors.primaryGreen,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Appointment Booked Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Appointment ID: ${appointmentId.substring(0, 8).toUpperCase()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Your appointment request has been sent to ${widget.practitioner.fullName}. You will receive a notification once it\'s approved.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardGreen.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, 
                      color: AppColors.primaryGreen, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please keep your phone accessible for confirmation call',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                backgroundColor: AppColors.cardGreen,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

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
          title: Text('Book Consultation',
            style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 4,
          shadowColor: AppColors.primaryGreen.withOpacity(0.3),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              
              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildPersonalInfoPage(),
                    _buildHealthInfoPage(),
                    _buildAppointmentPage(),
                  ],
                ),
              ),
              
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  height: 4,
                  decoration: BoxDecoration(
                    color: index <= _currentPage 
                      ? AppColors.primaryGreen 
                      : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Info',
                style: TextStyle(
                  fontSize: 12,
                  color: _currentPage >= 0 
                    ? AppColors.primaryGreen 
                    : Colors.grey.shade600,
                  fontWeight: _currentPage == 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                'Health Details',
                style: TextStyle(
                  fontSize: 12,
                  color: _currentPage >= 1 
                    ? AppColors.primaryGreen 
                    : Colors.grey.shade600,
                  fontWeight: _currentPage == 1 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                'Appointment',
                style: TextStyle(
                  fontSize: 12,
                  color: _currentPage >= 2 
                    ? AppColors.primaryGreen 
                    : Colors.grey.shade600,
                  fontWeight: _currentPage == 2 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title with icon
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: AppColors.primaryGreen, size: 24),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  Text(
                    'Tell us about yourself',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          
          // Practitioner info card
          _buildPractitionerInfoCard(),
          SizedBox(height: 24),
          
          // Full name
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your complete name',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              if (value.trim().length < 2) {
                return 'Name should be at least 2 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          
          // Age and Gender row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _ageController,
                  label: 'Age',
                  hint: 'Your age',
                  icon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter age';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 120) {
                      return 'Enter valid age';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildGenderDropdown(),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Phone number
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter your contact number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter phone number';
              }
              if (value.trim().length < 10) {
                return 'Enter valid phone number';
              }
              return null;
            },
          ),
          SizedBox(height: 24),
          
          // Info card
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardGreen.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: AppColors.primaryGreen, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your personal information is secure and will only be shared with your selected practitioner.',
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 14,
                      height: 1.4,
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
  
  Widget _buildHealthInfoPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title with icon
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.health_and_safety, color: AppColors.primaryGreen, size: 24),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  Text(
                    'Help us understand your condition',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          
          // Health condition selection
          Text(
            'Primary Health Condition *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select the main condition you want to address',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 12),
          _buildConditionSelector(),
          SizedBox(height: 16),
          
          // Custom condition input (if "Others" selected)
          if (_selectedCondition == 'Others') ...[
            _buildTextField(
              controller: _customConditionController,
              label: 'Specify Your Condition',
              hint: 'Please describe your specific condition',
              icon: Icons.health_and_safety_outlined,
              maxLines: 2,
              validator: (value) {
                if (_selectedCondition == 'Others' && 
                    (value == null || value.trim().isEmpty)) {
                  return 'Please specify your condition';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
          ],
          
          // Condition description
          _buildTextField(
            controller: _conditionDescriptionController,
            label: 'Detailed Description *',
            hint: 'Describe your symptoms, duration, severity, any current medications, previous treatments, etc.',
            icon: Icons.description_outlined,
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please provide condition details';
              }
              if (value.trim().length < 20) {
                return 'Please provide more detailed description';
              }
              return null;
            },
          ),
          SizedBox(height: 24),
          
          // Panchakarma experience
          Text(
            'Panchakarma Experience *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This helps the practitioner plan your treatment',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 12),
          _buildPanchakarmaExperienceSelector(),
          
          SizedBox(height: 24),
          
          // TODO: Future use - File upload section (commented for now)
          /*
          _buildFileUploadSection(),
          SizedBox(height: 24),
          */
          
          // Note about file upload - Future implementation
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cardGreen, AppColors.backgroundGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.upcoming, color: AppColors.primaryGreen),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Medical Reports Upload',
                        style: TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'File upload feature for medical reports will be available in the next update. For now, please bring your reports during the consultation or email them to your practitioner.',
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppointmentPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title with icon
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calendar_today, color: AppColors.primaryGreen, size: 24),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  Text(
                    'Choose your preferred schedule',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          
          // Date and time selection
          Row(
            children: [
              Expanded(
                child: _buildDateTimeSelector(
                  label: 'Preferred Date',
                  value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  icon: Icons.calendar_today,
                  onTap: () => _selectDate(context),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildDateTimeSelector(
                  label: 'Preferred Time',
                  value: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  icon: Icons.access_time,
                  onTap: () => _selectTime(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Time slot note
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundGreen,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The practitioner will confirm the exact time based on availability',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          
          // Additional notes
          _buildTextField(
            controller: _additionalNotesController,
            label: 'Additional Notes (Optional)',
            hint: 'Any specific concerns, questions, or requests you want to discuss with the practitioner',
            icon: Icons.note_outlined,
            maxLines: 4,
          ),
          SizedBox(height: 24),
          
          // Summary card
          _buildSummaryCard(),
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: AppColors.darkGreen),
          hintStyle: TextStyle(color: Colors.grey.shade500),
          errorStyle: TextStyle(color: Colors.red, fontSize: 12),
        ),
        cursorColor: AppColors.primaryGreen,
      ),
    );
  }
  
  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: 'Gender',
          prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: AppColors.darkGreen),
        ),
        items: ['Male', 'Female', 'Other']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(color: AppColors.darkGreen),
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              _selectedGender = value;
            });
          }
        },
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen),
      ),
    );
  }
  
  Widget _buildConditionSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar for conditions
          Container(
            margin: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search conditions...',
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppColors.primaryGreen, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                setState(() {
                  // Filter conditions based on search
                });
              },
            ),
          ),
          // Conditions list
          Container(
            height: 200,
            child: ListView.builder(
              itemCount: _healthConditions.length,
              itemBuilder: (context, index) {
                final condition = _healthConditions[index];
                final isSelected = _selectedCondition == condition;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: RadioListTile<String>(
                    title: Text(
                      condition,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppColors.darkGreen : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    value: condition,
                    groupValue: _selectedCondition,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedCondition = value ?? '';
                      });
                    },
                    activeColor: AppColors.primaryGreen,
                    selected: isSelected,
                    selectedTileColor: AppColors.backgroundGreen,
                    dense: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPanchakarmaExperienceSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _panchakarmaOptions.map((experience) {
          final isSelected = _panchakarmaExperience == experience;
          return Container(
            margin: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            child: RadioListTile<String>(
              title: Text(
                experience,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.darkGreen : Colors.black87,
                  fontSize: 14,
                ),
              ),
              value: experience,
              groupValue: _panchakarmaExperience,
              onChanged: (String? value) {
                setState(() {
                  _panchakarmaExperience = value ?? 'New to Panchakarma';
                });
              },
              activeColor: AppColors.primaryGreen,
              selected: isSelected,
              selectedTileColor: AppColors.backgroundGreen,
              dense: true,
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildDateTimeSelector({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryGreen, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, color: AppColors.primaryGreen, size: 18),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.backgroundGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.summarize_outlined, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Appointment Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Patient details
          _buildSummarySection(
            'Patient Information',
            [
              _buildSummaryRow('Name', _nameController.text.isNotEmpty 
                ? _nameController.text : 'Not provided'),
              _buildSummaryRow('Age', _ageController.text.isNotEmpty 
                ? '${_ageController.text} years' : 'Not provided'),
              _buildSummaryRow('Gender', _selectedGender),
              _buildSummaryRow('Phone', _phoneController.text.isNotEmpty 
                ? _phoneController.text : 'Not provided'),
            ],
          ),
          
          Divider(color: AppColors.accentGreen.withOpacity(0.3)),
          
          // Health details
          _buildSummarySection(
            'Health Information',
            [
              _buildSummaryRow('Condition', _selectedCondition.isNotEmpty 
                ? (_selectedCondition == 'Others' 
                  ? _customConditionController.text.isNotEmpty 
                    ? _customConditionController.text
                    : 'Other condition'
                  : _selectedCondition)
                : 'Not selected'),
              _buildSummaryRow('Experience', _panchakarmaExperience),
            ],
          ),
          
          Divider(color: AppColors.accentGreen.withOpacity(0.3)),
          
          // Appointment details
          _buildSummarySection(
            'Appointment Schedule',
            [
              _buildSummaryRow('Date', 
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              _buildSummaryRow('Time', 
                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
              _buildSummaryRow('Practitioner', widget.practitioner.fullName),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummarySection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        SizedBox(height: 8),
        ...children,
        SizedBox(height: 12),
      ],
    );
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPractitionerInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.backgroundGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryGreen, width: 2),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.cardGreen,
                  backgroundImage: widget.practitioner.profileImageUrl != null
                      ? NetworkImage(widget.practitioner.profileImageUrl!)
                      : null,
                  child: widget.practitioner.profileImageUrl == null
                      ? Icon(Icons.person, color: AppColors.primaryGreen, size: 30)
                      : null,
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
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.practitioner.qualification ?? 'Ayurveda Practitioner',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (widget.practitioner.experience != null) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.work_outline, 
                            size: 14, color: AppColors.accentGreen),
                          SizedBox(width: 4),
                          Text(
                            '${widget.practitioner.experience} years experience',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (widget.practitioner.specialties.isNotEmpty) ...[
            SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.practitioner.specialties.take(3).map((spec) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    spec,
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentPage > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: BorderSide(color: AppColors.primaryGreen),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.arrow_back, size: 18),
                  label: Text('Previous', 
                    style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            
            if (_currentPage > 0) SizedBox(width: 16),
            
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting 
                  ? null 
                  : (_currentPage == 2 ? _submitForm : _nextPage),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: _isSubmitting
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(_currentPage == 2 ? Icons.check : Icons.arrow_forward, size: 18),
                label: Text(
                  _isSubmitting 
                    ? 'Submitting...'
                    : (_currentPage == 2 ? 'Book Appointment' : 'Next'),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}