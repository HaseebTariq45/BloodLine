import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/home_menu_card.dart';
import '../widgets/blood_type_badge.dart';
import '../utils/theme_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    
    // Sync donation availability on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.syncDonationAvailability();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentUser = appProvider.currentUser;

    // Debug logging for user data
    debugPrint('Home Screen - Current User: ${currentUser.toString()}');

    // Check if this is a dummy user
    final bool isDummyUser = currentUser.id == 'user123';
    if (isDummyUser) {
      debugPrint(
        'WARNING: Home screen showing DUMMY USER - not logged in properly!',
      );
    }

    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;

    // Calculate responsive sizes
    final double titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final double headerFontSize = isSmallScreen ? 20.0 : 24.0;
    final double sectionTitleFontSize = isSmallScreen ? 18.0 : 20.0;
    final double bodyTextFontSize = isSmallScreen ? 12.0 : 14.0;
    final double iconSize = isSmallScreen ? 20.0 : 24.0;
    final double smallIconSize = isSmallScreen ? 12.0 : 14.0;
    final double badgeSize = isSmallScreen ? 40.0 : 45.0;

    // Calculate padding based on screen size
    final double horizontalPadding = screenWidth * 0.05;
    final double verticalPadding = screenHeight * 0.02;
    final EdgeInsets standardPadding = EdgeInsets.all(horizontalPadding);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: iconSize * 0.8,
                ),
              ),
              SizedBox(width: horizontalPadding * 0.4),
              Text(
                'BloodLine',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          // Notifications Icon
          Container(
            margin: EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.notifications, size: isSmallScreen ? 22 : 24, color: Colors.white),
                  if (appProvider.hasUnreadNotifications)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: BoxConstraints(
                          minWidth: isSmallScreen ? 10 : 12,
                          minHeight: isSmallScreen ? 10 : 12,
                        ),
                        child: const Text(
                          '',
                          style: TextStyle(color: Colors.white, fontSize: 8),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
          ),
          // Profile Picture
          Padding(
            padding: EdgeInsets.only(right: horizontalPadding),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: Hero(
                tag: 'profile',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: isSmallScreen ? 16 : 18,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        currentUser.imageUrl.isNotEmpty &&
                                !appProvider.profileImageLoadError
                            ? NetworkImage(currentUser.imageUrl, scale: 1.0)
                            : null,
                    onBackgroundImageError:
                        currentUser.imageUrl.isNotEmpty &&
                                !appProvider.profileImageLoadError
                            ? (exception, stackTrace) {
                              debugPrint(
                                'Failed to load profile image: $exception',
                              );
                              appProvider.setProfileImageLoadError(true);
                            }
                            : null,
                    child:
                        currentUser.imageUrl.isEmpty ||
                                appProvider.profileImageLoadError
                            ? Icon(
                              Icons.person,
                              color: AppConstants.primaryColor,
                              size: isSmallScreen ? 14 : 16,
                            )
                            : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: standardPadding,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppConstants.primaryColor,
                          AppConstants.primaryColor.withOpacity(0.85),
                          AppConstants.primaryColor.withOpacity(0.75),
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello,',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: bodyTextFontSize + 2,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    '${currentUser.name.split(' ')[0]}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: headerFontSize,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                      shadows: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            BloodTypeBadge(
                              bloodType: currentUser.bloodType,
                              size: badgeSize * 1.15,
                              onTap:
                                  () => _showBloodTypeInfo(
                                    context,
                                    currentUser.bloodType,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalPadding * 0.8),
                        // Eligibility Status
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: verticalPadding * 0.4,
                            horizontal: horizontalPadding * 0.8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                currentUser.isEligibleToDonate
                                    ? AppConstants.successColor
                                    : Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (currentUser.isEligibleToDonate
                                    ? AppConstants.successColor
                                    : Colors.orange).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                currentUser.isEligibleToDonate
                                    ? Icons.check_circle
                                    : currentUser.isAvailableBasedOnDonationDate
                                        ? Icons.warning_amber_rounded
                                        : Icons.access_time,
                                color: Colors.white,
                                size: smallIconSize,
                              ),
                              SizedBox(width: horizontalPadding * 0.4),
                              Text(
                                currentUser.isEligibleToDonate
                                    ? 'Eligible to Donate'
                                    : currentUser.isAvailableBasedOnDonationDate
                                        ? 'Set as Available'
                                        : 'Wait For ${currentUser.daysUntilNextDonation} Days To Donate',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: bodyTextFontSize,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Main Menu Grid
                  Padding(
                    padding: standardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppConstants.primaryColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppConstants.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.grid_view_rounded,
                                      color: AppConstants.primaryColor,
                                      size: isSmallScreen ? 18 : 20,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Services',
                                    style: TextStyle(
                                      fontSize: sectionTitleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              // Optional: Add a subtle info icon to guide users
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.info_outline,
                                    color: Colors.grey[600],
                                    size: isSmallScreen ? 16 : 18,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.info, color: Colors.white),
                                            SizedBox(width: 10),
                                            Flexible(
                                              child: Text(
                                                'Tap on any card to access the service',
                                              ),
                                            ),
                                          ],
                                        ),
                                        duration: Duration(seconds: 3),
                                        backgroundColor: AppConstants.primaryColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: verticalPadding * 1.2),
                        // First row of cards (2 cards)
                        Row(
                          children: [
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Find Blood Donors',
                                icon: Icons.person_search,
                                onTap: () {
                                  Navigator.pushNamed(context, '/donor_search');
                                },
                                index: 0,
                              ),
                            ),
                            SizedBox(width: horizontalPadding),
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Request Blood',
                                icon: Icons.bloodtype,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/blood_request',
                                  );
                                },
                                index: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalPadding),

                        // Second row of cards (2 cards)
                        Row(
                          children: [
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Blood Requests',
                                icon: Icons.format_list_bulleted,
                                onTap: () {
                                  Navigator.pushNamed(context, '/blood_requests_list');
                                },
                                index: 2,
                              ),
                            ),
                            SizedBox(width: horizontalPadding),
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Donation Tracking',
                                icon: Icons.volunteer_activism,
                                onTap: () {
                                  Navigator.pushNamed(context, '/donation_tracking');
                                },
                                index: 3,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalPadding),

                        // Third row (2 cards)
                        Row(
                          children: [
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Donation History',
                                icon: Icons.history,
                                onTap: () {
                                  Navigator.pushNamed(context, '/donation_history');
                                },
                                index: 4,
                              ),
                            ),
                            SizedBox(width: horizontalPadding),
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Health Tips',
                                icon: Icons.health_and_safety,
                                onTap: () {
                                  Navigator.pushNamed(context, '/health_tips');
                                },
                                index: 5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalPadding),

                        // Fourth row (2 cards)
                        Row(
                          children: [
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Emergency Contacts',
                                icon: Icons.emergency,
                                onTap: () {
                                  Navigator.pushNamed(context, '/emergency_contacts');
                                },
                                index: 6,
                              ),
                            ),
                            SizedBox(width: horizontalPadding),
                            Expanded(
                              child: HomeMenuCard(
                                title: 'Nearby Blood Banks',
                                icon: Icons.location_on,
                                onTap: () {
                                  Navigator.pushNamed(context, '/blood_banks');
                                },
                                index: 7,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime requestDate) {
    final now = DateTime.now();
    final difference = now.difference(requestDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Blood type compatibility helper methods
  Widget _buildBloodTypeInfoRow(String label, List<String> types) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: types.map((type) => _buildBloodTypeChip(type)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBloodTypeChip(String bloodType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.5)),
      ),
      child: Text(
        bloodType,
        style: TextStyle(
          color: AppConstants.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<String> _getCompatibleRecipients(String bloodType) {
    // Who can receive from this blood type
    switch (bloodType) {
      case 'O-':
        return ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'];
      case 'O+':
        return ['O+', 'A+', 'B+', 'AB+'];
      case 'A-':
        return ['A-', 'A+', 'AB-', 'AB+'];
      case 'A+':
        return ['A+', 'AB+'];
      case 'B-':
        return ['B-', 'B+', 'AB-', 'AB+'];
      case 'B+':
        return ['B+', 'AB+'];
      case 'AB-':
        return ['AB-', 'AB+'];
      case 'AB+':
        return ['AB+'];
      default:
        return [];
    }
  }

  List<String> _getCompatibleDonors(String bloodType) {
    // Who can donate to this blood type
    switch (bloodType) {
      case 'O-':
        return ['O-'];
      case 'O+':
        return ['O-', 'O+'];
      case 'A-':
        return ['O-', 'A-'];
      case 'A+':
        return ['O-', 'O+', 'A-', 'A+'];
      case 'B-':
        return ['O-', 'B-'];
      case 'B+':
        return ['O-', 'O+', 'B-', 'B+'];
      case 'AB-':
        return ['O-', 'A-', 'B-', 'AB-'];
      case 'AB+':
        return ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'];
      default:
        return [];
    }
  }

  String _getBloodTypeDescription(String bloodType) {
    switch (bloodType) {
      case 'O-':
        return 'You are a universal donor! Your blood can be given to anyone, making you extremely valuable in emergency situations. However, you can only receive O- blood.';
      case 'O+':
        return 'As the most common blood type, your donations are always in high demand. You can donate to all positive blood types but can only receive O+ and O- blood.';
      case 'A-':
        return 'Your blood is relatively rare and can be donated to both A and AB blood types. You can receive from A- and O- donors only.';
      case 'A+':
        return 'With the second most common blood type, your donations are always needed. You can donate to A+ and AB+ recipients and can receive from A+, A-, O+, and O- donors.';
      case 'B-':
        return 'Your blood type is uncommon and can be donated to both B and AB blood types. You can receive from B- and O- donors only.';
      case 'B+':
        return 'Your blood type is less common and can be donated to B+ and AB+ recipients. You can receive from B+, B-, O+, and O- donors.';
      case 'AB-':
        return 'You have a rare blood type and can donate to AB- and AB+ recipients. You are a universal recipient for negative blood types.';
      case 'AB+':
        return 'As a universal recipient, you can receive blood from anyone! However, you can only donate to other AB+ individuals.';
      default:
        return 'Information not available for this blood type.';
    }
  }

  void _showBloodTypeInfo(BuildContext context, String bloodType) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final bool isSmallScreen = screenWidth < 360;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 8,
            backgroundColor: Theme.of(context).cardColor,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              width: screenWidth * 0.92,
              constraints: BoxConstraints(
                maxWidth: 400,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with blood type
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bloodtype,
                              color: Colors.white,
                              size: isSmallScreen ? 32 : 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bloodType,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 38 : 46,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Blood Type',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Compatibility sections
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Can donate to section
                            _buildCompatibilitySection(
                              context,
                              title: 'You can donate to:',
                              icon: Icons.arrow_upward_rounded,
                              types: _getCompatibleRecipients(bloodType),
                              isTopSection: true,
                            ),

                            Divider(
                              height: 1,
                              thickness: 1,
                              color: Colors.grey.withOpacity(0.2),
                            ),

                            // Can receive from section
                            _buildCompatibilitySection(
                              context,
                              title: 'You can receive from:',
                              icon: Icons.arrow_downward_rounded,
                              types: _getCompatibleDonors(bloodType),
                              isTopSection: false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppConstants.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppConstants.primaryColor,
                                  size: isSmallScreen ? 18 : 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Did you know?',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getBloodTypeDescription(bloodType),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 14,
                                height: 1.4,
                                color:
                                    Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Close button
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildCompatibilityBloodTypeChip(String bloodType, {Color? color}) {
    final Color chipColor = color ?? AppConstants.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            chipColor.withOpacity(0.3),
            chipColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: chipColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: chipColor.withOpacity(0.1),
            blurRadius: 3,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        bloodType,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCompatibilitySection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> types,
    required bool isTopSection,
  }) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 360;
    final Color sectionColor = isTopSection ? AppConstants.successColor : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            sectionColor.withOpacity(0.08),
            sectionColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isTopSection ? 16 : 0),
          bottom: Radius.circular(!isTopSection ? 16 : 0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sectionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: sectionColor,
                  size: isSmallScreen ? 18 : 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: sectionColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                types
                    .map(
                      (type) => _buildCompatibilityBloodTypeChip(
                        type,
                        color: sectionColor,
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}
