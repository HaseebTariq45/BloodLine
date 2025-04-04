import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../utils/theme_helper.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import '../models/emergency_contact_model.dart';
import '../models/user_location_model.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class BloodResponseNotificationDialog extends StatefulWidget {
  final String responderName;
  final String responderPhone;
  final String bloodType;
  final String responderId;
  final String requestId;
  final VoidCallback onViewRequest;

  const BloodResponseNotificationDialog({
    super.key,
    required this.responderName,
    required this.responderPhone,
    required this.bloodType,
    required this.responderId,
    required this.requestId,
    required this.onViewRequest,
  });

  @override
  State<BloodResponseNotificationDialog> createState() =>
      _BloodResponseNotificationDialogState();
}

class _BloodResponseNotificationDialogState
    extends State<BloodResponseNotificationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  bool _showContactOptions = false;
  String? _copiedText;
  Timer? _copyTimer;
  bool _isLoading = false;
  bool _showingContacts = false;
  bool _showingLocation = false;
  bool _showingHealthQuestionnaire = false;
  UserModel? _responderDetails;
  List<EmergencyContactModel> _emergencyContacts = [];
  Map<String, dynamic>? _healthQuestionnaireData;
  bool _loadingHealthQuestionnaire = false;

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

    // Fetch responder details when dialog opens
    _fetchResponderDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _copyTimer?.cancel();
    super.dispose();
  }

  // Fetch responder details including location
  Future<void> _fetchResponderDetails() async {
    if (widget.responderId.isEmpty ||
        widget.responderId == 'unknown_responder') {
      debugPrint(
        'BloodResponseNotificationDialog - Using basic information without fetching responder details',
      );

      // Don't show an error, just skip fetching additional information
      // We already have basic info like name, phone, and blood type
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Debug logging
      debugPrint(
        'BloodResponseNotificationDialog - Fetching details for responder ID: ${widget.responderId}',
      );
      debugPrint('BloodResponseNotificationDialog - All dialog props:');
      debugPrint('  responderName: ${widget.responderName}');
      debugPrint('  responderPhone: ${widget.responderPhone}');
      debugPrint('  bloodType: ${widget.bloodType}');
      debugPrint('  requestId: ${widget.requestId}');

      // Get responder user details
      final userDetails = await appProvider.getUserDetailsById(
        widget.responderId,
      );
      if (userDetails != null) {
        debugPrint(
          'BloodResponseNotificationDialog - Successfully retrieved user details',
        );
        if (mounted) {
          setState(() {
            _responderDetails = userDetails;
          });
        }
      } else {
        debugPrint(
          'BloodResponseNotificationDialog - Failed to retrieve user details (null returned)',
        );
      }

      // Get emergency contacts
      try {
        final contacts = await appProvider.getEmergencyContactsForUser(
          widget.responderId,
        );
        debugPrint(
          'BloodResponseNotificationDialog - Retrieved ${contacts.length} user-added emergency contacts',
        );

        if (mounted) {
          setState(() {
            _emergencyContacts = contacts;
          });

          // If no contacts are found, don't show an error - this is expected now that we only show user-added contacts
          if (contacts.isEmpty) {
            debugPrint(
              'No user-added emergency contacts found for responder: ${widget.responderId}',
            );
          }
        }
      } catch (e) {
        debugPrint(
          'BloodResponseNotificationDialog - Error fetching emergency contacts: $e',
        );

        // Check if it's a Firestore index error
        if (e.toString().contains('failed-precondition') &&
            e.toString().contains('requires an index')) {
          if (mounted) {
            Future.microtask(() {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Emergency contacts are being set up and will be available soon',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint(
        'BloodResponseNotificationDialog - Error fetching responder details: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Accept the donation
  Future<void> _acceptDonation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Check if we have a valid responderId
      if (widget.responderId == 'unknown_responder' ||
          widget.responderId.isEmpty) {
        setState(() {
          _isLoading = false;
        });

        // Show information dialog that we cannot process the acceptance
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cannot process automatic acceptance: Responder information is incomplete.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );

          // Show direct contact dialog instead
          _showDirectContactDialog();
          return;
        }
      }

      await appProvider.acceptBloodRequestResponse(
        widget.requestId,
        widget.responderId,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Donation accepted! Location has been shared with the donor.',
            ),
            backgroundColor: AppConstants.successColor,
          ),
        );

        // Show confirmation dialog with next steps
        _showAcceptanceConfirmationDialog();
      }
    } catch (e) {
      debugPrint('Error accepting donation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting donation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show confirmation dialog after accepting donation
  void _showAcceptanceConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppConstants.successColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text('Donation Accepted'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have accepted ${widget.responderName}\'s offer to donate blood.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Next steps:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildNextStepItem(
                  icon: Icons.location_on,
                  text: 'Your location has been shared with the donor',
                ),
                _buildNextStepItem(
                  icon: Icons.phone,
                  text: 'Contact the donor to coordinate the donation',
                ),
                _buildNextStepItem(
                  icon: Icons.medical_services,
                  text: 'Prepare for the donation (stay hydrated, eat well)',
                ),
                _buildNextStepItem(
                  icon: Icons.info_outline,
                  text: 'Inform medical staff about the incoming donor',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'You can call or message the donor using the contact options provided.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close this dialog
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pop(); // Close the main dialog
                },
                child: const Text('CLOSE'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close this dialog
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pop(); // Close the main dialog
                  // Call the donor
                  _makePhoneCall(widget.responderPhone);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'CALL DONOR',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  // Build next step item with icon and text
  Widget _buildNextStepItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppConstants.primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  // Function to make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await url_launcher.launchUrl(launchUri);
  }

  // Function to send SMS
  Future<void> _sendSMS(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    await url_launcher.launchUrl(launchUri);
  }

  // Function to copy text to clipboard
  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() {
      _copiedText = label;
    });

    // Reset the copied text after 2 seconds
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedText = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      contentPadding: const EdgeInsets.all(16),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Blood Donation Response',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.responderName} has responded to your blood request',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Wrap content in Expanded + SingleChildScrollView to make it scrollable
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Responder details card - more compact
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[850]
                                  : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Responder info
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildCompactInfoRow(
                                        context: context,
                                        icon: Icons.person,
                                        title: 'Name',
                                        value: widget.responderName,
                                        color: AppConstants.primaryColor,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildCompactInfoRow(
                                        context: context,
                                        icon: Icons.bloodtype,
                                        title: 'Blood Type',
                                        value: widget.bloodType,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildCompactInfoRow(
                                        context: context,
                                        icon: Icons.phone,
                                        title: 'Phone',
                                        value: widget.responderPhone,
                                        color: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                // Quick action buttons
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildQuickActionButton(
                                        icon: Icons.call,
                                        label: 'Call',
                                        color: Colors.green,
                                        onTap:
                                            () => _makePhoneCall(
                                              widget.responderPhone,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildQuickActionButton(
                                        icon: Icons.message,
                                        label: 'SMS',
                                        color: Colors.blue,
                                        onTap:
                                            () =>
                                                _sendSMS(widget.responderPhone),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildQuickActionButton(
                                        icon: Icons.content_copy,
                                        label: 'Copy',
                                        color: Colors.orange,
                                        onTap:
                                            () => _copyToClipboard(
                                              widget.responderPhone,
                                              'Phone',
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Toggle buttons for additional info
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildToggleButton(
                                    icon: Icons.contact_emergency,
                                    label: 'Emergency Contacts',
                                    color: Colors.orange,
                                    isSelected: _showingContacts,
                                    onTap: () {
                                      setState(() {
                                        _showingContacts = !_showingContacts;
                                        if (_showingContacts) {
                                          _showingLocation = false;
                                          _showingHealthQuestionnaire = false;

                                          // If we don't have contacts yet, fetch them
                                          if (_emergencyContacts.isEmpty &&
                                              !_isLoading) {
                                            _fetchEmergencyContacts();
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildToggleButton(
                                    icon: Icons.location_on,
                                    label: 'Location',
                                    color: Colors.purple,
                                    isSelected: _showingLocation,
                                    onTap: () {
                                      setState(() {
                                        _showingLocation = !_showingLocation;
                                        if (_showingLocation) {
                                          _showingContacts = false;
                                          _showingHealthQuestionnaire = false;
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildToggleButton(
                                    icon: Icons.health_and_safety,
                                    label: 'Health Data',
                                    color: Colors.teal,
                                    isSelected: _showingHealthQuestionnaire,
                                    onTap: () {
                                      setState(() {
                                        _showingHealthQuestionnaire =
                                            !_showingHealthQuestionnaire;
                                        if (_showingHealthQuestionnaire) {
                                          _showingContacts = false;
                                          _showingLocation = false;

                                          // If we don't have health data yet, fetch it
                                          if (_healthQuestionnaireData ==
                                                  null &&
                                              !_loadingHealthQuestionnaire) {
                                            _fetchHealthQuestionnaireData();
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            // Conditionally show location, contacts, or health questionnaire
                            if (_showingLocation &&
                                _responderDetails?.location != null)
                              _buildCompactLocationSection(),
                            if (_showingContacts)
                              _isLoading && _emergencyContacts.isEmpty
                                  ? _buildLoadingIndicator(
                                    color: Colors.orange,
                                    message: 'Loading contacts...',
                                  )
                                  : _emergencyContacts.isNotEmpty
                                  ? _buildCompactEmergencyContactsSection()
                                  : _buildNoContactsMessage(),
                            if (_showingHealthQuestionnaire)
                              _loadingHealthQuestionnaire
                                  ? _buildLoadingIndicator(
                                    color: Colors.teal,
                                    message: 'Loading health data...',
                                  )
                                  : _healthQuestionnaireData != null
                                  ? _buildHealthQuestionnaireSection()
                                  : _buildNoHealthDataMessage(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Action buttons - simplified to just two main actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[600]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        'DISMISS',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                _showContactOptionsSheet();
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.contact_phone, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'CONTACT DONOR',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Additional action row with View Details button
              OutlinedButton(
                onPressed: widget.onViewRequest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.primaryColor,
                  side: BorderSide(color: AppConstants.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'VIEW REQUEST DETAILS',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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
  }

  // New compact info row for basic details
  Widget _buildCompactInfoRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Quick action button for the right side of the card
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Toggle button for showing/hiding additional sections
  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact location section
  Widget _buildCompactLocationSection() {
    final location = _responderDetails?.location;
    if (location == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.purple, size: 14),
              const SizedBox(width: 4),
              const Text(
                'Location',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.purple,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap:
                    () => _openLocation(location.latitude, location.longitude),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map, color: Colors.purple, size: 12),
                    SizedBox(width: 2),
                    Text(
                      'Open Maps',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 8, thickness: 0.5),
          Text(
            location.address ?? 'Address not available',
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              InkWell(
                onTap:
                    () => _copyToClipboard(
                      '${location.latitude}, ${location.longitude}',
                      'Coordinates',
                    ),
                child: const Icon(Icons.copy, size: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Open location in any map app
  Future<void> _openLocation(double latitude, double longitude) async {
    try {
      // Try different URI schemes to maximize compatibility
      final List<String> mapUris = [
        // Geo URI - works with many map apps
        'geo:$latitude,$longitude',
        // HTTP URL - fallback for web or if geo URI fails
        'https://maps.google.com/maps?q=$latitude,$longitude',
      ];

      bool launched = false;

      // Try each URI until one works
      for (final uri in mapUris) {
        if (await url_launcher.canLaunch(uri)) {
          await url_launcher.launch(uri);
          launched = true;
          break;
        }
      }

      // If none of the URIs worked, show a dialog with the coordinates
      if (!launched) {
        if (mounted) {
          _showLocationCopyDialog(latitude, longitude);
        }
      }
    } catch (e) {
      debugPrint('Error opening location: $e');
      if (mounted) {
        _showLocationCopyDialog(latitude, longitude);
      }
    }
  }

  // Show dialog with coordinates when map apps fail
  void _showLocationCopyDialog(double latitude, double longitude) {
    final coordsString = '$latitude, $longitude';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Location Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Could not open maps app. You can copy the coordinates and use them in your preferred maps application:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          coordsString,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          _copyToClipboard(coordsString, 'Coordinates');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  // Compact emergency contacts section
  Widget _buildCompactEmergencyContactsSection() {
    if (_emergencyContacts.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.contact_emergency,
                  color: Colors.grey,
                  size: 14,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Divider(height: 8, thickness: 0.5),
            const Text(
              'No user-added emergency contacts available',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 4),
            const Text(
              'Only contacts added by the responder are displayed here for privacy',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Show the first contact
    final contact = _emergencyContacts.first;
    final hasMultipleContacts = _emergencyContacts.length > 1;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.contact_emergency,
                color: Colors.orange,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Emergency Contact${hasMultipleContacts ? 's' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.orange,
                ),
              ),
              if (hasMultipleContacts) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_emergencyContacts.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              const Text(
                'User-added only',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const Divider(height: 8, thickness: 0.5),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      contact.phoneNumber,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final url = 'tel:${contact.phoneNumber}';
                      if (await url_launcher.canLaunch(url)) {
                        await url_launcher.launch(url);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone,
                        color: Colors.green,
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final url = 'sms:${contact.phoneNumber}';
                      if (await url_launcher.canLaunch(url)) {
                        await url_launcher.launch(url);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.message,
                        color: Colors.blue,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Show "View All" button if there are multiple contacts
          if (hasMultipleContacts) ...[
            const Divider(height: 12, thickness: 0.5),
            InkWell(
              onTap: _showAllContacts,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people, size: 12, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      'View All ${_emergencyContacts.length} Contacts',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAllContacts() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Emergency Contacts'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _emergencyContacts.length,
                itemBuilder: (context, index) {
                  final contact = _emergencyContacts[index];
                  return ListTile(
                    title: Text(contact.name),
                    subtitle: Text(contact.phoneNumber),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () async {
                            final url = 'tel:${contact.phoneNumber}';
                            if (await url_launcher.canLaunch(url)) {
                              await url_launcher.launch(url);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.message, color: Colors.blue),
                          onPressed: () async {
                            final url = 'sms:${contact.phoneNumber}';
                            if (await url_launcher.canLaunch(url)) {
                              await url_launcher.launch(url);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildLoadingIndicator({
    Color color = Colors.orange,
    String message = 'Loading...',
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 12),
          Text(message, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildNoContactsMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          const Text(
            'No emergency contacts available',
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  void _fetchEmergencyContacts() async {
    if (widget.responderId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Get emergency contacts
      final contacts = await appProvider.getEmergencyContactsForUser(
        widget.responderId,
      );

      if (mounted) {
        setState(() {
          _emergencyContacts = contacts;
          _isLoading = false;
        });

        // If no contacts are found, show a message
        if (contacts.isEmpty) {
          debugPrint(
            'No emergency contacts found for responder: ${widget.responderId}',
          );
          Future.microtask(() {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No emergency contacts available for this responder',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching emergency contacts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        Future.microtask(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error fetching emergency contacts: $e'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    }
  }

  // Shows a dialog with direct contact options
  void _showDirectContactDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Contact Donor Directly"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Due to a technical issue, automatic donation acceptance is not available. "
                  "Please contact ${widget.responderName} directly:",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.call, color: Colors.green),
                  title: const Text("Call"),
                  subtitle: Text(widget.responderPhone),
                  onTap: () {
                    Navigator.pop(context);
                    _makePhoneCall(widget.responderPhone);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.message, color: Colors.blue),
                  title: const Text("Send SMS"),
                  subtitle: Text(widget.responderPhone),
                  onTap: () {
                    Navigator.pop(context);
                    _sendSMS(widget.responderPhone);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CLOSE"),
              ),
            ],
          ),
    );
  }

  // Format timestamp to a readable format
  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        // Format as date if older than 30 days
        final month = date.month.toString().padLeft(2, '0');
        final day = date.day.toString().padLeft(2, '0');
        final year = date.year;
        return '$month/$day/$year';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }

  // Fetch health questionnaire data for the responder
  Future<void> _fetchHealthQuestionnaireData() async {
    if (widget.responderId.isEmpty ||
        widget.responderId == 'unknown_responder') {
      debugPrint('Cannot fetch health questionnaire data: invalid responderId');
      return;
    }

    setState(() {
      _loadingHealthQuestionnaire = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Fetch health questionnaire data from the provider
      final data = await appProvider.getHealthQuestionnaireData(
        widget.responderId,
      );

      if (mounted) {
        setState(() {
          _healthQuestionnaireData = data;
          _loadingHealthQuestionnaire = false;
        });

        debugPrint('Fetched health questionnaire data: $data');

        if (data == null || data.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No health questionnaire data available for this donor',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching health questionnaire data: $e');
      if (mounted) {
        setState(() {
          _loadingHealthQuestionnaire = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching health questionnaire data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build health questionnaire section
  Widget _buildHealthQuestionnaireSection() {
    if (_healthQuestionnaireData == null || _healthQuestionnaireData!.isEmpty) {
      return _buildNoHealthDataMessage();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with title and timestamp - fixed layout to prevent overflow
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.health_and_safety,
                  color: Colors.teal,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              // Make title text flexible to prevent overflow
              const Expanded(
                child: Text(
                  'Health Questionnaire',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.teal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              // Timestamp in compact format
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.update, size: 10, color: Colors.grey[600]),
                    const SizedBox(width: 2),
                    Text(
                      _formatDate(
                        _healthQuestionnaireData!['lastUpdated'] ??
                            DateTime.now().toString(),
                      ),
                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 0.5),
          // Content area with scrolling
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildHealthQuestionnaireContent(),
            ),
          ),
        ],
      ),
    );
  }

  // Build the content of the health questionnaire with grouped sections
  Widget _buildHealthQuestionnaireContent() {
    final data = _healthQuestionnaireData!;

    // Group data into categories for better organization
    final Map<String, List<Widget>> categories = {
      'General': <Widget>[],
      'Medical': <Widget>[],
      'Lifestyle': <Widget>[],
      'Other': <Widget>[],
    };

    // General health status
    if (data.containsKey('generalHealth')) {
      categories['General']!.add(
        _buildHealthStatusCard(data['generalHealth'] ?? 'Not provided'),
      );
    }

    // Last donation date
    if (data.containsKey('lastDonationDate') &&
        data['lastDonationDate'] != null) {
      categories['General']!.add(
        _buildInfoCard(
          title: 'Last Donation',
          value: _formatDate(data['lastDonationDate']),
          icon: Icons.calendar_today,
          color: Colors.blue,
        ),
      );
    }

    // Medical conditions, medications, and allergies (Medical category)
    List<Map<String, dynamic>> medicalItems = [
      {
        'key': 'medicalConditions',
        'title': 'Medical Conditions',
        'icon': Icons.medical_services,
        'color': Colors.red,
      },
      {
        'key': 'medications',
        'title': 'Current Medications',
        'icon': Icons.medication,
        'color': Colors.orange,
      },
      {
        'key': 'allergies',
        'title': 'Allergies',
        'icon': Icons.warning,
        'color': Colors.amber,
      },
    ];

    for (var item in medicalItems) {
      if (data.containsKey(item['key'])) {
        final value = data[item['key']];
        if (value != null &&
            (value is String && value.isNotEmpty ||
                value is List && value.isNotEmpty)) {
          final displayValue =
              value is List ? value.join(', ') : value.toString();
          categories['Medical']!.add(
            _buildInfoCard(
              title: item['title'],
              value: displayValue,
              icon: item['icon'],
              color: item['color'],
            ),
          );
        }
      }
    }

    // Lifestyle information
    if (data.containsKey('lifestyle')) {
      final lifestyle = data['lifestyle'];
      if (lifestyle is Map && lifestyle.isNotEmpty) {
        lifestyle.forEach((key, value) {
          if (value != null) {
            categories['Lifestyle']!.add(
              _buildInfoCard(
                title: key
                    .toString()
                    .replaceFirst(key[0], key[0].toUpperCase())
                    .replaceAll('_', ' '),
                value: value.toString(),
                icon: _getLifestyleIcon(key.toString()),
                color: Colors.green,
              ),
            );
          }
        });
      }
    }

    // Other health information
    data.forEach((key, value) {
      if (![
            'generalHealth',
            'medicalConditions',
            'medications',
            'allergies',
            'lastDonationDate',
            'lifestyle',
            'lastUpdated',
          ].contains(key) &&
          value != null) {
        categories['Other']!.add(
          _buildInfoCard(
            title: key
                .toString()
                .replaceFirst(key[0], key[0].toUpperCase())
                .replaceAll('_', ' '),
            value: value.toString(),
            icon: Icons.info_outline,
            color: Colors.blueGrey,
          ),
        );
      }
    });

    // Build the final layout with sections
    List<Widget> sectionWidgets = [];

    // Add sections that have content
    categories.forEach((title, items) {
      if (items.isNotEmpty) {
        sectionWidgets.add(_buildSection(title, items));
      }
    });

    // If no sections were added, show a message
    if (sectionWidgets.isEmpty) {
      sectionWidgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Center(
            child: Text(
              'No detailed health information available',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sectionWidgets,
    );
  }

  // Build a section with title and items
  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        ...items,
        const SizedBox(height: 8),
      ],
    );
  }

  // Build a special card for health status
  Widget _buildHealthStatusCard(String status) {
    // Determine color based on status
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'excellent':
      case 'very good':
        statusColor = Colors.green;
        statusIcon = Icons.sentiment_very_satisfied;
        break;
      case 'good':
        statusColor = Colors.lightGreen;
        statusIcon = Icons.sentiment_satisfied;
        break;
      case 'fair':
        statusColor = Colors.amber;
        statusIcon = Icons.sentiment_neutral;
        break;
      case 'poor':
        statusColor = Colors.orange;
        statusIcon = Icons.sentiment_dissatisfied;
        break;
      default:
        statusColor = Colors.blueGrey;
        statusIcon = Icons.favorite;
    }

    return Card(
      elevation: 0,
      color: statusColor.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: statusColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General Health Status',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build an info card for health data items
  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get appropriate icon for lifestyle items
  IconData _getLifestyleIcon(String key) {
    switch (key.toLowerCase()) {
      case 'smoking':
        return Icons.smoking_rooms;
      case 'alcohol':
        return Icons.liquor;
      case 'exercise':
        return Icons.fitness_center;
      case 'diet':
        return Icons.restaurant;
      case 'sleep':
        return Icons.nightlight;
      default:
        return Icons.person;
    }
  }

  // Build message for when no health data is available
  Widget _buildNoHealthDataMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline, size: 20, color: Colors.teal),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Health Data Available',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This donor has not provided any health questionnaire information.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Function to show contact options in a bottom sheet
  void _showContactOptionsSheet() {
    setState(() {
      _showContactOptions = true;
    });

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.contact_phone,
                        color: AppConstants.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact ${widget.responderName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Blood Type: ${widget.bloodType}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Contact options
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call, color: Colors.green),
                  ),
                  title: const Text('Call Donor'),
                  subtitle: Text(widget.responderPhone),
                  onTap: () {
                    Navigator.pop(context);
                    _makePhoneCall(widget.responderPhone);
                  },
                ),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.message, color: Colors.blue),
                  ),
                  title: const Text('Send SMS'),
                  subtitle: Text(widget.responderPhone),
                  onTap: () {
                    Navigator.pop(context);
                    _sendSMS(widget.responderPhone);
                  },
                ),

                if (_responderDetails?.email != null &&
                    _responderDetails!.email.isNotEmpty)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.email, color: Colors.orange),
                    ),
                    title: const Text('Send Email'),
                    subtitle: Text(_responderDetails!.email),
                    onTap: () async {
                      Navigator.pop(context);
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: _responderDetails!.email,
                        queryParameters: {
                          'subject': 'Blood Donation Coordination',
                          'body':
                              'Hello ${widget.responderName},\n\nThank you for responding to my blood request...',
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
                    },
                  ),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.content_copy, color: Colors.purple),
                  ),
                  title: const Text('Copy Phone Number'),
                  subtitle: Text(widget.responderPhone),
                  onTap: () {
                    Navigator.pop(context);
                    _copyToClipboard(widget.responderPhone, 'Phone number');
                  },
                ),

                // Emergency contacts section if available
                if (_emergencyContacts.isNotEmpty) ...[
                  const Divider(height: 32),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      'Emergency Contacts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  ..._emergencyContacts
                      .take(2)
                      .map(
                        (contact) => ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.contact_emergency,
                              color: Colors.red,
                            ),
                          ),
                          title: Text(contact.name),
                          subtitle: Text(contact.phoneNumber),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.call,
                                  color: Colors.green,
                                ),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final Uri phoneUri = Uri(
                                    scheme: 'tel',
                                    path: contact.phoneNumber,
                                  );
                                  await url_launcher.launchUrl(phoneUri);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.message,
                                  color: Colors.blue,
                                ),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final Uri smsUri = Uri(
                                    scheme: 'sms',
                                    path: contact.phoneNumber,
                                  );
                                  await url_launcher.launchUrl(smsUri);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (_emergencyContacts.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8),
                      child: TextButton.icon(
                        icon: const Icon(Icons.people, size: 16),
                        label: Text(
                          'View All ${_emergencyContacts.length} Contacts',
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showAllContacts();
                        },
                      ),
                    ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _showContactOptions = false;
        });
      }
    });
  }
}
