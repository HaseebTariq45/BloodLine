# 🩸 BloodLine

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Version](https://img.shields.io/badge/Version-1.2.0-blue?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

A modern, feature-rich mobile application that connects blood donors with people in need of blood donations.

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-firebase-integration">Firebase Integration</a> •
  <a href="#-backend-integration">Backend Integration</a> •
  <a href="#-development">Development</a> •
  <a href="#-dependencies">Dependencies</a> •
  <a href="#-license">License</a>
</p>

</div>

---

## ✨ Features

### 🔐 User Registration and Authentication
- 🔒 Secure account creation and login with email/password
- 🔥 Firebase Authentication integration
- 👤 User profile management

### 🩸 Blood Donation Management
- 🩸 Blood Type Selection and compatibility matching
- 🔄 Donor Availability Toggling
- 📝 Blood Request Creation and management
- 🔍 Donor Search by blood type, location, and availability

### 🏥 Health Monitoring
- 📋 Health Questionnaire for donation eligibility assessment
- 🧬 Medical Conditions tracking
- 💡 Health Tips and best practices for donors
- 📅 Donation eligibility status and next donation date calculation

### 🚑 Emergency Services
- 🏢 Blood Bank Locator with map integration
- 📞 Emergency Contacts Management 
  - ➕ Add personal, hospital, blood bank, and ambulance contacts
  - 👨‍👩‍👧‍👦 Relationship selection dropdown for personal contacts
  - ☎️ Quick-dial functionality for emergency numbers
  - 📌 Contact pinning for quick access

### 📊 Donation History and Tracking
- 🔄 Dynamic Donation History with Real-time Updates
- 🔥 Firebase Integration for Donation Tracking
- 📈 Data Visualization with Charts
- 🔖 Donation Status Management (Pending, Completed, Cancelled)

### 🔔 Notifications System
- 📲 Push notification settings
- 📧 Email notification settings
- 🚨 Blood request alerts
- ⏰ Donation reminders

### ⚙️ Settings and Preferences
- 🎨 Theme customization options
- 🔒 Privacy controls
- 📊 Data usage management
- 🔕 Notification preferences

---

## 🔥 Firebase Integration

The app is fully integrated with Firebase for authentication, storage, and notifications:

| Service | Purpose |
|---------|---------|
| **Authentication** | User registration and login via Firebase Auth |
| **Firestore** | Data storage for users, blood requests, donations, emergency contacts, and health data |
| **Storage** | Profile images and other media assets |
| **Messaging** | Push notifications for blood donation requests and reminders |

---

## 🌟 Key Features In Detail

### 📊 Dynamic Donation History

<details>
<summary>Click to expand</summary>

The donation history feature has been implemented with real-time Firestore integration:

- **Real-time Updates**: Stream-based updates for donation history changes
- **Donation Management**: Add, cancel, and view donation history
- **Data Visualization**: Monthly donation charts to visualize donation frequency
- **Status Filtering**: Filter donations by status (All, Completed, Pending, Cancelled)

</details>

### 📞 Emergency Contacts

<details>
<summary>Click to expand</summary>

The emergency contacts feature provides quick access to important contacts during emergencies:

- **Contact Management**: Add, edit, delete, and organize your emergency contacts
- **Categorization**: Categorize contacts as personal, hospital, blood bank, or ambulance
- **Relationship Selection**: Choose relationship types from a dropdown including:
  - Spouse, Parent, Child, Sibling, Relative, Friend, Colleague, Doctor, Caregiver, or Other
- **Contact Pinning**: Pin important contacts to the top of your list
- **Quick Dial**: One-tap calling for emergency services
- **Built-in Emergency Numbers**: Pre-loaded with essential emergency service numbers
- **Real-time Syncing**: All contacts are synced to your account in real-time

</details>

### 📋 Health Questionnaire

<details>
<summary>Click to expand</summary>

The health questionnaire helps determine donor eligibility:

- **Comprehensive Assessment**: Evaluates health factors that may affect donation eligibility
- **Medical History Tracking**: Records previous medical conditions and medications
- **Donation Eligibility Status**: Automatically calculates eligibility status
- **Next Donation Date**: Calculates the next possible donation date based on health factors
- **Temporary Deferrals**: Identifies and explains temporary deferrals
- **Progress Tracking**: Saves progress as you complete the questionnaire

</details>

### 🔔 Notifications System

<details>
<summary>Click to expand</summary>

The app features a comprehensive notification system:

- **Push Notifications**: Real-time alerts for blood donation requests in your area
- **Email Notifications**: Optional email alerts for important updates
- **Donation Reminders**: Reminds you when you're eligible to donate again
- **Request Updates**: Notifications when your blood request receives responses
- **Custom Settings**: Fine-grained control over notification preferences

</details>

---

## 🔄 Backend Integration

### 🔐 User Registration and Authentication

<details>
<summary>Click to expand</summary>

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

</details>

### 📱 Provider Integration

<details>
<summary>Click to expand</summary>

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

</details>

### 👤 Profile Screen Integration

<details>
<summary>Click to expand</summary>

In the `profile_screen.dart` file:

1. Update the `_saveProfile` method to call your backend API
2. Add proper error handling for network requests

</details>

---

## 🚀 Development

To run this project locally:

1. Clone the repository
   ```bash
   git clone https://github.com/your-username/bloodline.git
   cd bloodline
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Setup Firebase project and add configuration files:
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS
   - Follow the Firebase setup guide in `firestore_setup_guide.md`

4. Launch the app
   ```bash
   flutter run
   ```

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| **Flutter & Flutter Localizations** | Core framework |
| **Provider** | State management |
| **Firebase Core, Auth, Firestore** | Backend services |
| **Firebase Storage & Messaging** | Media storage and notifications |
| **Google Maps Flutter** | Location services |
| **FL Chart** | Data visualization |
| **URL Launcher** | Phone call functionality |
| **Animate_do & Lottie** | Animations |
| **Flutter SVG & Google Fonts** | UI enhancements |
| **Share Plus & Path Provider** | Sharing functionality |
| **Geolocator & Geocoding** | Location services |
| **Flutter Local Notifications** | Local notifications |
| **Flutter DotEnv** | Environment management |

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

<div align="center">
  Made with ❤️ for blood donors worldwide
</div>

---

## 👨‍💻 Meet the Developer

<div align="center">

### Haseeb Tariq
**Mobile App Developer**

</div>

BloodLine was developed by Haseeb Tariq, a dedicated mobile application developer with a passion for creating solutions that make a difference. Haseeb has expertly integrated modern technologies like Flutter and Firebase to build this comprehensive blood donation platform.

### Connect with Haseeb

<div align="center">

[![Email](https://img.shields.io/badge/Email-haseebawang4545%40gmail.com-red?style=for-the-badge&logo=gmail&logoColor=white)](mailto:haseebawang4545@gmail.com)
[![GitHub](https://img.shields.io/badge/GitHub-HaseebTariq45-black?style=for-the-badge&logo=github&logoColor=white)](https://github.com/HaseebTariq45)
[![Instagram](https://img.shields.io/badge/Instagram-haseeb__awan45-E1306C?style=for-the-badge&logo=instagram&logoColor=white)](https://instagram.com/haseeb_awan45)
[![Twitter](https://img.shields.io/badge/Twitter-haseeb__awan45-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white)](https://twitter.com/haseeb_awan45)

</div>

Have suggestions or want to contribute to the project? Feel free to reach out or submit a pull request on GitHub.
