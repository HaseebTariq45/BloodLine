import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../models/blood_request_model.dart';
import '../models/donation_model.dart';
import '../models/notification_model.dart';
import '../utils/theme_helper.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/request_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/donation_card.dart';
import '../widgets/contact_info_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationTrackingScreen extends StatefulWidget {
  final int? initialIndex;
  final int? subTabIndex;

  const DonationTrackingScreen({
    super.key,
    this.initialIndex,
    this.subTabIndex,
  });

  @override
  State<DonationTrackingScreen> createState() => _DonationTrackingScreenState();
}

class _DonationTrackingScreenState extends State<DonationTrackingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _mainTabController;
  late TabController _donationsTabController;
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Add filter options
  String? _selectedBloodType;
  final List<String> _bloodTypes = [
    'All Types',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.subTabIndex ?? 0,
    );
    _mainTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex ?? 0,
    );
    _donationsTabController = TabController(length: 2, vsync: this);
    _loadData();

    // Listen for search changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Add listeners for tab animations
    _mainTabController.addListener(_handleTabAnimation);
    _tabController.addListener(_handleTabAnimation);
    _donationsTabController.addListener(_handleTabAnimation);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabAnimation);
    _mainTabController.removeListener(_handleTabAnimation);
    _donationsTabController.removeListener(_handleTabAnimation);
    _tabController.dispose();
    _mainTabController.dispose();
    _donationsTabController.dispose();
    super.dispose();
  }

  // Handle tab controller animations
  void _handleTabAnimation() {
    // This forces a repaint when the tab animation occurs
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUserId = appProvider.currentUser.id;

      // Log information for debugging
      debugPrint(
        'DonationTrackingScreen - _loadData() - Loading data for user ID: $currentUserId',
      );

      // Verify if user ID is valid
      if (currentUserId.isEmpty || currentUserId == 'user123') {
        debugPrint('DonationTrackingScreen - Invalid user ID: $currentUserId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cannot load donation data: User not properly authenticated',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Verify Firestore collections exist
      try {
        // Check blood_requests collection for pending requests
        final pendingRequestsQuery =
            await FirebaseFirestore.instance
                .collection('blood_requests')
                .where('requesterId', isEqualTo: currentUserId)
                .where('status', isEqualTo: 'Pending')
                .limit(1)
                .get();

        debugPrint(
          'DonationTrackingScreen - pending blood_requests check - Query returned ${pendingRequestsQuery.docs.length} documents',
        );

        // Check blood_requests collection for in-progress requests
        final inProgressRequestsQuery =
            await FirebaseFirestore.instance
                .collection('blood_requests')
                .where('requesterId', isEqualTo: currentUserId)
                .where('status', whereIn: ['Accepted', 'Scheduled'])
                .limit(1)
                .get();

        debugPrint(
          'DonationTrackingScreen - in-progress blood_requests check - Query returned ${inProgressRequestsQuery.docs.length} documents',
        );

        // Check blood_requests collection for completed requests
        final completedRequestsQuery =
            await FirebaseFirestore.instance
                .collection('blood_requests')
                .where('requesterId', isEqualTo: currentUserId)
                .where('status', isEqualTo: 'Completed')
                .limit(1)
                .get();

        debugPrint(
          'DonationTrackingScreen - completed blood_requests check - Query returned ${completedRequestsQuery.docs.length} documents',
        );

        // Check donations collection
        final donationsQuery =
            await FirebaseFirestore.instance
                .collection('donations')
                .where('recipientId', isEqualTo: currentUserId)
                .limit(1)
                .get();

        debugPrint(
          'DonationTrackingScreen - donations collection check - Query returned ${donationsQuery.docs.length} documents',
        );

        // Also check if user is a donor
        final donorQuery =
            await FirebaseFirestore.instance
                .collection('donations')
                .where('donorId', isEqualTo: currentUserId)
                .limit(1)
                .get();

        debugPrint(
          'DonationTrackingScreen - donor check - Query returned ${donorQuery.docs.length} documents',
        );
      } catch (e) {
        debugPrint('DonationTrackingScreen - Error checking collections: $e');
      }

      // Data will be loaded via StreamBuilder in the widget tree
      debugPrint('DonationTrackingScreen - Initial data check completed');
    } catch (e) {
      debugPrint(
        'DonationTrackingScreen - Error loading donation tracking data: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method to build info rows for request details
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$title:',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Format date to readable string
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return dateStr;
    }
  }

  // Contact recipient with phone or messaging app
  void _contactRecipient(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      // Show an error message if no phone number is available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No contact number available for this person'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Format the phone number to ensure it works with URI schemes
    final formattedNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    
    // Show contact options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ContactInfoModal(
        name: 'Contact',
        phone: formattedNumber,
        title: 'Contact Information',
        onCallPressed: () {
          _launchUrl('tel:$formattedNumber');
        },
        onMessagePressed: () {
          _launchUrl('sms:$formattedNumber');
        },
      ),
    );
  }

  // Cancel a blood request
  Future<void> _cancelRequest(String requestId) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Cancel Request'),
              content: const Text(
                'Are you sure you want to cancel this request?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      // Update the request status in Firestore
      await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(requestId)
          .update({
            'status': 'Cancelled',
            'cancellationDate': DateTime.now().toIso8601String(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error cancelling request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show completion dialog
  Future<void> _showCompletionDialog(BloodRequestModel request) async {
    final TextEditingController notesController = TextEditingController();
    final currentUserId =
        Provider.of<AppProvider>(context, listen: false).currentUser.id;
    final bool isRequester = request.requesterId == currentUserId;
    final bool isDonor = request.responderId == currentUserId;

    try {
      // Validate the current status of the request
      if (!_isValidRequestStatus(request.status) ||
          !['Accepted', 'Scheduled'].contains(request.status)) {
        throw Exception(
          'Cannot complete request: Invalid status ${request.status}',
        );
      }

      final completed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(isRequester ? 'Mark as Done' : 'Mark as Complete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRequester
                        ? 'Confirm that this blood donation has been completed?'
                        : 'Have you completed this blood donation? This will move the donation to history.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isRequester ? 'Mark Done' : 'Mark Complete'),
                ),
              ],
            ),
      );

      if (completed != true) return;

      // Use a transaction to update both request and donation atomically
      final firestore = FirebaseFirestore.instance;
      await firestore.runTransaction((transaction) async {
        // 1. Update the blood request status to Completed
        final requestRef = firestore
            .collection('blood_requests')
            .doc(request.id);
        transaction.update(requestRef, {
          'status': 'Completed',
          'completionDate': DateTime.now().toIso8601String(),
          'completionNotes': notesController.text,
        });

        // 2. Update the donation record if it exists
        final donationId = 'donation_${request.id}';
          final donationRef = firestore.collection('donations').doc(donationId);
          transaction.update(donationRef, {
            'status': 'Completed',
            'completionDate': DateTime.now().toIso8601String(),
            'notes': notesController.text,
            'location': request.location,
          });
      });

      // 3. If the current user is the donor, update their last donation date
      if (isDonor) {
        try {
          final appProvider = Provider.of<AppProvider>(context, listen: false);
          final currentUser = appProvider.currentUser;
          final now = DateTime.now();
          
          // Update the user's lastDonationDate and neverDonatedBefore in Firestore atomically
          await firestore.collection('users').doc(currentUserId).update({
            'lastDonationDate': now.millisecondsSinceEpoch,
            'isAvailableToDonate': false, // Explicitly set to false since they just donated
            'neverDonatedBefore': false,   // Update this flag to show they have donated
          });
          
          // Update the user model in the app provider with the new donation date
          // and set availability to false since they just donated
          final updatedUser = currentUser.copyWith(
            lastDonationDate: now,
            isAvailableToDonate: false,
            neverDonatedBefore: false,     // Update in the model too
          );
          await appProvider.updateUserProfile(updatedUser);
          
          // Verify both fields were updated correctly
          final verifyUpdate = await firestore.collection('users').doc(currentUserId).get();
          if (verifyUpdate.exists) {
            final data = verifyUpdate.data();
            if (data != null && data['neverDonatedBefore'] == true) {
              // Try one more time with a direct update if the field wasn't properly updated
              await firestore.collection('users').doc(currentUserId).update({
                'neverDonatedBefore': false,
              });
              debugPrint('Had to fix neverDonatedBefore flag with a second attempt');
            }
          }
          
          // Force sync the donation availability status to ensure the UI updates
          await appProvider.syncDonationAvailability();
          
          // Refresh the provider to ensure UI updates
          appProvider.notifyListeners();
          
          debugPrint('Updated donor\'s donation status: lastDonationDate=${now.toString()}, neverDonatedBefore=false');
        } catch (e) {
          debugPrint('Error updating last donation date: $e');
          // Don't throw - we've already completed the donation successfully
          // But log this error for monitoring
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Donation marked complete, but failed to update your eligibility status: $e'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      // 4. Send notification to the other party
      try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final currentUser = appProvider.currentUser;
        
        // Determine the recipient of the notification (opposite of the current user)
        final String recipientId = isDonor ? request.requesterId : request.responderId!;
        final String completionDateStr = DateTime.now().toIso8601String();
        
        // Create notification model with consistent metadata structure
        final notification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: recipientId,
          title: 'Blood Donation Completed',
          body: isDonor 
              ? '${currentUser.name} has marked your blood donation request as complete'
              : '${currentUser.name} has confirmed receiving your blood donation',
          type: 'donation_completed',
          read: false,
          createdAt: completionDateStr,
          metadata: {
            'requestId': request.id,
            'donationId': 'donation_${request.id}',
            'completedBy': currentUserId,
            'completedByName': currentUser.name,
            'completionDate': completionDateStr,
            'notes': notesController.text.trim(),
            'bloodType': request.bloodType,
            'location': request.location,
          },
        );

        // Send notification
        await appProvider.sendNotification(notification);
        
        debugPrint('Sent donation completion notification to user: $recipientId');
      } catch (e) {
        debugPrint('Error sending completion notification: $e');
        // Don't throw - we've already completed the donation successfully
        // But log this for monitoring
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Donation marked complete, but notification failed to send: $e'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRequester
                  ? 'Donation marked as done!'
                  : 'Donation marked as complete!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking donation as complete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update donation status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Cancel a donation
  Future<void> _cancelDonation(String donationId) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Cancel Donation'),
              content: const Text(
                'Are you sure you want to cancel this donation? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No, Keep It'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Yes, Cancel'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      setState(() {
        _isLoading = true;
      });

      // Get the donation data first
      final donationDoc =
          await FirebaseFirestore.instance
              .collection('donations')
              .doc(donationId)
              .get();

      if (!donationDoc.exists) {
        throw Exception('Donation not found');
      }

      final donationData = donationDoc.data() as Map<String, dynamic>;

      // Check if this donation is linked to a request
      if (donationData.containsKey('requestId') &&
          donationData['requestId'] != null) {
        final requestId = donationData['requestId'];

        // Update the request status back to pending
        await FirebaseFirestore.instance
            .collection('blood_requests')
            .doc(requestId)
            .update({
              'status': 'Pending',
              'responderId': null,
              'responderName': null,
              'responderPhone': null,
              'responseDate': null,
            });
      }

      // Update the donation status
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({
            'status': 'Cancelled',
            'cancellationDate': DateTime.now().toIso8601String(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error cancelling donation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel donation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Check if a request can be completed from its current status
  bool _isValidRequestStatus(String status) {
    // Valid statuses for completing a request
    final validStatuses = ['Accepted', 'Scheduled', 'In Progress'];
    return validStatuses.contains(status);
  }

  bool _isValidDonationStatus(String status) {
    final validStatuses = ['Accepted', 'Scheduled', 'Completed', 'Cancelled'];
    return validStatuses.contains(status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Donation Tracking', showBackButton: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDonationDialog(context),
        child: const Icon(Icons.add),
        backgroundColor: AppConstants.primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Dashboard summary section with title and refresh button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Row(
                      children: [
                        Text(
                          'Donation Dashboard',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 18),
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                            });
                            _loadData().then((_) {
                              setState(() {
                                _isLoading = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dashboard refreshed'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            });
                          },
                          tooltip: 'Refresh dashboard',
                          color: AppConstants.primaryColor,
                        ),
                      ],
                    ),
                  ),
                  
                  // Animated Dashboard summary
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: _buildDashboardSummary(),
                  ),

                  // Search and filter in a row to save space
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Row(
                      children: [
                        // Search field
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: const TextStyle(fontSize: 14),
                              prefixIcon: const Icon(Icons.search, size: 18),
                              suffixIcon:
                                  _searchQuery.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                        },
                                      )
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Blood type filter dropdown
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).cardColor,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedBloodType ?? 'All Types',
                                isExpanded: true,
                                hint: const Text(
                                  'Blood Type',
                                  style: TextStyle(fontSize: 14),
                                ),
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  size: 18,
                                ),
                                items:
                                    _bloodTypes.map((String type) {
                                      return DropdownMenuItem<String>(
                                        value: type,
                                        child: Row(
                                          children: [
                                            _buildBloodTypeCircle(type),
                                            const SizedBox(width: 4),
                                            Text(
                                              type,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedBloodType =
                                        newValue == 'All Types'
                                            ? null
                                            : newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Custom tab bar with enhanced styling
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _mainTabController,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppConstants.primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.primaryColor.withOpacity(
                                  0.4,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor:
                              Theme.of(context).textTheme.bodyLarge?.color,
                          dividerColor: Colors.transparent,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          overlayColor:
                              MaterialStateProperty.resolveWith<Color?>((
                                Set<MaterialState> states,
                              ) {
                                if (states.contains(MaterialState.pressed)) {
                                  return Colors.transparent;
                                }
                                return null;
                              }),
                          splashFactory: NoSplash.splashFactory,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: [
                            Tab(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.receipt_long),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        'My Requests',
                                        style: TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Tab(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.volunteer_activism, size: 18),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        'My Donations',
                                        style: TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Tab content with animation
                  Expanded(
                    child: TabBarView(
                      controller: _mainTabController,
                      physics: const BouncingScrollPhysics(),
                      children: [_buildMyRequestsTab(), _buildMyDonationsTab()],
                    ),
                  ),
                ],
              ),
    );
  }

  // New dashboard summary widget with statistics
  Widget _buildDashboardSummary() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;
    final appProvider = Provider.of<AppProvider>(context);
    final userName = appProvider.currentUser.name;
    final userBloodType = appProvider.currentUser.bloodType;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('requesterId', isEqualTo: currentUserId)
              .snapshots(),
      builder: (context, requestsSnapshot) {
        // Get donations where user is a donor
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('donations')
              .where('donorId', isEqualTo: currentUserId)
              .snapshots(),
          builder: (context, donorSnapshot) {
            // Get donations where user is a recipient
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('donations')
                  .where('recipientId', isEqualTo: currentUserId)
                  .snapshots(),
              builder: (context, recipientSnapshot) {
                // Process request data
                int newRequestsCount = 0;
                int inProgressCount = 0;
                int completedCount = 0;

                if (requestsSnapshot.hasData) {
                  final requests = requestsSnapshot.data?.docs ?? [];
                  for (var doc in requests) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] as String;

                    if (status == 'New' || status == 'Pending') {
                      newRequestsCount++;
                    } else if (status == 'Accepted' || status == 'Scheduled') {
                      inProgressCount++;
                    } else if (status == 'Completed') {
                      completedCount++;
                    }
                  }
                }

                // Process donation data
                int donationsGiven = 0;
                int donationsReceived = 0;
                DateTime? lastDonationDate;

                if (donorSnapshot.hasData) {
                  final donations = donorSnapshot.data?.docs ?? [];
                  for (var doc in donations) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] as String?;
                    
                    if (status == 'Completed') {
                      donationsGiven++;
                      
                      // Check donation date
                      final donationDateStr = data['donationDate'] as String?;
                      if (donationDateStr != null) {
                        final donationDate = DateTime.tryParse(donationDateStr);
                        if (donationDate != null) {
                          if (lastDonationDate == null || donationDate.isAfter(lastDonationDate)) {
                            lastDonationDate = donationDate;
                          }
                        }
                      }
                    }
                  }
                }

                if (recipientSnapshot.hasData) {
                  final donations = recipientSnapshot.data?.docs ?? [];
                  for (var doc in donations) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] as String?;
                    
                    if (status == 'Completed') {
                      donationsReceived++;
                    }
                  }
                }

                // Calculate next eligible donation date
                DateTime? nextEligibleDate;
                if (lastDonationDate != null) {
                  // Typically, people can donate every 56 days (about 8 weeks)
                  nextEligibleDate = lastDonationDate.add(const Duration(days: 56));
                }

                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.primaryColor.withOpacity(0.9),
                        AppConstants.primaryColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Compact header with essential user info
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                        child: Row(
                          children: [
                            // Blood type circle - smaller
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 14,
                              child: Text(
                                userBloodType,
                                style: TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // User name and donation status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (lastDonationDate != null)
                                    Text(
                                      'Last: ${DateFormat('MMM d').format(lastDonationDate)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Eligibility badge - more compact
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: nextEligibleDate != null && 
                                           DateTime.now().isAfter(nextEligibleDate)
                                        ? Colors.lightGreenAccent
                                        : Colors.amber,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    nextEligibleDate != null && 
                                    DateTime.now().isAfter(nextEligibleDate)
                                        ? 'Ready'
                                        : nextEligibleDate != null
                                            ? '${DateFormat('MM/dd').format(nextEligibleDate)}'
                                            : 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Combined statistics in a single row - more compact
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Requests column
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Requests',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildCompactStatItem('New', newRequestsCount.toString(), Colors.amber),
                                        _buildCompactStatItem('Active', inProgressCount.toString(), Colors.lightBlue),
                                        _buildCompactStatItem('Done', completedCount.toString(), Colors.lightGreenAccent),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Donations column
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Donations',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildCompactStatItem('Given', donationsGiven.toString(), Colors.cyan),
                                        _buildCompactStatItem('Received', donationsReceived.toString(), Colors.pinkAccent),
                                        _buildCompactStatItem('Total', (donationsGiven + donationsReceived).toString(), Colors.purpleAccent),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // More compact stat item
  Widget _buildCompactStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Stat card for dashboard (Keep this for reference or in case it's used elsewhere)
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon in a circle
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 4),
          // Count with large font
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Title with small font
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Blood type circle badge for dropdown
  Widget _buildBloodTypeCircle(String bloodType) {
    Color circleColor;
    if (bloodType == 'All Types') {
      circleColor = Colors.grey;
    } else if (bloodType.contains('A')) {
      circleColor = Colors.blue;
    } else if (bloodType.contains('B')) {
      circleColor = Colors.red;
    } else if (bloodType.contains('AB')) {
      circleColor = Colors.purple;
    } else {
      circleColor = Colors.green;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleColor.withOpacity(0.2),
        border: Border.all(color: circleColor, width: 1.5),
      ),
      child: Center(
        child: Text(
          bloodType == 'All Types' ? 'All' : bloodType,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: circleColor,
          ),
        ),
      ),
    );
  }

  // Stat card for dashboard (Keep this for reference or in case it's used elsewhere)
  Widget _buildMyDonationsTab() {
    return Column(
      children: [
        // Sub-tab bar for My Donations with enhanced styling
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: TabBar(
                controller: _donationsTabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                isScrollable: false,
                labelPadding: EdgeInsets.zero,
                labelColor: AppConstants.primaryColor,
                unselectedLabelColor: Colors.grey.shade600,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pending_actions, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Accepted',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'History',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _donationsTabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildAcceptedDonationsTab(),
              _buildCompletedDonationsTab(),
            ],
          ),
        ),
      ],
    );
  }

  // Custom pull-to-refresh animation builder
  Widget _buildCustomRefreshIndicator({
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: Colors.white,
      color: AppConstants.primaryColor,
      strokeWidth: 3,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: child,
    );
  }

  Widget _buildInProgressResponsesTab() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;
    debugPrint(
      'DonationTrackingScreen - Building in-progress responses tab for user ID: $currentUserId',
    );

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('requesterId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'In Progress')
              .orderBy('requestDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        // Debug connection state
        debugPrint(
          'DonationTrackingScreen - In Progress responses - Connection state: ${snapshot.connectionState}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - In Progress responses - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data?.docs ?? [];

        // Apply search filter if needed
        final filteredRequests =
            _searchQuery.isEmpty
                ? requests
                : requests.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchableFields = [
                    data['bloodType']?.toString().toLowerCase() ?? '',
                    data['location']?.toString().toLowerCase() ?? '',
                    data['responderName']?.toString().toLowerCase() ?? '',
                  ];
                  return searchableFields.any(
                    (field) => field.contains(_searchQuery.toLowerCase()),
                  );
                }).toList();

        if (filteredRequests.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.hourglass_top,
            title:
                _searchQuery.isNotEmpty
                    ? 'No matching requests'
                    : 'No responses to your requests',
            message:
                _searchQuery.isNotEmpty
                    ? 'Try changing your search criteria'
                    : 'You don\'t have any responses to your blood donation requests yet.',
          );
        }

        return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingS,
            ),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              final requestData =
                  filteredRequests[index].data() as Map<String, dynamic>;
              final request = BloodRequestModel.fromMap(requestData);

              // Get responder info from the request data
              final responderName = requestData['responderName'] ?? 'Unknown';
              final responderPhone = requestData['responderPhone'] ?? 'N/A';
              final responderId = requestData['responderId'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shadowColor: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.07),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: context.isDarkMode
                          ? [
                              context.cardColor,
                              Colors.blue.withOpacity(0.08),
                            ]
                          : [
                              Colors.white,
                              Colors.blue.shade50.withOpacity(0.3),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            request.bloodType,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Response Received',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.location_on,
                          title: 'Location',
                          value: request.location,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.person,
                          title: 'Donor',
                          value: responderName,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.phone,
                          title: 'Contact',
                          value: responderPhone,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.calendar_today,
                          title: 'Request Date',
                          value: request.formattedDate,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _contactRecipient(responderPhone),
                                icon: const Icon(Icons.phone, size: 16),
                                label: const Text('Contact'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: BorderSide(
                                    color: Colors.blue,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _acceptResponse(request),
                                icon: const Icon(Icons.check_circle, size: 16),
                                label: const Text('Accept'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.successColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
        );
      },
    );
  }

  Widget _buildAcceptedRequestsTab() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('requesterId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'Accepted')
              .orderBy('requestDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - Accepted tab - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data?.docs ?? [];

        // Apply search filter if needed
        final filteredRequests =
            _searchQuery.isEmpty
                ? requests
                : requests.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchableFields = [
                    data['bloodType']?.toString().toLowerCase() ?? '',
                    data['location']?.toString().toLowerCase() ?? '',
                    data['responderName']?.toString().toLowerCase() ?? '',
                  ];
                  return searchableFields.any(
                    (field) => field.contains(_searchQuery.toLowerCase()),
                  );
                }).toList();

        if (filteredRequests.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.pending_actions,
            title:
                _searchQuery.isNotEmpty
                    ? 'No matching requests'
                    : 'No accepted requests',
            message:
                _searchQuery.isNotEmpty
                    ? 'Try changing your search criteria'
                    : 'You don\'t have any accepted blood donation requests.',
          );
        }

        return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingS,
            ),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              final requestData =
                  filteredRequests[index].data() as Map<String, dynamic>;
              final request = BloodRequestModel.fromMap(requestData);

              // Get responder info from the request data
              final responderName = requestData['responderName'] ?? 'Unknown';
              final responderPhone = requestData['responderPhone'] ?? 'N/A';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shadowColor: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.07),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: context.isDarkMode
                          ? [
                              context.cardColor,
                              Colors.black.withOpacity(0.08),
                            ]
                          : [
                              Colors.white,
                              Colors.grey.shade50,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text(
                      request.bloodType,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.location,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.person,
                          title: 'Donor',
                          value: responderName,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.phone,
                          title: 'Contact',
                          value: responderPhone,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.calendar_today,
                          title: 'Request Date',
                          value: request.formattedDate,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _contactRecipient(responderPhone),
                                icon: const Icon(Icons.phone, size: 16),
                                label: const Text('Contact'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppConstants.primaryColor,
                                  side: BorderSide(
                                    color: AppConstants.primaryColor,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showCompletionDialog(request),
                                icon: const Icon(Icons.check_circle, size: 16),
                                label: const Text('Mark as Done'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;
    debugPrint(
      'DonationTrackingScreen - Building completed tab for user ID: $currentUserId',
    );

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('requesterId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'Completed')
              .orderBy('requestDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - Completed requests - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data?.docs ?? [];

        // Apply search filter if needed
        final filteredRequests =
            _searchQuery.isEmpty
                ? requests
                : requests.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchableFields = [
                    data['bloodType']?.toString().toLowerCase() ?? '',
                    data['location']?.toString().toLowerCase() ?? '',
                    data['responderName']?.toString().toLowerCase() ?? '',
                  ];
                  return searchableFields.any(
                    (field) => field.contains(_searchQuery.toLowerCase()),
                  );
                }).toList();

        if (filteredRequests.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.check_circle,
            title:
                _searchQuery.isNotEmpty
                    ? 'No matching requests'
                    : 'No completed requests',
            message:
                _searchQuery.isNotEmpty
                    ? 'Try changing your search criteria'
                    : 'You don\'t have any completed blood requests yet.',
          );
        }

        return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingS,
            ),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              final requestData =
                  filteredRequests[index].data() as Map<String, dynamic>;
              final request = BloodRequestModel.fromMap(requestData);

            // Create a donation model from request data
            final donation = DonationModel(
              id: 'donation_${request.id}',
                donorId: request.responderId ?? '',
                donorName: request.responderName ?? 'Unknown Donor',
              bloodType: request.bloodType,
              date: request.requestDate,
              centerName: request.location,
              address: request.city,
                recipientId: currentUserId,
                recipientName: Provider.of<AppProvider>(context).currentUser.name,
                recipientPhone: Provider.of<AppProvider>(context).currentUser.phoneNumber ?? 'N/A',
              status: 'Completed',
            );

              return DonationCard(
                donation: donation,
                showActions: false,
                isDonor: false,
                onContactRecipient: () {
                  _contactRecipient(request.responderPhone ?? '');
                },
            );
          },
        );
      },
    );
  }

  // Show dialog to add a new donation
  void _showAddDonationDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final bloodTypeController = TextEditingController();
    final dateController = TextEditingController();
    final centerNameController = TextEditingController();
    final addressController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Donation'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Blood Type
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Blood Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    'A+',
                    'A-',
                    'B+',
                    'B-',
                    'AB+',
                    'AB-',
                    'O+',
                    'O-',
                  ].map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  )).toList(),
                  onChanged: (value) {
                    bloodTypeController.text = value ?? '';
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select blood type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      selectedDate = date;
                      dateController.text = DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                  child: TextFormField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    enabled: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a date';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Center Name
                TextFormField(
                  controller: centerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Center Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter center name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Address
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _addDonation(
                  bloodTypeController.text,
                  selectedDate,
                  centerNameController.text,
                  addressController.text,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Add a new donation to Firestore
  Future<void> _addDonation(
    String bloodType,
    DateTime date,
    String centerName,
    String address,
  ) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final user = appProvider.currentUser;

      // Create new donation model
      final donation = DonationModel(
        id: 'donation_${DateTime.now().millisecondsSinceEpoch}',
        donorId: user.id,
        donorName: user.name,
        bloodType: bloodType,
        date: date,
        centerName: centerName,
        address: address,
        status: 'Completed',
      );

      // Add to Firestore
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donation.id)
          .set(donation.toJson());

      // Update user's last donation date
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({
            'lastDonationDate': date.toIso8601String(),
          });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding donation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add donation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Schedule a donation
  Future<void> _scheduleDonation(DonationModel donation) async {
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Schedule Donation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select a date for your donation at ${donation.centerName}',
                ),
                SizedBox(height: 20),
                StatefulBuilder(
                  builder:
                      (context, setState) => ListTile(
                        title: Text('Date'),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy').format(selectedDate),
                        ),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 30)),
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                      ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, {'date': selectedDate});
                },
                child: Text('Schedule'),
              ),
            ],
          ),
    );

    if (result == null) return;

    try {
      // Update the donation with scheduled date and status
      final updatedDonation = donation.copyWith(
        date: result['date'],
        status: 'Scheduled',
      );

      // Start a transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get the donation document reference
        final donationRef = FirebaseFirestore.instance
            .collection('donations')
            .doc(donation.id);

        // Get corresponding request if this donation is linked to a request
        if (donation.recipientId.isNotEmpty) {
          final requestQuerySnapshot =
              await FirebaseFirestore.instance
                  .collection('blood_requests')
                  .where(
                    'responderId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                  )
                  .where('requesterId', isEqualTo: donation.recipientId)
                  .where('status', isEqualTo: 'Accepted')
                  .get();

          if (requestQuerySnapshot.docs.isNotEmpty) {
            final requestDoc = requestQuerySnapshot.docs.first;
            transaction.update(requestDoc.reference, {'status': 'Scheduled'});
          }
        }

        // Update the donation
        transaction.update(donationRef, {
          'date': result['date'].millisecondsSinceEpoch,
          'status': 'Scheduled',
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Donation scheduled successfully')),
      );
    } catch (e) {
      print('Error scheduling donation: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error scheduling donation: $e')));
    }
  }

  // Build tab for accepted donations (donations I've accepted as a donor)
  Widget _buildAcceptedDonationsTab() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;
    debugPrint(
      'DonationTrackingScreen - Building accepted donations tab for user ID: $currentUserId',
    );

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('responderId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'Accepted')
              .orderBy('requestDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - Accepted donations - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data?.docs ?? [];

        // Apply search filter if needed
        final filteredRequests =
            _searchQuery.isEmpty
                ? requests
                : requests.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchableFields = [
                    data['bloodType']?.toString().toLowerCase() ?? '',
                    data['location']?.toString().toLowerCase() ?? '',
                    data['requesterName']?.toString().toLowerCase() ?? '',
                  ];
                  return searchableFields.any(
                    (field) => field.contains(_searchQuery.toLowerCase()),
                  );
                }).toList();

        if (filteredRequests.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.volunteer_activism,
            title:
                _searchQuery.isNotEmpty
                    ? 'No matching donations'
                    : 'No accepted donations',
            message:
                _searchQuery.isNotEmpty
                    ? 'Try changing your search criteria'
                    : 'You haven\'t accepted any blood donation requests yet.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingS,
          ),
          itemCount: filteredRequests.length,
          itemBuilder: (context, index) {
            final requestData =
                filteredRequests[index].data() as Map<String, dynamic>;
            final request = BloodRequestModel.fromMap(requestData);

            // Create a donation model from request data
            final donation = DonationModel(
              id: 'donation_${request.id}',
              donorId: currentUserId,
              donorName: Provider.of<AppProvider>(context).currentUser.name,
              bloodType: request.bloodType,
              date: request.requestDate,
              centerName: request.location,
              address: request.city,
              recipientId: request.requesterId,
              recipientName: request.requesterName,
              recipientPhone: request.contactNumber,
              status: 'Accepted',
            );

            return DonationCard(
              donation: donation,
              showActions: true,
              isDonor: true,
              isAccepted: true,
              actionLabel: 'Mark as Complete',
              onAction: () {
                _showCompletionDialog(request);
              },
              onContactRecipient: () {
                _contactRecipient(request.contactNumber);
              },
              onCancel: () {
                _cancelDonation('donation_${request.id}');
              },
            );
          },
        );
      },
    );
  }

  // Build tab for completed donations history
  Widget _buildCompletedDonationsTab() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;
    debugPrint(
      'DonationTrackingScreen - Building completed donations tab for user ID: $currentUserId',
    );

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('responderId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'Completed')
              .orderBy('requestDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - Completed donations - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data?.docs ?? [];

        // Apply search filter if needed
        final filteredRequests =
            _searchQuery.isEmpty
                ? requests
                : requests.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchableFields = [
                    data['bloodType']?.toString().toLowerCase() ?? '',
                    data['location']?.toString().toLowerCase() ?? '',
                    data['requesterName']?.toString().toLowerCase() ?? '',
                  ];
                  return searchableFields.any(
                    (field) => field.contains(_searchQuery.toLowerCase()),
                  );
                }).toList();

        if (filteredRequests.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.history,
            title:
                _searchQuery.isNotEmpty
                    ? 'No matching donations'
                    : 'No completed donations',
            message:
                _searchQuery.isNotEmpty
                    ? 'Try changing your search criteria'
                    : 'You haven\'t completed any blood donations yet.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingS,
          ),
          itemCount: filteredRequests.length,
          itemBuilder: (context, index) {
            final requestData =
                filteredRequests[index].data() as Map<String, dynamic>;
            final request = BloodRequestModel.fromMap(requestData);

            // Create a donation model from request data
            final donation = DonationModel(
              id: 'donation_${request.id}',
              donorId: currentUserId,
              donorName: Provider.of<AppProvider>(context).currentUser.name,
              bloodType: request.bloodType,
              date: request.requestDate,
              centerName: request.location,
              address: request.city,
              recipientId: request.requesterId,
              recipientName: request.requesterName,
              recipientPhone: request.contactNumber,
              status: 'Completed',
            );

            return DonationCard(
              donation: donation,
              showActions: false,
              onContactRecipient: () {
                _contactRecipient(request.contactNumber);
              },
            );
          },
        );
      },
    );
  }

  // Empty placeholder for _buildToAcceptDonationsTab
  Widget _buildToAcceptDonationsTab() {
    return Center(
      child: Text('To Accept Donations'),
    );
  }

  // Accept a response from a donor
  Future<void> _acceptResponse(BloodRequestModel request) async {
    try {
      if (request.responderId == null || request.responderId!.isEmpty) {
        throw Exception('No responder ID found for this request');
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // Get the Firestore instance
      final firestore = FirebaseFirestore.instance;
      
      // Update request status to Accepted
      await firestore.collection('blood_requests').doc(request.id).update({
        'status': 'Accepted',
        'acceptedAt': DateTime.now().toIso8601String(),
      });

      // Create a donation entry for tracking
      final donationId = 'donation_${request.id}';
      await firestore.collection('donations').doc(donationId).set({
        'id': donationId,
        'donorId': request.responderId,
        'donorName': request.responderName,
        'recipientId': request.requesterId,
        'recipientName': request.requesterName,
        'recipientPhone': request.contactNumber,
        'bloodType': request.bloodType,
        'date': DateTime.now().toIso8601String(),
        'status': 'Accepted',
        'requestId': request.id,
        'location': request.location,
      });

      // Send notification to donor
      await appProvider.acceptBloodRequestResponse(request.id, request.responderId!);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have accepted ${request.responderName}\'s response'),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept response: $e'),
            backgroundColor: AppConstants.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      debugPrint('Error accepting response: $e');
    }
  }

  // Launch URLs with proper error handling
  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch $urlString'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching contact method: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildMyRequestsTab() {
    return Column(
      children: [
        // Sub-tab bar for My Requests with enhanced styling
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                isScrollable: false,
                labelPadding: EdgeInsets.zero,
                labelColor: AppConstants.primaryColor,
                unselectedLabelColor: Colors.grey.shade600,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_top, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'In Progress',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pending_actions, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Accepted',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Completed',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildInProgressResponsesTab(),
              _buildAcceptedRequestsTab(),
              _buildCompletedTab(),
            ],
          ),
        ),
      ],
    );
  }
}
