# Fixing Firebase reCAPTCHA Configuration Issues

The error `CONFIGURATION_NOT_FOUND` with reCAPTCHA during user registration/authentication typically happens because Firebase now requires reCAPTCHA verification by default.

## Option 1: Disable reCAPTCHA for Testing (Quick Solution)

For testing purposes, we've implemented a solution in the app code that disables reCAPTCHA verification. This is done by calling:

```dart
await FirebaseService.initializeAuth();
```

This is already included in the main.dart file.

## Option 2: Configure reCAPTCHA in Firebase Console (Proper Solution for Production)

For a production environment, follow these steps to properly configure reCAPTCHA:

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project (panchakarma-991c8)
3. Navigate to Authentication > Settings
4. Scroll to the "Security" section
5. In the "reCAPTCHA verification" section, click "Edit"
6. Select "Enable reCAPTCHA protection for your project"
7. Under "reCAPTCHA Key Administration":
   - Select "Use reCAPTCHA Enterprise"
   - Click "Create a new reCAPTCHA Enterprise key" - this will take you to Google Cloud Console
   - In Google Cloud Console, create a new key with the following settings:
     - Name: "Firebase Auth Key"
     - Type: "Score-based key"
     - Domains: Add your application domains (for testing, add "localhost")
     - Platform: Select both "Web" and "Android/iOS"
   - Click "Create"
   - Copy the reCAPTCHA Site Key
8. Return to Firebase Console and paste the Site Key
9. Click "Save"

## Option 3: Enable App Check in Firebase (Additional Security)

For even more security, you can implement Firebase App Check:

1. Go to Firebase Console > App Check
2. Click "Get started"
3. Under "Debug providers", add your device's debug token
4. Under "Production providers":
   - For Android: Set up SafetyNet or Play Integrity
   - For iOS: Set up DeviceCheck
   - For Web: Set up reCAPTCHA v3
5. Update your app code to initialize App Check before Firebase Auth

## Additional Resources

- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [Firebase reCAPTCHA Configuration](https://firebase.google.com/docs/auth/web/recaptcha-verification)
- [Firebase App Check](https://firebase.google.com/docs/app-check)