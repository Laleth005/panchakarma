# Firebase Authentication Debugging Guide

## Understanding Firebase Auth Errors

If you're still facing issues with Firebase Authentication even after applying the reCAPTCHA fix, use this guide to debug further.

## Common Firebase Auth Error Codes

| Error Code | Description | Solution |
|------------|-------------|----------|
| `CONFIGURATION_NOT_FOUND` | reCAPTCHA verification configuration missing | Follow the reCAPTCHA configuration steps in FIREBASE_RECAPTCHA_FIX_GUIDE.md |
| `EMAIL_EXISTS` | Email already in use | Try a different email or reset password |
| `INVALID_EMAIL` | Email format is incorrect | Ensure email follows standard format |
| `WEAK_PASSWORD` | Password doesn't meet requirements | Use a stronger password (at least 6 characters) |
| `NETWORK_REQUEST_FAILED` | Network connectivity issue | Check internet connection |
| `TOO_MANY_ATTEMPTS_TRY_LATER` | Too many failed login attempts | Wait before trying again |

## Enabling Debug Logs

We've added additional logging to help diagnose issues:

1. The app now logs:
   - Firebase Auth configuration attempts
   - User registration attempts 
   - Success/failure status
   - Detailed error information

2. Check the debug console for these logs when testing.

## Step-by-Step Debugging Process

### For Registration Issues:

1. **Check Console Logs**:
   - Look for "Configuring Firebase Auth settings..." log
   - Check if "Firebase Auth settings configured successfully" appears
   - Look for "Attempting to register user: [email]" log
   - Note any error messages

2. **Verify Firebase Project**:
   - Go to Firebase Console > Authentication > Users
   - Check if users are being created but with issues, or not created at all

3. **Test with Sample User**:
   - Try registering with a test email (e.g., test123@example.com)
   - Use a simple but valid password (e.g., Test123!)

4. **Check SHA Certificates**:
   - Verify your app's SHA-1 fingerprint is added to Firebase project
   - For debug builds, run: `./gradlew signingReport` in the android folder

### For Login Issues:

1. **Verify User Exists**:
   - Check Firebase Console to confirm the user was created
   - Ensure email format matches exactly

2. **Test Password Reset**:
   - Try the password reset flow to verify email delivery

3. **Check Authentication Method**:
   - Ensure Email/Password sign-in is enabled in Firebase Console

## Advanced Debugging

### Enable Firebase Debug Mode

Add this to your main.dart before initializing Firebase:

```dart
// For verbose Firebase logging (development only)
if (kDebugMode) {
  FirebaseAuth.instance.setLanguageCode("en");
  FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
}
```

### Test on Different Devices

- Try on both emulators and physical devices
- Test on different Android/iOS versions

### Verify Dependencies

Ensure you have the correct versions in pubspec.yaml:

```yaml
dependencies:
  firebase_core: ^latest_version
  firebase_auth: ^latest_version
  cloud_firestore: ^latest_version
```

## Getting Help

If problems persist:

1. Check [Firebase Authentication documentation](https://firebase.google.com/docs/auth)
2. Search for your specific error code on Stack Overflow
3. Join the [Flutter Community Discord](https://discord.gg/flutter) for live help

## Reverting to Previous Authentication Method

If needed, you can implement a simpler authentication method temporarily:

1. Create a local authentication service that mimics Firebase Auth
2. Use shared preferences to store authenticated state
3. Switch back to Firebase Auth once issues are resolved