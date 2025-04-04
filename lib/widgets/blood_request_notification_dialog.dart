import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../utils/theme_helper.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import '../models/blood_request_model.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class BloodRequestNotificationDialog extends StatefulWidget {
  final String requestId;
  final String requesterId;
  final String requesterName;
  final String requesterPhone;
  final String bloodType;
  final String location;
  final String city;
  final String urgency;
  final String notes;
  final String requestDate;

  const BloodRequestNotificationDialog({
    super.key,
    required this.requestId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhone,
    required this.bloodType,
    required this.location,
    this.city = '',
    required this.urgency,
    required this.notes,
    required this.requestDate,
  });

  @override
  State<BloodRequestNotificationDialog> createState() =>
      _BloodRequestNotificationDialogState();
}

class _BloodRequestNotificationDialogState
    extends State<BloodRequestNotificationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _copyTimer;
  String? _copiedText;
  bool _isLoading = false;
  bool _isAccepting = false;
  LatLng? _requesterLocation;
  double? _distanceToRequester;
  UserModel? _currentUser;
  // Store user location separately since it might not be part of UserModel
  double? _userLatitude;
  double? _userLongitude;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start the animation
    _animationController.forward();

    // Get user info and location details
    _loadUserAndLocationData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _copyTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserAndLocationData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      _currentUser = appProvider.currentUser;

      // Get user location from Firestore if not directly in user model
      if (_currentUser != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_currentUser!.id)
                .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            _userLatitude =
                userData['latitude'] is double
                    ? userData['latitude']
                    : userData['latitude'] != null
                    ? double.tryParse(userData['latitude'].toString())
                    : null;

            _userLongitude =
                userData['longitude'] is double
                    ? userData['longitude']
                    : userData['longitude'] != null
                    ? double.tryParse(userData['longitude'].toString())
                    : null;
          }
        }
      }

      // Get location coordinates
      await _geocodeLocation();

      // Calculate distance if locations are available
      if (_requesterLocation != null &&
          _userLatitude != null &&
          _userLongitude != null) {
        await _calculateDistance();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _geocodeLocation() async {
    try {
      if (widget.location.isNotEmpty) {
        List<Location> locations = await locationFromAddress(widget.location);
        if (locations.isNotEmpty) {
          setState(() {
            _requesterLocation = LatLng(
              locations.first.latitude,
              locations.first.longitude,
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error geocoding location: $e');
    }
  }

  Future<void> _calculateDistance() async {
    try {
      if (_requesterLocation != null &&
          _userLatitude != null &&
          _userLongitude != null) {
        // Use Haversine formula to calculate distance
        const double earthRadius = 6371; // in kilometers

        final double lat1 = _userLatitude!;
        final double lon1 = _userLongitude!;
        final double lat2 = _requesterLocation!.latitude;
        final double lon2 = _requesterLocation!.longitude;

        final double dLat = _toRadian(lat2 - lat1);
        final double dLon = _toRadian(lon2 - lon1);

        final double a =
            math.sin(dLat / 2) * math.sin(dLat / 2) +
            math.cos(_toRadian(lat1)) *
                math.cos(_toRadian(lat2)) *
                math.sin(dLon / 2) *
                math.sin(dLon / 2);

        final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
        final double distance = earthRadius * c;

        setState(() {
          _distanceToRequester = distance;
        });
      }
    } catch (e) {
      debugPrint('Error calculating distance: $e');
    }
  }

  double _toRadian(double degree) {
    return degree * math.pi / 180;
  }

  // Helper method to copy text to clipboard with feedback
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));

    setState(() {
      _copiedText = label;
    });

    // Show copied message for 2 seconds
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedText = null;
        });
      }
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }

  // Launch phone call
  Future<void> _launchCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: widget.requesterPhone);
    if (await url_launcher.canLaunchUrl(phoneUri)) {
      await url_launcher.launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Launch SMS
  Future<void> _launchSms() async {
    final Uri smsUri = Uri(scheme: 'sms', path: widget.requesterPhone);
    if (await url_launcher.canLaunchUrl(smsUri)) {
      await url_launcher.launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch messaging app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Accept blood request
  Future<void> _acceptRequest() async {
    setState(() {
      _isAccepting = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUser = appProvider.currentUser;

      // Update the blood request in Firestore
      await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(widget.requestId)
          .update({
            'status': 'Accepted',
            'responderId': currentUser.id,
            'responderName': currentUser.name,
            'responderPhone': currentUser.phoneNumber,
            'responseDate': DateTime.now().toIso8601String(),
          });

      // Create a notification for the requester
      final notificationData = {
        'userId': widget.requesterId,
        'title': 'Blood Request Accepted',
        'body': '${currentUser.name} has accepted your blood donation request!',
        'type': 'blood_request_response',
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
        'metadata': {
          'requestId': widget.requestId,
          'responderId': currentUser.id,
          'responderName': currentUser.name,
          'responderPhone': currentUser.phoneNumber,
          'bloodType': widget.bloodType,
        },
      };

      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notificationData);

      // Create a donation record in the accepted state
      final donationId = 'donation_${widget.requestId}';
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .set({
            'id': donationId,
            'donorId': currentUser.id,
            'donorName': currentUser.name,
            'recipientId': widget.requesterId,
            'recipientName': widget.requesterName,
            'recipientPhone': widget.requesterPhone,
            'bloodType': widget.bloodType,
            'date': DateTime.now().toIso8601String(),
            'status': 'Accepted',
            'requestId': widget.requestId,
          });

      // Navigate to donation tracking screen - My Donations tab and Accepted subtab
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacementNamed(
          '/donation_tracking',
          arguments: {
            'initialIndex': 1,
            'subTabIndex': 0,
          }, // 1 = My Donations, 0 = Accepted subtab
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You have accepted the blood request. The requester will be notified.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error accepting request: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isAccepting = false;
      });
    }
  }

  // Format date string
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: _buildDialogContent(context),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Blood request header
            _buildHeader(),

            const SizedBox(height: 16),

            // Requester information
            _buildRequesterInfo(),

            const SizedBox(height: 16),

            // Request details
            _buildRequestDetails(),

            const SizedBox(height: 20),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // Build the dialog header
  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.bloodtype_rounded,
                color: Colors.red.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Blood Donation Request',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 20, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.withOpacity(0.3)),
        ],
      ),
    );
  }

  // Build requester information section
  Widget _buildRequesterInfo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requester Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.person,
            'Name',
            widget.requesterName,
            onTap: () => _copyToClipboard(widget.requesterName, 'Name'),
            isCopied: _copiedText == 'Name',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.phone,
            'Phone',
            widget.requesterPhone,
            onTap: () => _copyToClipboard(widget.requesterPhone, 'Phone'),
            isCopied: _copiedText == 'Phone',
            trailingActions: [
              IconButton(
                icon: const Icon(Icons.call, size: 18, color: Colors.green),
                onPressed: _launchCall,
                tooltip: 'Call',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.message, size: 18, color: Colors.blue),
                onPressed: _launchSms,
                tooltip: 'Message',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.location_on,
            'Location',
            widget.location,
            onTap: () => _copyToClipboard(widget.location, 'Location'),
            isCopied: _copiedText == 'Location',
          ),
          if (_distanceToRequester != null)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Text(
                'Distance: ${_distanceToRequester!.toStringAsFixed(1)} km away',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Build request details section
  Widget _buildRequestDetails() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.bloodtype,
            'Blood Type',
            widget.bloodType,
            valueColor: Colors.red.shade700,
            valueFontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.timer,
            'Urgency',
            widget.urgency,
            valueColor:
                widget.urgency == 'Urgent'
                    ? Colors.red
                    : widget.urgency == 'High'
                    ? Colors.orange
                    : Colors.green,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.calendar_today,
            'Date',
            _formatDate(widget.requestDate),
          ),
          if (widget.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoRow(Icons.note, 'Notes', widget.notes),
          ],
        ],
      ),
    );
  }

  // Build action buttons
  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                ),
              ),
              child: const Text(
                'Decline',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isAccepting ? null : _acceptRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  _isAccepting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build info rows
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
    bool isCopied = false,
    List<Widget>? trailingActions,
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: valueFontWeight ?? FontWeight.normal,
                    color: valueColor ?? Colors.black87,
                    decoration:
                        onTap != null
                            ? TextDecoration.underline
                            : TextDecoration.none,
                    decorationStyle: TextDecorationStyle.dotted,
                  ),
                ),
              ),
              if (isCopied)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Copied to clipboard',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (trailingActions != null) ...trailingActions,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
