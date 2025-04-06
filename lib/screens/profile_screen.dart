import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/cities_data.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';
import '../utils/theme_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late String _bloodType;
  late String _city;
  late bool _isAvailableToDonate;
  bool _isEditing = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _userId;
  String? _phoneNumber;
  String? _address;
  String? _lastDonationDate;
  String _healthStatus = 'Healthy';
  Color _healthStatusColor = Colors.green;
  String? _nextDonationDate;

  // Health Questionnaire Data
  String? _height;
  String? _weight;
  String? _gender;
  bool _hasTattoo = false;
  bool _hasPiercing = false;
  bool _hasTraveled = false;
  bool _hasSurgery = false;
  bool _hasTransfusion = false;
  bool _hasPregnancy = false;
  bool _hasDisease = false;
  bool _hasMedication = false;
  bool _hasAllergies = false;
  String? _medications;
  String? _allergies;

  // List of available blood types
  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // Add private fields for health data
  String? _lastHealthCheck;
  String? _medicalConditions;
  String? _lastDonationLocation;
  int? _donationCount;
  bool _neverHadHealthCheck = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = appProvider.currentUser;

    _nameController = TextEditingController(text: currentUser.name);
    _emailController = TextEditingController(text: currentUser.email);
    _phoneController = TextEditingController(text: currentUser.phoneNumber);
    _phoneNumber = currentUser.phoneNumber;
    _addressController = TextEditingController(text: currentUser.address);
    _bloodType = currentUser.bloodType;
    _city = currentUser.city.isNotEmpty ? currentUser.city : 'Karachi';
    _isAvailableToDonate = currentUser.isAvailableToDonate;

    // Initialize health data
    _lastHealthCheck = null; // Will be fetched from Firestore
    _healthStatus = 'Healthy';
    _healthStatusColor = Colors.green;
    _medicalConditions = 'None';

    // Initialize donation data
    _lastDonationLocation = null; // Will be fetched from Firestore
    _nextDonationDate = null; // Will be calculated from user's last donation date
    _donationCount = null; // Will be calculated from donation history

    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    try {
    setState(() {
      _isLoading = true;
    });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userId = user.uid;

        // Load user profile data
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_userId)
                .get();

        if (!mounted) return;  // Check mounted after async operation

        if (userDoc.exists) {
          final data = userDoc.data()!;
          
          // Update controllers with null safety
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          
          // The field in Firestore is 'phoneNumber', not 'phone'
          final phoneValue = data['phoneNumber'] ?? '';
          _phoneController.text = phoneValue;
          _phoneNumber = phoneValue;
          debugPrint('Loaded phone number from Firestore: $phoneValue');
          
          _addressController.text = data['address'] ?? '';

          // Update other fields with null safety
          _bloodType = data['bloodType'] ?? 'Unknown';
          _city = data['city'] ?? 'Karachi';
          _address = data['address'];
          _isAvailableToDonate = data['isAvailableToDonate'] ?? true;

          // Handle lastDonationDate with better null safety
          if (data['lastDonationDate'] != null) {
            try {
              DateTime lastDonationDateTime;
              
              if (data['lastDonationDate'] is Timestamp) {
                lastDonationDateTime = (data['lastDonationDate'] as Timestamp).toDate();
                _lastDonationDate = lastDonationDateTime.toString().substring(0, 10);
              } else if (data['lastDonationDate'] is int) {
                lastDonationDateTime = DateTime.fromMillisecondsSinceEpoch(data['lastDonationDate'] as int);
                _lastDonationDate = lastDonationDateTime.toString().substring(0, 10);
              } else if (data['lastDonationDate'] is String) {
                lastDonationDateTime = DateTime.parse(data['lastDonationDate'] as String);
                _lastDonationDate = lastDonationDateTime.toString().substring(0, 10);
              } else {
                throw Exception('Unknown lastDonationDate format');
              }
              
              // Calculate next donation date (90 days after last donation)
              final nextEligibleDate = lastDonationDateTime.add(const Duration(days: 90));
              _nextDonationDate = nextEligibleDate.toString().substring(0, 10);
              
              // Debug output
              debugPrint('Last donation: $_lastDonationDate, Next eligible: $_nextDonationDate');
              
              // Fetch the location of the last donation
              if (mounted) {
                _fetchLastDonationLocation(user.uid);
              }
            } catch (e) {
              debugPrint('Error parsing lastDonationDate: $e');
              _lastDonationDate = null;
              _nextDonationDate = null;
            }
          } else if (data['neverDonatedBefore'] == true) {
            // Set appropriate values for users who never donated
            _lastDonationDate = 'Never donated before';
            _nextDonationDate = 'Eligible to donate';
            _lastDonationLocation = 'No donation history';
            debugPrint('User has never donated before');
          }
        }

        if (!mounted) return;  // Check mounted again

        // Load health questionnaire data with null safety
        try {
        final healthDoc =
            await FirebaseFirestore.instance
                .collection('health_questionnaires')
                .doc(_userId)
                .get();

          if (!mounted) return;  // Check mounted after async operation
                
          if (healthDoc.exists) {
          final data = healthDoc.data()!;

          setState(() {
            _height = data['height']?.toString();
            _weight = data['weight']?.toString();
            _gender = data['gender'];
            _hasTattoo = data['hasTattoo'] ?? false;
            _hasPiercing = data['hasPiercing'] ?? false;
            _hasTraveled = data['hasTraveled'] ?? false;
            _hasSurgery = data['hasSurgery'] ?? false;
            _hasTransfusion = data['hasTransfusion'] ?? false;
            _hasPregnancy = data['hasPregnancy'] ?? false;
            _hasDisease = data['hasDisease'] ?? false;
            _hasMedication = data['hasMedication'] ?? false;
            _hasAllergies = data['hasAllergies'] ?? false;
            _medications = data['medications'];
            _allergies = data['allergies'];

            // Determine health status
            _determineHealthStatus();
          });
          }
        } catch (e) {
          debugPrint('Error loading health questionnaire data: $e');
        }
        
        if (!mounted) return;  // Check mounted again
        
        // Sync availability status based on donation date when profile loads
        try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.syncDonationAvailability();
        } catch (e) {
          debugPrint('Error syncing availability: $e');
        }
        
        if (!mounted) return;  // Check mounted again
        
        // Load last health check data
        try {
          final healthDoc = await FirebaseFirestore.instance
              .collection('health_questionnaires')
              .doc(_userId)
              .get();
              
          if (!mounted) return;  // Check mounted after async operation
              
          if (healthDoc.exists && healthDoc.data() != null) {
            final healthData = healthDoc.data()!;
            
            // Check if user has indicated they never had a health check
            final bool neverHadHealthCheck = healthData['neverHadHealthCheck'] ?? false;
            
            setState(() {
              _neverHadHealthCheck = neverHadHealthCheck;
              
              if (neverHadHealthCheck) {
                _lastHealthCheck = 'Never had a health check';
              } else {
                // Get the last health check date if available
                final lastHealthCheckDate = healthData['lastHealthCheckDate'];
                _lastHealthCheck = lastHealthCheckDate != null && lastHealthCheckDate.isNotEmpty
                    ? lastHealthCheckDate
                    : 'Not available';
              }
            });
      }
    } catch (e) {
          debugPrint('Error loading health check data: $e');
        }

        if (!mounted) return;  // Check mounted again

        // After loading all data, check for inconsistencies and fix them
        try {
          final currentUser = Provider.of<AppProvider>(context, listen: false).currentUser;
          
          // Automatically fix inconsistencies (last donation date exists but neverDonatedBefore is true)
          if (currentUser.lastDonationDate != null && currentUser.neverDonatedBefore) {
            debugPrint('Found inconsistency in donation history, fixing automatically');
            await _fixDonationStatusInconsistency(_userId);
          }
        } catch (e) {
          debugPrint('Error checking for inconsistencies: $e');
        }

        if (!mounted) return;  // Check mounted again
        
        // Fetch donation count
        _fetchDonationCount(user.uid);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) {  // Only call setState if still mounted
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Determine health status based on questionnaire data
  void _determineHealthStatus() {
    bool hasRiskFactors =
        _hasTattoo ||
        _hasPiercing ||
        _hasTraveled ||
        _hasSurgery ||
        _hasTransfusion ||
        _hasPregnancy ||
        _hasDisease ||
        _hasMedication ||
        _hasAllergies;

    if (hasRiskFactors) {
      if (_hasTattoo || _hasPiercing) {
        _healthStatus = 'Possible Temp. Delay';
        _healthStatusColor = Colors.orange;
      } else if (_hasDisease || _hasTransfusion) {
        _healthStatus = 'Possible Permanent Deferral';
        _healthStatusColor = Colors.red.shade700;
      } else {
        _healthStatus = 'Needs Review';
        _healthStatusColor = Colors.blue.shade600;
      }
    } else {
      _healthStatus = 'Eligible';
      _healthStatusColor = Colors.green;
    }
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // Cancel editing - reset values
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final currentUser = appProvider.currentUser;

        _nameController.text = currentUser.name;
        // First try to use the current user's phone number, if empty use the cached _phoneNumber
        String phoneToUse = currentUser.phoneNumber.isNotEmpty ? currentUser.phoneNumber : (_phoneNumber ?? '');
        _phoneController.text = phoneToUse;
        print('Restoring phone number on cancel: $phoneToUse');
        
        _addressController.text = currentUser.address;
        _bloodType = currentUser.bloodType;
        _city = currentUser.city;
        _isAvailableToDonate = currentUser.isAvailableToDonate;
      } else {
        // Entering edit mode - Make sure phone controller has the current value
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final currentUser = appProvider.currentUser;
        
        // First try using the phone value from currentUser
        if (currentUser.phoneNumber.isNotEmpty) {
          _phoneController.text = currentUser.phoneNumber;
          _phoneNumber = currentUser.phoneNumber;
          print('Setting phone controller from currentUser in edit mode: ${currentUser.phoneNumber}');
        } 
        // If currentUser.phoneNumber is empty but we have a cached value, use that
        else if (_phoneNumber != null && _phoneNumber!.isNotEmpty) {
          _phoneController.text = _phoneNumber!;
          print('Setting phone controller from cached value in edit mode: $_phoneNumber');
        }
        // Otherwise, backup whatever is in the controller
        else {
          _phoneNumber = _phoneController.text;
          print('Backing up phone number before edit: $_phoneNumber');
        }
      }
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUser = appProvider.currentUser;

      // Update local cache of phone number
      _phoneNumber = _phoneController.text;
      print('Saving phone number: $_phoneNumber');

      // Create updated user
      final updatedUser = UserModel(
        id: currentUser.id,
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : (_phoneNumber ?? ''),
        address: _addressController.text,
        bloodType: _bloodType,
        city: _city,
        isAvailableToDonate: _isAvailableToDonate,
        lastDonationDate: currentUser.lastDonationDate,
        imageUrl: currentUser.imageUrl,
        location: currentUser.location,
      );

      // For debugging
      print('Updating user profile - phone: ${updatedUser.phoneNumber}');

      // Simulate network delay
      Future.delayed(const Duration(milliseconds: 800), () {
        // Note: In a real implementation, we would save the data to a database or API here
        // For now, we just update the local state
        appProvider.updateUserProfile(updatedUser);

        setState(() {
          _isLoading = false;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Profile updated successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      });
    } catch (e) {
      print('Error saving profile: $e');
      // Show error toast
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLastDonationLocation(String userId) async {
    try {
      // Simplify the query to avoid requiring an index
      final donationsQuery = await FirebaseFirestore.instance
          .collection('donations')
          .where('donorId', isEqualTo: userId)
          .where('status', isEqualTo: 'Completed')
          .get();
          
      if (!mounted) return;
      
      if (donationsQuery.docs.isNotEmpty) {
        // Sort manually instead of using orderBy to avoid requiring an index
        final sortedDocs = donationsQuery.docs.toList()
          ..sort((a, b) {
            // Get completion dates from documents
            final dateA = a.data()['completionDate'];
            final dateB = b.data()['completionDate'];
            
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            
            // Parse ISO dates and compare
            final dateTimeA = DateTime.tryParse(dateA);
            final dateTimeB = DateTime.tryParse(dateB);
            
            if (dateTimeA == null) return 1;
            if (dateTimeB == null) return -1;
            
            // Sort descending (newest first)
            return dateTimeB.compareTo(dateTimeA);
          });
        
        // Use the first (most recent) donation
        final latestDonation = sortedDocs.first.data();
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final currentUser = appProvider.currentUser;
        
        if (mounted) {
          setState(() {
            // Try to get location from the donation record
            if (latestDonation['location'] != null && latestDonation['location'].toString().isNotEmpty) {
              _lastDonationLocation = latestDonation['location'];
            } else if (latestDonation['bloodRequestId'] != null) {
              // If no location in donation, try to get it from the associated blood request
              // Don't return, so we still set a default value in case _fetchLocationFromBloodRequest fails
              _lastDonationLocation = 'Retrieving...';
              _fetchLocationFromBloodRequest(latestDonation['bloodRequestId']);
            } else {
              // Use the user's location as fallback
              _lastDonationLocation = '${currentUser.city} (from profile)';
              
              // Try to update the donation with this location
              _updateDonationLocation();
            }
            
            debugPrint('Last donation location from donations collection: $_lastDonationLocation');
          });
        }
      } else {
        // If no donations found, try blood_requests collection
        if (mounted) {
          setState(() {
            _lastDonationLocation = 'Unknown location';
          });
          _fetchLocationFromBloodRequests(userId);
        }
      }
    } catch (e) {
      debugPrint('Error fetching last donation location: $e');
      // Set a default value in case of error
      if (mounted) {
        setState(() {
          _lastDonationLocation = 'Location unavailable';
        });
      }
    }
  }

  Future<void> _fetchLocationFromBloodRequests(String userId) async {
    if (!mounted) return;
    
    try {
      // Search for completed blood requests where this user was the donor
      // Simplify query to avoid requiring index
      final requestsQuery = await FirebaseFirestore.instance
          .collection('blood_requests')
          .where('responderId', isEqualTo: userId)
          .where('status', isEqualTo: 'Completed')
          .get();
          
      if (!mounted) return;
          
      if (requestsQuery.docs.isNotEmpty) {
        // Sort manually
        final sortedDocs = requestsQuery.docs.toList()
          ..sort((a, b) {
            final dateA = a.data()['completionDate'];
            final dateB = b.data()['completionDate'];
            
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            
            return dateB.compareTo(dateA); // Sort descending
          });
          
        final latestRequest = sortedDocs.first.data();
        setState(() {
          _lastDonationLocation = latestRequest['location'] ?? 'Unknown';
          debugPrint('Last donation location from blood requests: $_lastDonationLocation');
        });
      } else {
        debugPrint('No completed requests found for donor $userId');
      }
    } catch (e) {
      debugPrint('Error fetching location from blood requests: $e');
    }
  }

  Future<void> _fetchLocationFromBloodRequest(String requestId) async {
    if (!mounted) return;
    
    try {
      final requestDoc = await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(requestId)
          .get();
          
      if (!mounted) return;
          
      if (requestDoc.exists && requestDoc.data() != null) {
        final requestData = requestDoc.data()!;
        setState(() {
          _lastDonationLocation = requestData['location'] ?? 'Unknown';
          debugPrint('Last donation location from request $requestId: $_lastDonationLocation');
        });
      }
    } catch (e) {
      debugPrint('Error fetching location from blood request: $e');
    }
  }

  Future<void> _fetchDonationCount(String userId) async {
    if (!mounted) return;
    
    try {
      final donationsQuery = await FirebaseFirestore.instance
          .collection('donations')
          .where('donorId', isEqualTo: userId)
          .where('status', isEqualTo: 'Completed')
          .get();
          
      if (!mounted) return;
      
      setState(() {
        _donationCount = donationsQuery.docs.length;
        debugPrint('Fetched donation count: $_donationCount');
      });
    } catch (e) {
      debugPrint('Error fetching donation count: $e');
    }
  }

  // Method to immediately fix the donation status inconsistency
  Future<void> _fixDonationStatusInconsistency(String? userId) async {
    if (!mounted) return;
    
    try {
      if (userId == null) {
        debugPrint('Cannot fix donation status: userId is null');
        return;
      }
      
      // Only fix if there's an inconsistency (lastDonationDate exists but neverDonatedBefore is true)
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      if (!mounted) return;
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        
        if (userData != null && 
            userData['lastDonationDate'] != null && 
            userData['neverDonatedBefore'] == true) {
          
          // Update Firestore
          await userRef.update({'neverDonatedBefore': false});
          
          if (!mounted) return;
          
          // Update local model
          final appProvider = Provider.of<AppProvider>(context, listen: false);
          final currentUser = appProvider.currentUser;
          final updatedUser = currentUser.copyWith(neverDonatedBefore: false);
          await appProvider.updateUserProfile(updatedUser);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Donation history status fixed'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          setState(() {
            // Reload UI
            _loadUserData();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fixing donation status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fixing donation status: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Method to update donation location from user's profile
  Future<void> _updateDonationLocation() async {
    if (!mounted) return;
    
    try {
      if (_userId == null) {
        debugPrint('Cannot update donation location: userId is null');
        return;
      }
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUser = appProvider.currentUser;
      
      // Get user's address and city for location
      final userLocation = '${currentUser.address}, ${currentUser.city}';
      
      // Find all donations for this user
      final donationsQuery = await FirebaseFirestore.instance
          .collection('donations')
          .where('donorId', isEqualTo: _userId)
          .get();
          
      if (!mounted) {
        Navigator.pop(context); // Close loading dialog
        return;
      }
      
      if (donationsQuery.docs.isNotEmpty) {
        // Get the batch to perform multiple updates
        final batch = FirebaseFirestore.instance.batch();
        int updatedCount = 0;
        
        for (final doc in donationsQuery.docs) {
          final donationRef = FirebaseFirestore.instance.collection('donations').doc(doc.id);
          
          // Only update if location is missing
          final data = doc.data();
          if (data['location'] == null || data['location'].toString().isEmpty) {
            // Try to get location from the original request if available
            String locationToUse = userLocation;
            
            if (data['requestId'] != null) {
              try {
                final requestDoc = await FirebaseFirestore.instance
                    .collection('blood_requests')
                    .doc(data['requestId'])
                    .get();
                    
                if (requestDoc.exists && requestDoc.data() != null) {
                  final requestData = requestDoc.data()!;
                  if (requestData['location'] != null && requestData['location'].toString().isNotEmpty) {
                    locationToUse = requestData['location'];
                  }
                }
              } catch (e) {
                debugPrint('Error getting location from request: $e');
              }
            }
            
            batch.update(donationRef, {
              'location': locationToUse,
            });
            updatedCount++;
            debugPrint('Updating location for donation ${doc.id} to: $locationToUse');
          }
        }
        
        // Commit the batch
        if (updatedCount > 0) {
          await batch.commit();
        }
        
        // Close loading dialog
        if (mounted) {
          Navigator.pop(context);
          
          setState(() {
            _lastDonationLocation = userLocation;
            debugPrint('Updated last donation location to: $userLocation');
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated $updatedCount donation records with location data'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Refresh the data
          _loadUserData();
        }
      } else {
        // Close loading dialog
        if (mounted) {
          Navigator.pop(context);
          
          // Show message that no donations were found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No donation records found to update'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still shown
      try {
        Navigator.pop(context);
      } catch (_) {}
      
      debugPrint('Error updating donation location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating donation location: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentUser = appProvider.currentUser;
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Remove standard app bar and let the ExtendedAppBar handle both the app bar and header
      body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _loadUserData,
                    color: AppConstants.primaryColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                    // Combined App Bar and Profile Header
                    _buildExtendedAppBar(currentUser),
                    
                    // Main content body
                    Padding(
                      padding: EdgeInsets.all(screenSize.width * 0.04),
                      child: _isEditing
                          ? _buildEditForm()
                          : _buildContentBody(
                            currentUser,
                            MediaQuery.of(context).orientation,
                          ),
                    ),

                    // Bottom padding to prevent FAB overlap
                    SizedBox(
                      height: _isEditing ? 0 : screenSize.height * 0.08,
                    ),
                  ],
                ),
              ),
            ),
          ),
      floatingActionButton: !_isEditing
          ? FloatingActionButton(
            onPressed: _toggleEdit,
            backgroundColor: AppConstants.primaryColor,
            child: const Icon(Icons.edit, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          )
          : null,
    );
  }

  // Extended App Bar that includes both the app bar and profile header
  Widget _buildExtendedAppBar(UserModel currentUser) {
    final orientation = MediaQuery.of(context).orientation;
    final screenSize = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final appBarHeight = kToolbarHeight;
    
    return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppConstants.primaryColor,
            AppConstants.primaryColor.withOpacity(0.85),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App Bar section
            SizedBox(
              height: appBarHeight,
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  
                  // Title
                  Expanded(
                    child: Center(
                      child: Text(
                        _isEditing ? 'Edit Profile' : 'My Profile',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  // Actions
                  if (currentUser.lastDonationDate != null && currentUser.neverDonatedBefore)
                    IconButton(
                      onPressed: () => _fixDonationStatusInconsistency(_userId),
                      icon: Icon(
                        Icons.sync_problem,
                        color: Colors.orange,
                      ),
                      tooltip: 'Fix donation history inconsistency',
                    ),
                  
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    tooltip: 'Settings',
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                          ),
                        ],
                      ),
                    ),
            
            // Profile Header section
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: orientation == Orientation.portrait
                    ? screenSize.height * 0.02
                    : screenSize.height * 0.015,
                horizontal: screenSize.width * 0.04,
              ),
              child: orientation == Orientation.portrait
                  ? _buildProfileHeaderPortrait(currentUser)
                  : _buildProfileHeaderLandscape(currentUser),
            ),
          ],
        ),
      ),
    );
  }

  // Portrait mode profile header - more compact version
  Widget _buildProfileHeaderPortrait(UserModel currentUser) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    // Reduce avatar size from 30% to 22% of screen width
    final avatarSize = screenSize.width * 0.22;
    // Slightly reduce font sizes
    final fontSize = screenSize.width * 0.045;
    final smallFontSize = screenSize.width * 0.03;

    return Row(
      children: [
        // Avatar section with blood type badge
        Stack(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
                image:
                    currentUser.imageUrl.isNotEmpty
                        ? DecorationImage(
                          image: NetworkImage(currentUser.imageUrl),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  currentUser.imageUrl.isEmpty
                      ? FittedBox(
                        fit: BoxFit.contain,
                        child: Padding(
                          padding: EdgeInsets.all(avatarSize * 0.2),
                          child: Icon(
                            Icons.person,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      )
                      : null,
            ),
            // Blood type badge
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(screenSize.width * 0.015),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currentUser.bloodType,
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: screenSize.width * 0.035,
                    ),
                  ),
                ),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: avatarSize * 0.2,
                child: Container(
                  padding: EdgeInsets.all(screenSize.width * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: AppConstants.primaryColor,
                    size: screenSize.width * 0.04,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(width: screenSize.width * 0.04),
        // User info section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  currentUser.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.008),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.03,
                  vertical: screenSize.height * 0.008,
                ),
                decoration: BoxDecoration(
                  color:
                      currentUser.isAvailableToDonate
                          ? Colors.green
                          : Colors.red,
                  borderRadius: BorderRadius.circular(screenSize.width * 0.04),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currentUser.isAvailableToDonate
                        ? 'Available to Donate'
                        : 'Not Available to Donate',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: smallFontSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Landscape mode profile header - more compact version
  Widget _buildProfileHeaderLandscape(UserModel currentUser) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    // Smaller size based on screen height for landscape mode
    final avatarSize = screenSize.height * 0.18;
    final fontSize = screenSize.height * 0.04;
    final smallFontSize = screenSize.height * 0.025;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Avatar with badges
        Stack(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
                image:
                    currentUser.imageUrl.isNotEmpty
                        ? DecorationImage(
                          image: NetworkImage(currentUser.imageUrl),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  currentUser.imageUrl.isEmpty
                      ? FittedBox(
                        fit: BoxFit.contain,
                        child: Padding(
                          padding: EdgeInsets.all(avatarSize * 0.2),
                          child: Icon(
                            Icons.person,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      )
                      : null,
            ),
            // Blood type badge
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(screenSize.height * 0.008),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currentUser.bloodType,
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: screenSize.height * 0.025,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: screenSize.width * 0.03),
        // User Info
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  currentUser.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.008),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.02,
                  vertical: screenSize.height * 0.008,
                ),
                decoration: BoxDecoration(
                  color:
                      currentUser.isAvailableToDonate
                          ? Colors.green
                          : Colors.red,
                  borderRadius: BorderRadius.circular(
                    screenSize.height * 0.015,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currentUser.isAvailableToDonate
                        ? 'Available to Donate'
                        : 'Not Available to Donate',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: smallFontSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Main content body wrapper to separate scrolling logic
  Widget _buildContentBody(UserModel user, Orientation orientation) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive padding and spacing
        final contentPadding = screenSize.width * 0.04;
        final cardSpacing = screenSize.height * 0.025;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Cards with dynamic sizing
            _buildQuickStats(user, orientation),

            SizedBox(height: cardSpacing),

            // User information section with responsive styling
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenSize.width * 0.04),
              ),
              child: Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: AppConstants.primaryColor,
                          size: screenSize.width * 0.055,
                        ),
                        SizedBox(width: contentPadding / 2),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: screenSize.width * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(thickness: screenSize.height * 0.002),
                    _buildInfoRow('Name', user.name, Icons.person_outline),
                    _buildInfoRow('Email', user.email, Icons.email_outlined),
                    _buildInfoRow(
                      'Phone',
                      user.phoneNumber,
                      Icons.phone_outlined,
                    ),
                    _buildInfoRow('Address', user.address, Icons.home_outlined),
                  ],
                ),
              ),
            ),

            SizedBox(height: cardSpacing),

            // Health information section with responsive styling
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenSize.width * 0.04),
              ),
              child: Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.health_and_safety,
                          color: Colors.green,
                          size: screenSize.width * 0.055,
                        ),
                        SizedBox(width: contentPadding / 2),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Health Status',
                              style: TextStyle(
                                fontSize: screenSize.width * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(thickness: screenSize.height * 0.002),
                    _buildInfoRow(
                      'Blood Type',
                      user.bloodType,
                      Icons.bloodtype_outlined,
                      valueColor: AppConstants.primaryColor,
                      valueBold: true,
                    ),
                    _buildInfoRow(
                      'Last Health Check',
                      _neverHadHealthCheck 
                        ? 'Never had a health check' 
                        : (_lastHealthCheck ?? 'Not available'),
                      Icons.calendar_today_outlined,
                    ),
                    _buildInfoRow(
                      'Health Status',
                      _healthStatus,
                      Icons.favorite_outline,
                      valueColor: _healthStatusColor,
                    ),
                    if (_medicalConditions != null &&
                        _medicalConditions!.isNotEmpty)
                      _buildInfoRow(
                        'Medical Conditions',
                        _medicalConditions ?? 'None',
                        Icons.medical_information_outlined,
                        valueColor: Colors.amber,
                      ),
                  ],
                ),
              ),
            ),

            // Donation history section with responsive styling
            if (user.lastDonationDate != null || user.neverDonatedBefore) ...[
              SizedBox(height: cardSpacing),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenSize.width * 0.04),
                ),
                child: Padding(
                  padding: EdgeInsets.all(contentPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: AppConstants.primaryColor,
                            size: screenSize.width * 0.055,
                          ),
                          SizedBox(width: contentPadding / 2),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Donation History',
                                style: TextStyle(
                                  fontSize: screenSize.width * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(thickness: screenSize.height * 0.002),
                      
                      // Last donation date (or message if never donated)
                      _buildInfoRow(
                        'Last Donation',
                        user.neverDonatedBefore 
                          ? 'Never donated before' 
                          : (_lastDonationDate ?? 'Not available'),
                        Icons.calendar_today_outlined,
                      ),
                      
                      // Time until eligible (or message if eligible now)
                      _buildInfoRow(
                        'Next Eligible',
                        user.neverDonatedBefore 
                          ? 'Eligible to donate' 
                          : (_nextDonationDate ?? 'Not calculated'),
                        Icons.event_available_outlined,
                        valueColor: user.isAvailableToDonate ? Colors.green : Colors.orange[700],
                        valueBold: user.isAvailableToDonate,
                      ),
                      
                      // Total donations (0 if never donated)
                      _buildInfoRow(
                        'Total Donations',
                        user.neverDonatedBefore ? '0' : (_donationCount != null ? '$_donationCount' : 'Loading...'),
                        Icons.bloodtype,
                        valueColor: AppConstants.primaryColor,
                        valueBold: true,
                      ),
                      
                      // Last location (or message if never donated)
                      _buildInfoRow(
                        'Last Location',
                        user.neverDonatedBefore 
                          ? 'No previous donation' 
                          : (_lastDonationLocation ?? 'Not available'),
                        Icons.location_on_outlined,
                        onTap: !user.neverDonatedBefore && (_lastDonationLocation == 'Unknown location' || _lastDonationLocation == 'Location unavailable')
                          ? () => _updateDonationLocation()
                          : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Action buttons with responsive spacing
            SizedBox(height: cardSpacing),
            _buildActionButtons(orientation),
          ],
        );
      },
    );
  }

  // Build info row with icon - responsive implementation
  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool valueBold = false,
    VoidCallback? onTap,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final textTheme = Theme.of(context).textTheme;

    // Calculate responsive dimensions
    final iconSize = screenSize.width * 0.05;
    final labelFontSize = screenSize.width * 0.035;
    final valueFontSize = screenSize.width * 0.04;
    final spacing = screenSize.width * 0.03;

    return InkWell(
      onTap: onTap,
      child: Padding(
      padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: iconSize, color: Colors.grey[600]),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label with FittedBox for text scaling
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: labelFontSize,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                SizedBox(height: screenSize.height * 0.005),
                // Value - use normal Text with ellipsis for multiline text
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                  value,
                  style: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
                    color: valueColor ?? textTheme.bodyLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                        ),
                      ),
                      if (onTap != null)
                        Icon(
                          Icons.refresh,
                          size: iconSize * 0.8,
                          color: AppConstants.primaryColor,
                        ),
                    ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  // Quick Stats with improved responsiveness
  Widget _buildQuickStats(UserModel user, Orientation orientation) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine layout based on screen size
        final isNarrow = screenSize.width < 320;
        final statCardHeight =
            orientation == Orientation.portrait
                ? screenSize.height * 0.12
                : screenSize.height * 0.15;

        // For very small screens, stack the cards vertically
        if (isNarrow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatCard(
                title: 'Blood Type',
                value: user.bloodType,
                icon: Icons.bloodtype_outlined,
                iconColor: AppConstants.primaryColor,
                animate: true,
                fullWidth: true,
              ),
              SizedBox(height: screenSize.height * 0.01),
              _buildStatCard(
                title: 'City',
                value: user.city,
                icon: Icons.location_city_outlined,
                iconColor: Colors.blue,
                animate: true,
                fullWidth: true,
              ),
              SizedBox(height: screenSize.height * 0.01),
              _buildStatCard(
                title: 'Status',
                value: user.isAvailableToDonate ? 'Active' : 'Inactive',
                icon: Icons.circle,
                iconColor: user.isAvailableToDonate ? Colors.green : Colors.red,
                animate: true,
                fullWidth: true,
              ),
            ],
          );
        }

        // For normal screens, use a row with responsive height
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Blood Type',
                value: user.bloodType,
                icon: Icons.bloodtype_outlined,
                iconColor: AppConstants.primaryColor,
                animate: true,
              ),
            ),
            SizedBox(width: screenSize.width * 0.02),
            Expanded(
              child: _buildStatCard(
                title: 'City',
                value: user.city,
                icon: Icons.location_city_outlined,
                iconColor: Colors.blue,
                animate: true,
              ),
            ),
            SizedBox(width: screenSize.width * 0.02),
            Expanded(
              child: _buildStatCard(
                title: 'Status',
                value: user.isAvailableToDonate ? 'Active' : 'Inactive',
                icon: Icons.circle,
                iconColor: user.isAvailableToDonate ? Colors.green : Colors.red,
                animate: true,
              ),
            ),
          ],
        );
      },
    );
  }

  // Single stat card with responsive design
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool animate = false,
    bool fullWidth = false,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    // Calculate sizes based on screen dimensions
    final iconSize =
        fullWidth ? screenSize.width * 0.06 : screenSize.width * 0.05;
    final titleSize = screenSize.width * 0.03;
    final valueSize = screenSize.width * 0.04;

    // Create the responsive card content with constraints to prevent overflow
    final cardContent = Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenSize.width * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.03),
        child:
            fullWidth
                // Horizontal layout for full width
                ? Row(
                  children: [
                    Icon(icon, color: iconColor, size: iconSize),
                    SizedBox(width: screenSize.width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: valueSize,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: titleSize,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                // Vertical layout for grid display
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: iconColor, size: iconSize),
                    SizedBox(height: screenSize.height * 0.005),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: valueSize,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: titleSize,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );

    if (!animate) return cardContent;

    // Add a subtle animation if requested
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: cardContent,
    );
  }

  // Responsive action buttons
  Widget _buildActionButtons(Orientation orientation) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes
        final fontSize = screenSize.width * 0.04;
        final iconSize = screenSize.width * 0.05;
        final verticalPadding = screenSize.height * 0.015;
        final horizontalPadding = screenSize.width * 0.04;
        final borderRadius = BorderRadius.circular(screenSize.width * 0.03);
        final spacing = screenSize.height * 0.015;

        // For landscape orientation, use a row layout
        if (orientation == Orientation.landscape) {
          return Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/donation_tracking');
                  },
                  icon: Icon(Icons.bloodtype, size: iconSize),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'My Donations',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: verticalPadding,
                      horizontal: horizontalPadding,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: borderRadius),
                    elevation: 2,
                  ),
                ),
              ),
              SizedBox(width: screenSize.width * 0.03),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/health-questionnaire');
                  },
                  icon: Icon(Icons.health_and_safety, size: iconSize),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Health Information',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: verticalPadding,
                      horizontal: horizontalPadding,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: borderRadius),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          );
        }

        // For portrait orientation, use a column layout
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/donation_tracking');
              },
              icon: Icon(Icons.bloodtype, size: iconSize),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'My Donations',
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: verticalPadding,
                  horizontal: horizontalPadding,
                ),
                shape: RoundedRectangleBorder(borderRadius: borderRadius),
                elevation: 2,
              ),
            ),
            SizedBox(height: spacing),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/health-questionnaire');
              },
              icon: Icon(Icons.health_and_safety, size: iconSize),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Update Health Information',
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: verticalPadding,
                  horizontal: horizontalPadding,
                ),
                shape: RoundedRectangleBorder(borderRadius: borderRadius),
                elevation: 2,
              ),
            ),
          ],
        );
      },
    );
  }

  // Profile Edit Form with responsive constraints
  Widget _buildEditForm() {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final titleFontSize = screenWidth < 360 ? 18.0 : 20.0;

    // Enhanced phone number handling
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = appProvider.currentUser;
    
    // Check all possible sources for phone number in priority order
    if (_phoneController.text.isEmpty) {
      if (currentUser.phoneNumber.isNotEmpty) {
        _phoneController.text = currentUser.phoneNumber;
        _phoneNumber = currentUser.phoneNumber;
        print('Setting phone controller from currentUser in edit form: ${currentUser.phoneNumber}');
      } else if (_phoneNumber != null && _phoneNumber!.isNotEmpty) {
        _phoneController.text = _phoneNumber!;
        print('Setting phone controller from cached _phoneNumber in edit form: $_phoneNumber');
      }
    } else {
      print('Phone controller already has value in edit form: ${_phoneController.text}');
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4, bottom: screenHeight * 0.02),
              child: Text(
                'Edit Your Profile',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isLandscape && screenWidth > 600)
              // Two-column layout for wide landscape
              Wrap(
                spacing: 16,
                runSpacing: 16, // Increased spacing between rows
                children: [
                  SizedBox(
                    width: (screenWidth - 48) * 0.48,
                    child: _buildTextInput(
                      'Name',
                      _nameController,
                      Icons.person_outline,
                      isRequired: true,
                    ),
                  ),
                  SizedBox(
                    width: (screenWidth - 48) * 0.48,
                    child: _buildTextInput(
                      'Email',
                      _emailController,
                      Icons.email_outlined,
                      readOnly: true,
                    ),
                  ),
                  SizedBox(
                    width: (screenWidth - 48) * 0.48,
                    child: _buildTextInput(
                      'Phone',
                      _phoneController,
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      isRequired: true,
                    ),
                  ),
                  SizedBox(
                    width: (screenWidth - 48) * 0.48,
                    child: _buildBloodTypeSelector(),
                  ),
                  SizedBox(
                    width: (screenWidth - 48) * 0.48,
                    child: _buildCityDropdown(),
                  ),
                  SizedBox(
                    width: (screenWidth - 48) * 0.48,
                    child: _buildDonationSwitch(),
                  ),
                  SizedBox(
                    width: screenWidth - 32,
                    child: _buildTextInput(
                      'Address',
                      _addressController,
                      Icons.home_outlined,
                      isRequired: true,
                      maxLines: 3,
                    ),
                  ),
                ],
              )
            else
              // Single column for portrait or narrow landscape
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextInput(
                    'Name',
                    _nameController,
                    Icons.person_outline,
                    isRequired: true,
                  ),
                  _buildTextInput(
                    'Email',
                    _emailController,
                    Icons.email_outlined,
                    readOnly: true,
                  ),
                  _buildTextInput(
                    'Phone',
                    _phoneController,
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    isRequired: true,
                  ),
                  _buildTextInput(
                    'Address',
                    _addressController,
                    Icons.home_outlined,
                    isRequired: true,
                    maxLines: 3,
                  ),
                  _buildCityDropdown(),
                  _buildBloodTypeSelector(),
                  _buildDonationSwitch(),
                ],
              ),

            // Action buttons with responsive layout
            Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.02,
                bottom: screenHeight * 0.06,
              ),
              child:
                  isLandscape
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _toggleEdit,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.06,
                                vertical: screenHeight * 0.015,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (_isEditing)
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveProfile,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(
                                _isLoading ? 'Saving...' : 'Save Changes',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
                                  vertical: screenHeight * 0.015,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveProfile,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(
                              _isLoading ? 'Saving...' : 'Save Changes',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.06,
                                vertical: screenHeight * 0.015,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _toggleEdit,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.06,
                                vertical: screenHeight * 0.015,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // Donation availability switch with improved styling
  Widget _buildDonationSwitch() {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final fontSize = screenSize.width * 0.04;
    final smallFontSize = fontSize * 0.75;
    final iconSize = screenSize.width * 0.055;
    final borderRadius = BorderRadius.circular(screenSize.width * 0.03);
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = appProvider.currentUser;
    final bool isEligibleBasedOnDate = currentUser.isAvailableBasedOnDonationDate;

    return Container(
      margin: EdgeInsets.only(bottom: screenSize.height * 0.02),
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.04,
        vertical: screenSize.height * 0.015,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: borderRadius,
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volunteer_activism,
                color: AppConstants.primaryColor,
                size: iconSize,
              ),
              SizedBox(width: screenSize.width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available to Donate',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isEligibleBasedOnDate 
                          ? 'Show your profile to those in need of blood'
                          : 'You must wait ${currentUser.daysUntilNextDonation} days until eligible',
                      style: TextStyle(
                        fontSize: smallFontSize,
                        color: isEligibleBasedOnDate
                            ? Theme.of(context).textTheme.bodySmall?.color
                            : Colors.orange,
                        fontWeight: isEligibleBasedOnDate ? FontWeight.normal : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isAvailableToDonate,
                onChanged: isEligibleBasedOnDate && _isEditing
                    ? (value) {
                        setState(() {
                          _isAvailableToDonate = value;
                        });
                      }
                    : null,
                activeColor: AppConstants.primaryColor,
              ),
            ],
          ),
          if (!isEligibleBasedOnDate) ...[
            SizedBox(height: screenSize.height * 0.01),
            Padding(
              padding: EdgeInsets.only(left: iconSize + screenSize.width * 0.03),
              child: Text(
                'Last donation: ${currentUser.lastDonationDate.toString().substring(0, 10)}',
                style: TextStyle(
                  fontSize: smallFontSize,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build the city dropdown
  Widget _buildCityDropdown() {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    final fontSize = screenSize.width * 0.04;
    final labelFontSize = fontSize * 0.9;
    final iconSize = screenSize.width * 0.055;
    final borderRadius = BorderRadius.circular(screenSize.width * 0.03);

    return Container(
      margin: EdgeInsets.only(bottom: screenSize.height * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'City',
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: screenSize.height * 0.01),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: context.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _city.isEmpty ? null : _city,
                isExpanded: true,
                hint: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Select City',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: fontSize,
                    ),
                  ),
                ),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _isEditing ? AppConstants.primaryColor : Theme.of(context).disabledColor,
                    size: 20,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
                menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
                items: CityManager().cities.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            city,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: fontSize,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _isEditing
                  ? (String? newValue) {
                    if (newValue != null) {
                    setState(() {
                        _city = newValue;
                        debugPrint('Profile: Selected city: $_city');
                    });
                    }
                  }
                  : null,
                dropdownColor: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                elevation: 8,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build blood type selector
  Widget _buildBloodTypeSelector() {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    
    final fontSize = screenSize.width * 0.04;
    final labelFontSize = fontSize * 0.9;
    final borderRadius = BorderRadius.circular(screenSize.width * 0.03);

    return Container(
      margin: EdgeInsets.only(bottom: screenSize.height * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blood Type',
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: screenSize.height * 0.01),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: context.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _bloodType,
                isExpanded: true,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _isEditing ? AppConstants.primaryColor : Theme.of(context).disabledColor,
                    size: 20,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return _bloodTypes.map<Widget>((item) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: fontSize,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: _bloodTypes.map((String bloodType) {
                  return DropdownMenuItem<String>(
                    value: bloodType,
                    child: Row(
                      children: [
                        Icon(
                          Icons.bloodtype_outlined,
                          size: 16,
                            color: AppConstants.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          bloodType,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: fontSize,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _isEditing
                  ? (newValue) {
                    setState(() {
                      _bloodType = newValue!;
                    });
                  }
                  : null,
                dropdownColor: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                elevation: 8,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build formatted text input
  Widget _buildTextInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final fontSize = screenSize.width * 0.04;
    final iconSize = screenSize.width * 0.055;
    final borderRadius = BorderRadius.circular(screenSize.width * 0.03);
    
    return Container(
      margin: EdgeInsets.only(bottom: screenSize.height * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize * 0.9,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: fontSize * 0.9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          SizedBox(height: screenSize.height * 0.01),
          TextField(
            controller: controller,
            readOnly: readOnly || !_isEditing,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: fontSize,
              color: readOnly || !_isEditing
                  ? Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8)
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: _isEditing
                    ? AppConstants.primaryColor
                    : Theme.of(context).disabledColor,
                size: iconSize,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: screenSize.height * 0.015,
                horizontal: screenSize.width * 0.03,
              ),
              filled: true,
              fillColor: readOnly || !_isEditing
                  ? Theme.of(context).disabledColor.withOpacity(0.05)
                  : Theme.of(context).cardColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(
                  color: context.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(
                  color: AppConstants.primaryColor,
                  width: 1.5,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: borderRadius,
              ),
              hintText: 'Enter $label',
              hintStyle: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: fontSize * 0.95,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleNeverDonatedButton() {
    // Add this call to fix inconsistent data first
    _fixDonationStatusInconsistency(_userId);
    
    // The rest of the method remains the same...
    // ...
  }
}
