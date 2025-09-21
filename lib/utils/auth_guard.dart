import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen_new.dart';

class AuthGuard {
  static final AuthService _authService = AuthService();

  // Check if user is authenticated
  static Future<bool> isAuthenticated(BuildContext context) async {
    User? user = _authService.currentUser;
    if (user == null) {
      _redirectToLogin(context);
      return false;
    }
    return true;
  }

  // Check if user has a specific role
  static Future<bool> hasRole(
    BuildContext context,
    UserRole requiredRole,
  ) async {
    if (!await isAuthenticated(context)) return false;

    UserRole? userRole = await _authService.getCurrentUserRole();

    if (userRole != requiredRole) {
      _redirectBasedOnRole(context, userRole);
      return false;
    }

    return true;
  }

  // Check if practitioner is approved (for practitioner routes)
  static Future<bool> isPractitionerApproved(BuildContext context) async {
    if (!await hasRole(context, UserRole.practitioner)) return false;

    final userData = await _authService.getCurrentUserData();
    if (userData == null) {
      _redirectToLogin(context);
      return false;
    }

    bool isApproved = userData.isApproved;
    if (!isApproved) {
      // Redirect to pending approval screen
      // TODO: Create and navigate to PendingApprovalScreen
      return false;
    }

    return true;
  }

  // Redirect to login screen
  static void _redirectToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // Redirect based on user role
  static Future<void> _redirectBasedOnRole(
    BuildContext context,
    UserRole? role,
  ) async {
    if (role == null) {
      _redirectToLogin(context);
      return;
    }

    // Import these as needed based on your actual file structure
    switch (role) {
      case UserRole.admin:
        // Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        break;
      case UserRole.practitioner:
        // Check if approved
        final userData = await _authService.getCurrentUserData();
        if (userData != null && userData.isApproved) {
          // Navigator.of(context).pushReplacementNamed('/practitioner/dashboard');
        } else {
          // Navigator.of(context).pushReplacementNamed('/practitioner/pending-approval');
        }
        break;
      case UserRole.patient:
        // Navigator.of(context).pushReplacementNamed('/patient/dashboard');
        break;
    }
  }
}
