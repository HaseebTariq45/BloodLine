# Firebase Integration for BloodLine App

This directory contains the Firebase integration services for the BloodLine blood donation app.

## Services

1. **FirebaseService** (`firebase_service.dart`)
   - Handles initialization of Firebase
   - Must be called at app startup

2. **FirebaseAuthService** (`firebase_auth_service.dart`)
   - Manages authentication with Firebase Authentication
   - Handles user sign-in, sign-up, and sign-out
   - Provides user authentication state changes

3. **FirebaseUserService** (`firebase_user_service.dart`)
   - Manages user data in Cloud Firestore
   - Handles CRUD operations for user profiles
   - Provides user data queries (e.g., finding donors by blood type)

## Setup

The Firebase configuration is set up with the following components:

1. **Android Configuration**
   - `google-services.json` file is placed in the `android/app` directory
   - Firebase dependencies are added to the app-level `build.gradle.kts`
   - Google services plugin is added to the project-level `build.gradle.kts`

2. **Flutter Configuration**
   - Firebase packages are added to `pubspec.yaml`:
     - `firebase_core`: Core functionality
     - `firebase_auth`: Authentication
     - `cloud_firestore`: Database
     - `firebase_storage`: Storage for profile images

## Usage

The Firebase services are primarily used through the `AppProvider` class, which:
- Initializes Firebase on app startup
- Manages user authentication state
- Handles user registration and login
- Provides user data to the UI components

## Firebase Firestore Structure

The app uses the following Firestore collection structure:

- **users**: Collection of user profiles
  - Fields:
    - name: User's full name
    - email: User's email address
    - phone: User's phone number
    - bloodType: User's blood type (A+, B-, etc.)
    - address: User's address
    - imageUrl: Profile image URL
    - isAvailableToDonate: Boolean flag indicating donation availability
    - lastDonationDate: Timestamp of last donation
    - createdAt: Account creation timestamp
    - updatedAt: Last update timestamp 