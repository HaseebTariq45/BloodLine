import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../utils/theme_helper.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class DonationRequestNotificationDialog extends StatefulWidget {
  final String requesterId;
  final String requesterName;
  final String requesterPhone;
  final String requesterEmail;
  final String requesterBloodType;
  final String requesterAddress;
  final String requestId;
  final bool isAlreadyAccepted;

  const DonationRequestNotificationDialog({
    super.key,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhone,
    required this.requesterEmail,
    required this.requesterBloodType,
    required this.requesterAddress,
    required this.requestId,
    this.isAlreadyAccepted = false,
  });

  @override
  State<DonationRequestNotificationDialog> createState() =>
      _DonationRequestNotificationDialogState();
}

class _DonationRequestNotificationDialogState
    extends State<DonationRequestNotificationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  bool _showContactOptions = false;
  String? _copiedText;
  Timer? _copyTimer;
  bool _isLoading = false;
  UserModel? _requesterDetails;

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

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Start the animation
    _animationController.forward();

    // Fetch requester details if needed
    _fetchRequesterDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _copyTimer?.cancel();
    super.dispose();
  }

  // Fetch additional requester details if necessary
  Future<void> _fetchRequesterDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Get user details if available in provider
      _requesterDetails = await appProvider.getUserDetailsById(
        widget.requesterId,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching requester details: $e');
      setState(() {
        _isLoading = false;
      });
    }
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

  // Launch email
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: widget.requesterEmail,
      queryParameters: {
        'subject': 'Blood Donation Request Response',
        'body':
            'Hello ${widget.requesterName},\n\nI received your blood donation request...',
      },
    );

    if (await url_launcher.canLaunchUrl(emailUri)) {
      await url_launcher.launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch email app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Accept donation request
  void _acceptDonationRequest() {
    // Forward to blood request notification dialog to handle acceptance
    Navigator.pop(context);
    Navigator.of(context).pushReplacementNamed(
      '/blood_request_notification',
      arguments: {
        'requestId': widget.requestId,
        'requesterId': widget.requesterId,
        'requesterName': widget.requesterName,
        'requesterPhone': widget.requesterPhone,
        'bloodType': widget.requesterBloodType,
        'location': widget.requesterAddress,
        'urgency': 'High',
        'notes': 'Donation request from ${widget.requesterName}',
        'requestDate': DateTime.now().toIso8601String(),
      },
    );
  }

  // Decline donation request
  void _declineDonationRequest() {
    // TODO: Implement donation declination
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You declined the donation request.'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  // View accepted donation details
  void _viewDonation() {
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacementNamed(
      '/donation_tracking',
      arguments: {
        'initialIndex': 1,
        'subTabIndex': 0,
      }, // 1 = My Donations, 0 = Accepted subtab
    );
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
    final isDark = context.isDarkMode;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.9,
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main content with fixed header, scrollable details, and fixed buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header - Enhanced with gradient background
              Container(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.primaryColor.withOpacity(0.15),
                      AppConstants.primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        widget.isAlreadyAccepted
                            ? 'Accepted Donation Request'
                            : 'Blood Donation Request',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBloodTypeBadge(widget.requesterBloodType),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isAlreadyAccepted
                                    ? 'Donation in Progress'
                                    : 'Urgent Request',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: context.textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      widget.isAlreadyAccepted
                                          ? Colors.blue.withOpacity(0.15)
                                          : Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color:
                                        widget.isAlreadyAccepted
                                            ? Colors.blue.withOpacity(0.3)
                                            : Colors.green.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.priority_high_rounded,
                                      size: 14,
                                      color:
                                          widget.isAlreadyAccepted
                                              ? Colors.blue
                                              : Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.isAlreadyAccepted
                                          ? 'In Progress'
                                          : 'Needs Assistance',
                                      style: TextStyle(
                                        color:
                                            widget.isAlreadyAccepted
                                                ? Colors.blue
                                                : Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 1,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),

              // Requester information - Scrollable with improved styling
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  color: AppConstants.primaryColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Requester Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Requester details with enhanced styling
                          _buildDetailRow(
                            context,
                            Icons.person,
                            'Name',
                            widget.requesterName,
                            onCopy:
                                () => _copyToClipboard(
                                  widget.requesterName,
                                  'Name',
                                ),
                            showCopy: true,
                          ),

                          _buildDetailRow(
                            context,
                            Icons.phone,
                            'Phone',
                            widget.requesterPhone,
                            onCopy:
                                () => _copyToClipboard(
                                  widget.requesterPhone,
                                  'Phone',
                                ),
                            showCopy: true,
                            onCall: _launchCall,
                            showCall: true,
                            onMessage: _launchSms,
                            showMessage: true,
                          ),

                          if (widget.requesterEmail.isNotEmpty)
                            _buildDetailRow(
                              context,
                              Icons.email,
                              'Email',
                              widget.requesterEmail,
                              onCopy:
                                  () => _copyToClipboard(
                                    widget.requesterEmail,
                                    'Email',
                                  ),
                              showCopy: true,
                              onEmail: _launchEmail,
                              showEmail: true,
                            ),

                          _buildDetailRow(
                            context,
                            Icons.location_on,
                            'Address',
                            widget.requesterAddress,
                            onCopy:
                                () => _copyToClipboard(
                                  widget.requesterAddress,
                                  'Address',
                                ),
                            showCopy: true,
                          ),

                          // Extra spacing at bottom
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Divider before buttons
              Container(
                height: 1,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),

              // Action buttons - Enhanced styling
              _buildActionButtons(),
            ],
          ),

          // Close button - Enhanced
          Positioned(
            right: 8,
            top: 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isDark ? Colors.black26 : Colors.white.withOpacity(0.8),
                  ),
                  child: Icon(
                    Icons.close,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: context.cardColor.withOpacity(0.7),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Loading details...',
                          style: TextStyle(
                            color: context.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Copied text indicator - Enhanced
          if (_copiedText != null)
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.black87,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_copiedText copied to clipboard',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBloodTypeBadge(String bloodType) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppConstants.primaryColor,
              AppConstants.primaryColor.withRed(
                (AppConstants.primaryColor.red + 30).clamp(0, 255),
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            bloodType,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool showCopy = false,
    Function()? onCopy,
    bool showCall = false,
    Function()? onCall,
    bool showMessage = false,
    Function()? onMessage,
    bool showEmail = false,
    Function()? onEmail,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppConstants.primaryColor, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      context.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.textColor,
                    ),
                  ),
                ),
              ),
              if (showCopy && onCopy != null)
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.copy,
                    size: 18,
                    color: context.secondaryTextColor,
                  ),
                  onPressed: onCopy,
                  tooltip: 'Copy to clipboard',
                ),
              if (showCall && onCall != null)
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8),
                  icon: Icon(Icons.call, size: 18, color: Colors.green),
                  onPressed: onCall,
                  tooltip: 'Call',
                ),
              if (showMessage && onMessage != null)
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8),
                  icon: Icon(Icons.message, size: 18, color: Colors.blue),
                  onPressed: onMessage,
                  tooltip: 'Send message',
                ),
              if (showEmail && onEmail != null)
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8),
                  icon: Icon(Icons.email, size: 18, color: Colors.orange),
                  onPressed: onEmail,
                  tooltip: 'Send email',
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Action buttons - Enhanced styling
  Widget _buildActionButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black12 : Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child:
            widget.isAlreadyAccepted
                ? Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _viewDonation,
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('VIEW DONATION'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _declineDonationRequest,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'DECLINE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _acceptDonationRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: const Text(
                          'ACCEPT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
