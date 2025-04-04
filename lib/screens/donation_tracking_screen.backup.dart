import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../models/blood_request_model.dart';
import '../models/donation_model.dart';
import '../utils/theme_helper.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/request_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DonationTrackingScreen extends StatefulWidget {
  const DonationTrackingScreen({super.key});

  @override
  State<DonationTrackingScreen> createState() => _DonationTrackingScreenState();
}

class _DonationTrackingScreenState extends State<DonationTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    _tabController = TabController(length: 4, vsync: this);
    _loadData();

    // Listen for search changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
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
                .where('status', whereIn: ['Accepted', 'In Progress'])
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
                .where('status', isEqualTo: 'Fulfilled')
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Donation Tracking', showBackButton: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDonationDialog(context),
        child: const Icon(Icons.add),
        backgroundColor: AppConstants.primaryColor,
      ),
      body: Column(
        children: [
          // Search and filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search donations...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 8),
                // Blood type filter dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).cardColor,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBloodType ?? 'All Types',
                      isExpanded: true,
                      hint: const Text('Filter by Blood Type'),
                      icon: const Icon(Icons.arrow_drop_down),
                      items:
                          _bloodTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedBloodType =
                              newValue == 'All Types' ? null : newValue;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).cardColor,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor:
                    Theme.of(context).textTheme.bodyLarge?.color,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppConstants.primaryColor,
                ),
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pending_actions, size: 16),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Pending',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_top, size: 16),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'In Progress',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 16),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Completed',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.volunteer_activism, size: 16),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'My Donations',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingRequestsTab(),
                _buildInProgressTab(),
                _buildCompletedTab(),
                _buildMyDonationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsTab() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;
    debugPrint(
      'DonationTrackingScreen - Building pending requests tab for user ID: $currentUserId',
    );

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('requesterId', isEqualTo: currentUserId)
              .snapshots(),
      builder: (context, snapshot) {
        // Debug connection state
        debugPrint(
          'DonationTrackingScreen - Pending requests - Connection state: ${snapshot.connectionState}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - Pending requests - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Filter the documents in the client-side instead
        final allRequests = snapshot.data?.docs ?? [];
        final requests =
            allRequests.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'Pending';
            }).toList();

        // Sort manually by requestDate
        requests.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aDate =
              aData['requestDate'] != null
                  ? DateTime.parse(aData['requestDate'].toString())
                  : DateTime(1970);
          final bDate =
              bData['requestDate'] != null
                  ? DateTime.parse(bData['requestDate'].toString())
                  : DateTime(1970);

          return bDate.compareTo(aDate); // Sort descending
        });

        debugPrint(
          'DonationTrackingScreen - Pending requests - Loaded ${requests.length} requests (filtered from ${allRequests.length} total)',
        );

        if (requests.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.pending_actions,
            title: 'No pending requests',
            message: 'You don\'t have any pending blood donation requests.',
            actionLabel: 'Create Request',
            onAction: () {
              // Navigate to create request screen
              Navigator.pushNamed(context, '/create_blood_request');
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final requestData = requests[index].data() as Map<String, dynamic>;
            final request = BloodRequestModel.fromMap(requestData);

            return RequestCard(
              request: request,
              showActions: true,
              actionLabel: 'Edit Request',
              onAction: () {
                // Navigate to edit screen
              },
              onCancel: () {
                _cancelRequest(request.id);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInProgressTab() {
    final currentUserId = Provider.of<AppProvider>(context).currentUser.id;
    debugPrint(
      'DonationTrackingScreen - Building in-progress tab for user ID: $currentUserId',
    );

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('requesterId', isEqualTo: currentUserId)
              .snapshots(),
      builder: (context, snapshot) {
        // Debug connection state
        debugPrint(
          'DonationTrackingScreen - In progress requests - Connection state: ${snapshot.connectionState}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - In progress requests - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Filter the documents in the client-side instead
        final allRequests = snapshot.data?.docs ?? [];
        final requests =
            allRequests.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'Accepted' ||
                  data['status'] == 'In Progress';
            }).toList();

        // Sort manually by responseDate
        requests.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aDate =
              aData['responseDate'] != null
                  ? DateTime.parse(aData['responseDate'].toString())
                  : DateTime(1970);
          final bDate =
              bData['responseDate'] != null
                  ? DateTime.parse(bData['responseDate'].toString())
                  : DateTime(1970);

          return bDate.compareTo(aDate); // Sort descending
        });

        debugPrint(
          'DonationTrackingScreen - In progress requests - Loaded ${requests.length} requests (filtered from ${allRequests.length} total)',
        );

        if (requests.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.hourglass_top,
            title: 'No active donations',
            message: 'You don\'t have any donations in progress.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final requestData = requests[index].data() as Map<String, dynamic>;
            final request = BloodRequestModel.fromMap(requestData);

            // Get responder info from the request data
            final responderName = requestData['responderName'] ?? 'Unknown';
            final responderPhone = requestData['responderPhone'] ?? 'N/A';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request.bloodType,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Donation in Progress',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: context.textColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                      title: 'Response Date',
                      value: _formatDate(requestData['responseDate'] ?? ''),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _contactDonor(responderPhone),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showCompletionDialog(request),
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: const Text('Mark as Completed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
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
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    final appProvider = Provider.of<AppProvider>(context);
    final currentUserId = appProvider.currentUser.id;

    debugPrint(
      'DonationTrackingScreen - Building completed tab for user ID: $currentUserId',
    );

    if (currentUserId.isEmpty) {
      debugPrint('DonationTrackingScreen - Completed tab - User ID is empty');
      return const Center(
        child: Text('Please sign in to view your completed donations'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('requesterId', isEqualTo: currentUserId)
              .snapshots(),
      builder: (context, snapshot) {
        // Debug connection state
        debugPrint(
          'DonationTrackingScreen - Completed requests - Connection state: ${snapshot.connectionState}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - Completed requests - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Filter the documents in the client-side instead
        final allRequests = snapshot.data?.docs ?? [];
        final requests =
            allRequests.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'Fulfilled';
            }).toList();

        // Sort manually by completionDate
        requests.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aDate =
              aData['completionDate'] != null
                  ? DateTime.parse(aData['completionDate'].toString())
                  : DateTime(1970);
          final bDate =
              bData['completionDate'] != null
                  ? DateTime.parse(bData['completionDate'].toString())
                  : DateTime(1970);

          return bDate.compareTo(aDate); // Sort descending
        });

        debugPrint(
          'DonationTrackingScreen - Completed requests - Loaded ${requests.length} requests (filtered from ${allRequests.length} total)',
        );

        // Try alternate collection for donations directly
        if (requests.isEmpty) {
          debugPrint(
            'DonationTrackingScreen - No completed requests found, checking donations collection...',
          );
          return _buildDonationsStreamBuilder(currentUserId);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final requestData = requests[index].data() as Map<String, dynamic>;
            final request = BloodRequestModel.fromMap(requestData);

            // Get donor info from the request data
            final donorName = requestData['responderName'] ?? 'Unknown';

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request.bloodType,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Donation Completed',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: context.textColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Fulfilled',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            icon: Icons.person,
                            title: 'Donor',
                            value: donorName,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoRow(
                            icon: Icons.calendar_today,
                            title: 'Completed',
                            value: _formatDate(
                              requestData['completionDate'] ?? '',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (requestData['completionNotes'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Notes: ${requestData['completionNotes']}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: context.textColor.withOpacity(0.7),
                          ),
                        ),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  void _cancelRequest(String requestId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Request'),
            content: const Text(
              'Are you sure you want to cancel this blood request? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('No, Keep It'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
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
                          content: Text('Blood request cancelled successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to cancel request: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );
  }

  void _contactDonor(String phone) {
    // Show contact options dialog
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Contact Donor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call, color: Colors.green),
                ),
                title: const Text('Call'),
                subtitle: Text(phone),
                onTap: () {
                  Navigator.pop(context);
                  _makePhoneCall(phone);
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
                subtitle: Text(phone),
                onTap: () {
                  Navigator.pop(context);
                  _sendSMS(phone);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendSMS(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch messaging app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCompletionDialog(BloodRequestModel request) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Donation Completion'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Has the donor successfully completed the blood donation? This will mark the request as fulfilled and remove it from active requests.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Add any notes about the donation',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    () =>
                        _markRequestAsCompleted(request, notesController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm Completion'),
              ),
            ],
          ),
    );
  }

  Future<void> _markRequestAsCompleted(
    BloodRequestModel request,
    String notes,
  ) async {
    Navigator.of(context).pop(); // Close the dialog

    try {
      setState(() {
        _isLoading = true;
      });

      // Get current timestamp
      final completionDate = DateTime.now().toIso8601String();

      // Update the blood request status
      await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(request.id)
          .update({
            'status': 'Fulfilled',
            'completionDate': completionDate,
            'completionNotes': notes,
          });

      // Create a donation record
      final donationData = {
        'requestId': request.id,
        'donorId': request.responderId ?? '',
        'donorName': request.responderName ?? 'Unknown',
        'bloodType': request.bloodType,
        'date': completionDate,
        'centerName': '', // Can be updated if we have this info
        'address': request.location,
        'recipientId': request.requesterId,
        'recipientName': request.requesterName,
        'status': 'Completed',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('donations')
          .add(donationData);

      // Send a thank you notification to the donor
      final thankYouNotification = {
        'userId': request.responderId,
        'title': 'Thank You for Your Donation',
        'body':
            'Your blood donation has been confirmed. Thank you for saving lives!',
        'type': 'donation_completed',
        'read': false,
        'createdAt': completionDate,
        'metadata': {
          'requestId': request.id,
          'requesterName': request.requesterName,
          'requestBloodType': request.bloodType,
        },
      };

      await FirebaseFirestore.instance
          .collection('notifications')
          .add(thankYouNotification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation marked as completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking donation as completed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete donation: $e'),
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

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} minutes ago';
        }
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  // Update the _buildDonationsStreamBuilder method for the Completed tab
  Widget _buildDonationsStreamBuilder(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('donations')
              .where('recipientId', isEqualTo: userId)
              .snapshots(),
      builder: (context, snapshot) {
        debugPrint(
          'DonationTrackingScreen - Donations collection - Connection state: ${snapshot.connectionState}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - Donations collection - Error: ${snapshot.error}',
          );
          return Center(
            child: Text('Error loading donations: ${snapshot.error}'),
          );
        }

        // Filter the documents in the client-side instead
        final allDonations = snapshot.data?.docs ?? [];
        final donations =
            allDonations.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'Completed';
            }).toList();

        // Sort manually by date
        donations.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          DateTime aDate = DateTime(1970);
          DateTime bDate = DateTime(1970);

          try {
            if (aData['date'] is int) {
              aDate = DateTime.fromMillisecondsSinceEpoch(aData['date']);
            } else if (aData['date'] is String) {
              aDate = DateTime.parse(aData['date']);
            }

            if (bData['date'] is int) {
              bDate = DateTime.fromMillisecondsSinceEpoch(bData['date']);
            } else if (bData['date'] is String) {
              bDate = DateTime.parse(bData['date']);
            }
          } catch (e) {
            debugPrint('Error parsing date: $e');
          }

          return bDate.compareTo(aDate); // Sort descending
        });

        debugPrint(
          'DonationTrackingScreen - Donations collection - Loaded ${donations.length} donations (filtered from ${allDonations.length} total)',
        );

        if (donations.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.history,
            title: 'No completed donations',
            message: 'You don\'t have any completed donations yet.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final donationData =
                donations[index].data() as Map<String, dynamic>;
            final donation = DonationModel.fromJson(donationData);

            // Determine status color
            Color statusColor;
            String statusText;

            switch (donation.status.toLowerCase()) {
              case 'completed':
                statusColor = Colors.green;
                statusText = 'Completed';
                break;
              case 'pending':
                statusColor = Colors.orange;
                statusText = 'Pending';
                break;
              case 'cancelled':
                statusColor = Colors.red;
                statusText = 'Cancelled';
                break;
              default:
                statusColor = Colors.grey;
                statusText = donation.status;
            }

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            donation.bloodType,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Blood Donation',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: context.textColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      title: 'Donation Date',
                      value: donation.formattedDate,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.location_on,
                      title: 'Donation Center',
                      value: donation.centerName,
                    ),
                    if (donation.recipientName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.person,
                        title: 'Recipient',
                        value: donation.recipientName,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyDonationsTab() {
    final appProvider = Provider.of<AppProvider>(context);
    final currentUserId = appProvider.currentUser.id;

    debugPrint(
      'DonationTrackingScreen - Building my donations tab for user ID: $currentUserId',
    );

    if (currentUserId.isEmpty) {
      debugPrint(
        'DonationTrackingScreen - My donations tab - User ID is empty',
      );
      return const Center(child: Text('Please sign in to view your donations'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('donations')
              .where('donorId', isEqualTo: currentUserId)
              .snapshots(),
      builder: (context, snapshot) {
        // Debug connection state
        debugPrint(
          'DonationTrackingScreen - My donations - Connection state: ${snapshot.connectionState}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(
            'DonationTrackingScreen - My donations - Error: ${snapshot.error}',
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allDonations = snapshot.data?.docs ?? [];

        // Apply blood type filter if selected
        final filteredByBloodType =
            _selectedBloodType == null
                ? allDonations
                : allDonations.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['bloodType'] == _selectedBloodType;
                }).toList();

        // Apply search filter
        final donations =
            _searchQuery.isEmpty
                ? filteredByBloodType
                : filteredByBloodType.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchableFields = [
                    data['donorName']?.toString().toLowerCase() ?? '',
                    data['bloodType']?.toString().toLowerCase() ?? '',
                    data['centerName']?.toString().toLowerCase() ?? '',
                    data['recipientName']?.toString().toLowerCase() ?? '',
                    data['address']?.toString().toLowerCase() ?? '',
                  ];

                  return searchableFields.any(
                    (field) => field.contains(_searchQuery),
                  );
                }).toList();

        // Sort manually by date
        donations.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          DateTime aDate = DateTime(1970);
          DateTime bDate = DateTime(1970);

          try {
            if (aData['date'] is int) {
              aDate = DateTime.fromMillisecondsSinceEpoch(aData['date']);
            } else if (aData['date'] is String) {
              aDate = DateTime.parse(aData['date']);
            }

            if (bData['date'] is int) {
              bDate = DateTime.fromMillisecondsSinceEpoch(bData['date']);
            } else if (bData['date'] is String) {
              bDate = DateTime.parse(bData['date']);
            }
          } catch (e) {
            debugPrint('Error parsing date: $e');
          }

          return bDate.compareTo(aDate); // Sort descending
        });

        debugPrint(
          'DonationTrackingScreen - My donations - Loaded ${donations.length} donations after filtering from ${allDonations.length} total',
        );

        if (donations.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.volunteer_activism,
            title:
                _searchQuery.isNotEmpty || _selectedBloodType != null
                    ? 'No matching donations'
                    : 'No donations yet',
            message:
                _searchQuery.isNotEmpty || _selectedBloodType != null
                    ? 'Try changing your search or filter criteria'
                    : 'You haven\'t made any blood donations yet.',
            actionLabel: 'Find Requests',
            onAction: null,
          );
        }

        // For statistics, use all donations (before filtering)
        final completedDonations =
            allDonations.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'Completed';
            }).toList();

        // Calculate statistics
        final stats = _calculateDonationStats(completedDonations);

        return Column(
          children: [
            // Statistics cards
            if (completedDonations.isNotEmpty && _searchQuery.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildDonationStatsCards(stats),
              ),
              const SizedBox(height: 8),
            ],

            // Donations list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: donations.length,
                itemBuilder: (context, index) {
                  final donationData =
                      donations[index].data() as Map<String, dynamic>;
                  final donation = DonationModel.fromJson(donationData);

                  // Determine status color
                  Color statusColor;
                  String statusText;

                  switch (donation.status.toLowerCase()) {
                    case 'completed':
                      statusColor = Colors.green;
                      statusText = 'Completed';
                      break;
                    case 'pending':
                      statusColor = Colors.orange;
                      statusText = 'Pending';
                      break;
                    case 'cancelled':
                      statusColor = Colors.red;
                      statusText = 'Cancelled';
                      break;
                    default:
                      statusColor = Colors.grey;
                      statusText = donation.status;
                  }

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  donation.bloodType,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Blood Donation',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: context.textColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            title: 'Donation Date',
                            value: donation.formattedDate,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            icon: Icons.location_on,
                            title: 'Donation Center',
                            value: donation.centerName,
                          ),
                          if (donation.recipientName.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              icon: Icons.person,
                              title: 'Recipient',
                              value: donation.recipientName,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Add these methods for donation statistics
  Map<String, dynamic> _calculateDonationStats(
    List<QueryDocumentSnapshot> donations,
  ) {
    // Total donations completed
    final int totalDonations = donations.length;

    // Lives potentially saved (each donation can save up to 3 lives)
    final int livesPotentiallySaved = totalDonations * 3;

    // Blood types distribution
    final Map<String, int> bloodTypeCount = {};
    for (final doc in donations) {
      final data = doc.data() as Map<String, dynamic>;
      final bloodType = data['bloodType'] ?? 'Unknown';
      bloodTypeCount[bloodType] = (bloodTypeCount[bloodType] ?? 0) + 1;
    }

    // Donation frequency by month
    final Map<String, int> donationsByMonth = {};
    for (final doc in donations) {
      final data = doc.data() as Map<String, dynamic>;
      DateTime donationDate = DateTime(1970);

      try {
        if (data['date'] is int) {
          donationDate = DateTime.fromMillisecondsSinceEpoch(data['date']);
        } else if (data['date'] is String) {
          donationDate = DateTime.parse(data['date']);
        }

        final monthYear = DateFormat('MMM yyyy').format(donationDate);
        donationsByMonth[monthYear] = (donationsByMonth[monthYear] ?? 0) + 1;
      } catch (e) {
        debugPrint('Error parsing date for statistics: $e');
      }
    }

    // Calculate total blood volume donated (average 450ml per donation)
    final double bloodVolumeMl = totalDonations * 450;

    // Get most recent donation date
    DateTime? mostRecentDonation;
    for (final doc in donations) {
      final data = doc.data() as Map<String, dynamic>;

      try {
        DateTime donationDate;
        if (data['date'] is int) {
          donationDate = DateTime.fromMillisecondsSinceEpoch(data['date']);
        } else if (data['date'] is String) {
          donationDate = DateTime.parse(data['date']);
        } else {
          continue; // Skip if date can't be parsed
        }

        if (mostRecentDonation == null ||
            donationDate.isAfter(mostRecentDonation)) {
          mostRecentDonation = donationDate;
        }
      } catch (e) {
        debugPrint('Error parsing date for recent donation: $e');
      }
    }

    // Next eligible donation date (56 days after most recent)
    DateTime? nextEligibleDate;
    if (mostRecentDonation != null) {
      nextEligibleDate = mostRecentDonation.add(const Duration(days: 56));
    }

    return {
      'totalDonations': totalDonations,
      'livesSaved': livesPotentiallySaved,
      'bloodTypeCount': bloodTypeCount,
      'donationsByMonth': donationsByMonth,
      'bloodVolumeMl': bloodVolumeMl,
      'recentDonation': mostRecentDonation,
      'nextEligibleDate': nextEligibleDate,
    };
  }

  Widget _buildDonationStatsCards(Map<String, dynamic> stats) {
    final currentDate = DateTime.now();
    final nextEligibleDate = stats['nextEligibleDate'] as DateTime?;
    final isEligible =
        nextEligibleDate == null || nextEligibleDate.isBefore(currentDate);

    return Column(
      children: [
        // Main stats card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Donation Impact',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatItem(
                      icon: Icons.bloodtype,
                      value: stats['totalDonations'].toString(),
                      label: 'Donations',
                      color: AppConstants.primaryColor,
                    ),
                    _buildStatItem(
                      icon: Icons.favorite,
                      value: stats['livesSaved'].toString(),
                      label: 'Lives Saved',
                      color: Colors.red,
                    ),
                    _buildStatItem(
                      icon: Icons.water_drop,
                      value:
                          '${(stats['bloodVolumeMl'] / 1000).toStringAsFixed(1)}L',
                      label: 'Blood Volume',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Eligibility card
        if (stats['recentDonation'] != null)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isEligible
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEligible ? Icons.check_circle : Icons.hourglass_top,
                      color: isEligible ? Colors.green : Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEligible
                              ? 'You are eligible to donate again!'
                              : 'Next donation date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isEligible ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEligible
                              ? 'Find a donation request now'
                              : 'You can donate again on ${DateFormat('MMM dd, yyyy').format(nextEligibleDate!)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (isEligible)
                    TextButton(
                      onPressed: () {
                        // Navigate to blood requests screen
                        Navigator.of(context).pushNamed('/available_requests');
                      },
                      child: const Text('Find Requests'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // Add this method to show add donation dialog
  void _showAddDonationDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController centerController = TextEditingController();
    final TextEditingController addressController = TextEditingController();

    String selectedBloodType = 'A+';
    DateTime selectedDate = DateTime.now();

    dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Record Donation'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add a record for donations made at centers outside the app',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    // Blood type dropdown
                    DropdownButtonFormField<String>(
                      value: selectedBloodType,
                      decoration: const InputDecoration(
                        labelText: 'Blood Type',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          _bloodTypes.where((type) => type != 'All Types').map((
                            String type,
                          ) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          selectedBloodType = newValue;
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select blood type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Date picker
                    TextFormField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Donation Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null && picked != selectedDate) {
                              selectedDate = picked;
                              dateController.text = DateFormat(
                                'yyyy-MM-dd',
                              ).format(selectedDate);
                            }
                          },
                        ),
                      ),
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Donation center name
                    TextFormField(
                      controller: centerController,
                      decoration: const InputDecoration(
                        labelText: 'Donation Center Name',
                        hintText: 'e.g. City Blood Bank',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter donation center name';
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
                        hintText: 'Enter center address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    _addDonationRecord(
                      bloodType: selectedBloodType,
                      date: selectedDate,
                      centerName: centerController.text,
                      address: addressController.text,
                    );
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _addDonationRecord({
    required String bloodType,
    required DateTime date,
    required String centerName,
    required String address,
  }) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUser = appProvider.currentUser;

      // Create donation model
      final donation = DonationModel(
        id: 'donation_${DateTime.now().millisecondsSinceEpoch}',
        donorId: currentUser.id,
        donorName: currentUser.name,
        bloodType: bloodType,
        date: date,
        centerName: centerName,
        address: address,
        status: 'Completed',
      );

      // Add to Firestore
      await FirebaseFirestore.instance
          .collection('donations')
          .add(donation.toJson());

      // Update user's last donation date
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .update({'lastDonationDate': date.millisecondsSinceEpoch});

      // Refresh user data in the provider
      await appProvider.refreshUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation record added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding donation record: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add donation record: $e'),
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
}
