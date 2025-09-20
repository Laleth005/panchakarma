import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'screens/auth/login_screen_new.dart' as new_login;
import 'screens/auth/signup_screen_new.dart';
import 'screens/auth/reset_password_verification.dart';
import 'screens/practitioner/practitioner_home_dashboard.dart';
import 'screens/patient/consulting_page.dart';

void main() async {
  // Catch any global initialization errors
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    print('Starting app initialization...');
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Initialize Firebase with error handling
    print('Initializing Firebase...');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase core initialized successfully');
    } catch (firebaseError) {
      print('Error initializing Firebase: $firebaseError');
      // Log the error but continue - the app might still work with limited functionality
    }
    
    // Initialize Firebase Auth service with retry
    print('Configuring Firebase Auth...');
    bool authConfigured = false;
    for (int attempt = 1; attempt <= 3 && !authConfigured; attempt++) {
      try {
        authConfigured = await FirebaseService.initializeAuth();
        if (authConfigured) {
          print('Firebase Auth configured successfully on attempt $attempt');
        } else {
          print('Firebase Auth configuration attempt $attempt failed, will retry');
        }
      } catch (authError) {
        print('Error during Firebase Auth configuration attempt $attempt: $authError');
        await Future.delayed(Duration(seconds: 1)); // Wait before retry
      }
    }
    
    // Initialize necessary Firestore collections
    try {
      print('Initializing required Firestore collections...');
      
      // Initialize password_resets collection
      await FirebaseFirestore.instance.collection('password_resets').doc('init').set({
        'initialized': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Initialize system_logs collection for tracking errors and events
      await FirebaseFirestore.instance.collection('system_logs').doc('init').set({
        'initialized': true,
        'timestamp': FieldValue.serverTimestamp(),
        'appVersion': '1.0.0', // Update with your app version
      });
      
      print('Required Firestore collections initialized');
    } catch (firestoreError) {
      print('Error initializing Firestore collections: $firestoreError');
      // Continue despite errors - collections might already exist
    }
    
    print('App initialization complete, launching app...');
    
    // Start the application
    runApp(const PanchakarmaApp());
  } catch (e) {
    // Last resort error handling for unexpected initialization errors
    print('Critical error during app initialization: $e');
    
    // Still try to run the app, even with minimal functionality
    runApp(const PanchakarmaApp());
  }
}

class PanchakarmaApp extends StatelessWidget {
  const PanchakarmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Panchakarma Management',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Colors.green.shade600,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green.shade600,
          secondary: Colors.teal,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade500, width: 2),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green.shade700,
            side: BorderSide(color: Colors.green.shade600),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        fontFamily: 'Poppins',
      ),
      home: const new_login.LoginScreen(),
      routes: {
        '/login': (context) => const new_login.LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/practitioner/dashboard': (context) => const PractitionerMainDashboard(practitionerId: ''),
        '/consulting': (context) => const ConsultingPage(),
        '/reset-password-verify': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return ResetPasswordVerification(
            email: args['email']!,
            token: args['token']!,
          );
        },
        // We'll add more routes as we create the corresponding screens
      },
    );
  }
}
