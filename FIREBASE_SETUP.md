# Panchakarma - Ayurvedic Treatment Management System

## Firebase Integration Guide

To properly connect the Panchakarma app to Firebase and store user details in the database, follow these steps:

### 1. Firebase Configuration

1. **Enable Developer Mode in Windows**
   - Run `start ms-settings:developers` in PowerShell
   - Turn on "Developer Mode" in the settings window that opens

2. **Firebase Authentication Settings**
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Select your project (panchakarma-991c8)
   - Go to Authentication > Sign-in method
   - Enable Email/Password authentication
   - Disable the "Requires email verification" option for testing
   
3. **Disable reCAPTCHA Verification (for testing only)**
   - In the Firebase Console, go to Authentication > Settings
   - Scroll to the "Security" section
   - Set the "reCAPTCHA" setting to "Disabled"
   
### 2. Firebase Firestore Setup

1. **Create Collections**
   - Go to Firestore Database in Firebase Console
   - Create the following collections:
     - `users` (common user data)
     - `admins` (admin specific data)
     - `practitioners` (practitioner specific data)
     - `patients` (patient specific data)

2. **Security Rules**
   - Go to Firestore > Rules
   - Update the rules to secure your data:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read their own data
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /patients/{userId} {
      allow read: if request.auth != null && (request.auth.uid == userId || 
                    exists(/databases/$(database)/documents/practitioners/$(request.auth.uid)) ||
                    exists(/databases/$(database)/documents/admins/$(request.auth.uid)));
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /practitioners/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && (request.auth.uid == userId || 
                    exists(/databases/$(database)/documents/admins/$(request.auth.uid)));
    }
    
    match /admins/{userId} {
      allow read: if request.auth != null && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
      allow write: if request.auth != null && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
  }
}
```

### 3. Running the App

1. **Build and Run**
   ```
   cd D:\panchakarma
   flutter run --android-skip-build-dependency-validation
   ```

2. **Register and Login Flow**
   - The app is now properly connected to Firebase
   - When users register, their details are stored in both the general `users` collection and the role-specific collection
   - During login, the app checks which collection the user belongs to and routes them to the appropriate dashboard
   - Practitioners must be approved by an admin before they can log in

### Troubleshooting

If you encounter any Firebase authentication issues:

1. Check if Developer Mode is enabled in Windows
2. Ensure reCAPTCHA verification is disabled in Firebase Console
3. Verify that the Firebase configuration in firebase_options.dart matches your Firebase project
4. Check Firebase console for any authentication errors