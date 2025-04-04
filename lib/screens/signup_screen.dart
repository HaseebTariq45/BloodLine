import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../constants/app_constants.dart';
import '../constants/cities_data.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';
import '../utils/theme_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late String _bloodType = 'A+';
  late String _city = '';
  bool _isAvailableToDonate = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();
    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if city is selected
    if (_city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your city'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user with email and password
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // Create user profile in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'bloodType': _bloodType,
            'phoneNumber': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
            'city': _city,
            'isAvailableToDonate': _isAvailableToDonate,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        // Navigate to health questionnaire screen
        Navigator.pushReplacementNamed(
          context,
          '/health-questionnaire',
          arguments: {'isPostSignup': true},
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred during signup';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get app provider
    final appProvider = Provider.of<AppProvider>(context);
    final bool isAuthenticating = appProvider.isAuthenticating;

    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;

    // Calculate responsive sizes
    final double headerIconSize = isSmallScreen ? 32.0 : 40.0;
    final double headerFontSize = isSmallScreen ? 16.0 : 18.0;
    final double sectionTitleFontSize = isSmallScreen ? 16.0 : 18.0;
    final double subtitleFontSize = isSmallScreen ? 12.0 : 14.0;
    final double formFontSize = isSmallScreen ? 14.0 : 16.0;
    final double buttonFontSize = isSmallScreen ? 14.0 : 16.0;
    final double bloodTypeFontSize = isSmallScreen ? 16.0 : 18.0;
    final double bloodTypeCheckSize = isSmallScreen ? 14.0 : 16.0;
    final double buttonHeight = isSmallScreen ? 50.0 : 56.0;

    // Calculate padding based on screen size
    final double horizontalPadding = screenWidth * 0.05;
    final double verticalPadding = screenHeight * 0.015;
    final EdgeInsets standardPadding = EdgeInsets.all(horizontalPadding);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: context.textColor,
            size: isSmallScreen ? 22 : 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Account',
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        child: Builder(
                          builder:
                              (context) => Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: verticalPadding * 2,
                                  horizontal: horizontalPadding,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppConstants.primaryColor.withOpacity(
                                        0.15,
                                      ),
                                      AppConstants.primaryColor.withOpacity(
                                        0.05,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          context.isDarkMode
                                              ? Colors.black.withOpacity(0.15)
                                              : Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppConstants.primaryColor
                                                .withOpacity(0.2),
                                            AppConstants.primaryColor
                                                .withOpacity(0.1),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppConstants.primaryColor
                                                .withOpacity(0.1),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.person_add_rounded,
                                        size: headerIconSize,
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Join our BloodLine community',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: headerFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: context.textColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Help save lives by becoming a blood donor',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: subtitleFontSize,
                                        color: context.secondaryTextColor,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ),
                      ),
                      SizedBox(height: verticalPadding * 2),
                      // Personal Information Section
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: sectionTitleFontSize,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: verticalPadding),
                            // Name Field
                            Container(
                              margin: EdgeInsets.only(bottom: verticalPadding),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        context.isDarkMode
                                            ? Colors.black.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _nameController,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: formFontSize,
                                  letterSpacing: 0.2,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Full Name',
                                  hintStyle: TextStyle(
                                    color: context.secondaryTextColor,
                                    fontSize: formFontSize,
                                    letterSpacing: 0.2,
                                  ),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppConstants.primaryColor.withOpacity(
                                            0.2,
                                          ),
                                          AppConstants.primaryColor.withOpacity(
                                            0.1,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.person_outline,
                                      color: AppConstants.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: context.cardColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            // Email Field
                            Container(
                              margin: EdgeInsets.only(bottom: verticalPadding),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        context.isDarkMode
                                            ? Colors.black.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: formFontSize,
                                  letterSpacing: 0.2,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Email Address',
                                  hintStyle: TextStyle(
                                    color: context.secondaryTextColor,
                                    fontSize: formFontSize,
                                    letterSpacing: 0.2,
                                  ),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppConstants.primaryColor.withOpacity(
                                            0.2,
                                          ),
                                          AppConstants.primaryColor.withOpacity(
                                            0.1,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.email_outlined,
                                      color: AppConstants.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: context.cardColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            // Phone Field
                            Container(
                              margin: EdgeInsets.only(bottom: verticalPadding),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        context.isDarkMode
                                            ? Colors.black.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: formFontSize,
                                  letterSpacing: 0.2,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Phone Number',
                                  hintStyle: TextStyle(
                                    color: context.secondaryTextColor,
                                    fontSize: formFontSize,
                                    letterSpacing: 0.2,
                                  ),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppConstants.primaryColor.withOpacity(
                                            0.2,
                                          ),
                                          AppConstants.primaryColor.withOpacity(
                                            0.1,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.phone_outlined,
                                      color: AppConstants.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: context.cardColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            // Address Field
                            Container(
                              margin: EdgeInsets.only(bottom: verticalPadding),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        context.isDarkMode
                                            ? Colors.black.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _addressController,
                                maxLines: 2,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: formFontSize,
                                  letterSpacing: 0.2,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Address',
                                  hintStyle: TextStyle(
                                    color: context.secondaryTextColor,
                                    fontSize: formFontSize,
                                    letterSpacing: 0.2,
                                  ),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppConstants.primaryColor.withOpacity(
                                            0.2,
                                          ),
                                          AppConstants.primaryColor.withOpacity(
                                            0.1,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.location_on_outlined,
                                      color: AppConstants.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: context.cardColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your address';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            // City Dropdown
                            Container(
                              margin: EdgeInsets.only(bottom: verticalPadding),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        context.isDarkMode
                                            ? Colors.black.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color:
                                      context.isDarkMode
                                          ? Colors.grey[800]!
                                          : Colors.grey[200]!,
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
                                        color: context.secondaryTextColor,
                                        fontSize: formFontSize,
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
                                      color: AppConstants.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: formFontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
                                  selectedItemBuilder: (BuildContext context) {
                                    return [null, ...CityManager().cities].map<Widget>((item) {
                                      if (item == null) {
                                        return const SizedBox.shrink(); // This will never be used because of our value handling
                                      }
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 16.0),
                                          child: Text(
                                            item.toString(),
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: formFontSize,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList();
                                  },
                                  items:
                                      (CityManager().cities.toList())
                                          .map<DropdownMenuItem<String>>((String city) {
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
                                                    color: context.textColor,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _city = newValue ?? '';
                                    });
                                  },
                                  dropdownColor: context.cardColor,
                                  borderRadius: BorderRadius.circular(15),
                                  elevation: 8,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: verticalPadding * 2),
                      // Blood Type Section
                      FadeInUp(
                        duration: const Duration(milliseconds: 700),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bloodtype_outlined,
                                  color: AppConstants.primaryColor,
                                  size: sectionTitleFontSize + 4,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Blood Type',
                                  style: TextStyle(
                                    fontSize: sectionTitleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: context.textColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: verticalPadding),
                            Container(
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        context.isDarkMode
                                            ? Colors.black.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      childAspectRatio: 1.0,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                itemCount: _bloodTypes.length,
                                itemBuilder: (context, index) {
                                  final bloodType = _bloodTypes[index];
                                  final isSelected = bloodType == _bloodType;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _bloodType = bloodType;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? AppConstants.primaryColor
                                                : context.isDarkMode
                                                ? Colors.grey[800]
                                                : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? AppConstants.primaryColor
                                                  : Colors.grey.withOpacity(
                                                    0.3,
                                                  ),
                                          width: 1.5,
                                        ),
                                        boxShadow:
                                            isSelected
                                                ? [
                                                  BoxShadow(
                                                    color: AppConstants
                                                        .primaryColor
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                                : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.water_drop,
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : AppConstants.primaryColor,
                                            size: 16,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            bloodType,
                                            style: TextStyle(
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : context.textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: bloodTypeFontSize - 2,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(height: 4),
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: verticalPadding),
                      // Donation Availability Section
                      FadeInUp(
                        duration: const Duration(milliseconds: 750),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding * 0.8,
                            vertical: verticalPadding,
                          ),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    context.isDarkMode
                                        ? Colors.black.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.volunteer_activism,
                                color: AppConstants.primaryColor,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Available to donate blood',
                                        style: TextStyle(
                                          fontSize: formFontSize,
                                          fontWeight: FontWeight.w500,
                                          color: context.textColor,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Tooltip(
                                      message:
                                          'Indicate if you are willing and eligible to donate blood. This will make you visible to those in need of your blood type.',
                                      triggerMode: TooltipTriggerMode.tap,
                                      showDuration: const Duration(seconds: 3),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryColor
                                            .withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                      child: Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isAvailableToDonate,
                                onChanged: (value) {
                                  setState(() {
                                    _isAvailableToDonate = value;
                                  });
                                },
                                activeColor: AppConstants.primaryColor,
                                activeTrackColor: AppConstants.primaryColor
                                    .withOpacity(0.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: verticalPadding * 2),
                      // Password Section
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Security',
                              style: TextStyle(
                                fontSize: sectionTitleFontSize,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: verticalPadding),
                            // Password Field
                            Container(
                              margin: EdgeInsets.only(bottom: verticalPadding),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        context.isDarkMode
                                            ? Colors.black.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: formFontSize,
                                  letterSpacing: 0.2,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: TextStyle(
                                    color: context.secondaryTextColor,
                                    fontSize: formFontSize,
                                    letterSpacing: 0.2,
                                  ),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppConstants.primaryColor.withOpacity(
                                            0.2,
                                          ),
                                          AppConstants.primaryColor.withOpacity(
                                            0.1,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.lock_outline,
                                      color: AppConstants.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: context.secondaryTextColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: context.cardColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            // Confirm Password Field
                            Container(
                              margin: EdgeInsets.only(bottom: verticalPadding),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        context.isDarkMode
                                            ? Colors.black.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: formFontSize,
                                  letterSpacing: 0.2,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Confirm Password',
                                  hintStyle: TextStyle(
                                    color: context.secondaryTextColor,
                                    fontSize: formFontSize,
                                    letterSpacing: 0.2,
                                  ),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppConstants.primaryColor.withOpacity(
                                            0.2,
                                          ),
                                          AppConstants.primaryColor.withOpacity(
                                            0.1,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.lock_outline,
                                      color: AppConstants.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: context.secondaryTextColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: context.cardColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: verticalPadding * 2),
                      // Sign Up Button
                      FadeInUp(
                        duration: const Duration(milliseconds: 900),
                        child: Container(
                          width: double.infinity,
                          height: buttonHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppConstants.primaryColor,
                                AppConstants.primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.primaryColor.withOpacity(
                                  0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                      SizedBox(height: verticalPadding),
                      // Login Link
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: context.secondaryTextColor,
                                fontSize: subtitleFontSize,
                                letterSpacing: 0.2,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
