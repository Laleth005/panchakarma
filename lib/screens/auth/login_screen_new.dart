import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../admin/admin_dashboard.dart';
import '../practitioner/practitioner_dashboard.dart';
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
    
    switch (role) {
      case UserRole.admin:
        dashboard = const AdminDashboard();
        break;
      case UserRole.practitioner:
        // Check if the practitioner is approved
        if (userId != null) {
          DocumentSnapshot practitionerDoc = await FirebaseFirestore.instance
              .collection('practitioners')
              .doc(userId)
              .get();
          
          if (practitionerDoc.exists) {
            Map<String, dynamic> data = practitionerDoc.data() as Map<String, dynamic>;
            bool isApproved = data['isApproved'] ?? false;
            
            if (!isApproved) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Your practitioner account is pending approval.';
              });
              await FirebaseAuth.instance.signOut();
              return;
            }
          }
        }
        
        dashboard = const PractitionerDashboard();
        break;
      case UserRole.patient:
        dashboard = const PatientDashboard();
        break;
    }
    
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
      // Sign in with email and password using our service
      final UserCredential? userCredential = await _firebaseService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (userCredential == null) {
        // Try direct Firestore authentication
        print('Trying direct Firestore authentication');
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
          
          // Get user role from our service
          UserRole? role = await _firebaseService.getUserRole(uid);
          
          if (role != null) {
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
        // Get user role from our service
        UserRole? role = await _firebaseService.getUserRole(user.uid);
        
        if (role != null) {
          // Navigate based on user role using our helper method
          await _navigateBasedOnRole(role, userId: user.uid);
        } else {
          // No role found
          setState(() {
            _isLoading = false;
            _errorMessage = 'User account not found.';
          });
          await _firebaseService.signOut();
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
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login failed. Please try again later.';
      });
      print(e);
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