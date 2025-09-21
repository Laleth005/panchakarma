import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Green Theme Colors
class AppColors {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color backgroundGreen = Color(0xFFF1F8E9);
  static const Color cardGreen = Color(0xFFE8F5E8);
}

// 1. RENAMED THE CLASS TO ConsultingPage
class ConsultingPage extends StatefulWidget {
  // 2. ADDED the patientId variable to accept the patient's ID
  final String? patientId;

  // 3. MODIFIED the constructor to include patientId
  const ConsultingPage({super.key, this.patientId});

  @override
  _ConsultingPageState createState() => _ConsultingPageState();
}

class _ConsultingPageState extends State<ConsultingPage> {
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
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String _selectedGender = 'Male';
  String _selectedCondition = '';
  String _panchakarmaExperience = 'New to Panchakarma';
  bool _isSubmitting = false;

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
          duration: const Duration(milliseconds: 300),
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
        duration: const Duration(milliseconds: 300),
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.lightGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Date and Time picker methods
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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
            colorScheme: const ColorScheme.light(
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

  // Firebase submission method
  Future<void> _submitForm() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // 4. USE THE PASSED-IN patientId INSTEAD OF GETTING IT FROM FIREBASE AUTH
      final patientId = widget.patientId;
      if (patientId == null) {
        throw Exception('Patient ID is not available. Please log in again.');
      }

      final consultationData = {
        'patientId': patientId, // Use the passed-in patientId
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _selectedGender,
        'phone': _phoneController.text.trim(),
        'healthCondition': _selectedCondition == 'Others'
            ? _customConditionController.text.trim()
            : _selectedCondition,
        'conditionDescription': _conditionDescriptionController.text.trim(),
        'panchakarmaExperience': _panchakarmaExperience,
        'preferredDate': Timestamp.fromDate(_selectedDate),
        'preferredTime':
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'additionalNotes': _additionalNotesController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('consultations')
          .add(consultationData);

      _showSuccessSnackBar('Consultation request submitted successfully!');

      if (mounted) {
        // Navigate back or to confirmation page
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error submitting form: $e');
      _showErrorSnackBar('Failed to submit form. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // --------------------------
  // WIDGET BUILDERS
  // --------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: AppBar(
        title: const Text('Consultation Request'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Prevents manual swiping
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
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          for (int i = 0; i < 3; i++)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: LinearProgressIndicator(
                  value: i <= _currentPage ? 1.0 : 0.0,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(
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
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please provide your basic information',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
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
                const SizedBox(width: 16),
                Expanded(child: _buildGenderSelector()),
              ],
            ),
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your health condition and preferences',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          const Text(
            'Primary Health Condition *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 12),
          _buildConditionSelector(),
          const SizedBox(height: 16),
          if (_selectedCondition == 'Others')
            Column(
              children: [
                _buildTextField(
                  controller: _customConditionController,
                  label: 'Specify your condition',
                  icon: Icons.edit,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
              ],
            ),
          _buildTextField(
            controller: _conditionDescriptionController,
            label: 'Describe your symptoms (optional)',
            icon: Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          const Text(
            'Panchakarma Experience',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 12),
          _buildPanchakarmaExperienceSelector(),
          const SizedBox(height: 24),
          const Text(
            'Preferred Appointment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 12),
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
              const SizedBox(width: 16),
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
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review & Submit',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your information before submitting',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
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
      style: const TextStyle(color: AppColors.darkGreen),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryGreen),
        labelStyle: const TextStyle(color: AppColors.primaryGreen),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accentGreen.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
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
        decoration: const InputDecoration(
          labelText: 'Gender',
          prefixIcon: Icon(Icons.wc, color: AppColors.primaryGreen),
          labelStyle: TextStyle(color: AppColors.primaryGreen),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: ['Male', 'Female', 'Other'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(color: AppColors.darkGreen),
            ),
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
            offset: const Offset(0, 2),
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
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: RadioListTile<String>(
            title: Text(
              option,
              style: const TextStyle(color: AppColors.darkGreen),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryGreen),
            const SizedBox(width: 12),
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
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardGreen.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Name', _nameController.text),
          _buildSummaryRow('Age', _ageController.text),
          _buildSummaryRow('Gender', _selectedGender),
          _buildSummaryRow('Phone', _phoneController.text),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.darkGreen,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(color: Colors.grey[700]),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_currentPage > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Back'),
                ),
              ),
            if (_currentPage > 0) const SizedBox(width: 12),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_currentPage == 2 ? 'Submit' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
