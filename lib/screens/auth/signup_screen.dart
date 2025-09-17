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

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedRole == UserRole.practitioner && _specialties.isEmpty) {
      setState(() {
        _errorMessage = "Please select at least one specialty";
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Register user with Firebase Authentication
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      final User? user = userCredential.user;
      if (user != null) {
        // Common user data
        Map<String, dynamic> userData = {
          'uid': user.uid,
          'email': user.email,
          'fullName': _fullNameController.text.trim(),
          'role': _selectedRole.toString().split('.').last,
          'phoneNumber': _phoneController.text.trim(),
          'profileImageUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Role-specific collection and data
        String collection = '';
        Map<String, dynamic> additionalData = {};
        
        switch (_selectedRole) {
          case UserRole.practitioner:
            collection = 'practitioners';
            additionalData = {
              'specialties': _specialties,
              'qualification': _qualificationController.text.trim(),
              'experience': _experienceController.text.trim(),
              'bio': _bioController.text.trim(),
              'isApproved': false,
            };
            break;
          case UserRole.patient:
            collection = 'patients';
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
        
        // Store user data in Firestore
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(user.uid)
            .set(userData);
        
        // Show success and navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedRole == UserRole.practitioner 
                ? 'Registration successful! Please wait for admin approval.'
                : 'Registration successful! You can now login.'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }
      
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green.shade800),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Account',
          style: TextStyle(
            color: Colors.green.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // Role Selection
                Text(
                  'Register as:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<UserRole>(
                        title: Text('Patient'),
                        value: UserRole.patient,
                        groupValue: _selectedRole,
                        onChanged: (UserRole? value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                        activeColor: Colors.green.shade700,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<UserRole>(
                        title: Text('Practitioner'),
                        value: UserRole.practitioner,
                        groupValue: _selectedRole,
                        onChanged: (UserRole? value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                        activeColor: Colors.green.shade700,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                // Common fields for all roles
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                const SizedBox(height: 16),
                
                // Role-specific fields
                if (_selectedRole == UserRole.practitioner) ...[
                  _buildPractitionerFields(),
                ],
                
                if (_selectedRole == UserRole.patient) ...[
                  _buildPatientFields(),
                ],
                
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPractitionerFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Professional Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        TextFormField(
          controller: _qualificationController,
          decoration: InputDecoration(
            labelText: 'Qualification',
            prefixIcon: Icon(Icons.school_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your qualification';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _experienceController,
          decoration: InputDecoration(
            labelText: 'Years of Experience',
            prefixIcon: Icon(Icons.timeline_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your experience';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _bioController,
          decoration: InputDecoration(
            labelText: 'Professional Bio',
            prefixIcon: Icon(Icons.description_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        
        Text(
          'Specialties:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
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
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green.shade700,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildPatientFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        TextFormField(
          controller: _dobController,
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          readOnly: true,
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(Duration(days: 365 * 18)), // 18 years ago
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
              });
            }
          },
        ),
        const SizedBox(height: 16),
        
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Gender',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          value: _selectedGender,
          items: ['Male', 'Female', 'Other']
              .map((gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  ))
              .toList(),
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
        
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Address',
            prefixIcon: Icon(Icons.home_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _medicalHistoryController,
          decoration: InputDecoration(
            labelText: 'Medical History (if any)',
            prefixIcon: Icon(Icons.medical_information_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _allergiesController,
          decoration: InputDecoration(
            labelText: 'Allergies (if any)',
            prefixIcon: Icon(Icons.health_and_safety_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}