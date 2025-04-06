import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../models/emergency_contact_model.dart';
import '../models/user_location_model.dart';
import '../firebase/firebase_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/donation_model.dart';
import '../models/blood_request_model.dart';
import '../models/blood_bank_model.dart';
import '../models/data_usage_model.dart';
import '../utils/location_service.dart';
import '../utils/notification_service.dart';
import '../firebase/firebase_auth_service.dart';
import '../firebase/firebase_user_service.dart';
import '../firebase/firebase_donation_service.dart';
import '../firebase/firebase_emergency_contact_service.dart';
import '../firebase/firebase_notification_service.dart';
import '../utils/app_updater.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert'; // For JSON encoding
import '../services/service_locator.dart'; // For service locator

class AppProvider extends ChangeNotifier {
  // Firebase services - lazy initialization
  late final FirebaseAuthService _authService;
  late final FirebaseUserService _userService;
  late final FirebaseDonationService _donationService;
  late final FirebaseEmergencyContactService _emergencyContactService;
  late final FirebaseNotificationService _notificationService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User data
  UserModel? _currentUser;
  UserModel get currentUser => _currentUser ?? UserModel.dummy();
  bool get isLoggedIn => _currentUser != null;

  // Authentication state
  bool _isAuthenticating = false;
  bool get isAuthenticating => _isAuthenticating;
  String _authError = '';
  String get authError => _authError;

  // Theme state management
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  bool _isSystemDarkMode = false;
  bool get isSystemDarkMode => _isSystemDarkMode;

  // Get current dark mode state
  bool get isDarkMode => _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system && _isSystemDarkMode);

  // App locale/language
  Locale _locale = const Locale('en', 'US');
  Locale get locale => _locale;
  String _selectedLanguage = 'English';
  String get selectedLanguage => _selectedLanguage;

  // Location settings
  bool _isLocationEnabled = false;
  bool get isLocationEnabled => _isLocationEnabled;

  // Notification settings
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;
  bool _emailNotificationsEnabled = false;
  bool get emailNotificationsEnabled => _emailNotificationsEnabled;
  bool _pushNotificationsEnabled = true;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool _hasUnreadNotifications = false;
  bool get hasUnreadNotifications => _hasUnreadNotifications;
  List<NotificationModel> _userNotifications = [];
  List<NotificationModel> get userNotifications => _userNotifications;
  bool _isLoadingNotifications = false;
  bool get isLoadingNotifications => _isLoadingNotifications;

  // Profile image error handling
  bool _profileImageLoadError = false;
  bool get profileImageLoadError => _profileImageLoadError;

  // Data usage tracking
  DataUsageModel _dataUsage = DataUsageModel.empty();
  DataUsageModel get dataUsage => _dataUsage;

  // Donation history
  List<DonationModel> _donations = [];
  List<DonationModel> get donations => _donations;

  // Current user's donations
  List<DonationModel> _userDonations = [];
  List<DonationModel> get userDonations => _userDonations;

  // Cache for donations stream to prevent multiple stream creation
  Stream<List<DonationModel>>? _userDonationsStream;

  // Blood requests
  List<BloodRequestModel> _bloodRequests = [];
  List<BloodRequestModel> get bloodRequests => _bloodRequests;

  // Blood banks
  List<BloodBankModel> _bloodBanks = [];
  List<BloodBankModel> get bloodBanks => _bloodBanks;

  // Blood donors
  List<UserModel> _donors = [];
  List<UserModel> get donors => _donors;

  // Get theme mode name for display
  String get themeModePreference {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
      default:
        return 'System';
    }
  }

  // Emergency contacts data
  List<EmergencyContactModel> _emergencyContacts = [];
  List<EmergencyContactModel> get emergencyContacts => _emergencyContacts;

  // System theme change listener
  VoidCallback? _systemThemeChangeListener;

  // Update-related properties
  bool _isCheckingForUpdate = false;
  bool _updateAvailable = false;
  String _latestVersion = '';
  String _updateDownloadUrl = '';
  String _releaseNotes = '';
  bool _isDownloadingUpdate = false;
  double _downloadProgress = 0.0;
  String _downloadedFilePath = '';

  // Update getters
  bool get isCheckingForUpdate => _isCheckingForUpdate;
  bool get updateAvailable => _updateAvailable;
  String get latestVersion => _latestVersion;
  String get updateDownloadUrl => _updateDownloadUrl;
  String get releaseNotes => _releaseNotes;
  bool get isDownloadingUpdate => _isDownloadingUpdate;
  double get downloadProgress => _downloadProgress;
  String get downloadedFilePath => _downloadedFilePath;

  // Constructor - load data for app
  AppProvider() {
    _initializeServices();
    _setupSystemThemeListener();
  }

  // Setup system theme change listener
  void _setupSystemThemeListener() {
    // Initialize system dark mode
    _isSystemDarkMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    
    _systemThemeChangeListener = () {
      _isSystemDarkMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      if (_themeMode == ThemeMode.system) {
        notifyListeners();
      }
    };
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = _systemThemeChangeListener;
  }

  @override
  void dispose() {
    // Clean up system theme listener
    if (_systemThemeChangeListener != null) {
      WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = null;
    }
    super.dispose();
  }

  // Initialize services
  void _initializeServices() async {
    try {
      // Load theme preference first
      await _loadThemeMode();
      
      // Initialize Firebase services
      _authService = FirebaseAuthService();
      _userService = FirebaseUserService();
      _donationService = FirebaseDonationService();
      _emergencyContactService = FirebaseEmergencyContactService();
      _notificationService = FirebaseNotificationService();

      // Load data
      _loadDummyData();
      _loadDataUsage();
      _checkAuthState();

      // Load real donations if user is logged in
      if (_authService.isSignedIn) {
        loadUserDonations();
      }
    } catch (e) {
      debugPrint('Error initializing AppProvider: $e');
      // Fallback to dummy data if Firebase initialization fails
      _loadDummyData();
      _loadDataUsage();
    }
  }

  // Load theme mode from shared preferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt('theme_mode');
      
      if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[modeIndex];
        notifyListeners();
      } else {
        // Invalid theme mode index, reset to system
        _themeMode = ThemeMode.system;
        await _saveThemeMode();
      }
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
      _themeMode = ThemeMode.system;
      await _saveThemeMode(); // Try to save the default
    }
  }

  // Save theme mode to shared preferences
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', _themeMode.index);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
      // Log error but don't throw - we don't want to crash the app
    }
  }

  // Check authentication state on app startup
  Future<void> _checkAuthState() async {
    try {
      if (_authService.isSignedIn) {
        try {
          // Ensure user data exists in Firestore
          await ensureUserDataInFirestore();

          // Get the user data from Firestore
          UserModel? userData = await _authService.getUserData();
          if (userData != null) {
            _currentUser = userData;

            // Load user-specific data
            loadUserDonations();
            loadEmergencyContacts();

            notifyListeners();
          }
        } catch (e) {
          debugPrint('Error loading user data: $e');
        }
      }

      // Listen for auth state changes
      _authService.authStateChanges.listen((User? user) {
        if (user == null) {
          // User signed out
          debugPrint('🔑 [AuthState] User signed out');
          _currentUser = null;
          _emergencyContacts = []; // Clear emergency contacts when user signs out
        } else {
          // User signed in, get their data from Firestore
          debugPrint('🔑 [AuthState] User signed in: ${user.uid}');
          ensureUserDataInFirestore().then((_) {
            _authService.getUserData().then((userData) {
              if (userData != null) {
                debugPrint('🔑 [AuthState] User data loaded from Firestore: ${userData.name}');
                _currentUser = userData;

                // Load user-specific data
                loadUserDonations();
                loadEmergencyContacts();
                
                // Sync notifications when user signs in
                debugPrint('🔑 [AuthState] Syncing notifications after sign in...');
                
                // Use Future to avoid blocking the auth state callback
                Future.microtask(() async {
                  // Refresh notifications from Firestore
                  await refreshNotifications();
                  
                  // Check notification settings
                  await checkNotificationSettings();
                  
                  // Ensure device token is saved for notifications
                  final notificationService = FirebaseNotificationService();
                  await notificationService.saveDeviceToken();
                  
                  debugPrint('✅ [AuthState] Notification sync completed after sign in');
                });
              } else {
                debugPrint('⚠️ [AuthState] No user data found in Firestore after sign in');
              }
              notifyListeners();
            });
          });
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error checking auth state: $e');
    }
  }

  // Load dummy data for demonstration
  void _loadDummyData() {
    // Only load dummy user data if not signed in with Firebase
    try {
      if (!_authService.isSignedIn) {
        _currentUser = UserModel.dummy();
      }
    } catch (e) {
      // If Firebase is not initialized, use dummy data
      _currentUser = UserModel.dummy();
    }

    // Remove dummy donation data loading
    _donations = [];
    _userDonations = [];

    _bloodRequests = BloodRequestModel.getDummyList();
    _bloodBanks = BloodBankModel.getDummyList();

    // Generate dummy donors
    _donors = List.generate(15, (index) {
      final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
      return UserModel(
        id: 'donor_$index',
        name: 'Donor ${index + 1}',
        email: 'donor${index + 1}@example.com',
        phoneNumber: '+1234${index}7890',
        bloodType: bloodTypes[index % bloodTypes.length],
        address: '${index + 100} Main St, City',
        imageUrl: 'assets/images/avatar_${(index % 8) + 1}.png',
        isAvailableToDonate: index % 3 != 0,
        lastDonationDate: DateTime.now().subtract(
          Duration(days: 90 + index * 5),
        ),
      );
    });

    // Set the current user to also have a local image
    if (_currentUser != null && _currentUser!.imageUrl.isEmpty) {
      _currentUser = _currentUser!.copyWith(
        imageUrl: 'assets/images/avatar_1.png',
      );
    }
  }

  // Load data usage from shared preferences
  Future<void> _loadDataUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final totalBytes = prefs.getInt('data_usage_total_bytes') ?? 0;
      final wifiBytes = prefs.getInt('data_usage_wifi_bytes') ?? 0;
      final mobileBytes = prefs.getInt('data_usage_mobile_bytes') ?? 0;
      final lastResetTimestamp = prefs.getInt('data_usage_last_reset');

      final lastReset =
          lastResetTimestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(lastResetTimestamp)
              : DateTime.now();

      _dataUsage = DataUsageModel(
        totalBytes: totalBytes,
        wifiBytes: wifiBytes,
        mobileBytes: mobileBytes,
        lastReset: lastReset,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data usage: $e');
      // If there's an error, start with empty data
      _dataUsage = DataUsageModel.empty();
    }
  }

  // Public method to refresh data usage
  Future<void> refreshDataUsage() async {
    await _loadDataUsage();
  }

  // Save data usage to shared preferences
  Future<void> _saveDataUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('data_usage_total_bytes', _dataUsage.totalBytes);
      await prefs.setInt('data_usage_wifi_bytes', _dataUsage.wifiBytes);
      await prefs.setInt('data_usage_mobile_bytes', _dataUsage.mobileBytes);
      await prefs.setInt(
        'data_usage_last_reset',
        _dataUsage.lastReset.millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error saving data usage: $e');
    }
  }

  // Track network data usage
  void recordDataUsage(int bytesUsed, bool isWifi) {
    if (isWifi) {
      _dataUsage = _dataUsage.copyWith(
        totalBytes: _dataUsage.totalBytes + bytesUsed,
        wifiBytes: _dataUsage.wifiBytes + bytesUsed,
      );
    } else {
      _dataUsage = _dataUsage.copyWith(
        totalBytes: _dataUsage.totalBytes + bytesUsed,
        mobileBytes: _dataUsage.mobileBytes + bytesUsed,
      );
    }
    notifyListeners();
    _saveDataUsage(); // Save data whenever it changes
  }

  // Reset data usage statistics
  void resetDataUsage() {
    _dataUsage = DataUsageModel.empty();
    notifyListeners();
    _saveDataUsage();
  }

  // Change app language
  void setLanguage(String language) {
    _selectedLanguage = language;

    switch (language) {
      case 'English':
        _locale = const Locale('en', 'US');
        break;
      case 'Spanish':
        _locale = const Locale('es', 'ES');
        break;
      case 'French':
        _locale = const Locale('fr', 'FR');
        break;
      case 'Arabic':
        _locale = const Locale('ar', 'SA');
        break;
      case 'Urdu':
        _locale = const Locale('ur', 'PK');
        break;
      default:
        _locale = const Locale('en', 'US');
    }

    notifyListeners();
  }

  // Login user with Firebase
  Future<bool> login(String email, String password) async {
    _isAuthenticating = true;
    _authError = '';
    notifyListeners();

    try {
      debugPrint('Starting login process for: $email');

      // Sign in with Firebase Auth
      final userCredential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      debugPrint(
        'Successfully signed in with Firebase Auth. UID: ${userCredential.user?.uid}',
      );

      // Ensure user data exists in Firestore
      await ensureUserDataInFirestore();

      // Get user profile data from Firestore
      final userData = await _authService.getUserData();

      if (userData != null) {
        debugPrint('Successfully retrieved user data from Firestore');
        _currentUser = userData;
      } else {
        debugPrint(
          'WARNING: No user data found in Firestore after successful authentication',
        );
      }

      _isAuthenticating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isAuthenticating = false;
      _authError = _getFirebaseAuthErrorMessage(e);
      debugPrint('Login error: $e');
      notifyListeners();
      return false;
    }
  }

  // Register a new user with Firebase
  Future<bool> registerUser(UserModel user, String password) async {
    _isAuthenticating = true;
    _authError = '';
    notifyListeners();

    try {
      debugPrint('Starting user registration process for: ${user.email}');

      // Register with Firebase Auth and save user data to Firestore
      final registeredUser = await _authService.registerUser(user, password);
      debugPrint('User registered successfully. User ID: ${registeredUser.id}');

      _currentUser = registeredUser;

      // Add the new user to the donors list as well
      _donors.add(registeredUser);

      debugPrint('Current user set in app state and added to donors list');

      _isAuthenticating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isAuthenticating = false;
      _authError = _getFirebaseAuthErrorMessage(e);
      debugPrint('Registration error: $e');
      notifyListeners();
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      _userDonations = [];
      _userDonationsStream = null; // Clear cached stream
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      // Rethrow to let UI handle the error
      rethrow;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    try {
      await _authService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // Refresh user data from Firestore
  Future<void> refreshUserData() async {
    try {
      if (_authService.isSignedIn) {
        debugPrint('🔄 [UserData] Refreshing user data from Firestore');
        final String? userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          debugPrint('🔄 [UserData] Attempting to retrieve user data from Firestore for user ID: $userId');
        }

        // Get the user data from Firestore
        UserModel? userData = await _authService.getUserData();
        if (userData != null) {
          _currentUser = userData;
          debugPrint('✅ [UserData] User data refreshed successfully: ${userData.name}');
          
          // Now that we have confirmed the user is logged in and data is loaded,
          // sync notifications (refresh from server, check settings, update token)
          debugPrint('🔄 [UserData] User authenticated, syncing notifications...');
          
          // Refresh notifications from Firestore
          await refreshNotifications();
          
          // Check notification settings
          await checkNotificationSettings();
          
          // Ensure device token is saved for notifications
          final notificationService = FirebaseNotificationService();
          await notificationService.saveDeviceToken();
          
          debugPrint('✅ [UserData] Notification sync completed after user authentication');
          
          notifyListeners();
        }
      } else {
        debugPrint('⚠️ [UserData] Cannot refresh user data: No user is signed in');
      }
    } catch (e) {
      debugPrint('❌ [UserData] Error refreshing user data: $e');
    }
  }

  // Toggle user availability to donate
  Future<void> toggleDonationAvailability() async {
    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(
        isAvailableToDonate: !_currentUser!.isAvailableToDonate,
      );

      await updateUserProfile(updatedUser);
    }
  }
  
  // Sync donation availability based on last donation date
  // This ensures the isAvailableToDonate flag is auto-updated when a new donation is added
  Future<void> syncDonationAvailability() async {
    if (_currentUser != null) {
      // If the user has never donated, they're eligible to donate
      if (_currentUser!.neverDonatedBefore) {
        if (!_currentUser!.isAvailableToDonate) {
          debugPrint('User has never donated, marking as available to donate');
          
          // Update the user profile to be available
          final updatedUser = _currentUser!.copyWith(
            isAvailableToDonate: true,
          );
          
          await updateUserProfile(updatedUser);
          debugPrint('Updated availability for user who has never donated: true');
        } else {
          debugPrint('User has never donated and is already marked as available');
        }
        return;
      }
      
      // Otherwise, check based on last donation date
      final nextDonationDate = _currentUser!.lastDonationDate?.add(const Duration(days: 90)) ?? DateTime.now();
      final daysRemaining = nextDonationDate.difference(DateTime.now()).inDays;
      final canDonate = daysRemaining <= 0;
      
      // If user has donated recently (daysRemaining > 0), set availability to false
      // If 90 days have passed and they're eligible again (daysRemaining <= 0), set to true
      if (_currentUser!.isAvailableToDonate != canDonate) {
        debugPrint('Updating donation eligibility status. Days until eligible: $daysRemaining, Can donate: $canDonate');
        
        // Update the user's availability flag based on days since last donation
        final updatedUser = _currentUser!.copyWith(
          isAvailableToDonate: canDonate,
        );
        
        await updateUserProfile(updatedUser);
        debugPrint('Updated availability based on donation date: ${updatedUser.isAvailableToDonate}');
      } else {
        debugPrint('No need to update eligibility. Current status: ${_currentUser!.isAvailableToDonate}, Days remaining: $daysRemaining');
      }
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _authError = _getFirebaseAuthErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Check if email exists in Firestore
  Future<bool> checkEmailExists(String email) async {
    try {
      // Query Firestore for a user with this email
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

      // Return true if any documents were found
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking email existence: $e');
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount(String password) async {
    try {
      debugPrint('Attempting to delete account');

      // Re-authenticate user before deleting
      if (_currentUser != null && _authService.currentUser != null) {
        await _authService.deleteUserAccount(password);

        // Clear local user data
        _currentUser = null;
        notifyListeners();

        debugPrint('Account deleted successfully');
        return true;
      } else {
        debugPrint('No user is currently logged in');
        return false;
      }
    } catch (e) {
      _authError = _getFirebaseAuthErrorMessage(e);
      debugPrint('Error deleting account: $e');
      notifyListeners();
      return false;
    }
  }

  // Helper method to get readable error messages
  String _getFirebaseAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'weak-password':
          return 'Password is too weak. Please use a stronger password.';
        case 'invalid-email':
          return 'Invalid email address format.';
        case 'operation-not-allowed':
          return 'Operation not allowed. Please contact support.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        default:
          return 'Authentication error: ${error.message}';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // Add a new donation for the current user
  Future<bool> addDonation(DonationModel donation) async {
    try {
      if (_currentUser == null) {
        debugPrint('Cannot add donation: No user is logged in');
        return false;
      }

      // Set current timestamp if date is not provided
      final donationWithCurrentUser = donation.copyWith(
        donorId: _currentUser!.id,
        donorName: _currentUser!.name,
        bloodType: _currentUser!.bloodType,
      );

      // Save to Firestore
      final newDonation = await _donationService.addDonation(
        donationWithCurrentUser,
      );

      // Update local lists
      _userDonations.add(newDonation);
      _donations.add(newDonation);

      // Update user's last donation date
      final updatedUser = _currentUser!.copyWith(
        lastDonationDate: donation.date,
      );

      // Save updated user to Firestore
      await _userService.saveUserData(updatedUser);
      _currentUser = updatedUser;
      
      // Sync availability status based on the new donation date
      await syncDonationAvailability();

      debugPrint('Donation added successfully: ${newDonation.id}');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding donation: $e');
      return false;
    }
  }

  // Cancel a donation appointment
  Future<bool> cancelDonation(String donationId) async {
    try {
      // Update status in Firestore
      await _donationService.updateDonationStatus(donationId, 'Cancelled');

      // Update local lists
      final donationIndex = _userDonations.indexWhere(
        (d) => d.id == donationId,
      );
      if (donationIndex != -1) {
        final updatedDonation = _userDonations[donationIndex].copyWith(
          status: 'Cancelled',
        );
        _userDonations[donationIndex] = updatedDonation;

        // Update in global donations list too
        final globalIndex = _donations.indexWhere((d) => d.id == donationId);
        if (globalIndex != -1) {
          _donations[globalIndex] = updatedDonation;
        }
      }

      debugPrint('Donation cancelled successfully: $donationId');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error canceling donation: $e');
      return false;
    }
  }

  // Load user's donations from Firestore
  Future<void> loadUserDonations() async {
    try {
      if (_currentUser != null) {
        debugPrint('Loading donations for user: ${_currentUser!.id}');
        _userDonations = await _donationService.getUserDonations(
          _currentUser!.id,
        );
        notifyListeners();
        debugPrint('Successfully loaded ${_userDonations.length} donations');
      }
    } catch (e) {
      debugPrint('Error loading user donations: $e');
      // Keep the list empty if there's an error
      _userDonations = [];
      notifyListeners();
    }
  }

  // Load all donations from Firestore (for admin purposes)
  Future<void> loadAllDonations() async {
    try {
      debugPrint('Loading all donations from Firestore');
      _donations = await _donationService.getAllDonations();
      notifyListeners();
      debugPrint('Successfully loaded ${_donations.length} donations');
    } catch (e) {
      debugPrint('Error loading all donations: $e');
      // Keep the list empty if there's an error
      _donations = [];
      notifyListeners();
    }
  }

  // Get a stream of user's donations for real-time updates
  Stream<List<DonationModel>> getUserDonationsStream() {
    if (_currentUser != null) {
      // Use cached stream if available
      _userDonationsStream ??= _donationService.getUserDonationsStream(_currentUser!.id);
      return _userDonationsStream!;
    }
    // Return empty stream if no user is logged in
    return Stream.value([]);
  }

  // Add new blood request
  void addBloodRequest(BloodRequestModel request) {
    _bloodRequests.add(request);
    notifyListeners();
  }

  // Filter donors by blood type and availability
  List<UserModel> filterDonors({String? bloodType, bool? onlyAvailable}) {
    return _donors.where((donor) {
      bool matchesBloodType = bloodType == null || donor.bloodType == bloodType;
      bool matchesAvailability =
          onlyAvailable == null || !onlyAvailable || donor.isAvailableToDonate;
      return matchesBloodType && matchesAvailability;
    }).toList();
  }

  // Load donors from Firestore
  Future<void> loadDonorsFromFirestore() async {
    try {
      debugPrint('Loading donors from Firestore...');
      final donorsList = await _userService.getAvailableDonors();

      // Don't include the current user in the donors list
      if (_currentUser != null) {
        _donors =
            donorsList.where((donor) => donor.id != _currentUser!.id).toList();
      } else {
        _donors = donorsList;
      }

      debugPrint('Successfully loaded ${_donors.length} donors from Firestore');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading donors from Firestore: $e');
      // If an error occurs, keep using the existing dummy donors
    }
  }

  // Filter blood banks by distance
  List<BloodBankModel> filterBloodBanksByDistance(int maxDistance) {
    return _bloodBanks.where((bank) => bank.distance <= maxDistance).toList();
  }

  // Toggle theme mode
  void toggleThemeMode() {
    // Cycle through light, dark, and system
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    _saveThemeMode();
    notifyListeners();
  }

  // Set specific theme mode
  void setThemeMode(ThemeMode mode) {
    if (mode != _themeMode) {
      _themeMode = mode;
      _saveThemeMode();
      notifyListeners();
    }
  }

  // Mark profile image as having a load error
  void setProfileImageLoadError(bool hasError) {
    _profileImageLoadError = hasError;
    notifyListeners();
  }

  // Notification settings methods
  Future<void> checkNotificationSettings() async {
    debugPrint('🔔 [NotificationSettings] Checking notification settings...');
    
    final notificationService = NotificationService();
    final previousNotificationsEnabled = _notificationsEnabled;
    final previousEmailEnabled = _emailNotificationsEnabled;
    final previousPushEnabled = _pushNotificationsEnabled;
    
    _notificationsEnabled = await notificationService.areNotificationsEnabled();
    _emailNotificationsEnabled =
        await notificationService.areEmailNotificationsEnabled();
    _pushNotificationsEnabled =
        await notificationService.arePushNotificationsEnabled();

    // Check for unread notifications
    _hasUnreadNotifications = _userNotifications.any(
      (notification) => !notification.read,
    );
    
    // Log changes or current state
    debugPrint('🔔 [NotificationSettings] Notifications enabled: $_notificationsEnabled ${_notificationsEnabled != previousNotificationsEnabled ? "(changed)" : ""}');
    debugPrint('🔔 [NotificationSettings] Email notifications: $_emailNotificationsEnabled ${_emailNotificationsEnabled != previousEmailEnabled ? "(changed)" : ""}');
    debugPrint('🔔 [NotificationSettings] Push notifications: $_pushNotificationsEnabled ${_pushNotificationsEnabled != previousPushEnabled ? "(changed)" : ""}');
    debugPrint('🔔 [NotificationSettings] Has unread notifications: $_hasUnreadNotifications');
    
    // Only notify listeners if there was an actual change
    if (_notificationsEnabled != previousNotificationsEnabled ||
        _emailNotificationsEnabled != previousEmailEnabled ||
        _pushNotificationsEnabled != previousPushEnabled) {
      debugPrint('🔔 [NotificationSettings] Notification settings changed, updating UI');
      notifyListeners();
    } else {
      debugPrint('🔔 [NotificationSettings] No changes to notification settings');
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    final notificationService = NotificationService();
    await notificationService.setNotificationsEnabled(enabled);
    _notificationsEnabled = enabled;

    // If turning off notifications, all sub-settings get disabled
    if (!enabled) {
      await toggleEmailNotifications(false);
      await togglePushNotifications(false);
    }

    notifyListeners();
  }

  Future<void> toggleEmailNotifications(bool enabled) async {
    final notificationService = NotificationService();
    await notificationService.setEmailNotificationsEnabled(enabled);
    _emailNotificationsEnabled = enabled;
    notifyListeners();
  }

  Future<void> togglePushNotifications(bool enabled) async {
    final notificationService = NotificationService();
    await notificationService.setPushNotificationsEnabled(enabled);
    _pushNotificationsEnabled = enabled;
    notifyListeners();
  }

  // Notification retrieval and management methods
  Future<void> refreshNotifications() async {
    _isLoadingNotifications = true;
    notifyListeners();

    try {
      final notifications = await _notificationService.getUserNotifications();
      
      // Check for new unread notifications to show in notification drawer
      if (_userNotifications.isNotEmpty && notifications.isNotEmpty) {
        // Find notifications that are new (not in old list) and unread
        final newNotifications = notifications.where((notification) => 
          !notification.read && 
          !_userNotifications.any((oldNotification) => oldNotification.id == notification.id)
        ).toList();
        
        if (newNotifications.isNotEmpty) {
          debugPrint('🔔 [Notifications] Found ${newNotifications.length} new unread notifications to display');
          
          // Show each new notification in the system drawer
          for (final notification in newNotifications) {
            await _showLocalNotificationFromModel(notification);
          }
        }
      }
      
      _userNotifications = notifications;
      _hasUnreadNotifications = notifications.any(
        (notification) => !notification.read,
      );
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
    } finally {
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }

  Future<List<NotificationModel>> getUserNotifications() async {
    // Use a flag to avoid multiple state updates during build
    final bool wasLoading = _isLoadingNotifications;

    if (!wasLoading) {
      _isLoadingNotifications = true;
      // Use microtask to ensure the notifyListeners call happens after the current build cycle
      Future.microtask(() => notifyListeners());
    }

    try {
      final notifications = await _notificationService.getUserNotifications();
      _userNotifications = notifications;
      _hasUnreadNotifications = notifications.any(
        (notification) => !notification.read,
      );

      // Schedule state update outside the current build cycle
      Future.microtask(() => notifyListeners());
      return notifications;
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      return [];
    } finally {
      _isLoadingNotifications = false;
      // Schedule state update outside the current build cycle
      Future.microtask(() => notifyListeners());
    }
  }

  Stream<List<NotificationModel>> getUserNotificationsStream() {
    return _notificationService.getUserNotificationsStream();
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      if (_currentUser == null) return;
      
      // Create list of notification ids to update
      final List<String> unreadNotificationIds = _userNotifications
          .where((notification) => !notification.read)
          .map((notification) => notification.id)
          .toList();
      
      if (unreadNotificationIds.isEmpty) return;
      
      debugPrint('Marking ${unreadNotificationIds.length} notifications as read');
      
      // Update notifications in Firestore
      for (final id in unreadNotificationIds) {
        await _firestore
            .collection('notifications')
            .doc(id)
            .update({'read': true});
      }
      
      // Update local list
      _userNotifications = _userNotifications.map((notification) {
        if (unreadNotificationIds.contains(notification.id)) {
          return notification.copyWith(read: true);
        }
        return notification;
      }).toList();
      
      // Update unread status
      _hasUnreadNotifications = false;
      
      notifyListeners();
      debugPrint('Successfully marked notifications as read');
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  // Mark a single notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);

      // Update local state
      final index = _userNotifications.indexWhere(
        (n) => n.id == notificationId,
      );
      if (index != -1) {
        _userNotifications[index] = _userNotifications[index].copyWith(
          read: true,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      // First, remove from local state to make UI update immediately
      final index = _userNotifications.indexWhere(
        (n) => n.id == notificationId,
      );
      if (index != -1) {
        _userNotifications.removeAt(index);
        notifyListeners();
      }

      // Then delete from Firestore
      await _notificationService.deleteNotification(notificationId);

      // Update unread status
      _hasUnreadNotifications = _userNotifications.any(
        (notification) => !notification.read,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      // If there was an error, refresh notifications to restore state
      await refreshNotifications();
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      // Store a copy of the notifications before clearing
      final notificationsToDelete = List.from(_userNotifications);

      // Clear local state
      _userNotifications.clear();
      _hasUnreadNotifications = false;
      notifyListeners();

      // Then delete all from Firestore
      for (final notification in notificationsToDelete) {
        await _notificationService.deleteNotification(notification.id);
      }
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      // If there was an error, refresh notifications to restore state
      await refreshNotifications();
    }
  }

  // Send a test notification (used in settings screen)
  Future<void> sendTestNotification() async {
    if (!_notificationsEnabled || !_pushNotificationsEnabled) return;

    try {
      final userId = _currentUser?.id;
      if (userId != null) {
        await _notificationService.addNotification(
          NotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: userId,
            title: 'Test Notification',
            body: 'This is a test notification',
            type: 'test',
            read: false,
            createdAt: DateTime.now().toIso8601String(),
            metadata: {},
          ),
        );

        // Refresh notifications after adding a new one
        await refreshNotifications();
      }
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  // Location methods
  Future<void> checkLocationStatus() async {
    final locationService = LocationService();
    _isLocationEnabled = await locationService.isLocationEnabled();
    notifyListeners();
  }

  Future<bool> enableLocation() async {
    final locationService = LocationService();
    bool success = await locationService.requestLocationPermission();
    _isLocationEnabled = success;
    notifyListeners();
    return success;
  }

  Future<void> disableLocation() async {
    final locationService = LocationService();
    await locationService.disableLocation();
    _isLocationEnabled = false;
    notifyListeners();
  }

  // Add to the initialize method
  Future<void> initialize() async {
    // ... (existing initialization code) ...

    // Initialize location status
    await checkLocationStatus();

    // Initialize notification status
    await checkNotificationSettings();

    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();
  }

  // Check and ensure user data exists in Firestore
  Future<void> ensureUserDataInFirestore() async {
    try {
      // Only proceed if user is authenticated
      if (_authService.isSignedIn) {
        debugPrint('Checking if user data exists in Firestore...');

        // Get the current auth user
        final User? firebaseUser = _authService.currentUser;

        if (firebaseUser == null) {
          debugPrint('No Firebase Auth user found');
          return;
        }

        // Try to get user data from Firestore
        final userData = await _authService.getUserData();

        if (userData == null) {
          debugPrint(
            'User data not found in Firestore. Creating default profile...',
          );

          // Create a basic user profile
          final newUserData = UserModel(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'New User',
            email: firebaseUser.email ?? '',
            phoneNumber: '',
            bloodType: 'A+', // Default blood type
            address: '',
            isAvailableToDonate: true,
          );

          // Save to Firestore
          await _userService.saveUserData(newUserData);

          // Update current user
          _currentUser = newUserData;
          notifyListeners();

          debugPrint('Created default user profile in Firestore');
        } else {
          debugPrint('User data exists in Firestore');
        }
      }
    } catch (e) {
      debugPrint('Error ensuring user data in Firestore: $e');
    }
  }

  // Update blood requests list
  void updateBloodRequests(List<BloodRequestModel> requests) {
    _bloodRequests = requests;
    notifyListeners();
  }

  // Load emergency contacts for the current user
  Future<void> loadEmergencyContacts() async {
    if (!isLoggedIn) return;

    try {
      // Get only user's personal contacts (not built-in ones)
      final QuerySnapshot userContactsSnapshot =
          await FirebaseFirestore.instance
              .collection('emergency_contacts')
              .where('userId', isEqualTo: currentUser.id)
              .orderBy('isPinned', descending: true)
              .orderBy('name')
              .get();

      final List<EmergencyContactModel> userContacts =
          userContactsSnapshot.docs
              .map(
                (doc) => EmergencyContactModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();

      _emergencyContacts = userContacts;
      debugPrint('Loaded ${userContacts.length} user-added emergency contacts');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading emergency contacts: $e');
    }
  }

  // Get a stream of emergency contacts for real-time updates
  Stream<List<EmergencyContactModel>> getEmergencyContactsStream() {
    if (!isLoggedIn) return Stream.value([]);

    try {
      // Stream user's personal contacts only (not built-in ones)
      return FirebaseFirestore.instance
          .collection('emergency_contacts')
          .where('userId', isEqualTo: currentUser.id)
          .orderBy('isPinned', descending: true)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
            final List<EmergencyContactModel> userContacts =
                snapshot.docs
                    .map(
                      (doc) => EmergencyContactModel.fromJson(
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .toList();

            return userContacts;
          });
    } catch (e) {
      debugPrint('Error streaming emergency contacts: $e');
      // Return an empty stream
      return Stream.value([]);
    }
  }

  // Add a new emergency contact
  Future<bool> addEmergencyContact(EmergencyContactModel contact) async {
    if (!isLoggedIn) return false;

    try {
      // Create a new contact with the current user ID
      final newContact = contact.copyWith(userId: currentUser.id);

      // Add to Firebase
      final success = await _emergencyContactService.addEmergencyContact(
        newContact,
      );

      if (success) {
        // Refresh the contacts list
        await loadEmergencyContacts();
      }

      return success;
    } catch (e) {
      debugPrint('Error adding emergency contact: $e');
      return false;
    }
  }

  // Update an existing emergency contact
  Future<bool> updateEmergencyContact(EmergencyContactModel contact) async {
    if (!isLoggedIn) return false;

    try {
      final success = await _emergencyContactService.updateEmergencyContact(
        contact,
      );

      if (success) {
        // Refresh the contacts list
        await loadEmergencyContacts();
      }

      return success;
    } catch (e) {
      debugPrint('Error updating emergency contact: $e');
      return false;
    }
  }

  // Delete an emergency contact
  Future<bool> deleteEmergencyContact(String contactId) async {
    if (!isLoggedIn) return false;

    try {
      final success = await _emergencyContactService.deleteEmergencyContact(
        contactId,
      );

      if (success) {
        // Refresh the contacts list
        await loadEmergencyContacts();
      }

      return success;
    } catch (e) {
      debugPrint('Error deleting emergency contact: $e');
      return false;
    }
  }

  // Toggle pin status for a contact
  Future<bool> toggleContactPinStatus(String contactId, bool isPinned) async {
    if (!isLoggedIn) return false;

    try {
      final success = await _emergencyContactService.togglePinStatus(
        contactId,
        isPinned,
      );

      if (success) {
        // Refresh the contacts list
        await loadEmergencyContacts();
      }

      return success;
    } catch (e) {
      debugPrint('Error toggling pin status: $e');
      return false;
    }
  }

  // Send a notification to another user
  Future<bool> sendNotification(NotificationModel notification) async {
    try {
      final result = await _notificationService.addNotification(notification);
      debugPrint('Notification sent successfully: ${result.id}');
      
      // If the notification is for the current user, also show it in system drawer
      if (notification.userId == _currentUser?.id) {
        _showLocalNotificationFromModel(notification.copyWith(id: result.id));
      }
      
      return true;
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return false;
    }
  }
  
  // Helper method to reliably show a local notification from a notification model
  Future<void> _showLocalNotificationFromModel(NotificationModel notification) async {
    try {
      // First check if notification service is available through service locator
      if (serviceLocator != null) {
        final localNotificationService = serviceLocator.localNotificationService;
        
        // Create payload with notification ID and type
        final payload = json.encode({
          'notificationId': notification.id,
          'type': notification.type,
          'metadata': notification.metadata
        });
        
        // Show the notification
        await localNotificationService.showNotification(
          title: notification.title,
          body: notification.body,
          payload: payload,
        );
        
        debugPrint('✅ [LocalNotification] Successfully showed local notification: ${notification.title}');
      } else {
        debugPrint('⚠️ [LocalNotification] Could not show notification: Service locator not available');
      }
    } catch (e) {
      debugPrint('❌ [LocalNotification] Error showing local notification: $e');
      // Error is caught silently to avoid app crashes
    }
  }

  // Get user details by ID
  Future<UserModel?> getUserDetailsById(String userId) async {
    try {
      final userData = await _userService.getUserData(userId);
      return userData;
    } catch (e) {
      debugPrint('Error getting user details: $e');
      return null;
    }
  }

  // Get emergency contacts for a user
  Future<List<EmergencyContactModel>> getEmergencyContactsForUser(
    String userId,
  ) async {
    try {
      final contacts = await _emergencyContactService
          .getEmergencyContactsForUser(userId);
      return contacts;
    } catch (e) {
      debugPrint('Error fetching emergency contacts: $e');
      rethrow;
    }
  }

  // Get health questionnaire data for a user by their ID
  Future<Map<String, dynamic>?> getHealthQuestionnaireData(
    String userId,
  ) async {
    try {
      // Fetch health questionnaire data from Firestore
      debugPrint('Fetching health questionnaire data for user: $userId');

      final documentSnapshot =
          await _firestore
              .collection('health_questionnaires')
              .doc(userId)
              .get();

      if (!documentSnapshot.exists) {
        debugPrint('No health questionnaire found for user: $userId');
        return null;
      }

      final data = documentSnapshot.data();
      debugPrint('Found health questionnaire data: $data');

      return data;
    } catch (e) {
      debugPrint('Error fetching health questionnaire data: $e');
      return null; // Return null instead of rethrowing to avoid crashing the UI
    }
  }

  // Accept a blood request response
  Future<void> acceptBloodRequestResponse(
    String requestId,
    String responderId,
  ) async {
    try {
      // Update request status to accepted
      await _firestore.collection('blood_requests').doc(requestId).update({
        'status': 'Accepted',
        'acceptedAt': DateTime.now().toIso8601String(),
      });

      // Get the current user (requester)
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Get user details
      final requesterDetails = await getUserDetailsById(currentUser.uid);
      if (requesterDetails == null) return;

      // Create notification model
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: responderId,
        title: 'Blood Donation Request Accepted',
        body:
            '${requesterDetails.name} has accepted your offer to donate blood.',
        type: 'blood_request_accepted',
        read: false,
        createdAt: DateTime.now().toIso8601String(),
        metadata: {
          'requesterId': currentUser.uid,
          'requesterName': requesterDetails.name,
          'requesterPhone': requesterDetails.phoneNumber,
          'requestId': requestId,
          'responderId': responderId,
        },
      );

      // Add notification
      await _notificationService.addNotification(notification);

      return;
    } catch (e) {
      debugPrint('Error accepting blood request response: $e');
      return;
    }
  }

  // Update management methods
  Future<void> checkForUpdates() async {
    // Guard against platform-related errors
    try {
      _isCheckingForUpdate = true;
      notifyListeners();
      
      try {
        // Get update information from Firestore through the AppUpdater
        final updateInfo = await AppUpdater.checkForUpdates();
        
        _updateAvailable = updateInfo['hasUpdate'] ?? false;
        _latestVersion = updateInfo['latestVersion'] ?? '';
        _updateDownloadUrl = updateInfo['downloadUrl'] ?? '';
        _releaseNotes = updateInfo['releaseNotes'] ?? '';
        
        _isCheckingForUpdate = false;
        notifyListeners();
      } catch (e) {
        debugPrint('Error checking for updates: $e');
        _isCheckingForUpdate = false;
        _updateAvailable = false;
        notifyListeners();
      }
    } catch (platformError) {
      // Handle platform detection or other critical errors
      debugPrint('Critical platform error in checkForUpdates: $platformError');
      _isCheckingForUpdate = false;
      _updateAvailable = false;
      notifyListeners();
    }
  }
  
  // Open the download URL in browser as fallback
  Future<void> openDownloadInBrowser() async {
    if (_updateDownloadUrl.isEmpty) {
      debugPrint('No download URL available');
      return;
    }
    
    try {
      // Make sure we're using the proper Google Drive URL for direct download
      String browserUrl = _updateDownloadUrl;
      
      // For Google Drive, we need to ensure it has the confirmation token
      if (browserUrl.contains('drive.google.com')) {
        debugPrint('Processing Google Drive URL for browser download');
        
        // If it doesn't already have the confirm parameter, add it
        if (!browserUrl.contains('confirm=')) {
          browserUrl = '$browserUrl&confirm=t';
        }
      }
      
      final url = Uri.parse(browserUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        debugPrint('Opened download URL in browser: $browserUrl');
      } else {
        debugPrint('Could not launch URL: $browserUrl');
      }
    } catch (e) {
      debugPrint('Error opening browser for download: $e');
    }
  }
  
  Future<void> downloadUpdate({BuildContext? context}) async {
    if (!_updateAvailable || _updateDownloadUrl.isEmpty) {
      debugPrint('No update available or download URL is empty');
      return;
    }
    
    _isDownloadingUpdate = true;
    _downloadProgress = 0.0;
    _downloadedFilePath = '';
    notifyListeners();
    
    try {
      // Check if we're dealing with a Dropbox URL
      bool isDropboxUrl = _updateDownloadUrl.contains('dropbox.com');
      debugPrint('Is Dropbox URL: $isDropboxUrl');
      
      // Try in-app download first
      try {
        await AppUpdater.downloadUpdate(
          _updateDownloadUrl,
          (progress) {
            _downloadProgress = progress;
            notifyListeners();
          },
          (filePath) async {
            _isDownloadingUpdate = false;
            _downloadProgress = 1.0;
            _downloadedFilePath = filePath;
            notifyListeners();
          },
          (error) async {
            debugPrint('Error downloading update in-app: $error');
            
            // If the in-app download fails, try browser download as fallback
            if (isDropboxUrl) {
              debugPrint('Trying browser download as fallback...');
              
              // Get direct download URL and try browser download
              final directUrl = AppUpdater.getDirectDownloadUrl(_updateDownloadUrl);
              final browserStarted = await AppUpdater.downloadWithBrowser(directUrl);
              debugPrint('Browser download with Dropbox URL: $browserStarted');
              
              if (browserStarted) {
                // Update UI to show browser download started
                _isDownloadingUpdate = false;
                _downloadProgress = 0.0;
                notifyListeners();
                return;
              }
            }
            
            // If all attempts fail, reset download state
            _isDownloadingUpdate = false;
            notifyListeners();
          },
          context: context,
        );
      } catch (e) {
        debugPrint('Exception in downloadUpdate: $e');
        _isDownloadingUpdate = false;
        notifyListeners();
        
        // Try browser download as last resort
        if (isDropboxUrl) {
          await AppUpdater.downloadWithBrowser(_updateDownloadUrl);
        }
      }
    } catch (e) {
      debugPrint('Exception in downloadUpdate: $e');
      _isDownloadingUpdate = false;
      notifyListeners();
    }
  }
  
  // Reset update state to allow retry
  void resetUpdateState() {
    _isDownloadingUpdate = false;
    _downloadProgress = 0.0;
    _downloadedFilePath = '';
    notifyListeners();
    debugPrint('Update state reset, retry is now possible');
  }
}
