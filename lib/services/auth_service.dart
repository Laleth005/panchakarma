import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/admin_model.dart';
import '../models/practitioner_model.dart';
import '../models/patient_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // Get user role by checking which collection they're in
  Future<UserRole?> getCurrentUserRole() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      String uid = currentUser.uid;

      // Check admin collection
      DocumentSnapshot adminSnapshot =
          await _firestore.collection('admins').doc(uid).get();
      if (adminSnapshot.exists) {
        return UserRole.admin;
      }

      // Check practitioner collection
      DocumentSnapshot practitionerSnapshot =
          await _firestore.collection('practitioners').doc(uid).get();
      if (practitionerSnapshot.exists) {
        return UserRole.practitioner;
      }

      // Check patient collection
      DocumentSnapshot patientSnapshot =
          await _firestore.collection('patients').doc(uid).get();
      if (patientSnapshot.exists) {
        return UserRole.patient;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user data based on role
  Future<dynamic> getCurrentUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      String uid = currentUser.uid;
      UserRole? role = await getCurrentUserRole();

      if (role == null) return null;

      String collection;
      switch (role) {
        case UserRole.admin:
          collection = 'admins';
          final snapshot = await _firestore.collection(collection).doc(uid).get();
          if (snapshot.exists) {
            return AdminModel.fromJson(snapshot.data()!);
          }
          break;
        case UserRole.practitioner:
          collection = 'practitioners';
          final snapshot = await _firestore.collection(collection).doc(uid).get();
          if (snapshot.exists) {
            return PractitionerModel.fromJson(snapshot.data()!);
          }
          break;
        case UserRole.patient:
          collection = 'patients';
          final snapshot = await _firestore.collection(collection).doc(uid).get();
          if (snapshot.exists) {
            return PatientModel.fromJson(snapshot.data()!);
          }
          break;
        default:
          return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create an admin user (should be called by an existing admin)
  Future<void> createAdminUser({
    required String email,
    required String password,
    required String fullName,
    required String clinicName,
    required String clinicAddress,
    String? phoneNumber,
    String? clinicLogo,
  }) async {
    try {
      // First create the user in Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        // Then create the admin document in Firestore
        await _firestore.collection('admins').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'fullName': fullName,
          'role': UserRole.admin.toString().split('.').last,
          'clinicName': clinicName,
          'clinicAddress': clinicAddress,
          'clinicLogo': clinicLogo,
          'phoneNumber': phoneNumber,
          'profileImageUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile(UserRole role, String uid, Map<String, dynamic> data) async {
    try {
      String collection;
      switch (role) {
        case UserRole.admin:
          collection = 'admins';
          break;
        case UserRole.practitioner:
          collection = 'practitioners';
          break;
        case UserRole.patient:
          collection = 'patients';
          break;
        default:
          throw Exception('Invalid user role');
      }
      
      // Add the updated timestamp
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection(collection).doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }
}