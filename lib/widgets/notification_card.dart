import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

// Data class for info row data
class InfoRowData {
  final String label;
  final String value;
  final IconData icon;
  final bool showCopyButton;
  final String? copyValue;

  InfoRowData({
    required this.label,
    required this.value,
    required this.icon,
    this.showCopyButton = false,
    this.copyValue,
  });
}

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onMarkAsRead;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  // String constants for localization or easy modification
  static const String requestAcceptedTitle = 'Request Accepted';
  static const String bloodRequestResponseTitle = 'Blood Request Response';
  static const String donationRequestTitle = 'Donation Request';
  static const String donorLabel = 'Donor';
  static const String responderLabel = 'Responder';
  static const String contactLabel = 'Contact';
  static const String closeText = 'CLOSE';
  static const String viewDetailsText = 'VIEW DETAILS';
  static const String copySuccessMessage = 'Phone number copied to clipboard';
  static const String trackingInfoText = 'You can track the donation progress in the Donation Tracking screen.';
  static const String todayText = 'Today';
  static const String yesterdayText = 'Yesterday';
  static const String errorParsingDate = 'Error parsing date';
  static const String defaultNotificationTitle = 'Notification';
  static const String deleteConfirmTitle = 'Delete Notification';
  static const String deleteConfirmMessage = 'Are you sure you want to delete this notification?';
  static const String cancelText = 'Cancel';
  static const String deleteText = 'Delete';
  static const String copyErrorMessage = 'Could not copy to clipboard';
  static const String navigationErrorMessage = 'Could not navigate to the desired screen';

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onMarkAsRead,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safe date parsing with fallback
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(notification.createdAt);
      } catch (e) {
      debugPrint('$errorParsingDate: $e');
      parsedDate = DateTime.now();
    }
    final formattedDate = _formatDate(parsedDate);
    
    // Get notification color for consistent styling
    final notificationColor = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: onDelete != null ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        if (onDelete == null) return false;
        return await _showDeleteConfirmationDialog(context);
      },
      onDismissed: (direction) {
        if (onDelete != null) onDelete!();
      },
      child: InkWell(
        onTap: () {
          // Handle notification tap based on type
          switch (notification.type) {
            case 'blood_request_response':
              _handleBloodRequestResponse(context);
              break;
            case 'blood_request_accepted':
              _handleBloodRequestAccepted(context);
              break;
            case 'donation_request':
              _handleDonationRequest(context);
              break;
            default:
              onTap?.call();
              break;
          }
        },
        child: Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
              shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: notificationColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: notificationColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getNotificationTitle(notification.type),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            notification.body,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[300] 
                                  : Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[400] 
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!notification.read)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show delete confirmation dialog
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deleteConfirmTitle),
        content: Text(deleteConfirmMessage),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
              cancelText,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[300] 
                    : Colors.grey[700],
              ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
              deleteText,
                    style: TextStyle(
                color: Colors.red,
                    ),
                  ),
                ),
              ],
      ),
    ) ?? false;
  }

  // Handle blood request response notification
  void _handleBloodRequestResponse(BuildContext context) {
              onMarkAsRead();

              // Get responder information with proper null checks
              final Map<String, dynamic> metadata = notification.metadata ?? {};
    debugPrint('Blood request response metadata: $metadata');

              final String? bloodType = metadata['bloodType'];
    final String? hospitalName = metadata['hospitalName'];
    final String? requesterName = metadata['requesterName'];
    final String? requesterPhone = metadata['requesterPhone'];
              final String? requestId = metadata['requestId'];

    // Primary color for this notification type
    final Color primaryColor = Colors.red.shade600;
    final List<Color> gradientColors = [primaryColor, Colors.red.shade400];

    // Show a dialog with information about the request
    _showEnhancedDialog(
                  context: context,
      title: bloodRequestResponseTitle,
      iconData: Icons.bloodtype,
      gradientColors: gradientColors,
      primaryColor: primaryColor,
      content: notification.body,
      infoRows: [
        if (requesterName != null) 
          InfoRowData(
            label: responderLabel,
            value: requesterName,
            icon: Icons.person,
          ),
        if (requesterPhone != null) 
          InfoRowData(
            label: contactLabel,
            value: requesterPhone,
            icon: Icons.phone,
            showCopyButton: true,
            copyValue: requesterPhone,
          ),
        if (bloodType != null)
          InfoRowData(
            label: 'Blood Type',
            value: bloodType,
            icon: Icons.bloodtype,
          ),
        if (hospitalName != null)
          InfoRowData(
            label: 'Hospital',
            value: hospitalName,
            icon: Icons.local_hospital,
          ),
      ],
      infoMessage: 'Please respond to the request as soon as possible if you can help.',
      onViewDetails: () {
                          Navigator.pop(context);
        _safeNavigate(
                            context,
                            '/donation_tracking',
          {'initialTab': 0, 'requestId': requestId},
        );
      },
    );
  }

  // Handle blood request accepted notification
  void _handleBloodRequestAccepted(BuildContext context) {
              onMarkAsRead();

              // Get responder information with proper null checks
              final Map<String, dynamic> metadata = notification.metadata ?? {};
              debugPrint('Blood request accepted metadata: $metadata');

              final String? responderId = metadata['responderId'];
              final String? responderName = metadata['responderName'];
              final String? responderPhone = metadata['responderPhone'];
              final String? requestId = metadata['requestId'];

    // Primary color for this notification type
    final Color primaryColor = Colors.green.shade600;
    final List<Color> gradientColors = [primaryColor, Colors.green.shade400];

    // Show dialog with information about the accepted request
    _showEnhancedDialog(
                context: context,
      title: requestAcceptedTitle,
      iconData: Icons.check_circle,
      gradientColors: gradientColors,
      primaryColor: primaryColor,
      content: notification.body,
      infoRows: [
        if (responderName != null) 
          InfoRowData(
            label: donorLabel,
            value: responderName,
            icon: Icons.person,
          ),
                      if (responderPhone != null) 
          InfoRowData(
            label: contactLabel,
            value: responderPhone,
            icon: Icons.phone,
            showCopyButton: true,
            copyValue: responderPhone,
          ),
      ],
      infoMessage: trackingInfoText,
      onViewDetails: () {
                        Navigator.pop(context);
        _safeNavigate(
                          context, 
                          '/donation_tracking',
          {'initialTab': 2},
        );
      },
    );
  }

  // Handle donation request notification
  void _handleDonationRequest(BuildContext context) {
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

    // Primary color for this notification type
    final Color primaryColor = Colors.blue.shade600;
    final List<Color> gradientColors = [primaryColor, Colors.blue.shade400];

    // Accept donation request function
    Future<void> _acceptDonationRequest() async {
      Navigator.pop(context); // Close the dialog first
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing your acceptance...'),
            ],
          ),
        ),
      );
      
      try {
        debugPrint('Accepting donation request: $requestId');
        final currentUser = Provider.of<AppProvider>(context, listen: false).currentUser;
        
        // Update donation request status
        if (requestId != null && requestId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('donation_requests')
              .doc(requestId)
              .update({
                'status': 'Accepted',
                'acceptedAt': DateTime.now().toIso8601String(),
              });
              
          debugPrint('Donation request accepted successfully in Firestore');
          
          // Create a donation record in the donations collection
          final donationId = 'donation_${requestId}';
          await FirebaseFirestore.instance
              .collection('donations')
              .doc(donationId)
              .set({
                'id': donationId,
                'donorId': currentUser.id,
                'donorName': currentUser.name,
                'recipientId': requesterId ?? '',
                'recipientName': requesterName ?? '',
                'recipientPhone': requesterPhone ?? '',
                'bloodType': requesterBloodType ?? '',
                'date': DateTime.now().toIso8601String(),
                'status': 'Accepted',
                'requestId': requestId,
                'location': requesterAddress ?? '',
              });
          
          debugPrint('Donation record created successfully in Firestore');
          
          // Also create a record in blood_requests collection to match the query in _buildAcceptedDonationsTab
          final bloodRequestId = 'bloodreq_${requestId}';
          await FirebaseFirestore.instance
              .collection('blood_requests')
              .doc(bloodRequestId)
              .set({
                'id': bloodRequestId,
                'responderId': currentUser.id,
                'responderName': currentUser.name,
                'requesterId': requesterId ?? '',
                'requesterName': requesterName ?? '',
                'contactNumber': requesterPhone ?? '',
                'bloodType': requesterBloodType ?? '',
                'location': requesterAddress ?? '',
                'city': requesterAddress ?? '',
                'status': 'Accepted',
                'requestDate': DateTime.now().toIso8601String(),
                'acceptedAt': DateTime.now().toIso8601String(),
              });
              
          debugPrint('Blood request record created successfully in Firestore');
          
          // Send notification to the requester that their request has been accepted
          if (requesterId != null && requesterId.isNotEmpty) {
            final appProvider = Provider.of<AppProvider>(context, listen: false);
            
            // Create notification model
            final notification = NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: requesterId, // Send to the requester
              title: 'Blood Donation Request Accepted',
              body: '${currentUser.name} has accepted your blood donation request',
              type: 'blood_request_accepted',
              read: false,
              createdAt: DateTime.now().toIso8601String(),
              metadata: {
                'requestId': requestId,
                'responderId': currentUser.id,
                'responderName': currentUser.name,
                'responderPhone': currentUser.phoneNumber,
                'bloodType': currentUser.bloodType,
                'location': requesterAddress ?? '',
              },
            );
            
            // Send the notification
            await appProvider.sendNotification(notification);
            debugPrint('Acceptance notification sent to requester: $requesterId');
          }
          
          // Close loading dialog
          Navigator.pop(context);
          
          // Navigate to donation tracking screen - My Donations tab
          _safeNavigate(
            context,
            '/donation_tracking',
            {'initialIndex': 1, 'subTabIndex': 0}, // 1 = My Donations tab, 0 = first subtab
          );
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Donation request accepted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Invalid request ID');
        }
      } catch (e) {
        debugPrint('Error accepting donation request: $e');
        
        // Close loading dialog
        Navigator.pop(context);
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting donation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Show dialog with information about the request
    _showEnhancedDialog(
      context: context,
      title: donationRequestTitle,
      iconData: Icons.volunteer_activism,
      gradientColors: gradientColors,
      primaryColor: primaryColor,
      content: notification.body,
      infoRows: [
        if (requesterName != null) 
          InfoRowData(
            label: 'Requester',
            value: requesterName,
            icon: Icons.person,
          ),
        if (requesterPhone != null) 
          InfoRowData(
            label: contactLabel,
            value: requesterPhone,
            icon: Icons.phone,
            showCopyButton: true,
            copyValue: requesterPhone,
          ),
        if (requesterBloodType != null)
          InfoRowData(
            label: 'Blood Type',
            value: requesterBloodType,
            icon: Icons.bloodtype,
          ),
        if (requesterAddress != null)
          InfoRowData(
            label: 'Location',
            value: requesterAddress,
            icon: Icons.location_on,
          ),
      ],
      infoMessage: 'Please accept this donation request if you can help. You will be redirected to the donation tracking screen.',
      onViewDetails: _acceptDonationRequest,
      actionButtonText: 'ACCEPT',
    );
  }

  // Safe navigation helper
  void _safeNavigate(BuildContext context, String route, [Map<String, dynamic>? arguments]) {
    try {
      Navigator.pushNamed(
        context, 
        route,
        arguments: arguments,
      );
    } catch (e) {
      debugPrint('Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(navigationErrorMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Safe clipboard copy helper
  Future<void> _safeCopy(BuildContext context, String text, Color color) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
          content: Text(copySuccessMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Clipboard error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(copyErrorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
                          ),
                        );
                      }
  }

  // Enhanced dialog that shows more information with better styling
  void _showEnhancedDialog({
    required BuildContext context,
    required String title,
    required IconData iconData,
    required List<Color> gradientColors,
    required Color primaryColor,
    required String content,
    required List<InfoRowData> infoRows,
    required String infoMessage,
    required VoidCallback onViewDetails,
    String actionButtonText = 'VIEW DETAILS',
  }) {
    final mediaQuery = MediaQuery.of(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
                      showDialog(
                        context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        insetPadding: EdgeInsets.symmetric(
          horizontal: 20, 
          vertical: mediaQuery.viewInsets.bottom > 0 ? 8 : 24
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.8,
            maxWidth: mediaQuery.size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient header with icon
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          iconData,
                          color: primaryColor,
                          size: 32,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                        content,
                            style: TextStyle(
                              fontSize: 16,
                          height: 1.4,
                          color: isDarkMode ? Colors.grey[300] : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Information container
                      if (infoRows.isNotEmpty) ...[
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            children: infoRows.map((row) {
                              return Column(
                                children: [
                                  _buildInfoRowEnhanced(
                                    context,
                                    row.label,
                                    row.value,
                                    row.icon,
                                    primaryColor: primaryColor,
                                    isDarkMode: isDarkMode,
                                    showCopyButton: row.showCopyButton,
                                    onCopy: row.showCopyButton ? () {
                                      _safeCopy(
                                        context, 
                                        row.copyValue ?? row.value,
                                        primaryColor,
                                      );
                                    } : null,
                                  ),
                                  if (infoRows.last != row) SizedBox(height: 12),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      
                      SizedBox(height: 20),
                      Row(
                      children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                                      child: Text(
                              infoMessage,
                                        style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
                                fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                        children: [
                          Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDarkMode ? Colors.grey[600]! : Colors.grey.shade300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            closeText,
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onViewDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(actionButtonText),
                        ),
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

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today, format as time
      return '$todayText, ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return '$yesterdayText, ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays < 7) {
      // Within a week
      return '${DateFormat('EEEE').format(dateTime)}, ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      // More than a week ago
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'blood_request_response':
        return Icons.bloodtype;
      case 'blood_request_accepted':
        return Icons.check_circle;
      case 'donation_request':
        return Icons.volunteer_activism;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'blood_request_response':
        return Colors.red;
      case 'blood_request_accepted':
        return Colors.green;
      case 'donation_request':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }

  String _getNotificationTitle(String type) {
    switch (type) {
      case 'blood_request_response':
        return bloodRequestResponseTitle;
      case 'blood_request_accepted':
        return requestAcceptedTitle;
      case 'donation_request':
        return donationRequestTitle;
      default:
        return defaultNotificationTitle;
    }
  }

  // Enhanced info row with icon and better styling
  Widget _buildInfoRowEnhanced(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    required Color primaryColor,
    required bool isDarkMode,
    bool showCopyButton = false,
    Function()? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode ? primaryColor.withOpacity(0.2) : primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: primaryColor,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
                label,
              style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey.shade700,
                ),
              ),
              Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[900],
                ),
              ),
            ],
          ),
        ),
        if (showCopyButton)
          IconButton(
            icon: Icon(
              Icons.copy,
              size: 18,
              color: isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
            ),
            onPressed: onCopy,
            tooltip: 'Copy to clipboard',
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
          ),
        ],
    );
  }
}