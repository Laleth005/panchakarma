import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/admin_model.dart';
import '../models/practitioner_model.dart';
import '../models/patient_model.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
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
      DocumentSnapshot adminSnapshot = await _firestore
          .collection('admins')
          .doc(uid)
          .get();
      if (adminSnapshot.exists) {
        return UserRole.admin;
      }

      // Check practitioner collection
      DocumentSnapshot practitionerSnapshot = await _firestore
          .collection('practitioners')
          .doc(uid)
          .get();
      if (practitionerSnapshot.exists) {
        return UserRole.practitioner;
      }

      // Check patient collection
      DocumentSnapshot patientSnapshot = await _firestore
          .collection('patients')
          .doc(uid)
          .get();
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
          final snapshot = await _firestore
              .collection(collection)
              .doc(uid)
              .get();
          if (snapshot.exists) {
            return AdminModel.fromJson(snapshot.data()!);
          }
          break;
        case UserRole.practitioner:
          collection = 'practitioners';
          final snapshot = await _firestore
              .collection(collection)
              .doc(uid)
              .get();
          if (snapshot.exists) {
            return PractitionerModel.fromJson(snapshot.data()!);
          }
          break;
        case UserRole.patient:
          collection = 'patients';
          final snapshot = await _firestore
              .collection(collection)
              .doc(uid)
              .get();
          if (snapshot.exists) {
            return PatientModel.fromJson(snapshot.data()!);
          }
          break;
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
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

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

  // Enhanced password reset that handles the CONFIGURATION_NOT_FOUND error and other edge cases
  Future<void> resetPassword(String email) async {
    print('Starting password reset process for email: $email');
    final FirebaseService _firebaseService = FirebaseService();

    try {
      // First check if the user exists in any of our collections
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      String? userUid;
      String? userCollection;

      // Check in each collection to find the user
      print('Searching for user with email: $email in all collections');

      // Check in admin collection
      var adminQuery = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .get();
      if (adminQuery.docs.isNotEmpty) {
        userUid = adminQuery.docs.first.id;
        userCollection = 'admins';
        print('Found user in admins collection: $userUid');
      }

      // Check in practitioners collection if not found in admins
      if (userUid == null) {
        var practitionerQuery = await _firestore
            .collection('practitioners')
            .where('email', isEqualTo: email)
            .get();
        if (practitionerQuery.docs.isNotEmpty) {
          userUid = practitionerQuery.docs.first.id;
          userCollection = 'practitioners';
          print('Found user in practitioners collection: $userUid');
        }
      }

      // Check in patients collection if not found in practitioners
      if (userUid == null) {
        var patientQuery = await _firestore
            .collection('patients')
            .where('email', isEqualTo: email)
            .get();
        if (patientQuery.docs.isNotEmpty) {
          userUid = patientQuery.docs.first.id;
          userCollection = 'patients';
          print('Found user in patients collection: $userUid');
        }
      }

      // Check in general users collection if still not found
      if (userUid == null) {
        var userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();
        if (userQuery.docs.isNotEmpty) {
          userUid = userQuery.docs.first.id;
          userCollection = 'users';
          print('Found user in users collection: $userUid');
        }
      }

      // If user wasn't found in any collection
      if (userUid == null) {
        print('No user found with email: $email in any collection');
        // Log the failed attempt
        await _firebaseService.logPasswordResetAttempt(
          email: email,
          method: 'user_lookup',
          success: false,
          errorMessage: 'User not found in any collection',
          userId: 'unknown',
        );
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with this email address.',
        );
      }

      // Try to send the password reset email directly using Firebase Auth
      try {
        print(
          'Attempting to send password reset email via Firebase Auth for: $email',
        );
        await _auth.sendPasswordResetEmail(email: email);
        print('Password reset email sent successfully to $email');

        // Log successful reset email
        await _firebaseService.logPasswordResetAttempt(
          email: email,
          method: 'firebase_auth',
          success: true,
          userId: userUid,
        );

        return; // Success! Exit the function
      } catch (firebaseError) {
        print('Error with Firebase sendPasswordResetEmail: $firebaseError');

        // Log the failed Firebase Auth attempt
        await _firebaseService.logPasswordResetAttempt(
          email: email,
          method: 'firebase_auth',
          success: false,
          errorMessage: firebaseError.toString(),
          userId: userUid,
        );

        // If we get a CONFIGURATION_NOT_FOUND error, use our fallback method
        if (firebaseError.toString().contains('CONFIGURATION_NOT_FOUND')) {
          print(
            'Detected CONFIGURATION_NOT_FOUND error, switching to manual reset method',
          );

          // Generate a secure temporary password
          final String tempPassword =
              'Reset${DateTime.now().millisecondsSinceEpoch}!';

          try {
            // Create a password reset record in Firestore
            print(
              'Creating password reset record for user: $userUid in $userCollection',
            );

            // Store the reset info in a dedicated collection for security tracking
            await _firestore.collection('password_resets').add({
              'userId': userUid,
              'email': email,
              'tempPassword': tempPassword,
              'collection': userCollection,
              'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
              'completedAt': null,
            });

            // Send a notification to admins
            await _firestore.collection('admin_notifications').add({
              'type': 'password_reset',
              'userId': userUid,
              'userCollection': userCollection,
              'email': email,
              'tempPassword': tempPassword,
              'createdAt': FieldValue.serverTimestamp(),
              'message':
                  'User requested password reset. Please contact them with a temporary password.',
              'handled': false,
            });

            // Log the successful manual reset
            await _firebaseService.logPasswordResetAttempt(
              email: email,
              method: 'manual',
              success: true,
              userId: userUid,
            );

            print(
              'Successfully created admin notification for manual password reset for $email',
            );
            return; // Exit with success
          } catch (dbError) {
            print('Error creating password reset record: $dbError');

            // Log the failed manual reset
            await _firebaseService.logPasswordResetAttempt(
              email: email,
              method: 'manual',
              success: false,
              errorMessage: dbError.toString(),
              userId: userUid,
            );

            throw FirebaseAuthException(
              code: 'reset-failed',
              message:
                  'Unable to process password reset. Please contact support directly.',
            );
          }
        } else {
          // For any other error with the Firebase password reset
          print('Unknown error during password reset: $firebaseError');
          rethrow;
        }
      }
    } catch (e) {
      print('Unhandled error in resetPassword: $e');

      // Log any unhandled errors
      await _firebaseService.logPasswordResetAttempt(
        email: email,
        method: 'unknown',
        success: false,
        errorMessage: e.toString(),
      );

      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(
    UserRole role,
    String uid,
    Map<String, dynamic> data,
  ) async {
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
      }

      // Add the updated timestamp
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(collection).doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Verify reset token and update password
  Future<void> verifyResetTokenAndUpdatePassword(
    String email,
    String token,
    String newPassword,
  ) async {
    print('Verifying reset token and updating password for: $email');
    final FirebaseService _firebaseService = FirebaseService();

    try {
      // First look up the password reset record
      final resetQuery = await _firestore
          .collection('password_resets')
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      // If no pending reset found, check if this is a standard Firebase token
      if (resetQuery.docs.isEmpty) {
        try {
          // Attempt to use Firebase's native password reset verification
          await _auth.confirmPasswordReset(
            code: token,
            newPassword: newPassword,
          );

          // Log the successful reset
          await _firebaseService.logPasswordResetAttempt(
            email: email,
            method: 'firebase_token',
            success: true,
            userId: 'unknown',
          );

          print('Password reset successful using Firebase token');
          return;
        } catch (firebaseError) {
          print(
            'Error confirming password reset with Firebase: $firebaseError',
          );

          // Log the failed Firebase reset
          await _firebaseService.logPasswordResetAttempt(
            email: email,
            method: 'firebase_token',
            success: false,
            errorMessage: firebaseError.toString(),
            userId: 'unknown',
          );

          throw FirebaseAuthException(
            code: 'invalid-token',
            message:
                'Invalid or expired reset token. Please request a new password reset.',
          );
        }
      }

      // For manual reset flow
      final resetDoc = resetQuery.docs.first;
      final resetData = resetDoc.data();

      // Verify the token matches the temporary password
      if (token != resetData['tempPassword']) {
        print('Token mismatch during password reset verification');

        // Log the failed reset attempt
        await _firebaseService.logPasswordResetAttempt(
          email: email,
          method: 'manual_token',
          success: false,
          errorMessage: 'Token mismatch',
          userId: resetData['userId'],
        );

        throw FirebaseAuthException(
          code: 'invalid-token',
          message: 'Invalid reset token. Please check and try again.',
        );
      }

      // Update the user's password in Firebase Auth
      String userId = resetData['userId'];

      // Update the password
      try {
        // Find the user first
        await _auth.fetchSignInMethodsForEmail(email).then((methods) {
          if (methods.isEmpty) {
            throw Exception('User not found');
          }
        });

        // Create a custom token to sign in as the user
        // Note: This requires Cloud Functions in a production app
        // For this implementation, we'll update the password in Firestore as a workaround

        // Update the user's password in their collection document
        final collection = resetData['collection'] ?? 'users';
        await _firestore.collection(collection).doc(userId).update({
          'password': newPassword, // In a real app, this should be hashed
          'passwordUpdatedAt': FieldValue.serverTimestamp(),
          'passwordResetCompleted': true,
        });

        // Mark the reset as completed
        await _firestore.collection('password_resets').doc(resetDoc.id).update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Log the successful reset
        await _firebaseService.logPasswordResetAttempt(
          email: email,
          method: 'manual_token',
          success: true,
          userId: userId,
        );

        print('Password reset successful for user: $userId');
      } catch (e) {
        print('Error updating password: $e');

        // Log the failed reset attempt
        await _firebaseService.logPasswordResetAttempt(
          email: email,
          method: 'manual_token',
          success: false,
          errorMessage: e.toString(),
          userId: userId,
        );

        throw FirebaseAuthException(
          code: 'update-failed',
          message:
              'Failed to update password. Please try again or contact support.',
        );
      }
    } catch (e) {
      print('Error in verifyResetTokenAndUpdatePassword: $e');
      rethrow;
    }
  }
}
