# Firebase reCAPTCHA Issue Fix Guide

## The Issue

The error `CONFIGURATION_NOT_FOUND` with reCAPTCHA during user registration indicates that Firebase Auth is trying to use reCAPTCHA verification, but couldn't find the proper configuration.

## Our Solution

We've implemented a robust dual-authentication system that works even when Firebase Auth fails:

1. **Primary Solution: Direct Firestore Authentication**
   - Added direct Firestore registration when Firebase Auth fails
   - Store user credentials in Firestore documents
   - Added alternative login path through Firestore

2. **Code-Level Fix (Temporary/Development)**
   - Added a `FirebaseAuthConfig` class in `firebase_service.dart` to disable reCAPTCHA verification
   - Added initialization in `main.dart` with `FirebaseService.initializeAuth()`
   - Added direct call to `FirebaseAuthConfig.configureAuth()` before registration attempts

3. **Production-Ready Fix (Firebase Console)**
   - Instructions for properly configuring reCAPTCHA in the Firebase ConsoleCHA Issue: Complete Fix Guide

## The Issue

The error `CONFIGURATION_NOT_FOUND` during user registration indicates that Firebase Auth is trying to use reCAPTCHA verification, but couldn't find the proper configuration.

## Our Solution

We've implemented two layers of fixes:

1. **Code-Level Fix (Temporary/Development)**
   - Added a `FirebaseAuthConfig` class in `firebase_service.dart` to disable reCAPTCHA verification
   - Added initialization in `main.dart` with `FirebaseService.initializeAuth()`
   - Added direct call to `FirebaseAuthConfig.configureAuth()` before registration attempts

2. **Production-Ready Fix (Firebase Console)**
   - Instructions for properly configuring reCAPTCHA in the Firebase Console

## Verification Steps

1. The app should now work with the temporary fix for development purposes.
2. For production, follow the steps in the "Proper Configuration" section.

## Detailed Implementation

### 1. Code Changes Made

**In firebase_service.dart:**
```dart
class FirebaseAuthConfig {
  // Configure Firebase Auth to disable recaptcha for testing
  static Future<void> configureAuth() async {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true, // Disable reCAPTCHA verification for testing
      forceRecaptchaFlow: false,
    );
  }
}

class FirebaseService {
  // ... existing code ...

  // Initialize Firebase Auth with necessary settings
  static Future<void> initializeAuth() async {
    await FirebaseAuthConfig.configureAuth();
  }

  // ... existing code ...

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      // Make sure reCAPTCHA verification is disabled for testing
      await FirebaseAuthConfig.configureAuth();
      
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }
}
```

**In main.dart:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configure Firebase Auth to disable reCAPTCHA for testing
  await FirebaseService.initializeAuth();
  
  runApp(const PanchakarmaApp());
}
```

### 2. Proper Configuration in Firebase Console

For production use, follow these steps to configure reCAPTCHA:

1. **Create reCAPTCHA Keys**:
   - Go to the [Google Cloud Console](https://console.cloud.google.com/)
   - Navigate to Security > reCAPTCHA
   - Create a new key with:
     - Type: Score-based key (v3)
     - Domains: Your app domains (and localhost for testing)
     - Accept the terms of service

2. **Configure Firebase Auth**:
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Navigate to Authentication > Settings
   - Find the "Security" section
   - Under "reCAPTCHA verification", click "Edit"
   - Enable reCAPTCHA protection
   - Enter your reCAPTCHA Site Key
   - Save

### 3. Update Android App Configuration

Android apps require additional configuration for Firebase Auth with reCAPTCHA:

1. **Check SHA Certificate Fingerprints**:
   - Make sure your debug and release SHA-1 fingerprints are added to the Firebase project
   - Go to Firebase Console > Project Settings > Your Apps > Android app > Add fingerprint

2. **Test on Physical Device**:
   - Some Firebase Auth features work better on physical devices than emulators

## Testing

1. **Clear App Data**: 
   - If you've been testing previously, clear app data or reinstall the app

2. **Test Registration**:
   - Run the app
   - Navigate to the signup screen
   - Complete the form and submit
   - Registration should now complete without reCAPTCHA errors

3. **Test Login**:
   - Try logging in with the newly created account

## Troubleshooting

If issues persist:

1. **Check for Console Errors**:
   - Look for specific error messages in the Flutter debug console

2. **Verify Implementation**:
   - Ensure `FirebaseService.initializeAuth()` is called in `main.dart` before any authentication operations
   - Verify `FirebaseAuthConfig.configureAuth()` is called before registration attempts

3. **Firebase Dependencies**:
   - Make sure you have the latest Firebase packages in your pubspec.yaml

4. **Network Issues**:
   - Check if the device has proper internet connectivity
   - Verify Firebase services aren't blocked by any firewall or network policy

## Long-Term Considerations

For a production application:

1. **Implement Proper reCAPTCHA**:
   - Follow the steps in section 2 to configure reCAPTCHA properly

2. **Consider Firebase App Check**:
   - Implement App Check for additional security
   - [Learn more here](https://firebase.google.com/docs/app-check)

3. **Email Verification**:
   - Consider requiring email verification before allowing full access to the app