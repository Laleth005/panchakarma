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

class PatientConsultationFormPage extends StatefulWidget {
  const PatientConsultationFormPage({Key? key}) : super(key: key);

  @override
  _PatientConsultationFormPageState createState() =>
      _PatientConsultationFormPageState();
}

class _PatientConsultationFormPageState
    extends State<PatientConsultationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _customConditionController =
      TextEditingController();
  final TextEditingController _conditionDescriptionController =
      TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();

  // Form state variables
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay(hour: 10, minute: 0);
  String _selectedGender = 'Male';
  String _selectedCondition = '';
  String _panchakarmaExperience = 'New to Panchakarma';
  bool _isSubmitting = false;

  // User authentication state
  User? _currentUser;
  bool _isCheckingAuth = true;

  // Health conditions list
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
  void initState() {
    super.initState();
    _initializeAuthentication();
  }

  // Initialize authentication and user details
  Future<void> _initializeAuthentication() async {
    try {
      // Get current user
      _currentUser = FirebaseAuth.instance.currentUser;

      if (_currentUser != null) {
        print('✅ User authenticated: ${_currentUser!.uid}');
        print('User email: ${_currentUser!.email}');
        print('User display name: ${_currentUser!.displayName}');

        // Pre-populate form with user data if available
        _prefillUserData();

        // Listen to auth state changes
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
          if (mounted) {
            setState(() {
              _currentUser = user;
            });

            if (user == null) {
              print('❌ User signed out during form session');
              _showErrorSnackBar('Session expired. Please login again.');
              Navigator.of(context).pop();
            }
          }
        });
      } else {
        print('❌ No authenticated user found');
        _showErrorSnackBar('Please login first to access this form');
        Navigator.of(context).pop();
        return;
      }
    } catch (e) {
      print('❌ Authentication initialization error: $e');
      _showErrorSnackBar('Authentication error. Please try again.');
      Navigator.of(context).pop();
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  // Pre-fill form with user data
  void _prefillUserData() {
    if (_currentUser != null) {
      // Pre-fill name if available
      if (_currentUser!.displayName != null &&
          _currentUser!.displayName!.isNotEmpty) {
        _nameController.text = _currentUser!.displayName!;
      }
    }
  }

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

  // Navigation methods
  void _nextPage() {
    if (_validateCurrentPage()) {
      if (_currentPage < 2) {
        setState(() {
          _currentPage++;
        });
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _validatePersonalInfo();
      case 1:
        return _validateHealthInfo();
      case 2:
        return true; // Summary page doesn't need validation
      default:
        return false;
    }
  }

  bool _validatePersonalInfo() {
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your name');
      return false;
    }
    if (_ageController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your age');
      return false;
    }
    int? age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 1 || age > 120) {
      _showErrorSnackBar('Please enter a valid age (1-120)');
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your phone number');
      return false;
    }
    if (_phoneController.text.trim().length < 10) {
      _showErrorSnackBar('Please enter a valid phone number');
      return false;
    }
    return true;
  }

  bool _validateHealthInfo() {
    if (_selectedCondition.isEmpty) {
      _showErrorSnackBar('Please select a health condition');
      return false;
    }
    if (_selectedCondition == 'Others' &&
        _customConditionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please specify your condition');
      return false;
    }
    return true;
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.lightGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Date and Time picker methods
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.darkGreen,
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.darkGreen,
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

  // Enhanced Firebase submission method
  Future<void> _submitForm() async {
    // First validate all data
    if (!_validateAllData()) {
      return;
    }

    // Check if user is still authenticated
    if (_currentUser == null) {
      _showErrorSnackBar('Session expired. Please login again.');
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('🚀 Starting form submission for user: ${_currentUser!.uid}');

      // Refresh the user token to ensure it's valid
      await _currentUser!.reload();
      String? idToken = await _currentUser!.getIdToken(true);

      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'token-not-available',
          message: 'Unable to get authentication token',
        );
      }

      print('✅ Authentication token refreshed successfully');

      // Prepare appointment data with comprehensive user info
      final appointmentData = <String, dynamic>{
        // User authentication details
        'userId': _currentUser!.uid,
        'userEmail': _currentUser!.email ?? 'No email provided',
        'userDisplayName':
            _currentUser!.displayName ?? _nameController.text.trim(),
        'phoneVerified': _currentUser!.phoneNumber != null,
        'emailVerified': _currentUser!.emailVerified,

        // Patient information
        'patientName': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'gender': _selectedGender,
        'phoneNumber': _phoneController.text.trim(),

        // Health information
        'healthCondition': _selectedCondition == 'Others'
            ? _customConditionController.text.trim()
            : _selectedCondition,
        'conditionDescription': _conditionDescriptionController.text.trim(),
        'panchakarmaExperience': _panchakarmaExperience,

        // Appointment details
        'appointmentDate': Timestamp.fromDate(_selectedDate),
        'appointmentTime':
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'appointmentDateTime': Timestamp.fromDate(
          DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime.hour,
            _selectedTime.minute,
          ),
        ),

        // Additional information
        'additionalNotes': _additionalNotesController.text.trim(),

        // Status and metadata
        'status': 'pending',
        'appointmentType': 'consultation',
        'paymentStatus': 'pending',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'submittedAt': DateTime.now().toIso8601String(),

        // Device and session info
        'submissionSource': 'mobile_app',
        'deviceInfo': 'flutter_app',
      };

      print(
        '📝 Appointment data prepared with ${appointmentData.keys.length} fields',
      );

      // Check Firestore connectivity
      await FirebaseFirestore.instance.disableNetwork();
      await FirebaseFirestore.instance.enableNetwork();
      print('✅ Firestore network connectivity verified');

      // Submit to Firestore with retry logic
      DocumentReference docRef;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          docRef = await FirebaseFirestore.instance
              .collection('appointments')
              .add(appointmentData);

          print('✅ Appointment saved successfully with ID: ${docRef.id}');
          break;
        } catch (e) {
          retryCount++;
          print('⚠️ Attempt $retryCount failed: $e');

          if (retryCount >= maxRetries) {
            throw e;
          }

          // Wait before retry
          await Future.delayed(Duration(seconds: retryCount));
        }
      }

      // Verify the document was created

      // Wait for user to see the success message
      await Future.delayed(Duration(seconds: 2));

      // Navigate back to dashboard
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } on FirebaseAuthException catch (e) {
      print('🔥 Firebase Auth Error: ${e.code} - ${e.message}');
      String errorMessage = 'Authentication error: ';

      switch (e.code) {
        case 'user-token-expired':
        case 'token-not-available':
        case 'invalid-user-token':
          errorMessage += 'Session expired. Please login again.';
          // Navigate back to login
          Navigator.of(context).popUntil((route) => route.isFirst);
          break;
        case 'user-disabled':
          errorMessage += 'Your account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage += 'User account not found. Please login again.';
          break;
        default:
          errorMessage += 'Please login again and retry.';
      }

      _showErrorSnackBar(errorMessage);
    } on FirebaseException catch (e) {
      print('🔥 Firebase Firestore Error: ${e.code} - ${e.message}');
      String errorMessage = 'Failed to submit appointment. ';

      switch (e.code) {
        case 'permission-denied':
          errorMessage += 'Access denied. Please check your login status.';
          break;
        case 'unavailable':
          errorMessage +=
              'Service unavailable. Please check your internet connection.';
          break;
        case 'unauthenticated':
          errorMessage += 'Authentication required. Please login again.';
          break;
        case 'deadline-exceeded':
        case 'cancelled':
          errorMessage += 'Request timed out. Please try again.';
          break;
        case 'resource-exhausted':
          errorMessage +=
              'Service temporarily overloaded. Please try again later.';
          break;
        default:
          errorMessage += 'Error code: ${e.code}. Please try again.';
      }

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      print('❌ General Error during submission: $e');
      _showErrorSnackBar('Unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Save appointment ID to user's profile for tracking
  Future<void> _saveAppointmentToUserProfile(String appointmentId) async {
    try {
      if (_currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('appointments')
            .doc(appointmentId)
            .set({
              'appointmentId': appointmentId,
              'status': 'pending',
              'type': 'consultation',
              'createdAt': FieldValue.serverTimestamp(),
            });
        print('✅ Appointment reference saved to user profile');
      }
    } catch (e) {
      print('⚠️ Failed to save appointment reference to user profile: $e');
      // This is not critical, so we don't show error to user
    }
  }

  // Method to validate all data before submission
  bool _validateAllData() {
    // Validate personal info
    if (!_validatePersonalInfo()) {
      setState(() {
        _currentPage = 0;
      });
      _pageController.animateToPage(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return false;
    }

    // Validate health info
    if (!_validateHealthInfo()) {
      setState(() {
        _currentPage = 1;
      });
      _pageController.animateToPage(
        1,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return false;
    }

    return true;
  }

  // --------------------------
  // WIDGET BUILDERS
  // --------------------------

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking authentication
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: AppColors.backgroundGreen,
        appBar: AppBar(
          title: Text('Consultation Request'),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryGreen),
              SizedBox(height: 16),
              Text(
                'Verifying authentication...',
                style: TextStyle(color: AppColors.darkGreen),
              ),
            ],
          ),
        ),
      );
    }

    // Show error if user is not authenticated
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundGreen,
        appBar: AppBar(
          title: Text('Authentication Required'),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: AppColors.primaryGreen),
              SizedBox(height: 16),
              Text(
                'Please login to access this form',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Main form UI
    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: AppBar(
        title: Text('Consultation Request'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Show user indicator
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Hi, ${_currentUser!.displayName?.split(' ').first ?? 'User'}',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildPersonalInfoPage(),
                _buildHealthInfoPage(),
                _buildSummaryPage(),
              ],
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          for (int i = 0; i < 3; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                child: LinearProgressIndicator(
                  value: i <= _currentPage ? 1.0 : 0.0,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryGreen,
                  ),
                  minHeight: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
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
            SizedBox(height: 8),
            Text(
              'Please provide your basic information',
              style: TextStyle(color: Colors.grey[600]),
            ),

            // Show user account info
            if (_currentUser != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accentGreen.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Logged in as: ${_currentUser!.email}',
                        style: TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 24),

            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _ageController,
                    label: 'Age',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your age';
                      }
                      int? age = int.tryParse(value.trim());
                      if (age == null || age < 1 || age > 120) {
                        return 'Enter valid age (1-120)';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(child: _buildGenderSelector()),
              ],
            ),
            SizedBox(height: 16),

            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.trim().length < 10) {
                  return 'Enter valid phone number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthInfoPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
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
          SizedBox(height: 8),
          Text(
            'Tell us about your health condition and preferences',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),

          Text(
            'Primary Health Condition *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
          SizedBox(height: 12),
          _buildConditionSelector(),
          SizedBox(height: 16),

          if (_selectedCondition == 'Others')
            Column(
              children: [
                _buildTextField(
                  controller: _customConditionController,
                  label: 'Specify your condition',
                  icon: Icons.edit,
                  maxLines: 2,
                ),
                SizedBox(height: 16),
              ],
            ),

          _buildTextField(
            controller: _conditionDescriptionController,
            label: 'Describe your symptoms (optional)',
            icon: Icons.description,
            maxLines: 3,
          ),
          SizedBox(height: 24),

          Text(
            'Panchakarma Experience',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
          SizedBox(height: 12),
          _buildPanchakarmaExperienceSelector(),
          SizedBox(height: 24),

          Text(
            'Preferred Appointment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildDateTimeSelector(
                  label: 'Date',
                  value:
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  icon: Icons.calendar_today,
                  onTap: _selectDate,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildDateTimeSelector(
                  label: 'Time',
                  value:
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  icon: Icons.access_time,
                  onTap: _selectTime,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          _buildTextField(
            controller: _additionalNotesController,
            label: 'Additional Notes (optional)',
            icon: Icons.note_add,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Submit',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please review your information before submitting',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          _buildSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: AppColors.darkGreen),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryGreen),
        labelStyle: TextStyle(color: AppColors.primaryGreen),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accentGreen.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accentGreen.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: 'Gender',
          prefixIcon: Icon(Icons.wc, color: AppColors.primaryGreen),
          labelStyle: TextStyle(color: AppColors.primaryGreen),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: ['Male', 'Female', 'Other'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: TextStyle(color: AppColors.darkGreen)),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedGender = newValue ?? 'Male';
          });
        },
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
      child: SizedBox(
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
                    color: isSelected
                        ? AppColors.primaryGreen
                        : AppColors.darkGreen,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                value: condition,
                groupValue: _selectedCondition,
                activeColor: AppColors.primaryGreen,
                onChanged: (value) {
                  setState(() {
                    _selectedCondition = value ?? '';
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPanchakarmaExperienceSelector() {
    return Column(
      children: _panchakarmaOptions.map((option) {
        return Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          child: RadioListTile<String>(
            title: Text(option, style: TextStyle(color: AppColors.darkGreen)),
            value: option,
            groupValue: _panchakarmaExperience,
            activeColor: AppColors.primaryGreen,
            onChanged: (value) {
              setState(() {
                _panchakarmaExperience = value ?? '';
              });
            },
          ),
        );
      }).toList(),
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryGreen),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    value,
                    style: TextStyle(fontSize: 16, color: AppColors.darkGreen),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardGreen.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
          SizedBox(height: 12),

          // User Account Info
          if (_currentUser != null) ...[
            _buildSummaryRow(
              'Account Email',
              _currentUser!.email ?? 'Not available',
            ),
            _buildSummaryRow(
              'User ID',
              _currentUser!.uid.substring(0, 8) + '...',
            ),
            Divider(color: AppColors.accentGreen.withOpacity(0.5)),
          ],

          // Personal Information
          _buildSummaryRow('Name', _nameController.text),
          _buildSummaryRow('Age', _ageController.text),
          _buildSummaryRow('Gender', _selectedGender),
          _buildSummaryRow('Phone', _phoneController.text),

          Divider(color: AppColors.accentGreen.withOpacity(0.5)),

          // Health Information
          _buildSummaryRow(
            'Condition',
            _selectedCondition == 'Others'
                ? _customConditionController.text
                : _selectedCondition,
          ),
          if (_conditionDescriptionController.text.trim().isNotEmpty)
            _buildSummaryRow(
              'Description',
              _conditionDescriptionController.text,
            ),
          _buildSummaryRow('Experience', _panchakarmaExperience),

          Divider(color: AppColors.accentGreen.withOpacity(0.5)),

          // Appointment Information
          _buildSummaryRow(
            'Preferred Date',
            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          ),
          _buildSummaryRow(
            'Preferred Time',
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          ),
          if (_additionalNotesController.text.trim().isNotEmpty)
            _buildSummaryRow(
              'Additional Notes',
              _additionalNotesController.text,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.darkGreen,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            if (_currentPage > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Back'),
                ),
              ),
            if (_currentPage > 0) SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : _currentPage == 2
                    ? _submitForm
                    : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Submitting...'),
                        ],
                      )
                    : Text(_currentPage == 2 ? 'Submit Appointment' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
