import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' as io;
import 'dart:math';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/localization/app_localization.dart';
import '../utils/theme_helper.dart';
import '../utils/location_service.dart';
import '../utils/notification_service.dart';
import '../services/version_service.dart';
import '../services/service_locator.dart';
import '../widgets/all_files_access_setting.dart';
import 'data_usage_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_updater.dart';

// Helper for safe platform detection
bool get isAndroid {
  try {
    return io.Platform.isAndroid;
  } catch (e) {
    debugPrint('Platform detection error in settings_screen: $e');
    return false;
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = false;
  bool _locationEnabled = false;
  bool _emailNotifications = false;
  final bool _smsNotifications = false;
  bool _pushNotifications = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'Arabic',
    'Urdu',
  ];

  @override
  void initState() {
    super.initState();
    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Load settings from provider
    _loadSettings();
    
    // Check for updates when the settings screen is opened - with delay for safety
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        try {
          Provider.of<AppProvider>(context, listen: false).checkForUpdates();
        } catch (e) {
          debugPrint('Error checking for updates: $e');
          // Prevent app from crashing if update check fails
        }
      }
    });
  }

  void _loadSettings() {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      setState(() {
        _locationEnabled = appProvider.isLocationEnabled;
        _notificationsEnabled = appProvider.notificationsEnabled;
        _emailNotifications = appProvider.emailNotificationsEnabled;
        _pushNotifications = appProvider.pushNotificationsEnabled;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      // Set default values if loading fails
      setState(() {
        _locationEnabled = false;
        _notificationsEnabled = false;
        _emailNotifications = false;
        _pushNotifications = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    // Use service locator instead of Provider for VersionService
    final versionSvc = serviceLocator.versionService;

    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;

    // Calculate responsive sizes
    final double titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final double itemTitleFontSize = isSmallScreen ? 14.0 : 16.0;
    final double subtitleFontSize = isSmallScreen ? 11.0 : 12.0;
    final double versionFontSize = isSmallScreen ? 10.0 : 12.0;

    // Calculate icon sizes
    final double iconSize = isSmallScreen ? 18.0 : 20.0;
    final double iconContainerSize = isSmallScreen ? 36.0 : 40.0;

    // Calculate padding based on screen size
    final double mainPadding = screenWidth * 0.04;
    final double cardPadding = isSmallScreen ? 12.0 : 16.0;
    final double itemPadding = isSmallScreen ? 6.0 : 8.0;
    final double itemSpacing = isSmallScreen ? 12.0 : 16.0;
    final double sectionSpacing = isSmallScreen ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(title: 'settings'.tr(context), showBackButton: true),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).brightness == Brightness.dark
                      ? AppConstants.primaryColor.withOpacity(0.05)
                      : AppConstants.primaryColor.withOpacity(0.03),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: mainPadding,
                    vertical: mainPadding * 1.5,
                  ),
                  children: [
                    // Profile summary at the top
                    _buildProfileSummary(context),

                    SizedBox(height: sectionSpacing * 1.2),

                    // App Settings Card
                    _buildAnimatedSettingsCard(
                      title: 'app_settings'.tr(context),
                      titleFontSize: titleFontSize,
                      cardPadding: cardPadding,
                      icon: Icons.settings,
                      children: [
                        // Dark Mode
                        _buildSettingItem(
                          title: 'Theme Mode',
                          subtitle: 'Choose between light, dark, or system theme',
                          icon: Icons.dark_mode,
                          titleFontSize: itemTitleFontSize,
                          subtitleFontSize: subtitleFontSize,
                          iconSize: iconSize,
                          iconContainerSize: iconContainerSize,
                          itemPadding: itemPadding,
                          itemSpacing: itemSpacing,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                appProvider.themeModePreference,
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: appProvider.themeMode == ThemeMode.light
                                    ? const Icon(Icons.wb_sunny)
                                    : appProvider.themeMode == ThemeMode.dark
                                        ? const Icon(Icons.nightlight_round)
                                        : const Icon(Icons.brightness_auto),
                                onPressed: () {
                                  setState(() {
                                    appProvider.toggleThemeMode();
                                  });
                                  // Show a feedback toast
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Theme set to ${appProvider.themeModePreference}'),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                                color: AppConstants.primaryColor,
                                tooltip: 'Change theme mode',
                              ),
                            ],
                          ),
                        ),
                        const Divider(),

                        // Language Selector
                        _buildSettingItem(
                          title: 'language'.tr(context),
                          subtitle: 'Select your preferred language'.tr(
                            context,
                          ),
                          icon: Icons.language,
                          titleFontSize: itemTitleFontSize,
                          subtitleFontSize: subtitleFontSize,
                          iconSize: iconSize,
                          iconContainerSize: iconContainerSize,
                          itemPadding: itemPadding,
                          itemSpacing: itemSpacing,
                          trailing: Builder(
                            builder:
                                (context) => GestureDetector(
                                  onTap: () {
                                    _showLanguageBottomSheet(
                                      context,
                                      appProvider,
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 10 : 14,
                                      vertical: isSmallScreen ? 8 : 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppConstants.primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppConstants.primaryColor
                                            .withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppConstants.primaryColor
                                              .withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _getLangEmoji(
                                          appProvider.selectedLanguage,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          appProvider.selectedLanguage,
                                          style: TextStyle(
                                            color: AppConstants.primaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: isSmallScreen ? 13 : 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: AppConstants.primaryColor,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: sectionSpacing),

                    // Notification Settings Card
                    _buildAnimatedSettingsCard(
                      title: 'notifications_settings'.tr(context),
                      titleFontSize: titleFontSize,
                      cardPadding: cardPadding,
                      icon: Icons.notifications_active,
                      children: [
                        _buildSettingItem(
                          title: 'Notification Preferences'.tr(context),
                          subtitle: 'Manage your notification preferences',
                          icon: Icons.notifications,
                          titleFontSize: itemTitleFontSize,
                          subtitleFontSize: subtitleFontSize,
                          iconSize: iconSize,
                          iconContainerSize: iconContainerSize,
                          itemPadding: itemPadding,
                          itemSpacing: itemSpacing,
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: isSmallScreen ? 16.0 : 18.0,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white60
                                    : Colors.black54,
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/notification_settings',
                            );
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: sectionSpacing),

                    // Privacy Settings Card
                    _buildAnimatedSettingsCard(
                      title: 'privacy_permission'.tr(context),
                      titleFontSize: titleFontSize,
                      cardPadding: cardPadding,
                      icon: Icons.security,
                      children: [
                        _buildSettingItem(
                          title: 'location_services'.tr(context),
                          subtitle:
                              'Allow app to access your location for nearby blood banks'
                                  .tr(context),
                          icon: Icons.location_on,
                          titleFontSize: itemTitleFontSize,
                          subtitleFontSize: subtitleFontSize,
                          iconSize: iconSize,
                          iconContainerSize: iconContainerSize,
                          itemPadding: itemPadding,
                          itemSpacing: itemSpacing,
                          trailing: Switch(
                            value: _locationEnabled,
                            onChanged: (value) async {
                              final appProvider = Provider.of<AppProvider>(
                                context,
                                listen: false,
                              );

                              if (value) {
                                // Try to enable location
                                final success =
                                    await appProvider.enableLocation();
                                if (!success) {
                                  _showLocationPermissionDialog();
                                }
                              } else {
                                // Disable location
                                await appProvider.disableLocation();
                              }

                              setState(() {
                                _locationEnabled =
                                    appProvider.isLocationEnabled;
                              });
                            },
                            activeColor: AppConstants.primaryColor,
                          ),
                        ),
                        const Divider(),
                        // All Files Access Setting
                        if (isAndroid) 
                          Column(
                            children: [
                              const AllFilesAccessSetting(),
                              const Divider(),
                            ],
                          ),
                        _buildSettingItem(
                          title: 'data_usage'.tr(context),
                          subtitle: 'Control how the app uses your data'.tr(
                            context,
                          ),
                          icon: Icons.data_usage,
                          titleFontSize: itemTitleFontSize,
                          subtitleFontSize: subtitleFontSize,
                          iconSize: iconSize,
                          iconContainerSize: iconContainerSize,
                          itemPadding: itemPadding,
                          itemSpacing: itemSpacing,
                          onTap: () {
                            // Navigate to data usage settings
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DataUsageScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: sectionSpacing),

                    // About & Legal Card
                    _buildAnimatedSettingsCard(
                      title: 'about_legal'.tr(context),
                      titleFontSize: titleFontSize,
                      cardPadding: cardPadding,
                      icon: Icons.info_outline,
                      children: [
                        _buildSettingItem(
                          title: 'privacy_policy'.tr(context),
                          icon: Icons.privacy_tip,
                          titleFontSize: itemTitleFontSize,
                          iconSize: iconSize,
                          iconContainerSize: iconContainerSize,
                          itemPadding: itemPadding,
                          itemSpacing: itemSpacing,
                          onTap: () {
                            // Navigate to privacy policy
                            Navigator.pushNamed(context, '/privacy_policy');
                          },
                        ),
                        const Divider(),
                        _buildSettingItem(
                          title: 'terms_of_service'.tr(context),
                          icon: Icons.description,
                          titleFontSize: itemTitleFontSize,
                          iconSize: iconSize,
                          iconContainerSize: iconContainerSize,
                          itemPadding: itemPadding,
                          itemSpacing: itemSpacing,
                          onTap: () {
                            // Navigate to terms of service
                            Navigator.pushNamed(context, '/terms_conditions');
                          },
                        ),
                        const Divider(),
                        _buildSettingItem(
                          title: 'about_us'.tr(context),
                          icon: Icons.info,
                          titleFontSize: itemTitleFontSize,
                          iconSize: iconSize,
                          iconContainerSize: iconContainerSize,
                          itemPadding: itemPadding,
                          itemSpacing: itemSpacing,
                          onTap: () {
                            // Navigate to about us
                            Navigator.pushNamed(context, '/about_us');
                          },
                        ),
                        const Divider(),
                        _buildSettingItem(
                          title: 'contact_support'.tr(context),
                          icon: Icons.support_agent,
                          titleFontSize: itemTitleFontSize,
                          iconSize: iconSize,
                          iconContainerSize: iconContainerSize,
                          itemPadding: itemPadding,
                          itemSpacing: itemSpacing,
                          onTap: () {
                            // Navigate to support
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: sectionSpacing),

                    // Account Settings Card
                    _buildAnimatedSettingsCard(
                      title: 'account'.tr(context),
                      titleFontSize: titleFontSize,
                      cardPadding: cardPadding,
                      icon: Icons.account_circle,
                      children: [
                        _buildSettingItem(
                          title: 'change_password'.tr(context),
                          icon: Icons.lock,
                          titleFontSize: itemTitleFontSize,
                          iconSize: iconSize,
                          iconContainerSize: iconContainerSize,
                          itemPadding: itemPadding,
                          itemSpacing: itemSpacing,
                          onTap: () {
                            // Navigate to change password
                            _showChangePasswordDialog(
                              titleFontSize: titleFontSize,
                              bodyFontSize: subtitleFontSize + 2,
                            );
                          },
                        ),
                        const Divider(),
                        _buildSettingItem(
                          title: 'logout'.tr(context),
                          icon: Icons.logout,
                          titleFontSize: itemTitleFontSize,
                          iconSize: iconSize,
                          iconContainerSize: iconContainerSize,
                          itemPadding: itemPadding,
                          itemSpacing: itemSpacing,
                          onTap: () {
                            _showLogoutDialog(
                              titleFontSize: titleFontSize,
                              bodyFontSize: subtitleFontSize + 2,
                            );
                          },
                        ),
                        const Divider(),
                        _buildSettingItem(
                          title: 'delete_account'.tr(context),
                          icon: Icons.delete_forever,
                          iconColor: AppConstants.errorColor,
                          titleColor: AppConstants.errorColor,
                          titleFontSize: itemTitleFontSize,
                          iconSize: iconSize,
                          iconContainerSize: iconContainerSize,
                          itemPadding: itemPadding,
                          itemSpacing: itemSpacing,
                          onTap: () {
                            // Show delete account confirmation dialog
                            _showDeleteAccountDialog(
                              titleFontSize: titleFontSize,
                              bodyFontSize: subtitleFontSize + 2,
                            );
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: sectionSpacing),
                    
                    // Updates Card
                    _buildAnimatedSettingsCard(
                      title: 'Updates',
                      titleFontSize: titleFontSize,
                      cardPadding: cardPadding,
                      icon: Icons.system_update,
                      children: [
                        _buildUpdateSection(
                          itemTitleFontSize: itemTitleFontSize,
                          subtitleFontSize: subtitleFontSize,
                          iconSize: iconSize,
                          iconContainerSize: iconContainerSize,
                          itemPadding: itemPadding,
                          itemSpacing: itemSpacing,
                        ),
                      ],
                    ),

                    SizedBox(height: sectionSpacing * 1.5),

                    // App version
                    Center(
                      child: Builder(
                        builder:
                            (context) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    context.isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[100],
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color:
                                        context.isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '${'app_version'.tr(context)} ${versionSvc.appVersion}',
                                    style: TextStyle(
                                      color:
                                          context.isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                      fontSize: versionFontSize,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSummary(BuildContext context) {
    return Builder(
      builder: (context) {
        final appProvider = Provider.of<AppProvider>(context);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).brightness == Brightness.dark
                    ? AppConstants.primaryColor.withOpacity(0.12)
                    : AppConstants.primaryColor.withOpacity(0.05),
                Theme.of(context).cardColor,
              ],
            ),
          ),
          child: Row(
            children: [
              // Profile image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    color: AppConstants.primaryColor,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appProvider.currentUser.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appProvider.currentUser.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Profile button
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit,
                        color: AppConstants.primaryColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSettingsCard({
    required String title,
    required List<Widget> children,
    required double titleFontSize,
    required double cardPadding,
    required IconData icon,
  }) {
    return Builder(
      builder: (context) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    context.isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header with title and icon
              Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: AppConstants.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.dividerColor),
              Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(children: children),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required IconData icon,
    Color iconColor = AppConstants.primaryColor,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
    required double titleFontSize,
    double subtitleFontSize = 12.0,
    required double iconSize,
    double iconContainerSize = 40.0,
    required double itemPadding,
    required double itemSpacing,
  }) {
    return Builder(
      builder: (context) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: itemPadding),
            child: Row(
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  padding: EdgeInsets.all(iconContainerSize * 0.25),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: iconSize),
                ),
                SizedBox(width: itemSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w500,
                          color: titleColor ?? context.textColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: itemPadding * 0.5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
                if (onTap != null && trailing == null)
                  Icon(
                    Icons.chevron_right,
                    color: context.isDarkMode ? Colors.grey[400] : Colors.grey,
                    size: iconSize,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndentedSettingItem({
    required String title,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    required double titleFontSize,
    required double iconSize,
    required double itemPadding,
    required double itemSpacing,
    required double leftPadding,
  }) {
    return Builder(
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(left: leftPadding),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: itemPadding),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: AppConstants.primaryColor,
                      size: iconSize,
                    ),
                    SizedBox(width: itemSpacing),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: context.textColor,
                          fontSize: titleFontSize,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing,
                    if (onTap != null && trailing == null)
                      Icon(
                        Icons.chevron_right,
                        color:
                            context.isDarkMode ? Colors.grey[400] : Colors.grey,
                        size: iconSize,
                      ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _showLogoutDialog({
    required double titleFontSize,
    required double bodyFontSize,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(), // Not used
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Theme.of(context).cardColor,
              elevation: 6,
              title: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'logout'.tr(context),
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 12.0,
                ),
                child: Text(
                  'Are you sure you want to logout?'.tr(context),
                  style: TextStyle(fontSize: bodyFontSize),
                  textAlign: TextAlign.center,
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('cancel'.tr(context)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () async {
                        // Show a loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const CircularProgressIndicator(),
                              ),
                            );
                          },
                        );

                        try {
                          // Logout user and navigate to login screen
                          final appProvider = Provider.of<AppProvider>(
                            context,
                            listen: false,
                          );
                          await appProvider.logout();

                          // Close both dialogs
                          Navigator.of(context).pop(); // Close loading dialog
                          Navigator.of(context).pop(); // Close logout dialog

                          // Navigate to login screen
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        } catch (e) {
                          // Close loading dialog
                          Navigator.of(context).pop();

                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to logout: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text('logout'.tr(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog({
    required double titleFontSize,
    required double bodyFontSize,
  }) {
    final passwordController = TextEditingController();
    bool isLoading = false;
    String errorMessage = '';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(), // Not used
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Theme.of(context).cardColor,
                  elevation: 6,
                  title: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConstants.errorColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: AppConstants.errorColor,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'delete_account'.tr(context),
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.errorColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppConstants.errorColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppConstants.errorColor.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppConstants.errorColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This action cannot be undone. All your data will be permanently deleted.'
                                      .tr(context),
                                  style: TextStyle(
                                    fontSize: bodyFontSize,
                                    color: AppConstants.errorColor.withOpacity(
                                      0.8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Please enter your password to confirm:',
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (errorMessage.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        TextField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppConstants.errorColor,
                                width: 2,
                              ),
                            ),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  actions: <Widget>[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).textTheme.bodyMedium?.color,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('cancel'.tr(context)),
                    ),
                    if (isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppConstants.errorColor,
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.errorColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        label: Text('delete'.tr(context)),
                        onPressed: () async {
                          if (passwordController.text.isEmpty) {
                            setState(() {
                              errorMessage = 'Password is required';
                            });
                            return;
                          }

                          setState(() {
                            isLoading = true;
                            errorMessage = '';
                          });

                          try {
                            // Delete account and navigate to login screen
                            final appProvider = Provider.of<AppProvider>(
                              context,
                              listen: false,
                            );
                            final success = await appProvider.deleteAccount(
                              passwordController.text,
                            );

                            if (success) {
                              // Close dialog and navigate to login
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );

                              // Show a success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Your account has been deleted',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              setState(() {
                                isLoading = false;
                                errorMessage = appProvider.authError;
                              });
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              errorMessage = 'An error occurred: $e';
                            });
                          }
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'This feature requires location permission to find blood banks near you. '
              'Please enable location permission in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  LocationService().openApplicationSettings();
                },
                child: const Text('OPEN SETTINGS'),
              ),
            ],
          ),
    );
  }

  void _sendTestNotifications() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final notificationService = NotificationService();

    // Display a snackbar to inform the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending test notifications...'),
        duration: Duration(seconds: 2),
      ),
    );

    // Check which notification types are enabled and send appropriate tests
    if (appProvider.emailNotificationsEnabled) {
      await notificationService.sendEmailNotification(
        appProvider.currentUser.email,
        'Test Notification',
        'This is a test email notification from the BloodLine app.',
      );
    }

    if (appProvider.pushNotificationsEnabled) {
      await notificationService.sendPushNotification(
        appProvider.currentUser.id,
        'Test Notification',
        'This is a test push notification from the BloodLine app.',
      );
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test notifications sent successfully!'),
        backgroundColor: AppConstants.successColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showChangePasswordDialog({
    required double titleFontSize,
    required double bodyFontSize,
  }) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    String errorMessage = '';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(), // Not used
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return StatefulBuilder(
          builder: (context, setState) {
            return ScaleTransition(
              scale: curvedAnimation,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Theme.of(context).cardColor,
                elevation: 6,
                title: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: AppConstants.primaryColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (errorMessage.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      TextField(
                        controller: currentPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: const Icon(Icons.vpn_key, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppConstants.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: newPasswordController,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppConstants.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppConstants.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                actions: <Widget>[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).textTheme.bodyMedium?.color,
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Cancel'.tr(context)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  if (isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      child: const CircularProgressIndicator(),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Text('Change Password'),
                      onPressed: () async {
                        // Validate inputs
                        if (currentPasswordController.text.isEmpty ||
                            newPasswordController.text.isEmpty ||
                            confirmPasswordController.text.isEmpty) {
                          setState(() {
                            errorMessage = 'All fields are required';
                          });
                          return;
                        }

                        if (newPasswordController.text !=
                            confirmPasswordController.text) {
                          setState(() {
                            errorMessage = 'New passwords do not match';
                          });
                          return;
                        }

                        // Show loading
                        setState(() {
                          isLoading = true;
                          errorMessage = '';
                        });

                        try {
                          // Get the current user
                          final user = FirebaseAuth.instance.currentUser;
                          final credentials = EmailAuthProvider.credential(
                            email: user!.email!,
                            password: currentPasswordController.text,
                          );

                          // Re-authenticate the user
                          await user.reauthenticateWithCredential(credentials);

                          // Change the password
                          await user.updatePassword(newPasswordController.text);

                          // Close the dialog
                          Navigator.of(context).pop();

                          // Show success message
                          _showSuccessSnackbar('Password changed successfully');
                        } catch (e) {
                          // Show error message
                          setState(() {
                            isLoading = false;
                            if (e is FirebaseAuthException) {
                              switch (e.code) {
                                case 'wrong-password':
                                  errorMessage =
                                      'Current password is incorrect';
                                  break;
                                case 'weak-password':
                                  errorMessage = 'New password is too weak';
                                  break;
                                default:
                                  errorMessage = 'Error: ${e.message}';
                              }
                            } else {
                              errorMessage =
                                  'An error occurred. Please try again.';
                            }
                          });
                        }
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context, AppProvider appProvider) {
    final languages = ['English', 'Spanish', 'French', 'Arabic', 'Urdu'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Language',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final language = languages[index];
                    final isSelected = appProvider.selectedLanguage == language;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      tileColor: isSelected ? AppConstants.primaryColor.withOpacity(0.15) : null,
                      leading: _getLangEmoji(language),
                      title: Text(
                        language,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppConstants.primaryColor : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: AppConstants.primaryColor,
                            )
                          : null,
                      onTap: () {
                        appProvider.setLanguage(language);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getLangEmoji(String language) {
    switch (language) {
      case 'English':
        return Text('🇺🇸', style: TextStyle(fontSize: 24));
      case 'Spanish':
        return Text('🇪🇸', style: TextStyle(fontSize: 24));
      case 'French':
        return Text('🇫🇷', style: TextStyle(fontSize: 24));
      case 'Arabic':
        return Text('🇸🇦', style: TextStyle(fontSize: 24));
      case 'Urdu':
        return Text('🇵🇰', style: TextStyle(fontSize: 24));
      default:
        return Text(
          language.substring(0, 2).toUpperCase(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        );
    }
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.wb_sunny;
      case ThemeMode.dark:
        return Icons.nightlight_round;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  // Build the update section for the settings screen
  Widget _buildUpdateSection({
    required double itemTitleFontSize,
    required double subtitleFontSize,
    required double iconSize,
    required double iconContainerSize,
    required double itemPadding,
    required double itemSpacing,
  }) {
    final appProvider = Provider.of<AppProvider>(context);
    // Use service locator instead of Provider for VersionService
    final versionSvc = serviceLocator.versionService;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppConstants.primaryColor;
    final cardBgColor = isDarkMode ? Colors.grey[850] : Colors.grey[50];
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    // Show error message when something goes wrong
    void _showUpdateErrorMessage(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Check for updates
        _buildSettingItem(
          title: 'Check for Updates',
          subtitle: appProvider.updateAvailable 
              ? 'New version ${appProvider.latestVersion} available!'
              : 'Current version: ${versionSvc.appVersion}',
          icon: Icons.update,
          titleFontSize: itemTitleFontSize,
          subtitleFontSize: subtitleFontSize,
          iconSize: iconSize,
          iconContainerSize: iconContainerSize,
          itemPadding: itemPadding,
          itemSpacing: itemSpacing,
          trailing: appProvider.isCheckingForUpdate 
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: appProvider.updateAvailable 
                        ? Colors.green.withOpacity(0.1)
                        : primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      appProvider.updateAvailable 
                          ? Icons.new_releases_outlined
                          : Icons.refresh,
                      color: appProvider.updateAvailable 
                          ? Colors.green 
                          : primaryColor,
                    ),
                    onPressed: () {
                      appProvider.checkForUpdates();
                    },
                    tooltip: 'Check for updates',
                  ),
                ),
          onTap: () {
            if (!appProvider.isCheckingForUpdate) {
              appProvider.checkForUpdates();
            }
          },
        ),
        
        if (appProvider.updateAvailable) ...[
          const Divider(),
          // Update available section
          Container(
            margin: EdgeInsets.symmetric(vertical: itemSpacing),
            padding: EdgeInsets.all(itemPadding),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Version information header with badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.new_releases,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Update Available',
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Version badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                            ? Colors.blueGrey.withOpacity(0.3) 
                            : Colors.blueGrey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDarkMode 
                              ? Colors.blueGrey.withOpacity(0.5) 
                              : Colors.blueGrey.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        appProvider.latestVersion,
                        style: TextStyle(
                          fontSize: subtitleFontSize - 2,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white70 : Colors.blueGrey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Version comparison
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? Colors.grey[800]!.withOpacity(0.5) 
                        : Colors.grey[100]!.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode 
                          ? Colors.grey[700]! 
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current',
                              style: TextStyle(
                                fontSize: subtitleFontSize - 2,
                                color: textColor.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              versionSvc.appVersion,
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: textColor.withOpacity(0.4),
                        size: 20,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'New',
                              style: TextStyle(
                                fontSize: subtitleFontSize - 2,
                                color: textColor.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appProvider.latestVersion,
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Release notes
                if (appProvider.releaseNotes.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 18,
                        color: textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What\'s New',
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? Colors.grey[800] 
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode 
                            ? Colors.grey[700]! 
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      appProvider.releaseNotes,
                      style: TextStyle(
                        fontSize: subtitleFontSize - 1,
                        height: 1.4,
                        color: textColor.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Download section
                if (appProvider.isDownloadingUpdate) ...[
                  // Downloading state
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              value: appProvider.downloadProgress > 0 
                                  ? appProvider.downloadProgress 
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Downloading Update...',
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress bar with percentage
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Download Progress',
                                style: TextStyle(
                                  fontSize: subtitleFontSize - 2,
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                appProvider.downloadProgress > 0
                                    ? '${(appProvider.downloadProgress * 100).toStringAsFixed(0)}%'
                                    : 'Preparing...',
                                style: TextStyle(
                                  fontSize: subtitleFontSize - 2,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: appProvider.downloadProgress > 0 
                                  ? appProvider.downloadProgress 
                                  : null,
                              backgroundColor: isDarkMode 
                                  ? Colors.grey[700] 
                                  : Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Cancel button
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            appProvider.resetUpdateState();
                          },
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancel Download'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (appProvider.downloadProgress == 1.0) ...[
                  // Download complete - simplified UI without installation options
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check, color: Colors.green, size: iconSize - 4),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Download Complete',
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'The update has been downloaded to your device. You can find it in your Downloads folder.',
                                    style: TextStyle(
                                      fontSize: subtitleFontSize - 1,
                                      color: textColor.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'After opening the Downloads folder, tap on the APK file to install it manually.',
                                  style: TextStyle(
                                    fontSize: subtitleFontSize - 2,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  appProvider.resetUpdateState();
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Start Over'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  side: BorderSide(color: Colors.grey[400]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final bool success = await AppUpdater.openDownloadsFolder();
                                    if (!success && context.mounted) {
                                      // Show message to user if all methods failed
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Could Not Open Downloads'),
                                            content: const Text(
                                              'Unable to open the Downloads folder automatically. Please open your file manager manually and navigate to the Downloads folder to find your APK file.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  } catch (e) {
                                    _showUpdateErrorMessage('Failed to open Downloads folder: ${e.toString()}');
                                  }
                                },
                                icon: const Icon(Icons.folder_open, size: 18),
                                label: const Text('Open Downloads'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Initial download buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.system_update_outlined,
                            size: 18,
                            color: textColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Download Options',
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Main download button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withBlue(min(255, primaryColor.blue + 30))],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            try {
                              appProvider.downloadUpdate(context: context);
                            } catch (e) {
                              _showUpdateErrorMessage('Failed to download update: ${e.toString()}');
                            }
                          },
                          icon: const Icon(Icons.download, size: 22),
                          label: const Text(
                            'Download Update',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Alternative download container
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.amber[700],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Large APK File?',
                                    style: TextStyle(
                                      fontSize: subtitleFontSize - 1,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'If the in-app download fails or takes too long, try downloading directly in your browser.',
                              style: TextStyle(
                                fontSize: subtitleFontSize - 2,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  try {
                                    appProvider.openDownloadInBrowser();
                                  } catch (e) {
                                    _showUpdateErrorMessage('Failed to open browser: ${e.toString()}');
                                  }
                                },
                                icon: const Icon(Icons.open_in_browser, size: 18),
                                label: const Text('Download in Browser'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                                  side: BorderSide(
                                    color: isDarkMode ? Colors.blue[700]! : Colors.blue[300]!,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
