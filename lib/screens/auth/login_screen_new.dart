import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../admin/admin_dashboard.dart';
import '../practitioner/practitioner_home_dashboard.dart';
import '../patient/patient_dashboard.dart';
import 'signup_screen_new.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<UserModel?> _fetchUserData(String uid) async {
    try {
      // First check the users collection for basic info
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String role = userData['role'] ?? 'patient';
        
        // Then fetch detailed data from role-specific collection
        DocumentSnapshot roleDoc;
        if (role == 'practitioner') {
          roleDoc = await FirebaseFirestore.instance
              .collection('practitioners')
              .doc(uid)
              .get();
        } else {
          roleDoc = await FirebaseFirestore.instance
              .collection('patients')
              .doc(uid)
              .get();
        }
        
        if (roleDoc.exists) {
          Map<String, dynamic> roleData = roleDoc.data() as Map<String, dynamic>;
          // Merge basic user data with role-specific data
          userData.addAll(roleData);
        }
        
        return UserModel.fromFirestore(userData);
      }
      
      // Fallback: check role-specific collections directly
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(uid)
          .get();
      
      if (patientDoc.exists) {
        return UserModel.fromFirestore(patientDoc.data() as Map<String, dynamic>);
      }
      
      DocumentSnapshot practitionerDoc = await FirebaseFirestore.instance
          .collection('practitioners')
          .doc(uid)
          .get();
      
      if (practitionerDoc.exists) {
        return UserModel.fromFirestore(practitionerDoc.data() as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  Future<void> _navigateBasedOnRole(UserModel user) async {
    Widget dashboard;
    
    switch (user.role) {
      case UserRole.admin:
        dashboard = const AdminDashboard();
        break;
      case UserRole.practitioner:
        // Check if practitioner is approved
        if (user.isApproved != true) {
          _showApprovalPendingDialog();
          return;
        }
        dashboard = PractitionerHomeDashboard(practitionerId: user.uid);
        break;
      case UserRole.patient:
        dashboard = PatientDashboard(patientId: user.uid);
        break;
    }
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => dashboard),
      (route) => false,
    );
  }

  void _showApprovalPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.pending_actions, color: Colors.orange, size: 50),
        title: Text('Account Pending Approval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your practitioner account is currently under review by our admin team.'),
            SizedBox(height: 16),
            Text('You will be notified via email once your account is approved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              FirebaseAuth.instance.signOut();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.mark_email_unread, color: Colors.blue, size: 50),
        title: Text('Email Verification Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please verify your email address to continue.'),
            SizedBox(height: 16),
            Text('Check your inbox for a verification link.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Verification email sent!'),
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to send verification email'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Resend Email'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              FirebaseAuth.instance.signOut();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Find user in Firestore by email (new method for direct Firestore auth)
  Future<UserModel?> _getUserByEmail(String email) async {
    try {
      print('Searching for user with email: $email');
      
      // Search in users collection
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        Map<String, dynamic> userData = userQuery.docs.first.data() as Map<String, dynamic>;
        String uid = userQuery.docs.first.id;
        
        // Make sure password matches
        if (userData['password'] != _passwordController.text) {
          print('Password mismatch');
          return null;
        }
        
        // Set the uid if it's not there
        userData['uid'] = uid;
        
        print('User found in users collection: $uid');
        return UserModel.fromFirestore(userData);
      }
      
      print('User not found in users collection, checking role-specific collections');
      
      // Try practitioners collection
      QuerySnapshot practitionerQuery = await FirebaseFirestore.instance
          .collection('practitioners')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (practitionerQuery.docs.isNotEmpty) {
        Map<String, dynamic> userData = practitionerQuery.docs.first.data() as Map<String, dynamic>;
        String uid = practitionerQuery.docs.first.id;
        
        // Make sure password matches
        if (userData['password'] != _passwordController.text) {
          print('Password mismatch');
          return null;
        }
        
        // Set the uid if it's not there
        userData['uid'] = uid;
        
        print('User found in practitioners collection: $uid');
        return UserModel.fromFirestore(userData);
      }
      
      // Try patients collection
      QuerySnapshot patientQuery = await FirebaseFirestore.instance
          .collection('patients')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (patientQuery.docs.isNotEmpty) {
        Map<String, dynamic> userData = patientQuery.docs.first.data() as Map<String, dynamic>;
        String uid = patientQuery.docs.first.id;
        
        // Make sure password matches
        if (userData['password'] != _passwordController.text) {
          print('Password mismatch');
          return null;
        }
        
        // Set the uid if it's not there
        userData['uid'] = uid;
        
        print('User found in patients collection: $uid');
        return UserModel.fromFirestore(userData);
      }
      
      print('User not found in any collection');
      return null;
    } catch (e) {
      print('Error searching for user: $e');
      return null;
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Try to find the user in Firestore by email
      final UserModel? user = await _getUserByEmail(_emailController.text.trim());
      
      if (user != null) {
        print('User found, proceeding with login');
        
        // Update last login timestamp
        await _updateLastLogin(user.uid, user.role);
        
        // Navigate to appropriate dashboard based on user role
        if (user.role == UserRole.admin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else if (user.role == UserRole.practitioner) {
          // For practitioners, check if they're approved
          if (user.isApproved != null && !user.isApproved!) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Your practitioner account is pending approval. Please check back later.';
            });
            return;
          }
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PractitionerHomeDashboard(practitionerId: user.uid)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PatientDashboard(patientId: user.uid)),
          );
        }
      } else {
        // User not found or wrong password
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid email or password. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login error: ${e.toString()}';
      });
      print('Login error: $e');
    }
  }

  Future<void> _updateLastLogin(String uid, UserRole role) async {
    try {
      final String collection = role == UserRole.practitioner ? 'practitioners' : 'patients';
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(uid)
          .update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Also update the users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last login: $e');
      // Don't block login if this fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F8E9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1B5E20),
                        Color(0xFF2E7D32),
                        Color(0xFF388E3C),
                        Color(0xFF4CAF50),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        spreadRadius: 3,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative background elements
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      // Main content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // App Icon
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.spa,
                                size: 60,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(height: 20),
                            // App Name
                            Text(
                              'AyurSutra',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your Wellness Journey Begins Here',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Login Form
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 20),
                          
                          // Welcome Text
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: 8),
                          
                          Text(
                            'Sign in to continue your wellness journey',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: 32),
                          
                          // Error Message
                          if (_errorMessage != null)
                            Container(
                              padding: EdgeInsets.all(16),
                              margin: EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red[700]),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Email Field
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Email is required';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          
                          // Password Field
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Color(0xFF2E7D32),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Password is required';
                              return null;
                            },
                          ),
                          
                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Login Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _isLoading
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
                                      SizedBox(width: 16),
                                      Text('Signing In...'),
                                    ],
                                  )
                                : Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Register Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'New to AyurSutra? ',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignupScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Create Account',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 32),
                          
                          // Footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.eco, color: Color(0xFF2E7D32), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Nurturing wellness through ancient wisdom',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.eco, color: Color(0xFF2E7D32), size: 16),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF2E7D32)),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
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
        ),
        validator: validator,
      ),
    );
  }
}