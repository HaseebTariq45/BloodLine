import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/cities_data.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';
import '../utils/theme_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late String _bloodType;
  late String _city;
  late bool _isAvailableToDonate;
  bool _isEditing = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _userId;
  String? _phoneNumber;
  String? _address;
  String? _lastDonationDate;
  String _healthStatus = 'Healthy';
  Color _healthStatusColor = Colors.green;
  String? _nextDonationDate;

  // Health Questionnaire Data
  String? _height;
  String? _weight;
  String? _gender;
  bool _hasTattoo = false;
  bool _hasPiercing = false;
  bool _hasTraveled = false;
  bool _hasSurgery = false;
  bool _hasTransfusion = false;
  bool _hasPregnancy = false;
  bool _hasDisease = false;
  bool _hasMedication = false;
  bool _hasAllergies = false;
  String? _medications;
  String? _allergies;

  // List of available blood types
  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // Add private fields for health data
  String? _lastHealthCheck;
  String? _medicalConditions;
  String? _lastDonationLocation;
  int? _donationCount;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = appProvider.currentUser;

    _nameController = TextEditingController(text: currentUser.name);
    _emailController = TextEditingController(text: currentUser.email);
    _phoneController = TextEditingController(text: currentUser.phoneNumber);
    _phoneNumber = currentUser.phoneNumber;
    _addressController = TextEditingController(text: currentUser.address);
    _bloodType = currentUser.bloodType;
    _city = currentUser.city.isNotEmpty ? currentUser.city : 'Karachi';
    _isAvailableToDonate = currentUser.isAvailableToDonate;

    // Initialize health data
    _lastHealthCheck = 'June 15, 2023'; // Example data
    _healthStatus = 'Healthy';
    _healthStatusColor = Colors.green;
    _medicalConditions = 'None';

    // Initialize donation data
    _lastDonationLocation = 'City Hospital';
    _nextDonationDate = DateTime.now()
        .add(const Duration(days: 30))
        .toString()
        .substring(0, 10);
    _donationCount = 3;

    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;  // Don't proceed if widget is not mounted
    
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userId = user.uid;

        // Load user profile data
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_userId)
                .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;

          if (!mounted) return;  // Check again after async operation
          
          // Update controllers with null safety
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          
          // The field in Firestore is 'phoneNumber', not 'phone'
          final phoneValue = data['phoneNumber'] ?? '';
          _phoneController.text = phoneValue;
          _phoneNumber = phoneValue;
          print('Loaded phone number from Firestore: $phoneValue');
          
          _addressController.text = data['address'] ?? '';

          // Update other fields with null safety
          _bloodType = data['bloodType'] ?? 'Unknown';
          _city = data['city'] ?? 'Karachi';
          _address = data['address'];
          _isAvailableToDonate = data['isAvailableToDonate'] ?? true;

          // Handle lastDonationDate with better null safety
          if (data['lastDonationDate'] != null) {
            try {
              if (data['lastDonationDate'] is Timestamp) {
                _lastDonationDate =
                    (data['lastDonationDate'] as Timestamp)
                        .toDate()
                        .millisecondsSinceEpoch
                        .toString();
              } else if (data['lastDonationDate'] is int) {
                _lastDonationDate = data['lastDonationDate'].toString();
              } else if (data['lastDonationDate'] is String) {
                _lastDonationDate = data['lastDonationDate'];
              }
            } catch (e) {
              print('Error parsing lastDonationDate: $e');
              _lastDonationDate = null;
            }
          }
        }

        // Load health questionnaire data with null safety
        final healthDoc =
            await FirebaseFirestore.instance
                .collection('health_questionnaires')
                .doc(_userId)
                .get();

        if (healthDoc.exists && mounted) {  // Check if still mounted
          final data = healthDoc.data()!;

          setState(() {
            _height = data['height']?.toString();
            _weight = data['weight']?.toString();
            _gender = data['gender'];
            _hasTattoo = data['hasTattoo'] ?? false;
            _hasPiercing = data['hasPiercing'] ?? false;
            _hasTraveled = data['hasTraveled'] ?? false;
            _hasSurgery = data['hasSurgery'] ?? false;
            _hasTransfusion = data['hasTransfusion'] ?? false;
            _hasPregnancy = data['hasPregnancy'] ?? false;
            _hasDisease = data['hasDisease'] ?? false;
            _hasMedication = data['hasMedication'] ?? false;
            _hasAllergies = data['hasAllergies'] ?? false;
            _medications = data['medications'];
            _allergies = data['allergies'];

            // Determine health status
            _determineHealthStatus();
          });
        }
        
        // Sync availability status based on donation date when profile loads
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.syncDonationAvailability();
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {  // Only call setState if still mounted
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Determine health status based on questionnaire data
  void _determineHealthStatus() {
    bool hasRiskFactors =
        _hasTattoo ||
        _hasPiercing ||
        _hasTraveled ||
        _hasSurgery ||
        _hasTransfusion ||
        _hasPregnancy ||
        _hasDisease ||
        _hasMedication ||
        _hasAllergies;

    if (hasRiskFactors) {
      if (_hasTattoo || _hasPiercing) {
        _healthStatus = 'Possible Temp. Delay';
        _healthStatusColor = Colors.orange;
      } else if (_hasDisease || _hasTransfusion) {
        _healthStatus = 'Possible Permanent Deferral';
        _healthStatusColor = Colors.red.shade700;
      } else {
        _healthStatus = 'Needs Review';
        _healthStatusColor = Colors.blue.shade600;
      }
    } else {
      _healthStatus = 'Eligible';
      _healthStatusColor = Colors.green;
    }
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // Cancel editing - reset values
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final currentUser = appProvider.currentUser;

        _nameController.text = currentUser.name;
        // First try to use the current user's phone number, if empty use the cached _phoneNumber
        String phoneToUse = currentUser.phoneNumber.isNotEmpty ? currentUser.phoneNumber : (_phoneNumber ?? '');
        _phoneController.text = phoneToUse;
        print('Restoring phone number on cancel: $phoneToUse');
        
        _addressController.text = currentUser.address;
        _bloodType = currentUser.bloodType;
        _city = currentUser.city;
        _isAvailableToDonate = currentUser.isAvailableToDonate;
      } else {
        // Entering edit mode - Make sure phone controller has the current value
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final currentUser = appProvider.currentUser;
        
        // First try using the phone value from currentUser
        if (currentUser.phoneNumber.isNotEmpty) {
          _phoneController.text = currentUser.phoneNumber;
          _phoneNumber = currentUser.phoneNumber;
          print('Setting phone controller from currentUser in edit mode: ${currentUser.phoneNumber}');
        } 
        // If currentUser.phoneNumber is empty but we have a cached value, use that
        else if (_phoneNumber != null && _phoneNumber!.isNotEmpty) {
          _phoneController.text = _phoneNumber!;
          print('Setting phone controller from cached value in edit mode: $_phoneNumber');
        }
        // Otherwise, backup whatever is in the controller
        else {
          _phoneNumber = _phoneController.text;
          print('Backing up phone number before edit: $_phoneNumber');
        }
      }
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUser = appProvider.currentUser;

      // Update local cache of phone number
      _phoneNumber = _phoneController.text;
      print('Saving phone number: $_phoneNumber');

      // Create updated user
      final updatedUser = UserModel(
        id: currentUser.id,
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : (_phoneNumber ?? ''),
        address: _addressController.text,
        bloodType: _bloodType,
        city: _city,
        isAvailableToDonate: _isAvailableToDonate,
        lastDonationDate: currentUser.lastDonationDate,
        imageUrl: currentUser.imageUrl,
        location: currentUser.location,
      );

      // For debugging
      print('Updating user profile - phone: ${updatedUser.phoneNumber}');

      // Simulate network delay
      Future.delayed(const Duration(milliseconds: 800), () {
        // Note: In a real implementation, we would save the data to a database or API here
        // For now, we just update the local state
        appProvider.updateUserProfile(updatedUser);

        setState(() {
          _isLoading = false;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Profile updated successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      });
    } catch (e) {
      print('Error saving profile: $e');
      // Show error toast
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentUser = appProvider.currentUser;
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: _isEditing ? 'Edit Profile' : 'My Profile',
        showProfilePicture: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Settings',
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _loadUserData,
                    color: AppConstants.primaryColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Profile Header with Avatar - more compact now
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppConstants.primaryColor,
                                  AppConstants.primaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppConstants.primaryColor.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  orientation == Orientation.portrait
                                      ? screenSize.height * 0.02
                                      : screenSize.height * 0.015,
                              horizontal: screenSize.width * 0.04,
                            ),
                            child:
                                orientation == Orientation.portrait
                                    ? _buildProfileHeaderPortrait(currentUser)
                                    : _buildProfileHeaderLandscape(currentUser),
                          ),

                          // Main content body
                          Padding(
                            padding: EdgeInsets.all(screenSize.width * 0.04),
                            child:
                                _isEditing
                                    ? _buildEditForm()
                                    : _buildContentBody(
                                      currentUser,
                                      orientation,
                                    ),
                          ),

                          // Bottom padding to prevent FAB overlap
                          SizedBox(
                            height: _isEditing ? 0 : screenSize.height * 0.08,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
          },
        ),
      ),
      floatingActionButton:
          !_isEditing
              ? FloatingActionButton(
                onPressed: _toggleEdit,
                backgroundColor: AppConstants.primaryColor,
                child: const Icon(Icons.edit, color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              )
              : null,
    );
  }

  // Portrait mode profile header - more compact version
  Widget _buildProfileHeaderPortrait(UserModel currentUser) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    // Reduce avatar size from 30% to 22% of screen width
    final avatarSize = screenSize.width * 0.22;
    // Slightly reduce font sizes
    final fontSize = screenSize.width * 0.045;
    final smallFontSize = screenSize.width * 0.03;

    return Row(
      children: [
        // Avatar section with blood type badge
        Stack(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
                image:
                    currentUser.imageUrl.isNotEmpty
                        ? DecorationImage(
                          image: NetworkImage(currentUser.imageUrl),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  currentUser.imageUrl.isEmpty
                      ? FittedBox(
                        fit: BoxFit.contain,
                        child: Padding(
                          padding: EdgeInsets.all(avatarSize * 0.2),
                          child: Icon(
                            Icons.person,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      )
                      : null,
            ),
            // Blood type badge
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(screenSize.width * 0.015),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currentUser.bloodType,
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: screenSize.width * 0.035,
                    ),
                  ),
                ),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: avatarSize * 0.2,
                child: Container(
                  padding: EdgeInsets.all(screenSize.width * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: AppConstants.primaryColor,
                    size: screenSize.width * 0.04,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(width: screenSize.width * 0.04),
        // User info section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  currentUser.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.008),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.03,
                  vertical: screenSize.height * 0.008,
                ),
                decoration: BoxDecoration(
                  color:
                      currentUser.isAvailableToDonate
                          ? Colors.green
                          : Colors.red,
                  borderRadius: BorderRadius.circular(screenSize.width * 0.04),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currentUser.isAvailableToDonate
                        ? 'Available to Donate'
                        : 'Not Available to Donate',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: smallFontSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Landscape mode profile header - more compact version
  Widget _buildProfileHeaderLandscape(UserModel currentUser) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    // Smaller size based on screen height for landscape mode
    final avatarSize = screenSize.height * 0.18;
    final fontSize = screenSize.height * 0.04;
    final smallFontSize = screenSize.height * 0.025;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Avatar with badges
        Stack(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
                image:
                    currentUser.imageUrl.isNotEmpty
                        ? DecorationImage(
                          image: NetworkImage(currentUser.imageUrl),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  currentUser.imageUrl.isEmpty
                      ? FittedBox(
                        fit: BoxFit.contain,
                        child: Padding(
                          padding: EdgeInsets.all(avatarSize * 0.2),
                          child: Icon(
                            Icons.person,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      )
                      : null,
            ),
            // Blood type badge
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(screenSize.height * 0.008),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currentUser.bloodType,
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: screenSize.height * 0.025,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: screenSize.width * 0.03),
        // User Info
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  currentUser.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.008),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.02,
                  vertical: screenSize.height * 0.008,
                ),
                decoration: BoxDecoration(
                  color:
                      currentUser.isAvailableToDonate
                          ? Colors.green
                          : Colors.red,
                  borderRadius: BorderRadius.circular(
                    screenSize.height * 0.015,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currentUser.isAvailableToDonate
                        ? 'Available to Donate'
                        : 'Not Available to Donate',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: smallFontSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Main content body wrapper to separate scrolling logic
  Widget _buildContentBody(UserModel user, Orientation orientation) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive padding and spacing
        final contentPadding = screenSize.width * 0.04;
        final cardSpacing = screenSize.height * 0.025;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Cards with dynamic sizing
            _buildQuickStats(user, orientation),

            SizedBox(height: cardSpacing),

            // User information section with responsive styling
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenSize.width * 0.04),
              ),
              child: Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: AppConstants.primaryColor,
                          size: screenSize.width * 0.055,
                        ),
                        SizedBox(width: contentPadding / 2),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: screenSize.width * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(thickness: screenSize.height * 0.002),
                    _buildInfoRow('Name', user.name, Icons.person_outline),
                    _buildInfoRow('Email', user.email, Icons.email_outlined),
                    _buildInfoRow(
                      'Phone',
                      user.phoneNumber,
                      Icons.phone_outlined,
                    ),
                    _buildInfoRow('Address', user.address, Icons.home_outlined),
                  ],
                ),
              ),
            ),

            SizedBox(height: cardSpacing),

            // Health information section with responsive styling
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenSize.width * 0.04),
              ),
              child: Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.health_and_safety,
                          color: Colors.green,
                          size: screenSize.width * 0.055,
                        ),
                        SizedBox(width: contentPadding / 2),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Health Status',
                              style: TextStyle(
                                fontSize: screenSize.width * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(thickness: screenSize.height * 0.002),
                    _buildInfoRow(
                      'Blood Type',
                      user.bloodType,
                      Icons.bloodtype_outlined,
                      valueColor: AppConstants.primaryColor,
                      valueBold: true,
                    ),
                    _buildInfoRow(
                      'Last Health Check',
                      _lastHealthCheck ?? 'Not available',
                      Icons.calendar_today_outlined,
                    ),
                    _buildInfoRow(
                      'Health Status',
                      _healthStatus,
                      Icons.favorite_outline,
                      valueColor: _healthStatusColor,
                    ),
                    if (_medicalConditions != null &&
                        _medicalConditions!.isNotEmpty)
                      _buildInfoRow(
                        'Medical Conditions',
                        _medicalConditions ?? 'None',
                        Icons.medical_information_outlined,
                        valueColor: Colors.amber,
                      ),
                  ],
                ),
              ),
            ),

            // Donation history section with responsive styling
            if (user.lastDonationDate != null) ...[
              SizedBox(height: cardSpacing),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenSize.width * 0.04),
                ),
                child: Padding(
                  padding: EdgeInsets.all(contentPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: AppConstants.primaryColor,
                            size: screenSize.width * 0.055,
                          ),
                          SizedBox(width: contentPadding / 2),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Donation History',
                                style: TextStyle(
                                  fontSize: screenSize.width * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(thickness: screenSize.height * 0.002),
                      _buildInfoRow(
                        'Last Donation',
                        user.lastDonationDate.toString().substring(0, 10),
                        Icons.calendar_month_outlined,
                      ),
                      _buildInfoRow(
                        'Total Donations',
                        '${_donationCount ?? 0}',
                        Icons.bloodtype,
                        valueColor: AppConstants.primaryColor,
                        valueBold: true,
                      ),
                      _buildInfoRow(
                        'Last Location',
                        _lastDonationLocation ?? 'Not recorded',
                        Icons.location_on_outlined,
                      ),
                      _buildInfoRow(
                        'Next Eligible Date',
                        _nextDonationDate ?? 'Not available',
                        Icons.event_available_outlined,
                        valueColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Action buttons with responsive spacing
            SizedBox(height: cardSpacing),
            _buildActionButtons(orientation),
          ],
        );
      },
    );
  }

  // Build info row with icon - responsive implementation
  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final textTheme = Theme.of(context).textTheme;

    // Calculate responsive dimensions
    final iconSize = screenSize.width * 0.05;
    final labelFontSize = screenSize.width * 0.035;
    final valueFontSize = screenSize.width * 0.04;
    final spacing = screenSize.width * 0.03;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: iconSize, color: Colors.grey[600]),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label with FittedBox for text scaling
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: labelFontSize,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                SizedBox(height: screenSize.height * 0.005),
                // Value - use normal Text with ellipsis for multiline text
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
                    color: valueColor ?? textTheme.bodyLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Stats with improved responsiveness
  Widget _buildQuickStats(UserModel user, Orientation orientation) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine layout based on screen size
        final isNarrow = screenSize.width < 320;
        final statCardHeight =
            orientation == Orientation.portrait
                ? screenSize.height * 0.12
                : screenSize.height * 0.15;

        // For very small screens, stack the cards vertically
        if (isNarrow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatCard(
                title: 'Blood Type',
                value: user.bloodType,
                icon: Icons.bloodtype_outlined,
                iconColor: AppConstants.primaryColor,
                animate: true,
                fullWidth: true,
              ),
              SizedBox(height: screenSize.height * 0.01),
              _buildStatCard(
                title: 'City',
                value: user.city,
                icon: Icons.location_city_outlined,
                iconColor: Colors.blue,
                animate: true,
                fullWidth: true,
              ),
              SizedBox(height: screenSize.height * 0.01),
              _buildStatCard(
                title: 'Status',
                value: user.isAvailableToDonate ? 'Active' : 'Inactive',
                icon: Icons.circle,
                iconColor: user.isAvailableToDonate ? Colors.green : Colors.red,
                animate: true,
                fullWidth: true,
              ),
            ],
          );
        }

        // For normal screens, use a row with responsive height
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Blood Type',
                value: user.bloodType,
                icon: Icons.bloodtype_outlined,
                iconColor: AppConstants.primaryColor,
                animate: true,
              ),
            ),
            SizedBox(width: screenSize.width * 0.02),
            Expanded(
              child: _buildStatCard(
                title: 'City',
                value: user.city,
                icon: Icons.location_city_outlined,
                iconColor: Colors.blue,
                animate: true,
              ),
            ),
            SizedBox(width: screenSize.width * 0.02),
            Expanded(
              child: _buildStatCard(
                title: 'Status',
                value: user.isAvailableToDonate ? 'Active' : 'Inactive',
                icon: Icons.circle,
                iconColor: user.isAvailableToDonate ? Colors.green : Colors.red,
                animate: true,
              ),
            ),
          ],
        );
      },
    );
  }

  // Single stat card with responsive design
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool animate = false,
    bool fullWidth = false,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    // Calculate sizes based on screen dimensions
    final iconSize =
        fullWidth ? screenSize.width * 0.06 : screenSize.width * 0.05;
    final titleSize = screenSize.width * 0.03;
    final valueSize = screenSize.width * 0.04;

    // Create the responsive card content with constraints to prevent overflow
    final cardContent = Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenSize.width * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.03),
        child:
            fullWidth
                // Horizontal layout for full width
                ? Row(
                  children: [
                    Icon(icon, color: iconColor, size: iconSize),
                    SizedBox(width: screenSize.width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: valueSize,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: titleSize,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                // Vertical layout for grid display
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: iconColor, size: iconSize),
                    SizedBox(height: screenSize.height * 0.005),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: valueSize,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: titleSize,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );

    if (!animate) return cardContent;

    // Add a subtle animation if requested
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: cardContent,
    );
  }

  // Responsive action buttons
  Widget _buildActionButtons(Orientation orientation) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes
        final fontSize = screenSize.width * 0.04;
        final iconSize = screenSize.width * 0.05;
        final verticalPadding = screenSize.height * 0.015;
        final horizontalPadding = screenSize.width * 0.04;
        final borderRadius = BorderRadius.circular(screenSize.width * 0.03);
        final spacing = screenSize.height * 0.015;

        // For landscape orientation, use a row layout
        if (orientation == Orientation.landscape) {
          return Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/donation_tracking');
                  },
                  icon: Icon(Icons.bloodtype, size: iconSize),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'My Donations',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: verticalPadding,
                      horizontal: horizontalPadding,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: borderRadius),
                    elevation: 2,
                  ),
                ),
              ),
              SizedBox(width: screenSize.width * 0.03),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/health-questionnaire');
                  },
                  icon: Icon(Icons.health_and_safety, size: iconSize),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Health Information',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: verticalPadding,
                      horizontal: horizontalPadding,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: borderRadius),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          );
        }

        // For portrait orientation, use a column layout
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/donation_tracking');
              },
              icon: Icon(Icons.bloodtype, size: iconSize),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'My Donations',
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: verticalPadding,
                  horizontal: horizontalPadding,
                ),
                shape: RoundedRectangleBorder(borderRadius: borderRadius),
                elevation: 2,
              ),
            ),
            SizedBox(height: spacing),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/health-questionnaire');
              },
              icon: Icon(Icons.health_and_safety, size: iconSize),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Update Health Information',
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: verticalPadding,
                  horizontal: horizontalPadding,
                ),
                shape: RoundedRectangleBorder(borderRadius: borderRadius),
                elevation: 2,
              ),
            ),
          ],
        );
      },
    );
  }

  // Profile Edit Form with responsive constraints
  Widget _buildEditForm() {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final titleFontSize = screenWidth < 360 ? 18.0 : 20.0;

    // Enhanced phone number handling
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = appProvider.currentUser;
    
    // Check all possible sources for phone number in priority order
    if (_phoneController.text.isEmpty) {
      if (currentUser.phoneNumber.isNotEmpty) {
        _phoneController.text = currentUser.phoneNumber;
        _phoneNumber = currentUser.phoneNumber;
        print('Setting phone controller from currentUser in edit form: ${currentUser.phoneNumber}');
      } else if (_phoneNumber != null && _phoneNumber!.isNotEmpty) {
        _phoneController.text = _phoneNumber!;
        print('Setting phone controller from cached _phoneNumber in edit form: $_phoneNumber');
      }
    } else {
      print('Phone controller already has value in edit form: ${_phoneController.text}');
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4, bottom: screenHeight * 0.02),
              child: Text(
                'Edit Your Profile',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isLandscape && screenWidth > 600)
              // Two-column layout for wide landscape
              Wrap(
                spacing: 16,
                runSpacing: 16, // Increased spacing between rows
                children: [
                  SizedBox(
                    width: (screenWidth - 48) * 0.48,
                    child: _buildTextInput(
                      'Name',
                      _nameController,
                      Icons.person_outline,
                      isRequired: true,
                    ),
                  ),
                  SizedBox(
                    width: (screenWidth - 48) * 0.48,
                    child: _buildTextInput(
                      'Email',
                      _emailController,
                      Icons.email_outlined,
                      readOnly: true,
                    ),
                  ),
                  SizedBox(
                    width: (screenWidth - 48) * 0.48,
                    child: _buildTextInput(
                      'Phone',
                      _phoneController,
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      isRequired: true,
                    ),
                  ),
                  SizedBox(
                    width: (screenWidth - 48) * 0.48,
                    child: _buildBloodTypeSelector(),
                  ),
                  SizedBox(
                    width: (screenWidth - 48) * 0.48,
                    child: _buildCityDropdown(),
                  ),
                  SizedBox(
                    width: (screenWidth - 48) * 0.48,
                    child: _buildDonationSwitch(),
                  ),
                  SizedBox(
                    width: screenWidth - 32,
                    child: _buildTextInput(
                      'Address',
                      _addressController,
                      Icons.home_outlined,
                      isRequired: true,
                      maxLines: 3,
                    ),
                  ),
                ],
              )
            else
              // Single column for portrait or narrow landscape
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextInput(
                    'Name',
                    _nameController,
                    Icons.person_outline,
                    isRequired: true,
                  ),
                  _buildTextInput(
                    'Email',
                    _emailController,
                    Icons.email_outlined,
                    readOnly: true,
                  ),
                  _buildTextInput(
                    'Phone',
                    _phoneController,
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    isRequired: true,
                  ),
                  _buildTextInput(
                    'Address',
                    _addressController,
                    Icons.home_outlined,
                    isRequired: true,
                    maxLines: 3,
                  ),
                  _buildCityDropdown(),
                  _buildBloodTypeSelector(),
                  _buildDonationSwitch(),
                ],
              ),

            // Action buttons with responsive layout
            Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.02,
                bottom: screenHeight * 0.06,
              ),
              child:
                  isLandscape
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _toggleEdit,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.06,
                                vertical: screenHeight * 0.015,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (_isEditing)
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveProfile,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(
                                _isLoading ? 'Saving...' : 'Save Changes',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
                                  vertical: screenHeight * 0.015,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveProfile,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(
                              _isLoading ? 'Saving...' : 'Save Changes',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.06,
                                vertical: screenHeight * 0.015,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _toggleEdit,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.06,
                                vertical: screenHeight * 0.015,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // Donation availability switch with improved styling
  Widget _buildDonationSwitch() {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final fontSize = screenSize.width * 0.04;
    final smallFontSize = fontSize * 0.75;
    final iconSize = screenSize.width * 0.055;
    final borderRadius = BorderRadius.circular(screenSize.width * 0.03);
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = appProvider.currentUser;
    final bool isEligibleBasedOnDate = currentUser.isAvailableBasedOnDonationDate;

    return Container(
      margin: EdgeInsets.only(bottom: screenSize.height * 0.02),
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.04,
        vertical: screenSize.height * 0.015,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: borderRadius,
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volunteer_activism,
                color: AppConstants.primaryColor,
                size: iconSize,
              ),
              SizedBox(width: screenSize.width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available to Donate',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isEligibleBasedOnDate 
                          ? 'Show your profile to those in need of blood'
                          : 'You must wait ${currentUser.daysUntilNextDonation} days until eligible',
                      style: TextStyle(
                        fontSize: smallFontSize,
                        color: isEligibleBasedOnDate
                            ? Theme.of(context).textTheme.bodySmall?.color
                            : Colors.orange,
                        fontWeight: isEligibleBasedOnDate ? FontWeight.normal : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isAvailableToDonate,
                onChanged: isEligibleBasedOnDate && _isEditing
                    ? (value) {
                        setState(() {
                          _isAvailableToDonate = value;
                        });
                      }
                    : null,
                activeColor: AppConstants.primaryColor,
              ),
            ],
          ),
          if (!isEligibleBasedOnDate) ...[
            SizedBox(height: screenSize.height * 0.01),
            Padding(
              padding: EdgeInsets.only(left: iconSize + screenSize.width * 0.03),
              child: Text(
                'Last donation: ${currentUser.lastDonationDate.toString().substring(0, 10)}',
                style: TextStyle(
                  fontSize: smallFontSize,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build the city dropdown
  Widget _buildCityDropdown() {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    final fontSize = screenSize.width * 0.04;
    final labelFontSize = fontSize * 0.9;
    final iconSize = screenSize.width * 0.055;
    final borderRadius = BorderRadius.circular(screenSize.width * 0.03);

    return Container(
      margin: EdgeInsets.only(bottom: screenSize.height * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'City',
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: screenSize.height * 0.01),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: context.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _city.isEmpty ? null : _city,
                isExpanded: true,
                hint: Center(
                  child: Text(
                    'Select City',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: fontSize,
                    ),
                  ),
                ),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _isEditing ? AppConstants.primaryColor : Theme.of(context).disabledColor,
                    size: 20,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
                menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
                selectedItemBuilder: (BuildContext context) {
                  return CityManager().cities.map<Widget>((item) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: fontSize,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: CityManager().cities.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            city,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: fontSize,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _isEditing
                  ? (newValue) {
                    setState(() {
                      _city = newValue!;
                    });
                  }
                  : null,
                dropdownColor: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                elevation: 8,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build formatted text input
  Widget _buildTextInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final fontSize = screenSize.width * 0.04;
    final iconSize = screenSize.width * 0.055;
    final borderRadius = BorderRadius.circular(screenSize.width * 0.03);

    // Enhanced phone number handling with better debugging
    if (label == 'Phone') {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUser = appProvider.currentUser;
      
      print('Phone field check - controller value: ${controller.text}');
      print('Phone field check - _phoneNumber value: $_phoneNumber');
      print('Phone field check - provider value: ${currentUser.phoneNumber}');
      
      if (controller.text.isEmpty) {
        // Try provider value first
        if (currentUser.phoneNumber.isNotEmpty) {
          controller.text = currentUser.phoneNumber;
          _phoneNumber = currentUser.phoneNumber;
          print('Setting phone controller from provider in text input: ${currentUser.phoneNumber}');
        } 
        // Then try cached value
        else if (_phoneNumber != null && _phoneNumber!.isNotEmpty) {
          controller.text = _phoneNumber!;
          print('Setting phone controller from cached value in text input: $_phoneNumber');
        }
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: screenSize.height * 0.02),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: fontSize,
          color:
              readOnly
                  ? Colors.grey
                  : Theme.of(context).textTheme.bodyMedium?.color,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: fontSize),
          prefixIcon: Icon(
            icon,
            color: AppConstants.primaryColor,
            size: iconSize,
          ),
          border: OutlineInputBorder(borderRadius: borderRadius),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: EdgeInsets.symmetric(
            vertical: screenSize.height * 0.015,
            horizontal: screenSize.width * 0.03,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
          ),
        ),
        validator:
            isRequired
                ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your $label';
                  }
                  return null;
                }
                : null,
      ),
    );
  }

  // Build blood type selector
  Widget _buildBloodTypeSelector() {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final fontSize = screenSize.width * 0.04;
    final labelFontSize = fontSize * 0.9;
    final iconSize = screenSize.width * 0.055;
    final borderRadius = BorderRadius.circular(screenSize.width * 0.03);

    return Container(
      margin: EdgeInsets.only(bottom: screenSize.height * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blood Type',
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: screenSize.height * 0.01),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: context.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _bloodType,
                isExpanded: true,
                hint: Center(
                  child: Text(
                    'Select Blood Type',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: fontSize,
                    ),
                  ),
                ),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _isEditing ? AppConstants.primaryColor : Theme.of(context).disabledColor,
                    size: 20,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return _bloodTypes.map<Widget>((String type) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        type,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: fontSize,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: _bloodTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppConstants.primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.primaryColor.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              type,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          type,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: fontSize,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _isEditing
                  ? (newValue) {
                    setState(() {
                      _bloodType = newValue!;
                    });
                  }
                  : null,
                dropdownColor: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                elevation: 8,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to ensure phone values are synchronized
  void _syncPhoneValues() {
    // Only sync if not in the process of editing
    if (!_isEditing) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUser = appProvider.currentUser;
      
      // Priority order: _phoneController > _phoneNumber > provider
      if (_phoneController.text.isNotEmpty) {
        _phoneNumber = _phoneController.text;
        print('Syncing from controller: $_phoneNumber');
      } else if (_phoneNumber != null && _phoneNumber!.isNotEmpty) {
        _phoneController.text = _phoneNumber!;
        print('Syncing from _phoneNumber: $_phoneNumber');
      } else if (currentUser.phoneNumber.isNotEmpty) {
        _phoneNumber = currentUser.phoneNumber;
        _phoneController.text = currentUser.phoneNumber;
        print('Syncing from provider: $_phoneNumber');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPhoneValues();
  }
}
