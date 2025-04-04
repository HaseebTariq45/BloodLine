# BloodLine

This Flutter application helps connect blood donors with people in need of blood donations. It features user profiles, blood requests, donor search, and more.

## Features

- User Registration and Authentication
- Donor Profile Management
- Blood Type Selection
- Donor Availability Toggling
- Blood Request Creation
- Donor Search (by blood type and location)
- Blood Bank Locator
- Dynamic Donation History with Real-time Updates
  - Firebase Integration for Donation Tracking
  - Data Visualization with Charts
  - Donation Status Management (Pending, Completed, Cancelled)

## Backend Integration Instructions

The app is integrated with Firebase for authentication and data storage. Here's what has been implemented:

### Firebase Integration

- **Authentication**: User registration and login via Firebase Auth
- **Firestore**: Data storage for users, blood requests, and donations
- **Storage**: Profile images and other media assets

### Dynamic Donation History

The donation history feature has been implemented with real-time Firestore integration:

- **Real-time Updates**: Stream-based updates for donation history changes
- **Donation Management**: Add, cancel, and view donation history
- **Data Visualization**: Monthly donation charts to visualize donation frequency
- **Status Filtering**: Filter donations by status (All, Completed, Pending, Cancelled)

### User Registration and Authentication

In the `signup_screen.dart` file:

1. Locate the `_register()` method
2. Replace the simulated network delay with an actual API call to your authentication service
3. Send the collected user data (name, email, phone, address, password, blood type, etc.) to your backend
4. Process the registration response from your backend (success or error messages)

```dart
// Current implementation (front-end only)
Future.delayed(const Duration(milliseconds: 1500), () {
  // Create a new user with a unique ID (in real app, this would come from backend)
  final newUser = UserModel(...);
  appProvider.registerUser(newUser, _passwordController.text);
  // ...
});

// Replace with:
try {
  final response = await yourAuthService.register(
    name: _nameController.text,
    email: _emailController.text,
    phone: _phoneController.text,
    address: _addressController.text,
    password: _passwordController.text,
    bloodType: _bloodType,
    isAvailableToDonate: _isAvailableToDonate,
  );
  
  if (response.success) {
    // Create user from response data
    final newUser = UserModel(
      id: response.userId,
      name: _nameController.text,
      email: _emailController.text,
      // ...other fields
    );
    
    appProvider.registerUser(newUser, _passwordController.text);
    
    // Navigate to login or home screen
    Navigator.of(context).pushReplacementNamed('/login');
  } else {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  }
} catch (e) {
  // Handle network errors
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Network error: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

### Provider Integration

In the `app_provider.dart` file:

1. Modify the `registerUser` method to store auth tokens and user data
2. Implement proper API calls for user creation

```dart
// Current implementation
void registerUser(UserModel user, String password) {
  // For this demo, we just store the user object locally
  _currentUser = user;
  _donors.add(user);
  notifyListeners();
}

// Replace with:
Future<bool> registerUser(UserModel user, String password) async {
  try {
    // Store API tokens received from backend
    final response = await _apiService.register(user, password);
    _authToken = response.token;
    _currentUser = UserModel.fromJson(response.user);
    
    // Store tokens securely (using secure_storage or similar)
    await _storageService.setAuthToken(_authToken);
    
    notifyListeners();
    return true;
  } catch (e) {
    debugPrint('Registration error: $e');
    return false;
  }
}
```

### Profile Screen Integration

In the `profile_screen.dart` file:

1. Update the `_saveProfile` method to call your backend API
2. Add proper error handling for network requests

## Development

To run this project locally:

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Launch the app using `flutter run`

## Dependencies

- Flutter
- Provider (for state management)
- Animate_do (for animations)
- Google Fonts
- Flutter DotEnv (for environment variables)
- Firebase Core, Auth, Firestore (for backend integration)
- FL Chart (for donation history visualization)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
