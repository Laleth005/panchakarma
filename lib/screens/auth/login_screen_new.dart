import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../admin/admin_dashboard.dart';
import '../practitioner/practitioner_home_dashboard.dart';
import '../patient/patient_dashboard.dart';
import 'signup_screen_new.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Create an instance of FirebaseService
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper method to navigate based on user role
  Future<void> _navigateBasedOnRole(UserRole role, {String? userId}) async {
    Widget dashboard;
    
    // Save userId in shared preferences or similar for session persistence
    // For this demo, we'll use a simpler approach by passing it to dashboards
    
    switch (role) {
      case UserRole.admin:
        dashboard = const AdminDashboard();
        break;
      case UserRole.practitioner:
        // Use our improved practitioner dashboard with user ID
        dashboard = PractitionerHomeDashboard(practitionerId: userId);
        break;
      case UserRole.patient:
        // Pass the userId to the PatientDashboard constructor
        dashboard = PatientDashboard(patientId: userId);
        break;
    }
    
    print("Navigating to ${role.toString()} dashboard with userId: $userId");
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => dashboard),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      print('Attempting to login with email: ${_emailController.text.trim()}');
      
      // Sign in with email and password using our service
      final UserCredential? userCredential = await _firebaseService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (userCredential == null) {
        // Try direct Firestore authentication
        print('Firebase Auth failed, trying direct Firestore authentication');
        final userData = await _firebaseService.authenticateWithFirestore(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        if (userData != null) {
          // Check if this is a network error response
          if (userData.containsKey('isOfflineError') && userData['isOfflineError'] == true) {
            setState(() {
              _errorMessage = userData['message'] as String;
              _isLoading = false;
            });
            return;
          }
          
          // Direct Firestore authentication succeeded
          print('Direct Firestore authentication successful: ${userData['email']}');
          final String uid = userData['uid'] as String;
          
          // Store the user ID in local storage for later use
          // In a real app, you would use SharedPreferences for this
          // SharedPreferences prefs = await SharedPreferences.getInstance();
          // prefs.setString('userId', uid);
          
          // Get user role from our service
          UserRole? role = await _firebaseService.getUserRole(uid);
          print('User role found: $role');
          
          if (role != null) {
            // For patients, special handling
            if (role == UserRole.patient) {
              print('User is a patient, checking if patient data exists');
              
              // Check if the patient document exists in Firestore
              final patientDoc = await FirebaseFirestore.instance
                  .collection('patients')
                  .doc(uid)
                  .get();
              
              if (!patientDoc.exists) {
                print('Patient document not found, creating it');
                
                // Create a basic patient document if it doesn't exist
                await FirebaseFirestore.instance.collection('patients').doc(uid).set({
                  'uid': uid,
                  'email': userData['email'],
                  'fullName': userData['fullName'] ?? 'Patient',
                  'role': 'patient',
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              }
            }
            
            // Navigate based on user role
            await _navigateBasedOnRole(role, userId: uid);
          } else {
            setState(() {
              _errorMessage = "User role not found.";
              _isLoading = false;
            });
          }
        } else {
          // Both authentication methods failed
          setState(() {
            _errorMessage = "Invalid email or password.";
            _isLoading = false;
          });
        }
        return;
      }
      
      // Get user data from Firestore
      final User? user = userCredential.user;
      if (user != null) {
        print('Firebase Auth successful, user UID: ${user.uid}');
        
        // Get user role from our service
        UserRole? role = await _firebaseService.getUserRole(user.uid);
        print('User role found: $role');
        
        if (role != null) {
          // For patients, ensure the patient document exists
          if (role == UserRole.patient) {
            print('User is a patient, checking if patient data exists');
            
            // Check if the patient document exists
            final patientDoc = await FirebaseFirestore.instance
                .collection('patients')
                .doc(user.uid)
                .get();
            
            if (!patientDoc.exists) {
              print('Patient document not found, creating it');
              
              // Create a basic patient document if it doesn't exist
              await FirebaseFirestore.instance.collection('patients').doc(user.uid).set({
                'uid': user.uid,
                'email': user.email,
                'fullName': user.displayName ?? 'Patient',
                'role': 'patient',
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
          
          // Navigate based on user role using our helper method
          await _navigateBasedOnRole(role, userId: user.uid);
        } else {
          // No role found, try to determine role based on collections
          print('No role found, checking collections');
          
          // Check patients collection first
          final patientDoc = await FirebaseFirestore.instance
              .collection('patients')
              .doc(user.uid)
              .get();
          
          if (patientDoc.exists) {
            print('Found user in patients collection');
            await _navigateBasedOnRole(UserRole.patient, userId: user.uid);
            return;
          }
          
          // Check practitioners
          final practitionerDoc = await FirebaseFirestore.instance
              .collection('practitioners')
              .doc(user.uid)
              .get();
          
          if (practitionerDoc.exists) {
            print('Found user in practitioners collection');
            await _navigateBasedOnRole(UserRole.practitioner, userId: user.uid);
            return;
          }
          
          // Check admins
          final adminDoc = await FirebaseFirestore.instance
              .collection('admins')
              .doc(user.uid)
              .get();
          
          if (adminDoc.exists) {
            print('Found user in admins collection');
            await _navigateBasedOnRole(UserRole.admin, userId: user.uid);
            return;
          }
          
          // If we get here, user exists in Firebase Auth but not in Firestore
          // Create a patient account by default
          print('Creating new patient account for user');
          await FirebaseFirestore.instance.collection('patients').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'fullName': user.displayName ?? 'Patient',
            'role': 'patient',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          await _navigateBasedOnRole(UserRole.patient, userId: user.uid);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.code == 'user-not-found') {
          _errorMessage = 'No user found with this email.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Wrong password provided.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Please enter a valid email address.';
        } else if (e.code == 'user-disabled') {
          _errorMessage = 'This account has been disabled.';
        } else {
          _errorMessage = 'Login failed: ${e.message}';
        }
      });
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login failed. Please try again later.';
      });
      print('Unexpected error during login: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  
                  // App Logo
                  const Icon(
                    Icons.health_and_safety_outlined,
                    size: 80,
                    color: Colors.green,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // App Name
                  const Center(
                    child: Text(
                      'Panchakarma',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // App Description
                  const Center(
                    child: Text(
                      'Ayurvedic Treatment Management',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Login Text
                  Text(
                    'Login',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  
                  if (_errorMessage != null) const SizedBox(height: 16),
                  
                  // Email Field
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
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Implement forgot password
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('LOGIN'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Don\'t have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const SignupScreen()),
                          );
                        },
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}