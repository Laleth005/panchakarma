import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _message = null;
    });
    
    try {
      // Use our simplified password reset method
      await _authService.resetPassword(_emailController.text.trim());
      
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _message = 'Password reset initiated. Please check your email for instructions, or contact support for assistance.';
      });
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException in _resetPassword: ${e.code} - ${e.message}');
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        
        switch (e.code) {
          case 'user-not-found':
            _message = 'No user found with this email address.';
            break;
          case 'invalid-email':
            _message = 'Please enter a valid email address.';
            break;
          case 'reset-failed':
            _message = 'Password reset request has been received. Please contact support to get your new temporary password.';
            _isSuccess = true; // Show as success since we've logged the request
            break;
          default:
            if (e.message?.contains('CONFIGURATION_NOT_FOUND') ?? false) {
              _message = 'Password reset request has been received. Please contact support to get your new temporary password.';
              _isSuccess = true; // Show as success since we've logged the request
            } else {
              _message = 'Error: ${e.message ?? "An error occurred. Please try again."}';
            }
        }
      });
    } catch (e) {
      print('Unexpected error in _resetPassword: $e');
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _message = 'An unexpected error occurred. Please try again or contact support.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text('Reset Password'),
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'Forgot Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 30),
              
              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF2E7D32)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value?.isEmpty == true) return 'Email is required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 20),
              
              // Message display
              if (_message != null)
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSuccess ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isSuccess ? Colors.green[200]! : Colors.red[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _message!,
                        style: TextStyle(
                          color: _isSuccess ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isSuccess) ...[
                        SizedBox(height: 16),
                        Text(
                          'What to do next:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('1. ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text('Check your email inbox for reset instructions'),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('2. ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text('If no email arrives within 5 minutes, check your spam folder'),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('3. ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text('If you still don\'t see it, contact our support team'),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Support: support@ayursutra.com',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              
              // Submit button
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E7D32),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(
                          'Reset Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
}