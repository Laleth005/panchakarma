# Testing Firebase Authentication

## Prerequisites

1. Make sure you've implemented the latest changes to disable reCAPTCHA for testing.
2. Ensure your app can connect to Firebase (check for any network-related errors).

## Steps to Test

### 1. Test User Registration

1. Launch the app on an emulator or physical device.
2. Navigate to the sign-up screen.
3. Fill in all required fields:
   - Email (use a valid format but it doesn't need to be real, e.g., `test@example.com`)
   - Password (must meet Firebase requirements: at least 6 characters)
   - Any other required fields in your UI
4. Submit the registration form.
5. Expected outcome: Account creation succeeds, and you're either logged in automatically or redirected to the login page.

### 2. Test User Login

1. Navigate to the login screen.
2. Enter the credentials of a user you just registered.
3. Submit the login form.
4. Expected outcome: Login succeeds, and you're redirected to the main app screen.

### 3. Verify in Firebase Console

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Select your project.
3. Navigate to Authentication > Users.
4. Verify that your test user appears in the list.

## Common Issues and Solutions

### If Registration Still Fails with reCAPTCHA Error

1. Double-check that `FirebaseService.initializeAuth()` is called before any authentication operations.
2. Verify that this method is being called early in the app initialization.
3. Make sure you're using the latest versions of Firebase packages in pubspec.yaml:
   ```yaml
   firebase_core: ^latest_version
   firebase_auth: ^latest_version
   cloud_firestore: ^latest_version
   ```
4. Try clearing app data or reinstalling the app if testing on a device.

### If Login Fails After Successful Registration

1. Verify that the user exists in Firebase Console > Authentication > Users.
2. Check if email verification is required in your authentication flow.
3. Ensure passwords meet Firebase security requirements.

## Next Steps After Testing

1. For Development: Continue using the disabled reCAPTCHA setting for ease of testing.
2. For Production: Set up proper reCAPTCHA verification as outlined in RECAPTCHA_FIX.md.
3. Consider implementing additional Firebase features like email verification or phone authentication if needed.