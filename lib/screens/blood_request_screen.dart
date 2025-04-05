import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/cities_data.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../models/blood_request_model.dart';
import '../utils/theme_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_notification_service.dart';
import '../utils/blood_compatibility.dart';

class BloodRequestScreen extends StatefulWidget {
  const BloodRequestScreen({super.key});

  @override
  State<BloodRequestScreen> createState() => _BloodRequestScreenState();
}

class _BloodRequestScreenState extends State<BloodRequestScreen>
    with TickerProviderStateMixin {
  final _selfFormKey = GlobalKey<FormState>();
  final _otherFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedBloodType = 'A+';
  String _selectedUrgency = 'Normal';
  String _selectedCity = 'Karachi';
  bool _isLoading = false;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Animation for item slide-in
  late List<AnimationController> _itemAnimationControllers;
  late List<Animation<Offset>> _itemAnimations;

  // Scroll controller for scrolling to fields with errors
  final ScrollController _scrollController = ScrollController();

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

  final List<String> _urgencyTypes = ['Normal', 'Urgent'];

  @override
  void initState() {
    super.initState();
    // Initialize tab controller
    _tabController = TabController(length: 1, vsync: this);

    // Animation setup for fade in
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Setup staggered animations for form elements
    _setupStaggeredAnimations();

    // Prefill with user data if available
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (appProvider.isLoggedIn) {
      _nameController.text = appProvider.currentUser.name;
      _phoneController.text = appProvider.currentUser.phoneNumber;
    }

    // Set initial city value from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AppProvider>(context, listen: false).currentUser;
      if (user.city.isNotEmpty) {
        setState(() {
          _selectedCity = user.city;
        });
      }
    });
  }

  void _setupStaggeredAnimations() {
    // Number of sections/items to animate
    const int itemCount = 6;

    _itemAnimationControllers = List.generate(
      itemCount,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _itemAnimations = List.generate(
      itemCount,
      (index) =>
          Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _itemAnimationControllers[index],
              curve: Curves.easeOutQuint,
            ),
          ),
    );

    // Start animations with staggered delays
    for (int i = 0; i < itemCount; i++) {
      Future.delayed(Duration(milliseconds: 100 * i), () {
        if (mounted) {
          _itemAnimationControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _hospitalController.dispose();
    _notesController.dispose();
    _tabController.dispose();
    _animationController.dispose();
    _scrollController.dispose();

    for (var controller in _itemAnimationControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _submitRequest() async {
    if (_selfFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final user = appProvider.currentUser;
        final bloodRequest = BloodRequestModel(
          id: 'req_${DateTime.now().millisecondsSinceEpoch}',
          requesterId: user.id,
          requesterName: _nameController.text,
          contactNumber: _phoneController.text,
          bloodType: _selectedBloodType,
          location: _hospitalController.text,
          city: _selectedCity,
          requestDate: DateTime.now(),
          urgency: _selectedUrgency,
          notes: _notesController.text,
        );

        // Save the blood request to Firestore
        await FirebaseFirestore.instance
            .collection('blood_requests')
            .doc(bloodRequest.id)
            .set(bloodRequest.toMap());

        // Find compatible donors and send notifications
        final FirebaseNotificationService notificationService =
            FirebaseNotificationService();

        // Logic to find compatible donors based on blood type
        final compatibleDonors = await _findCompatibleDonors(
          _selectedBloodType,
        );

        if (compatibleDonors.isNotEmpty) {
          // Send notifications to compatible donors
          await notificationService.sendBloodRequestNotification(
            requestId: bloodRequest.id,
            requesterId: user.id,
            requesterName: _nameController.text,
            requesterPhone: _phoneController.text,
            bloodType: _selectedBloodType,
            location: _hospitalController.text,
            city: _selectedCity,
            urgency: _selectedUrgency,
            notes: _notesController.text,
            recipientIds: compatibleDonors,
          );
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Show success message and navigate back
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Blood request submitted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 3),
            ),
          );

          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting request: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      }
    } else {
      // Scroll to the first error
      _scrollToFirstError();
    }
  }

  // Function to find compatible donors based on blood type
  Future<List<String>> _findCompatibleDonors(String bloodType) async {
    try {
      final List<String> compatibleBloodTypes =
          BloodCompatibility.getCompatibleDonorTypes(bloodType);

      debugPrint('Finding donors with blood types: $compatibleBloodTypes');

      // Query Firestore for users with compatible blood types who are available to donate
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('bloodType', whereIn: compatibleBloodTypes)
              .where('isAvailableToDonate', isEqualTo: true)
              .get();

      // Extract user IDs
      final List<String> donorIds = snapshot.docs.map((doc) => doc.id).toList();

      debugPrint('Found ${donorIds.length} compatible donors');
      return donorIds;
    } catch (e) {
      debugPrint('Error finding compatible donors: $e');
      return [];
    }
  }

  void _scrollToFirstError() {
    // Small delay to allow validation to complete and rebuild UI
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // Scroll to top, as we'll check fields from top to bottom
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppConstants.successColor,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Request Submitted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your blood request has been submitted successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        context.isDarkMode
                            ? Colors.grey[850]
                            : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        icon: Icons.bloodtype,
                        title: 'Blood Type',
                        value: _selectedBloodType,
                        color: AppConstants.primaryColor,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon:
                            _selectedUrgency == 'Urgent'
                                ? Icons.priority_high
                                : Icons.access_time,
                        title: 'Urgency',
                        value: _selectedUrgency,
                        color:
                            _selectedUrgency == 'Urgent'
                                ? AppConstants.errorColor
                                : AppConstants.primaryColor,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.location_on,
                        title: 'Location',
                        value: _hospitalController.text,
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Potential donors will be notified. You will receive a notification when a donor accepts your request.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                    // Navigate to Blood Requests screen with My Requests tab selected
                    Navigator.of(context).pushNamed(
                      '/blood_requests_list',
                      arguments: {'initialTab': 3},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'VIEW MY REQUESTS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: context.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to build form fields
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required String? Function(String?) validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: context.textColor),
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          hintStyle: TextStyle(color: context.secondaryTextColor),
          floatingLabelStyle: TextStyle(
            color: AppConstants.primaryColor,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppConstants.primaryColor, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppConstants.primaryColor,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          fillColor: context.cardColor,
          filled: true,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildBloodTypeDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Blood Type',
          floatingLabelStyle: TextStyle(
            color: AppConstants.primaryColor,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.bloodtype_outlined,
              color: AppConstants.primaryColor,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: AppConstants.primaryColor.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          fillColor: Colors.white,
          filled: true,
        ),
        value: _selectedBloodType,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppConstants.primaryColor.withOpacity(0.7),
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(15),
        items:
            _bloodTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppConstants.primaryColor,
                      ),
                      child: Center(
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      type,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedBloodType = value!;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a blood type';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: const CustomAppBar(title: 'Request Blood', showBackButton: true),
      body: FadeTransition(opacity: _fadeAnimation, child: _buildRequestForm()),
    );
  }

  // Build the blood request form
  Widget _buildRequestForm() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20.0),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _selfFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form header - Section 1
            SlideTransition(
              position: _itemAnimations[0],
              child: _buildHeaderSection(),
            ),

            const SizedBox(height: 30),

            // Blood type section - Section 2
            SlideTransition(
              position: _itemAnimations[1],
              child: _buildBloodTypeSection(),
            ),

            const SizedBox(height: 30),

            // Hospital/Location field - Section 3
            SlideTransition(
              position: _itemAnimations[2],
              child: _buildLocationSection(),
            ),

            const SizedBox(height: 30),

            // City dropdown - Section 4
            SlideTransition(
              position: _itemAnimations[3],
              child: _buildCityDropdown(),
            ),

            const SizedBox(height: 30),

            // Contact Information section - Section 5
            SlideTransition(
              position: _itemAnimations[4],
              child: _buildContactSection(),
            ),

            const SizedBox(height: 30),

            // Notes and Notice - Section 6
            SlideTransition(
              position: _itemAnimations[5],
              child: _buildNotesAndNoticeSection(),
            ),

            const SizedBox(height: 30),

            // Submit button
            ScaleTransition(
              scale: _fadeAnimation,
              child: CustomButton(
                text: 'SUBMIT REQUEST',
                isLoading: _isLoading,
                onPressed: _submitRequest,
                icon: Icons.send,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Form header section
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bloodtype,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Blood Request',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find donors quickly',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Please provide accurate information to help us match you with potential donors.',
            style: TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
          ),
        ],
      ),
    );
  }

  // Blood type selection section
  Widget _buildBloodTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildSectionHeader('Blood Type Required', Icons.bloodtype_outlined),

        const SizedBox(height: 16),

        // Blood type grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _bloodTypes.length,
          itemBuilder: (context, index) {
            final bloodType = _bloodTypes[index];
            final isSelected = bloodType == _selectedBloodType;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBloodType = bloodType;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppConstants.primaryColor
                          : context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isSelected
                              ? AppConstants.primaryColor.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color:
                        isSelected
                            ? AppConstants.primaryColor
                            : Colors.grey.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          bloodType,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : AppConstants.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: AppConstants.primaryColor,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Urgency selection
        Text(
          'Urgency Level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.textColor,
          ),
        ),

        const SizedBox(height: 12),

        // Urgency toggle
        Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children:
                _urgencyTypes.map((urgency) {
                  final isSelected = urgency == _selectedUrgency;
                  final isUrgent = urgency == 'Urgent';

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedUrgency = urgency;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? (isUrgent
                                      ? AppConstants.errorColor.withOpacity(0.1)
                                      : AppConstants.primaryColor.withOpacity(
                                        0.1,
                                      ))
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isSelected
                                    ? (isUrgent
                                        ? AppConstants.errorColor
                                        : AppConstants.primaryColor)
                                    : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              isUrgent
                                  ? Icons.priority_high
                                  : Icons.access_time,
                              color:
                                  isSelected
                                      ? (isUrgent
                                          ? AppConstants.errorColor
                                          : AppConstants.primaryColor)
                                      : Colors.grey,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              urgency,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? (isUrgent
                                            ? AppConstants.errorColor
                                            : AppConstants.primaryColor)
                                        : context.textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  // Hospital/Location field section
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Hospital/Location', Icons.location_on_outlined),

        const SizedBox(height: 16),

        _buildFormField(
          controller: _hospitalController,
          label: 'Hospital Name or Location',
          icon: Icons.location_on_outlined,
          hintText: 'Enter hospital name or location',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the hospital or location';
            }
            return null;
          },
        ),
      ],
    );
  }

  // City dropdown
  Widget _buildCityDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city, size: 16),
              const SizedBox(width: 6),
              Text(
                'City',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: context.isDarkMode
                      ? Colors.black12
                      : Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: context.isDarkMode
                    ? Colors.grey[800]!
                    : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCity,
                isExpanded: true,
                hint: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Select City',
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 14,
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
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                ),
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                // Limit visible items to improve performance
                menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
                items: CityManager().cities.map((location) {
                  return DropdownMenuItem<String>(
                    value: location,
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
                              location,
                              style: TextStyle(
                                color: context.textColor,
                                fontWeight: FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedCity = value;
                      debugPrint('BloodRequest: Selected city: $_selectedCity');
                    });
                  }
                },
                dropdownColor: context.cardColor,
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

  // Contact Information section
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Contact Information', Icons.person_outline),

        const SizedBox(height: 16),

        _buildFormField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),

        _buildFormField(
          controller: _phoneController,
          label: 'Contact Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your contact number';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Additional Notes and Notice section
  Widget _buildNotesAndNoticeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Additional Notes (Optional)',
          Icons.note_alt_outlined,
        ),

        const SizedBox(height: 16),

        _buildFormField(
          controller: _notesController,
          label: 'Notes',
          icon: Icons.note_alt_outlined,
          maxLines: 3,
          hintText: 'E.g., Patient details, specific requirements',
          validator: (value) {
            return null; // No specific validation for notes
          },
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                context.isDarkMode
                    ? Colors.amber.withOpacity(0.1)
                    : Colors.amber[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber[400]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Important Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'By submitting this form, you agree to share your contact information with potential donors. Blood availability cannot be guaranteed and depends on donor response.',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textColor,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build a section header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppConstants.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.textColor,
          ),
        ),
      ],
    );
  }
}
