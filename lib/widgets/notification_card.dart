import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';

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

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onMarkAsRead,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDate(DateTime.parse(notification.createdAt));

    return InkWell(
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
                      color: _getNotificationColor(notification.type).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
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
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
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
    );
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

    // Show a dialog with information about the request
    _showEnhancedDialog(
      context: context,
      title: bloodRequestResponseTitle,
      iconData: Icons.bloodtype,
      gradientColors: [Colors.red.shade600, Colors.red.shade400],
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
        Navigator.pushNamed(
          context, 
          '/blood_requests',
          arguments: {'requestId': requestId},
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

    // Show dialog with information about the accepted request
    _showEnhancedDialog(
      context: context,
      title: requestAcceptedTitle,
      iconData: Icons.check_circle,
      gradientColors: [Colors.green.shade600, Colors.green.shade400],
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
        Navigator.pushNamed(
          context, 
          '/donation_tracking',
          arguments: {'initialTab': 2},
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

    // Show dialog with information about the request
    _showEnhancedDialog(
      context: context,
      title: donationRequestTitle,
      iconData: Icons.volunteer_activism,
      gradientColors: [Colors.blue.shade600, Colors.blue.shade400],
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
      infoMessage: 'You can review this donation request and respond accordingly.',
      onViewDetails: () {
        Navigator.pop(context);
        Navigator.pushNamed(
          context, 
          '/donation_tracking',
          arguments: {'initialTab': 2, 'requestId': requestId},
        );
      },
    );
  }

  // Reusable enhanced dialog builder
  void _showEnhancedDialog({
    required BuildContext context,
    required String title,
    required IconData iconData,
    required List<Color> gradientColors,
    required String content,
    required List<InfoRowData> infoRows,
    required String infoMessage,
    required VoidCallback onViewDetails,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
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
                          color: gradientColors[0],
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
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Information container
                      if (infoRows.isNotEmpty) ...[
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
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
                                    showCopyButton: row.showCopyButton,
                                    onCopy: row.showCopyButton ? () {
                                      Clipboard.setData(ClipboardData(text: row.copyValue ?? row.value));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(copySuccessMessage),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: gradientColors[0],
                                          duration: Duration(seconds: 2),
                                        ),
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
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              infoMessage,
                              style: TextStyle(
                                color: Colors.grey.shade600,
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
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(closeText),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onViewDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gradientColors[0],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(viewDetailsText),
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
        return 'Notification';
    }
  }

  // Enhanced info row with icon and better styling
  Widget _buildInfoRowEnhanced(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool showCopyButton = false,
    Function()? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.green.shade600,
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
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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
              color: Colors.grey.shade600,
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