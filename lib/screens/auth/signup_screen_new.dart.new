import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import 'login_screen.dart';

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

  // Create an instance of FirebaseService
  final FirebaseService _firebaseService = FirebaseService();

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

  void _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Prepare user data (we'll need this regardless of registration method)
      Map<String, dynamic> userData = {
        'email': _emailController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'role': _selectedRole.toString().split('.').last,
        'phoneNumber': _phoneController.text.trim(),
        'profileImageUrl': null,
        'password': _passwordController.text, // Store the password for direct login
      };
      
      // Role-specific data
      Map<String, dynamic> additionalData = {};
      
      switch (_selectedRole) {
        case UserRole.practitioner:
          additionalData = {
            'specialties': _specialties,
            'qualification': _qualificationController.text.trim(),
            'experience': _experienceController.text.trim(),
            'bio': _bioController.text.trim(),
            'isApproved': false,
          };
          break;
        case UserRole.patient:
          additionalData = {
            'dateOfBirth': _dobController.text.trim(),
            'gender': _selectedGender,
            'address': _addressController.text.trim(),
            'medicalHistory': _medicalHistoryController.text.trim(),
            'allergies': _allergiesController.text.trim(),
            'doshaType': null,  // Will be determined by practitioner
            'primaryPractitionerId': null,  // Will be assigned later
          };
          break;
        default:
          // Admin users cannot register themselves, they are pre-created
          throw Exception("Invalid role for registration");
      }
      
      // Combine common and role-specific data
      userData.addAll(additionalData);
      
      // Try to register with Firebase Authentication first
      final UserCredential? userCredential = await _firebaseService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // If Firebase Auth succeeded, use that user
      if (userCredential != null && userCredential.user != null) {
        final User user = userCredential.user!;
        
        // Add Firebase UID to the user data
        userData['uid'] = user.uid;
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['updatedAt'] = FieldValue.serverTimestamp();
        
        // Store user data in Firestore using our service
        await _firebaseService.saveUserData(user, userData, _selectedRole);
        
        showSuccessAndNavigate('Firebase Auth registration successful!');
      } 
      // If Firebase Auth failed with recaptcha issue, use direct Firestore registration
      else {
        print('Firebase Auth registration failed, trying direct Firestore registration');
        
        // Use direct registration to Firestore
        await _firebaseService.registerDirectlyToFirestore(userData, _selectedRole);
        
        showSuccessAndNavigate('Direct registration successful! You can log in with your email and password.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.code == 'weak-password') {
          _errorMessage = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'This email is already registered.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Please enter a valid email address.';
        } else {
          _errorMessage = 'Registration failed: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Registration failed. Please try again later.';
      });
      print('Registration error: $e');
    }
  }
  
  // Helper method to show success message and navigate
  void showSuccessAndNavigate(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate back to login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                  style: Theme.of(context).textTheme.titleMedium,
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
                ),
                const SizedBox(height: 24),
                
                // Basic Information
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleLarge,
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
                    labelText: 'Email',
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
                
                // Phone Number
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
                    'Practitioner Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Specialties
                  Text(
                    'Specialties:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSpecialties.map((specialty) {
                      final isSelected = _specialties.contains(specialty);
                      return FilterChip(
                        label: Text(specialty),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _specialties.add(specialty);
                            } else {
                              _specialties.remove(specialty);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Qualification
                  TextFormField(
                    controller: _qualificationController,
                    decoration: const InputDecoration(
                      labelText: 'Qualification',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your qualification';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Experience
                  TextFormField(
                    controller: _experienceController,
                    decoration: const InputDecoration(
                      labelText: 'Years of Experience',
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your years of experience';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Bio
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Professional Bio',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your professional bio';
                      }
                      return null;
                    },
                  ),
                ] else if (_selectedRole == UserRole.patient) ...[
                  Text(
                    'Patient Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Date of Birth
                  TextFormField(
                    controller: _dobController,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth (YYYY-MM-DD)',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your date of birth';
                      }
                      // Basic date validation
                      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
                        return 'Please use format YYYY-MM-DD';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Gender
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.people_outline),
                    ),
                    value: _selectedGender,
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
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
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('REGISTER'),
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
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}