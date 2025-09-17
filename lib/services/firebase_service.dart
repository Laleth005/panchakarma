import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class FirebaseAuthConfig {
  // Configure Firebase Auth to disable recaptcha for testing
  static Future<void> configureAuth() async {
    try {
      print('Configuring Firebase Auth settings...');
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true, // Disable reCAPTCHA verification for testing
        forceRecaptchaFlow: false,
      );
      print('Firebase Auth settings configured successfully');
      
      // Check if the settings were applied
      final user = FirebaseAuth.instance.currentUser;
      print('Current user: ${user?.uid ?? 'Not signed in'}');
    } catch (e) {
      print('Error configuring Firebase Auth settings: $e');
      rethrow;
    }
  }
}

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize Firebase Auth with necessary settings
  static Future<void> initializeAuth() async {
    try {
      await FirebaseAuthConfig.configureAuth();
      print('Firebase Auth configured successfully');
    } catch (e) {
      print('Error configuring Firebase Auth: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get authenticated user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Try Firebase Auth first
      print('Attempting to sign in with Firebase Auth: $email');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      print('Firebase Auth sign-in successful: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('Error signing in with Firebase Auth: $e');
      
      // If Firebase Auth fails, don't throw an error yet
      // We'll try direct Firestore login
      if (e is FirebaseAuthException) {
        if (e.message?.contains('CONFIGURATION_NOT_FOUND') == true ||
            e.code == 'unknown' ||
            e.code == 'user-not-found') {
          print('Firebase Auth failed, will try direct Firestore login');
          return null;
        }
      }
      
      // For any other error, just rethrow
      rethrow;
    }
  }
  
  // Authenticate directly with Firestore
  Future<Map<String, dynamic>?> authenticateWithFirestore(String email, String password) async {
    try {
      print('Attempting to authenticate directly with Firestore: $email');
      
      // Query users collection where email matches
      final QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password) // We stored the password in Firestore for this fallback
          .limit(1)
          .get();
      
      // Check if we found a user
      if (userQuery.docs.isEmpty) {
        print('No matching user found in Firestore');
        return null;
      }
      
      // Get the user data from the first document
      final userData = userQuery.docs.first.data() as Map<String, dynamic>;
      print('Direct Firestore login successful for user: ${userData['email']}');
      
      // Return user data
      return userData;
    } catch (e) {
      print('Error authenticating with Firestore: $e');
      return null;
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(String email, String password) async {
    try {
      // Make sure reCAPTCHA verification is disabled for testing
      await FirebaseAuthConfig.configureAuth();
      
      print('Attempting to register user: $email');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      print('User registered successfully: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('Error registering user: $e');
      if (e is FirebaseAuthException) {
        print('Firebase Auth Error Code: ${e.code}');
        print('Firebase Auth Error Message: ${e.message}');
        
        // If the error is related to reCAPTCHA configuration, return null to indicate
        // that we should try direct Firestore registration instead
        if (e.message?.contains('CONFIGURATION_NOT_FOUND') == true ||
            e.code == 'unknown') {
          print('Firebase Auth failed with reCAPTCHA issue, will try direct Firestore registration');
          return null;
        }
      }
      rethrow;
    }
  }

  // Save user data to Firestore based on role
  Future<void> saveUserData(User user, Map<String, dynamic> userData, UserRole role) async {
    try {
      // Always save to users collection for common data
      await _firestore.collection('users').doc(user.uid).set(userData);

      // Save role-specific data to the appropriate collection
      switch (role) {
        case UserRole.admin:
          await _firestore.collection('admins').doc(user.uid).set(userData);
          break;
        case UserRole.practitioner:
          await _firestore.collection('practitioners').doc(user.uid).set(userData);
          break;
        case UserRole.patient:
          await _firestore.collection('patients').doc(user.uid).set(userData);
          break;
      }
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Determine user role from Firestore
  Future<UserRole?> getUserRole(String uid) async {
    try {
      // Check each collection in order of hierarchy
      DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists) return UserRole.admin;

      DocumentSnapshot practitionerDoc = await _firestore.collection('practitioners').doc(uid).get();
      if (practitionerDoc.exists) return UserRole.practitioner;

      DocumentSnapshot patientDoc = await _firestore.collection('patients').doc(uid).get();
      if (patientDoc.exists) return UserRole.patient;

      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  // Direct user registration to Firestore (bypassing Firebase Auth for testing)
  Future<Map<String, dynamic>> registerDirectlyToFirestore(Map<String, dynamic> userData, UserRole role) async {
    try {
      print('Attempting direct registration to Firestore');
      
      // Generate a custom UID since we don't have one from Firebase Auth
      String customUid = DateTime.now().millisecondsSinceEpoch.toString() + '_' + userData['email'].toString().split('@')[0];
      
      // Add the custom UID to the user data
      userData['uid'] = customUid;
      userData['isDirectRegistration'] = true; // Flag to identify direct registrations
      userData['createdAt'] = FieldValue.serverTimestamp();
      userData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Store in 'users' collection
      await _firestore.collection('users').doc(customUid).set(userData);
      print('User data stored in users collection with ID: $customUid');
      
      // Also store in role-specific collection
      switch (role) {
        case UserRole.admin:
          await _firestore.collection('admins').doc(customUid).set(userData);
          break;
        case UserRole.practitioner:
          await _firestore.collection('practitioners').doc(customUid).set(userData);
          break;
        case UserRole.patient:
          await _firestore.collection('patients').doc(customUid).set(userData);
          break;
      }
      print('User data stored in ${role.toString().split('.').last}s collection');
      
      // Return the user data including the generated UID
      return userData;
    } catch (e) {
      print('Error with direct Firestore registration: $e');
      rethrow;
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      // Update the timestamp
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      // Get the user's role to update the correct collection
      UserRole? role = await getUserRole(uid);
      
      // Update the users collection
      await _firestore.collection('users').doc(uid).update(data);
      
      // Also update the role-specific collection if available
      if (role != null) {
        String collection = role.toString().split('.').last + 's'; // admin -> admins
        await _firestore.collection(collection).doc(uid).update(data);
      }
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }
  
  // Delete user
  Future<void> deleteUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // First delete from Firestore
        String uid = user.uid;
        
        // Get the user's role to delete from the correct collection
        UserRole? role = await getUserRole(uid);
        
        // Delete from users collection
        await _firestore.collection('users').doc(uid).delete();
        
        // Delete from role-specific collection if available
        if (role != null) {
          String collection = role.toString().split('.').last + 's'; // admin -> admins
          await _firestore.collection(collection).doc(uid).delete();
        }
        
        // Then delete the auth user
        await user.delete();
      }
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }
}