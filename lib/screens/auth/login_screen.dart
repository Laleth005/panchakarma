import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../admin/admin_dashboard.dart';
import '../practitioner/practitioner_dashboard.dart';
import '../patient/patient_dashboard.dart';
import 'signup_screen.dart';

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
  
  // Helper method to navigate based on user ID
  Future<void> _navigateBasedOnUserId(String uid) async {
    // Check in all collections: admin, practitioner, patient
    final DocumentSnapshot adminDoc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(uid)
        .get();
    
    final DocumentSnapshot practitionerDoc = await FirebaseFirestore.instance
        .collection('practitioners')
        .doc(uid)
        .get();
    
    final DocumentSnapshot patientDoc = await FirebaseFirestore.instance
        .collection('patients')
        .doc(uid)
        .get();
    
    // Navigate based on user role
    if (adminDoc.exists) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AdminDashboard()),
      );
    } else if (practitionerDoc.exists) {
      final bool isApproved = practitionerDoc.get('isApproved') ?? false;
      if (!isApproved) {
        setState(() {
          _errorMessage = "Your account is pending approval. Please try again later.";
          _isLoading = false;
        });
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => PractitionerDashboard()),
      );
    } else if (patientDoc.exists) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => PatientDashboard()),
      );
    } else {
      // User exists in auth but not in Firestore collections
      setState(() {
        _errorMessage = "User profile not found. Please contact support.";
        _isLoading = false;
      });
      
      await FirebaseAuth.instance.signOut();
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Configure Firebase Auth settings
      await FirebaseService.initializeAuth();
      
      String email = _emailController.text.trim();
      String password = _passwordController.text;
      
      // Try to sign in with Firebase Auth first
      final UserCredential? userCredential = await _firebaseService.signInWithEmailAndPassword(
        email,
        password,
      );
      
      if (userCredential != null && userCredential.user != null) {
        // Firebase Auth succeeded, proceed with normal flow
        final User user = userCredential.user!;
        print('Signed in with Firebase Auth: ${user.uid}');
        
        // Check in all collections: admin, practitioner, patient
        await _navigateBasedOnUserId(user.uid);
      } 
      else {
        // Firebase Auth failed, try direct Firestore authentication
        print('Trying direct Firestore authentication');
        final userData = await _firebaseService.authenticateWithFirestore(email, password);
        
        if (userData != null) {
          // Direct Firestore authentication succeeded
          print('Direct Firestore authentication successful: ${userData['email']}');
          final String uid = userData['uid'] as String;
          
          // Navigate based on user role from Firestore
          await _navigateBasedOnUserId(uid);
        } 
        else {
          // Both authentication methods failed
          setState(() {
            _errorMessage = "Invalid email or password.";
            _isLoading = false;
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Invalid password.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This user has been disabled.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }
      
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      print('Login error: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo or Icon
                Icon(
                  Icons.spa_outlined,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                
                // App Name
                Text(
                  'Panchakarma',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Tagline
                Text(
                  'Ayurvedic Treatment Management',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
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
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
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
                            // TODO: Implement forgot password functionality
                          },
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.red.shade50,
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Login Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('LOGIN'),
                      ),
                      const SizedBox(height: 24),
                      
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
                            child: const Text('Register Now'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}