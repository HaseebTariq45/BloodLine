import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../widgets/blood_response_notification_dialog.dart';
import '../widgets/donation_request_notification_dialog.dart';
import '../constants/app_constants.dart';
import '../utils/theme_helper.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final Function onMarkAsRead;
  final Function onDelete;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onMarkAsRead,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the notification color based on type
    Color color;
    IconData iconData;

    switch (notification.type) {
      case 'blood_request_response':
        color = Colors.red.shade700;
        iconData = Icons.favorite;
        break;
      case 'blood_request_accepted':
        color = Colors.green.shade700;
        iconData = Icons.check_circle;
        break;
      case 'donation_request':
        color = Colors.green.shade700;
        iconData = Icons.bloodtype;
        break;
      case 'donation_reminder':
        color = Colors.orange.shade700;
        iconData = Icons.calendar_today;
        break;
      case 'urgent_request':
        color = Colors.red.shade900;
        iconData = Icons.priority_high;
        break;
      case 'test':
        color = Colors.blue.shade700;
        iconData = Icons.notifications;
        break;
      default:
        color = Colors.purple.shade700;
        iconData = Icons.notifications;
    }

    // Format date for display
    String _formatDate(String dateString) {
      try {
        final DateTime date = DateTime.parse(dateString);
        final DateTime now = DateTime.now();
        final Duration difference = now.difference(date);

        if (difference.inDays > 0) {
          return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
        } else if (difference.inHours > 0) {
          return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
        } else if (difference.inMinutes > 0) {
          return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
        } else {
          return 'Just now';
        }
      } catch (e) {
        return 'Recently';
      }
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 30.0,
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor:
                  context.isDarkMode ? const Color(0xFF252525) : Colors.white,
              title: Text(
                'Delete Notification',
                style: TextStyle(
                  color: context.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Are you sure you want to delete this notification?',
                style: TextStyle(color: context.textColor.withOpacity(0.8)),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Delete',
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
      onDismissed: (direction) {
        // Call the delete function
        onDelete();
      },
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
        child: InkWell(
          onTap: () {
            // Provide haptic feedback for better interaction
            HapticFeedback.lightImpact();

            if (notification.type == 'blood_request_response') {
              // Mark notification as read
              onMarkAsRead();

              // Get responder information with proper null checks
              final Map<String, dynamic> metadata = notification.metadata ?? {};
              debugPrint('Notification metadata: $metadata');

              final String? responderId = metadata['responderId'];
              final String? responderName = metadata['responderName'];
              final String? responderPhone = metadata['responderPhone'];
              final String? bloodType = metadata['bloodType'];
              final String? requestId = metadata['requestId'];

              // Debug log
              debugPrint('Notification card, responder info:');
              debugPrint(
                '  responderId: $responderId (${responderId == null
                    ? "null"
                    : responderId.isEmpty
                    ? "empty"
                    : "not empty"})',
              );
              debugPrint('  responderName: $responderName');
              debugPrint('  responderPhone: $responderPhone');
              debugPrint('  bloodType: $bloodType');
              debugPrint('  requestId: $requestId');

              // Check if we have essential information (name, phone, blood type)
              // Even if responderId is null, we can still show the dialog
              if (responderName != null &&
                  responderPhone != null &&
                  requestId != null) {
                // Show blood response dialog with donor details
                showDialog(
                  context: context,
                  builder:
                      (context) => BloodResponseNotificationDialog(
                        responderName: responderName,
                        responderPhone: responderPhone,
                        bloodType: bloodType ?? 'Unknown',
                        responderId:
                            responderId ??
                            'unknown_responder', // Use placeholder for null responderId
                        requestId: requestId,
                        onViewRequest: () {
                          // Handle viewing the request
                          Navigator.pop(context);
                          // Navigate to donation tracking screen's in-progress tab
                          Navigator.pushNamed(
                            context,
                            '/donation_tracking',
                            arguments: {
                              'initialIndex': 0,
                              'subTabIndex': 1,
                            }, // Main tab 0 (My Requests), subtab 1 (In Progress)
                          );
                        },
                      ),
                );
              } else {
                // Show error only if essential information is missing
                debugPrint(
                  'Missing essential responder information. Full notification: ${notification.toMap()}',
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Could not show details: Missing essential responder information.',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'DISMISS',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              }
            } else if (notification.type == 'blood_request_accepted') {
              // Mark notification as read
              onMarkAsRead();

              // Get responder information with proper null checks
              final Map<String, dynamic> metadata = notification.metadata ?? {};
              debugPrint('Blood request accepted metadata: $metadata');

              final String? responderId = metadata['responderId'];
              final String? responderName = metadata['responderName'];
              final String? responderPhone = metadata['responderPhone'];
              final String? requestId = metadata['requestId'];

              // Show a dialog with information about the accepted request
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text('Blood Request Accepted'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (responderName != null) 
                        _buildInfoRow(context, 'Donor', responderName),
                      if (responderPhone != null) 
                        _buildInfoRow(context, 'Contact', responderPhone),
                      const SizedBox(height: 16),
                      Text(
                        'You can track the donation progress in the Donation Tracking screen.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('CLOSE'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to donation tracking screen with my donations tab
                        Navigator.pushNamed(
                          context, 
                          '/donation_tracking',
                          arguments: {'initialTab': 2},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                      ),
                      child: Text('VIEW DETAILS'),
                    ),
                  ],
                ),
              );
            } else if (notification.type == 'donation_request') {
              // Mark notification as read
              onMarkAsRead();

              // Get requester information with proper null checks
              final Map<String, dynamic> metadata = notification.metadata ?? {};
              debugPrint('Donation request metadata: $metadata');

              final String? requesterId = metadata['requesterId'];
              final String? requesterName = metadata['requesterName'];
              final String? requesterPhone = metadata['requesterPhone'];
              final String? requesterEmail = metadata['requesterEmail'];
              final String? requesterBloodType = metadata['requesterBloodType'];
              final String? requesterAddress = metadata['requesterAddress'];
              final String? requestId = metadata['requestId'];

              // Debug log
              debugPrint('Notification card, requester info:');
              debugPrint('  requesterId: $requesterId');
              debugPrint('  requesterName: $requesterName');
              debugPrint('  requesterPhone: $requesterPhone');
              debugPrint('  requesterEmail: $requesterEmail');
              debugPrint('  requesterBloodType: $requesterBloodType');
              debugPrint('  requesterAddress: $requesterAddress');
              debugPrint('  requestId: $requestId');

              // Check if we have essential information
              if (requesterName != null &&
                  requesterPhone != null &&
                  requesterId != null &&
                  requestId != null) {
                // Check if the request has already been accepted by the current user
                final appProvider = Provider.of<AppProvider>(
                  context,
                  listen: false,
                );
                final currentUserId = appProvider.currentUser.id;

                FirebaseFirestore.instance
                    .collection('blood_requests')
                    .doc(requestId)
                    .get()
                    .then((doc) {
                      if (doc.exists) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] as String?;
                        final responderId = data['responderId'] as String?;

                        final bool isAlreadyAccepted =
                            (status == 'Accepted' || status == 'Completed') &&
                            responderId == currentUserId;

                        // Show donation request dialog with requester details
                        showDialog(
                          context: context,
                          builder:
                              (context) => DonationRequestNotificationDialog(
                                requesterId: requesterId,
                                requesterName: requesterName,
                                requesterPhone: requesterPhone,
                                requesterEmail:
                                    requesterEmail ?? 'Not provided',
                                requesterBloodType:
                                    requesterBloodType ?? 'Unknown',
                                requesterAddress:
                                    requesterAddress ?? 'Not provided',
                                requestId: requestId,
                                isAlreadyAccepted: isAlreadyAccepted,
                              ),
                        );
                      } else {
                        // Request doesn't exist anymore
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'This blood request is no longer available',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    })
                    .catchError((error) {
                      debugPrint('Error checking request status: $error');
                      // Show dialog without checking status (fallback)
                      showDialog(
                        context: context,
                        builder:
                            (context) => DonationRequestNotificationDialog(
                              requesterId: requesterId,
                              requesterName: requesterName,
                              requesterPhone: requesterPhone,
                              requesterEmail: requesterEmail ?? 'Not provided',
                              requesterBloodType:
                                  requesterBloodType ?? 'Unknown',
                              requesterAddress:
                                  requesterAddress ?? 'Not provided',
                              requestId: requestId,
                              isAlreadyAccepted: false,
                            ),
                      );
                    });
              } else {
                // Show error if essential information is missing
                debugPrint(
                  'Missing essential requester information. Full notification: ${notification.toMap()}',
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Could not show details: Missing essential requester information.',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'DISMISS',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              }
            } else {
              // For other notification types
              onMarkAsRead();

              // Show a simple dialog for other notification types
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.body,
                            style: TextStyle(
                              fontSize: 16,
                              color: context.textColor.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Received: ${_formatDate(notification.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  context.isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
              );
            }
          },
          onLongPress: () {
            // Provide haptic feedback for better interaction
            HapticFeedback.mediumImpact();

            // Show options in a bottom sheet
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder:
                  (context) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!notification.read)
                          ListTile(
                            leading: Icon(
                              Icons.mark_email_read,
                              color: AppConstants.primaryColor,
                            ),
                            title: Text(
                              'Mark as read',
                              style: TextStyle(color: context.textColor),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              onMarkAsRead();
                            },
                          ),
                        ListTile(
                          leading: Icon(
                            Icons.delete_outline,
                            color: Colors.red[700],
                          ),
                          title: Text(
                            'Delete notification',
                            style: TextStyle(color: context.textColor),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            // Show confirmation dialog
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor:
                                      context.isDarkMode
                                          ? const Color(0xFF252525)
                                          : Colors.white,
                                  title: Text(
                                    'Delete Notification',
                                    style: TextStyle(
                                      color: context.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete this notification?',
                                    style: TextStyle(
                                      color: context.textColor.withOpacity(0.8),
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
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
                                        onDelete();
                                      },
                                      child: Text(
                                        'Delete',
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
                      ],
                    ),
                  ),
            );
          },
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border:
                  notification.read
                      ? null
                      : Border.all(color: color.withOpacity(0.5), width: 1.5),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with colored background
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(iconData, color: color, size: 24.0),
                ),
                const SizedBox(width: 16.0),
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight:
                                    notification.read
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                fontSize: 16.0,
                                color: context.textColor,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (!notification.read)
                            Container(
                              width: 10.0,
                              height: 10.0,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: context.textColor.withOpacity(0.7),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12.0,
                              color:
                                  context.isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14.0,
                            color:
                                context.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build info rows in dialogs
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
