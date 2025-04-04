import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firebase_user_service.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseUserService _userService = FirebaseUserService();

  // Get the current Firebase user
  User? get currentUser => _auth.currentUser;

  // Check if a user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('Attempting to sign in with email: $email');
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Sign in successful for user: ${result.user?.uid}');
      return result;
    } catch (e) {
      debugPrint('Firebase auth error during sign in: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('Attempting to create user with email: $email');
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('User created successfully: ${result.user?.uid}');
      return result;
    } catch (e) {
      debugPrint('Firebase auth error during user creation: $e');
      rethrow;
    }
  }

  // Register a new user with full profile information
  Future<UserModel> registerUser(UserModel userModel, String password) async {
    try {
      debugPrint('Starting registration for ${userModel.email}');
      
      // Create Firebase auth user
      final UserCredential userCredential = await createUserWithEmailAndPassword(
        userModel.email,
        password,
      );
      
      debugPrint('Firebase user created with UID: ${userCredential.user?.uid}');
      
      // Update the user's display name
      await userCredential.user?.updateDisplayName(userModel.name);
      debugPrint('Display name updated');
      
      // Create a UserModel with the generated Firebase UID
      final UserModel updatedUserModel = userModel.copyWith(
        id: userCredential.user!.uid,
      );
      
      debugPrint('Created updated UserModel with Firebase UID');
      
      // Save user data to Firestore
      await _userService.saveUserData(updatedUserModel);
      debugPrint('User data saved to Firestore');
      
      return updatedUserModel;
    } catch (e) {
      debugPrint('Error during user registration: $e');
      if (e is FirebaseAuthException) {
        debugPrint('Firebase Auth Error Code: ${e.code}');
        debugPrint('Firebase Auth Error Message: ${e.message}');
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData() async {
    if (currentUser != null) {
      return await _userService.getUserData(currentUser!.uid);
    }
    return null;
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel updatedUser) async {
    await _userService.updateUserData(updatedUser);
    // Also update display name if it has changed
    if (currentUser != null && currentUser!.displayName != updatedUser.name) {
      await currentUser!.updateDisplayName(updatedUser.name);
    }
  }

  // Delete user account
  Future<void> deleteUserAccount(String password) async {
    try {
      debugPrint('Attempting to delete user account');
      
      // Get the current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in');
      }
      
      // Re-authenticate user before deletion
      final credentials = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credentials);
      debugPrint('User re-authenticated successfully');
      
      // Delete user data from Firestore first
      await _userService.deleteUserData(user.uid);
      debugPrint('User data deleted from Firestore');
      
      // Delete the Firebase Auth user
      await user.delete();
      debugPrint('User deleted from Firebase Auth');
    } catch (e) {
      debugPrint('Error deleting user account: $e');
      if (e is FirebaseAuthException) {
        debugPrint('Firebase Auth Error Code: ${e.code}');
        debugPrint('Firebase Auth Error Message: ${e.message}');
      }
      rethrow;
    }
  }

  // Test login with specific email (for debugging)
  Future<bool> testLogin(String email, String password) async {
    try {
      debugPrint('Attempting TEST login with email: $email');
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('TEST login successful!');
      return true;
    } catch (e) {
      debugPrint('TEST login failed with error: $e');
      if (e is FirebaseAuthException) {
        debugPrint('Firebase Auth Error Code: ${e.code}');
        debugPrint('Firebase Auth Error Message: ${e.message}');
      }
      return false;
    }
  }
} 