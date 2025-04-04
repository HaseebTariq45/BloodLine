import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../utils/localization/app_localization.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool showProfilePicture;
  final bool translateTitle;
  final double? height;
  final bool showNotificationIcon;
  final VoidCallback? onNotificationTap;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.showProfilePicture = true,
    this.translateTitle = true,
    this.height,
    this.showNotificationIcon = true,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentUser = appProvider.currentUser;
    final hasUnreadNotifications = appProvider.hasUnreadNotifications;

    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;

    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;

    // Calculate responsive sizes
    final double titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final double backIconSize = isSmallScreen ? 16.0 : 18.0;
    final double profileIconSize = isSmallScreen ? 14.0 : 16.0;
    final double profileAvatarRadius = isSmallScreen ? 14.0 : 16.0;
    final double backButtonMargin = isSmallScreen ? 6.0 : 8.0;
    final double profilePadding = isSmallScreen ? 12.0 : 16.0;
    final double notificationIconSize = isSmallScreen ? 20.0 : 24.0;
    final double badgeSize = isSmallScreen ? 8.0 : 10.0;

    final displayTitle = translateTitle ? title.tr(context) : title;

    // Create a list that might include the notification button and all other actions
    List<Widget> allActions = [];

    // Add notification icon if requested
    if (showNotificationIcon) {
      allActions.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                padding: EdgeInsets.zero,
                onPressed:
                    onNotificationTap ??
                    () {
                      // Navigate to notifications screen
                      Navigator.pushNamed(context, '/notifications');
                    },
                iconSize: notificationIconSize,
              ),
              if (hasUnreadNotifications)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Add profile picture if requested
    if (showProfilePicture) {
      allActions.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: GestureDetector(
            onTap: () {
              // Navigate to profile screen
              Navigator.pushNamed(context, '/profile');
            },
            child: CircleAvatar(
              radius: profileAvatarRadius,
              backgroundColor: Colors.white,
              backgroundImage:
                  currentUser.imageUrl.isNotEmpty
                      ? NetworkImage(currentUser.imageUrl)
                      : null,
              child:
                  currentUser.imageUrl.isEmpty
                      ? Icon(
                        Icons.person,
                        color: AppConstants.primaryColor,
                        size: profileIconSize,
                      )
                      : null,
            ),
          ),
        ),
      );
    }

    // Add all other actions
    if (actions != null) {
      allActions.addAll(actions!);
    }

    return AppBar(
      backgroundColor: AppConstants.primaryColor,
      elevation: 0,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          displayTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: titleFontSize,
            color: Colors.white,
          ),
        ),
      ),
      centerTitle: true,
      leading:
          showBackButton
              ? Container(
                margin: EdgeInsets.all(backButtonMargin),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: backIconSize,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              )
              : null,
      actions: allActions,
      toolbarHeight:
          height ?? (isSmallScreen ? kToolbarHeight * 0.9 : kToolbarHeight),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height ?? kToolbarHeight);
}
