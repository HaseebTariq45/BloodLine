import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/notification_model.dart';
import '../widgets/notification_card.dart';
import '../widgets/empty_state.dart';
import '../constants/app_constants.dart';
import '../utils/theme_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Use microtask to ensure this runs after the widget is fully built
    Future.microtask(() => _loadNotifications());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Get notifications from provider
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.getUserNotifications();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Group notifications by date
  Map<String, List<NotificationModel>> _groupNotificationsByDate(List<NotificationModel> notifications) {
    final Map<String, List<NotificationModel>> grouped = {};
    
    for (final notification in notifications) {
      try {
        final date = DateTime.parse(notification.createdAt);
        final today = DateTime.now();
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        
        String dateKey;
        if (date.year == today.year && date.month == today.month && date.day == today.day) {
          dateKey = 'Today';
        } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
          dateKey = 'Yesterday';
        } else if (today.difference(date).inDays < 7) {
          dateKey = DateFormat('EEEE').format(date); // Day name (e.g., Monday)
        } else {
          dateKey = DateFormat('MMM d, yyyy').format(date); // Month day, year
        }
        
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        
        grouped[dateKey]!.add(notification);
      } catch (e) {
        // If date parsing fails, add to "Other" category
        if (!grouped.containsKey('Other')) {
          grouped['Other'] = [];
        }
        grouped['Other']!.add(notification);
      }
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final bool hasNotifications = appProvider.userNotifications.isNotEmpty;
    final bool hasUnreadNotifications = appProvider.userNotifications.any((notification) => !notification.read);
    final groupedNotifications = _groupNotificationsByDate(appProvider.userNotifications);
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140.0,
              floating: true,
              pinned: true,
              elevation: 0,
              leadingWidth: 40,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              backgroundColor: context.isDarkMode 
                  ? const Color(0xFF1E1E1E) 
                  : AppConstants.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 50.0, bottom: 16.0),
                title: Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppConstants.primaryColor,
                        AppConstants.primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      if (hasNotifications && !hasUnreadNotifications)
                        Positioned(
                          bottom: 80.0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16.0),
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              decoration: BoxDecoration(
                                color: context.isDarkMode 
                                    ? const Color(0xFF2A2A2A) 
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: context.isDarkMode 
                                        ? Colors.greenAccent 
                                        : AppConstants.primaryColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'All caught up!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: context.isDarkMode 
                                          ? Colors.white 
                                          : AppConstants.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (hasUnreadNotifications)
                  Padding(
                    padding: const EdgeInsets.only(right: 2.0),
                    child: IconButton(
                      icon: const Icon(Icons.done_all, color: Colors.white),
                      tooltip: 'Mark all as read',
                      iconSize: 22,
                      onPressed: () {
                        appProvider.markAllNotificationsAsRead();
                        // Show a confirmation snackbar
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('All notifications marked as read'),
                                ],
                              ),
                              backgroundColor: AppConstants.successColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                if (hasNotifications)
                  Padding(
                    padding: const EdgeInsets.only(right: 2.0),
                    child: IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.white),
                      tooltip: 'Delete all notifications',
                      iconSize: 22,
                      onPressed: () {
                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: context.isDarkMode ? const Color(0xFF252525) : Colors.white,
                              title: Text(
                                'Delete All Notifications',
                                style: TextStyle(
                                  color: context.textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to delete all notifications? This action cannot be undone.',
                                style: TextStyle(
                                  color: context.textColor.withOpacity(0.8),
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    appProvider.deleteAllNotifications();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.delete_outline, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text('All notifications deleted'),
                                          ],
                                        ),
                                        backgroundColor: Colors.red[700],
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Delete All',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Refresh notifications',
                    iconSize: 22,
                    onPressed: () {
                      appProvider.refreshNotifications();
                      // Show loading indicator
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Refreshing notifications...'),
                            ],
                          ),
                          backgroundColor: context.isDarkMode 
                              ? const Color(0xFF2C2C2C) 
                              : Colors.grey[800],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ];
        },
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading notifications...',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await appProvider.refreshNotifications();
                },
                color: AppConstants.primaryColor,
                child: hasNotifications
                    ? ListView.builder(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 100.0),
                        itemCount: groupedNotifications.length,
                        itemBuilder: (context, index) {
                          final dateKey = groupedNotifications.keys.elementAt(index);
                          final notifications = groupedNotifications[dateKey]!;
                          
                          return FadeInUp(
                            duration: Duration(milliseconds: 300 + (index * 100)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 16.0),
                                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                        decoration: BoxDecoration(
                                          color: context.isDarkMode 
                                              ? AppConstants.primaryColor.withOpacity(0.15)
                                              : AppConstants.primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _getDateIcon(dateKey),
                                              size: 14,
                                              color: AppConstants.primaryColor,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              dateKey,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: context.isDarkMode 
                                                    ? AppConstants.primaryColor
                                                    : AppConstants.primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Divider(
                                          color: context.isDarkMode 
                                              ? Colors.white24 
                                              : Colors.grey[300],
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16.0, 
                                    right: 16.0, 
                                    top: 8.0,
                                    bottom: 16.0,
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: notifications.length,
                                    itemBuilder: (context, index) {
                                      final notification = notifications[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: NotificationCard(
                                          notification: notification,
                                          onDelete: () => appProvider.deleteNotification(notification.id),
                                          onMarkAsRead: () => appProvider.markNotificationAsRead(notification.id),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : FadeIn(
                        duration: const Duration(milliseconds: 500),
                        child: EmptyState(
                          icon: Icons.notifications_off_outlined,
                          title: 'No Notifications',
                          message: 'You don\'t have any notifications yet. We\'ll notify you when something important happens.',
                          action: ElevatedButton.icon(
                            onPressed: () {
                              appProvider.refreshNotifications();
                            },
                            icon: Icon(Icons.refresh),
                            label: Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
      ),
    );
  }

  // Helper method to get appropriate icon for date headers
  IconData _getDateIcon(String dateKey) {
    if (dateKey == 'Today') {
      return Icons.today;
    } else if (dateKey == 'Yesterday') {
      return Icons.history;
    } else if (dateKey.contains(',')) {
      return Icons.calendar_month;
    } else {
      return Icons.calendar_today;
    }
  }
}
