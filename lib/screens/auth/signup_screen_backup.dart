import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
// Removed unused import: import '../../services/firebase_service.dart';
import '../../services/recaptcha_configuration.dart';
import 'login_screen_new.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  UserRole _selectedRole = UserRole.patient;
  List<String> _specialties = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Additional fields for Practitioner
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  
  // Additional fields for Patient
  final _dobController = TextEditingController();
  String? _selectedGender;
  final _addressController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();
  
  final List<String> _availableSpecialties = [
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
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Use our custom registration method that handles reCAPTCHA configuration
      UserCredential userCredential = await RecaptchaConfiguration.createUserWithoutRecaptcha(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (userCredential.user != null) {
        // Send email verification
        await userCredential.user!.sendEmailVerification();
        
        // Prepare user data based on role
        Map<String, dynamic> userData = {
          'uid': userCredential.user!.uid,
          'email': _emailController.text.trim(),
          'fullName': _fullNameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'role': _selectedRole.toString().split('.').last,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Add role-specific data
        if (_selectedRole == UserRole.practitioner) {
          userData.addAll({
            'qualification': _qualificationController.text.trim(),
            'experienceYears': int.tryParse(_experienceController.text.trim()) ?? 0,
            'bio': _bioController.text.trim(),
            'specialties': _specialties,
            'isApproved': false, // Requires admin approval
            'rating': 0.0,
            'totalRatings': 0,
          });
          
          // Add practitioner to practitioners collection
          await FirebaseFirestore.instance
              .collection('practitioners')
              .doc(userCredential.user!.uid)
              .set(userData);
        } else {
          // Patient specific data
          userData.addAll({
            'dateOfBirth': _dobController.text.trim(),
            'gender': _selectedGender,
            'address': _addressController.text.trim(),
            'medicalHistory': _medicalHistoryController.text.trim(),
            'allergies': _allergiesController.text.trim(),
          });
          
          // Add patient to patients collection
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(userCredential.user!.uid)
              .set(userData);
        }
        
        // Also store in general users collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);
        
        // Show success message and navigate to login
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.code == 'email-already-in-use') {
          _errorMessage = 'This email is already registered.';
        } else if (e.code == 'weak-password') {
          _errorMessage = 'Password is too weak. Use at least 6 characters.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Please enter a valid email address.';
        } else if (e.code == 'configuration-not-found') {
          _errorMessage = 'Firebase configuration error. Please try again or contact support.';
        } else {
          _errorMessage = 'Registration failed: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred during registration.';
      });
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
              SizedBox(width: 10),
              Text('Success'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your account has been created successfully.'),
              SizedBox(height: 10),
              Text('A verification email has been sent to your email address.'),
              if (_selectedRole == UserRole.practitioner)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Your practitioner account requires approval before you can log in.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.orange[800]),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: Text('Go to Login'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF2E7D32),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F5E4), // Soft natural background color
      appBar: AppBar(
        title: const Text('Register', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(0xFF2E7D32), // Deep green
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Decorative top banner with leaf pattern (smaller than login)
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2E7D32), // Deep green
                    Color(0xFF388E3C), // Medium green
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative leaves pattern
                  Positioned(
                    right: -10,
                    top: -5,
                    child: Opacity(
                      opacity: 0.2,
                      child: Icon(
                        Icons.eco,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    top: 20,
                    child: Text(
                      'Join AyurSutra',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        color: Colors.red.shade100,
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // User Role Selection
                    Text(
                      'Register as:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<UserRole>(
                      segments: const [
                        ButtonSegment<UserRole>(
                          value: UserRole.patient,
                          label: Text('Patient'),
                          icon: Icon(Icons.person),
                        ),
                        ButtonSegment<UserRole>(
                          value: UserRole.practitioner,
                          label: Text('Practitioner'),
                          icon: Icon(Icons.medical_services),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (Set<UserRole> newSelection) {
                        setState(() {
                          _selectedRole = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(MaterialState.selected)) {
                              return Color(0xFF2E7D32); // Selected background color
                            }
                            return Colors.white; // Unselected background color
                          },
                        ),
                        foregroundColor: MaterialStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.white; // Selected text color
                            }
                            return Color(0xFF2E7D32); // Unselected text color
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Basic Information
                    Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Role-specific fields
                    if (_selectedRole == UserRole.practitioner) ...[
                      Text(
                        'Professional Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Qualification
                      TextFormField(
                        controller: _qualificationController,
                        decoration: const InputDecoration(
                          labelText: 'Qualification',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        validator: (value) => value?.isEmpty == true 
                            ? 'Please enter your qualification' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Years of Experience
                      TextFormField(
                        controller: _experienceController,
                        decoration: const InputDecoration(
                          labelText: 'Years of Experience',
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty == true 
                            ? 'Please enter your years of experience' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Specialties
                      Text(
                        'Select your specialties:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: _availableSpecialties.map((specialty) {
                          return FilterChip(
                            label: Text(specialty),
                            selected: _specialties.contains(specialty),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _specialties.add(specialty);
                                } else {
                                  _specialties.remove(specialty);
                                }
                              });
                            },
                            selectedColor: Color(0xFFAED581),
                            checkmarkColor: Color(0xFF2E7D32),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Bio
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(
                          labelText: 'Professional Bio',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        validator: (value) => value?.isEmpty == true 
                            ? 'Please provide a brief professional bio' : null,
                      ),
                    ],
                    
                    if (_selectedRole == UserRole.patient) ...[
                      Text(
                        'Personal Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Date of Birth
                      GestureDetector(
                        onTap: _selectDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dobController,
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              prefixIcon: Icon(Icons.calendar_today),
                              hintText: 'YYYY-MM-DD',
                            ),
                            validator: (value) => value?.isEmpty == true 
                                ? 'Please select your date of birth' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Gender
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        value: _selectedGender,
                        items: ['Male', 'Female', 'Other'].map((String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select your gender';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Medical History
                      TextFormField(
                        controller: _medicalHistoryController,
                        decoration: const InputDecoration(
                          labelText: 'Medical History',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Allergies
                      TextFormField(
                        controller: _allergiesController,
                        decoration: const InputDecoration(
                          labelText: 'Allergies',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Register Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Color(0xFF2E7D32), // Deep green for button
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('REGISTER', style: TextStyle(color: Colors.white)),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account?'),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: Text('Login', style: TextStyle(color: Color(0xFF2E7D32))),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Ayurvedic decorative footer
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.spa, color: Color(0xFF2E7D32), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Begin your wellness journey with AyurSutra',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.spa, color: Color(0xFF2E7D32), size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}