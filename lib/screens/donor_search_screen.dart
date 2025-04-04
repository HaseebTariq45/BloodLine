import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/blood_type_badge.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';
import '../utils/theme_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/cities_data.dart';
import '../services/firebase_notification_service.dart';

class DonorSearchScreen extends StatefulWidget {
  const DonorSearchScreen({super.key});

  @override
  State<DonorSearchScreen> createState() => _DonorSearchScreenState();
}

class _DonorSearchScreenState extends State<DonorSearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String? _selectedBloodType;
  String? _selectedLocation;
  bool _onlyAvailable = false;
  List<UserModel> _filteredDonors = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

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

  // Replace the hardcoded locations with cities from CityManager
  List<String> _locations = CityManager().cities;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDonors();
    });
  }

  // Load donors from Firestore
  Future<void> _loadDonors() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    // Load donors from Firestore
    await appProvider.loadDonorsFromFirestore();

    // Update filtered donors
    _updateFilteredDonors();

    // Hide loading state
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateFilteredDonors() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final searchQuery = _searchController.text.toLowerCase();

    setState(() {
      _filteredDonors =
          appProvider
              .filterDonors(
                bloodType: _selectedBloodType,
                onlyAvailable: _onlyAvailable,
              )
              .where((donor) {
                // Text search across name, address, and city
                bool matchesSearch = true;
                if (searchQuery.isNotEmpty) {
                  matchesSearch =
                      donor.name.toLowerCase().contains(searchQuery) ||
                      donor.address.toLowerCase().contains(searchQuery) ||
                      donor.city.toLowerCase().contains(searchQuery);
                }

                // Flexible location matching with fallback for empty city values
                bool matchesLocation = true;
                if (_selectedLocation != null) {
                  // Use partial matching and check address as fallback if city is empty
                  if (donor.city.isNotEmpty) {
                    matchesLocation = donor.city.toLowerCase().contains(
                      _selectedLocation!.toLowerCase(),
                    );
                  } else {
                    // Fallback to address field if city is empty (for older profiles)
                    matchesLocation = donor.address.toLowerCase().contains(
                      _selectedLocation!.toLowerCase(),
                    );
                  }
                }

                return matchesSearch && matchesLocation;
              })
              .toList();
    });

    // Animate when list changes
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: const CustomAppBar(title: 'Find Blood Donors'),
      body: RefreshIndicator(
        onRefresh: _loadDonors,
        child: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: AppConstants.paddingS),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar with integrated title
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: context.isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: context.textColor),
                      decoration: InputDecoration(
                        hintText: 'Search donors by name or location',
                        hintStyle: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppConstants.primaryColor.withOpacity(0.7),
                        ),
                        filled: true,
                        fillColor: context.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: context.secondaryTextColor,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _updateFilteredDonors();
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => _updateFilteredDonors(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Combined filters header and dropdowns
                  Row(
                    children: [
                      // Blood Type Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Blood Type',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: context.textColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(12),
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
                                  value: _selectedBloodType,
                                  isExpanded: true,
                                  hint: Center(
                                    child: Text(
                                      'All Types',
                                      style: TextStyle(
                                        color: context.secondaryTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppConstants.primaryColor,
                                    size: 18,
                                  ),
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 12,
                                  ),
                                  selectedItemBuilder: (BuildContext context) {
                                    return [null, ..._bloodTypes].map<Widget>((
                                      String? item,
                                    ) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item ?? 'All Types',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList();
                                  },
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        'All Types',
                                        style: TextStyle(
                                          color: context.textColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    ..._bloodTypes.map((type) {
                                      return DropdownMenuItem<String>(
                                        value: type,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppConstants.primaryColor,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  type,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              type,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                                color: context.textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedBloodType = value;
                                    });
                                    _updateFilteredDonors();
                                  },
                                  dropdownColor: context.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  elevation: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Location Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'City',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: context.textColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(12),
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
                                  value: _selectedLocation,
                                  isExpanded: true,
                                  hint: Center(
                                    child: Text(
                                      'Any City',
                                      style: TextStyle(
                                        color: context.secondaryTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppConstants.primaryColor,
                                    size: 18,
                                  ),
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
                                  selectedItemBuilder: (BuildContext context) {
                                    return [null, ..._locations].map<Widget>((
                                      item,
                                    ) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item == null ? 'Any City' : item.toString(),
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList();
                                  },
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Any City',
                                              style: TextStyle(
                                                color: context.textColor,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...(CityManager().cities).map((location) {
                                      return DropdownMenuItem<String>(
                                        value: location,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: AppConstants.primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                location,
                                                style: TextStyle(
                                                  color: context.textColor,
                                                  fontWeight: FontWeight.normal,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedLocation = value;
                                    });
                                    _updateFilteredDonors();
                                  },
                                  dropdownColor: context.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  elevation: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Available Toggle with smaller height
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _onlyAvailable = !_onlyAvailable;
                      });
                      _updateFilteredDonors();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _onlyAvailable
                            ? AppConstants.primaryColor.withOpacity(0.1)
                            : context.isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _onlyAvailable
                                ? AppConstants.primaryColor.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: _onlyAvailable
                              ? AppConstants.primaryColor
                              : context.isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _onlyAvailable
                                  ? AppConstants.primaryColor
                                  : context.isDarkMode
                                      ? Colors.grey[700]
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            child: Icon(
                              _onlyAvailable ? Icons.check : null,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          Text(
                            'Available donors only',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: _onlyAvailable
                                  ? AppConstants.primaryColor
                                  : context.textColor,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.person_outline,
                            color: _onlyAvailable
                                ? AppConstants.primaryColor
                                : context.secondaryTextColor,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Results Count
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Found ${_filteredDonors.length} donors',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: context.textColor,
                    ),
                  ),
                  if (_filteredDonors.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.sort,
                          size: 16,
                          color: context.secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sort by',
                          style: TextStyle(
                            color: context.secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Donor List
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredDonors.isEmpty
                      ? _buildEmptyState()
                      : FadeTransition(
                        opacity: _fadeAnimation,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingM,
                            vertical: AppConstants.paddingS,
                          ),
                          itemCount: _filteredDonors.length,
                          itemBuilder: (context, index) {
                            final donor = _filteredDonors[index];
                            // Add staggered animation delay based on index
                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              opacity: 1.0,
                              curve: Curves.easeInOut,
                              child: AnimatedPadding(
                                duration: const Duration(milliseconds: 500),
                                padding: EdgeInsets.only(
                                  top: 0,
                                  bottom: 16,
                                  left: 0,
                                  right: 0,
                                ),
                                child: _buildDonorCard(donor),
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bloodtype_outlined,
            size: 80,
            color: context.isDarkMode ? Colors.grey[600] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No donors found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try changing your filters or search for different criteria',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.secondaryTextColor, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedBloodType = null;
                _selectedLocation = null;
                _onlyAvailable = false;
              });
              _updateFilteredDonors();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Reset Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorCard(UserModel donor) {
    final eligibilityStatus =
        donor.isEligibleToDonate
            ? 'Available Now'
            : donor.daysUntilNextDonation > 0
            ? 'Available in ${donor.daysUntilNextDonation} days'
            : 'Not Available';

    final eligibilityColor =
        donor.isEligibleToDonate
            ? AppConstants.successColor
            : donor.daysUntilNextDonation > 0
            ? AppConstants.accentColor
            : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
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
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black12
                : Colors.grey.withOpacity(0.07),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _showDonorDetailsDialog(donor);
            },
            splashColor: AppConstants.primaryColor.withOpacity(0.05),
            highlightColor: AppConstants.primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Donor Image with Availability Indicator
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: context.isDarkMode
                                      ? Colors.black12
                                      : Colors.grey.withOpacity(0.2),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: AppConstants.accentColor,
                              backgroundImage: donor.imageUrl.isNotEmpty
                                  ? AssetImage(donor.imageUrl)
                                  : null,
                              child: donor.imageUrl.isEmpty
                                  ? Text(
                                      donor.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: context.isDarkMode
                                        ? Colors.black12
                                        : Colors.grey.withOpacity(0.2),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                donor.isAvailableToDonate
                                    ? Icons.check_circle
                                    : Icons.access_time_rounded,
                                color: donor.isAvailableToDonate
                                    ? AppConstants.successColor
                                    : AppConstants.accentColor,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Donor Information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    donor.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: context.textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppConstants.primaryColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    donor.bloodType,
                                    style: const TextStyle(
                                      color: AppConstants.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    donor.address,
                                    style: TextStyle(
                                      color: context.secondaryTextColor,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: context.secondaryTextColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Last donation: ${donor.lastDonationDate.day}/${donor.lastDonationDate.month}/${donor.lastDonationDate.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.secondaryTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Availability Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: eligibilityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: eligibilityColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    donor.isEligibleToDonate
                                        ? Icons.check_circle_outline
                                        : Icons.schedule,
                                    size: 14,
                                    color: eligibilityColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    eligibilityStatus,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: eligibilityColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Replace horizontal scrolling with adaptive layout
                  _buildResponsiveButtonLayout(context, donor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Launch phone call
  void _launchCall(String phoneNumber) async {
    // Create a Uri for the phone call
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    // Launch the dialer with the phone number
    try {
      await launchUrl(phoneUri);
      debugPrint('Opened phone dialer for: $phoneNumber');
    } catch (error) {
      // Show error message if unable to launch dialer
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open phone dialer: $error'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
      debugPrint('Error opening phone dialer: $error');
    }
  }

  // Launch SMS
  void _launchSms(String phoneNumber) async {
    // Create a Uri for SMS
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    
    // Launch the SMS app with the phone number
    try {
      await launchUrl(smsUri);
      debugPrint('Opened SMS app for: $phoneNumber');
    } catch (error) {
      // Show error message if unable to launch SMS app
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open SMS app: $error'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
      debugPrint('Error opening SMS app: $error');
    }
  }

  // Show donor details dialog
  void _showDonorDetailsDialog(UserModel donor) {
    final eligibilityStatus =
        donor.isEligibleToDonate
            ? 'Available Now'
            : donor.daysUntilNextDonation > 0
            ? 'Available in ${donor.daysUntilNextDonation} days'
            : 'Not Available';

    final eligibilityColor =
        donor.isEligibleToDonate
            ? AppConstants.successColor
            : donor.daysUntilNextDonation > 0
            ? AppConstants.accentColor
            : Colors.grey;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: context.isDarkMode ? Colors.white70 : Colors.black54,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  
                  // Donor image and name
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppConstants.accentColor,
                    backgroundImage:
                        donor.imageUrl.isNotEmpty
                            ? AssetImage(donor.imageUrl)
                            : null,
                    child:
                        donor.imageUrl.isEmpty
                            ? Text(
                              donor.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    donor.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      donor.bloodType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                
                  // Details
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDetailRow(
                            icon: Icons.location_on,
                            title: 'Address',
                            value: donor.address,
                          ),
                          _buildDetailRow(
                            icon: Icons.phone,
                            title: 'Phone',
                            value: donor.phoneNumber,
                          ),
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            title: 'Last Donation',
                            value:
                                '${donor.lastDonationDate.day}/${donor.lastDonationDate.month}/${donor.lastDonationDate.year}',
                          ),
                          _buildDetailRow(
                            icon:
                                donor.isEligibleToDonate
                                    ? Icons.check_circle
                                    : Icons.access_time,
                            title: 'Availability Status',
                            value: eligibilityStatus,
                            color: eligibilityColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                
                  // Actions
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _launchSms(donor.phoneNumber);
                          },
                          icon: const Icon(Icons.message, size: 16),
                          label: const Text('MESSAGE'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _launchCall(donor.phoneNumber);
                          },
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text('CALL'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
  }

  // Build detail row for donor dialog
  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? AppConstants.primaryColor).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? AppConstants.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Request blood donation from donor
  Future<void> _requestDonation(UserModel donor) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = appProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You need to be logged in to request a donation'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Request Donation'),
                content: Text(
                  'Are you sure you want to request a blood donation from ${donor.name}? '
                  'This will send a notification to the donor with your contact details.',
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
                    child: const Text('Confirm'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Create and send the notification using the notification service
      final notificationService = FirebaseNotificationService();
      await notificationService.sendDonationRequestNotification(
        requesterId: currentUser.id,
        requesterName: currentUser.name,
        requesterPhone: currentUser.phoneNumber,
        requesterEmail: currentUser.email,
        requesterBloodType: currentUser.bloodType,
        requesterAddress: currentUser.address,
        recipientId: donor.id, // Send to donor
      );

      setState(() {
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Donation request sent to ${donor.name}'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send donation request: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  // Helper method to calculate responsive font size
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Scale font based on screen width with min/max constraints
    if (screenWidth < 320) {
      return baseSize * 0.8; // Smaller screens get 80% of the base size
    } else if (screenWidth > 600) {
      return baseSize * 1.2; // Larger screens get 120% of the base size
    } else {
      // Linear scaling between 320px and 600px
      final scale = 0.8 + (0.4 * (screenWidth - 320) / (600 - 320));
      return baseSize * scale;
    }
  }

  // Helper method to calculate responsive padding
  double _getResponsivePadding(BuildContext context, double basePadding) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Scale padding based on screen width with min/max constraints
    if (screenWidth < 320) {
      return basePadding * 0.7; // Smaller screens get 70% of the base padding
    } else if (screenWidth > 600) {
      return basePadding * 1.3; // Larger screens get 130% of the base padding
    } else {
      // Linear scaling between 320px and 600px
      final scale = 0.7 + (0.6 * (screenWidth - 320) / (600 - 320));
      return basePadding * scale;
    }
  }

  // Build responsive button layout based on available width
  Widget _buildResponsiveButtonLayout(BuildContext context, UserModel donor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // For extra small screens - stack buttons vertically
        if (availableWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMessageButton(context, donor, isFullWidth: true),
              const SizedBox(height: 8),
              _buildCallButton(context, donor, isFullWidth: true),
              const SizedBox(height: 8),
              _buildRequestButton(context, donor, isFullWidth: true),
            ],
          );
        }
        // For small screens - arrange in 2 rows (2 buttons + 1 button)
        else if (availableWidth < 380) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _buildMessageButton(context, donor)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCallButton(context, donor)),
                ],
              ),
              const SizedBox(height: 8),
              _buildRequestButton(context, donor, isFullWidth: true),
            ],
          );
        }
        // For medium and larger screens - single row with all 3 buttons
        else {
          return Row(
            children: [
              Expanded(child: _buildMessageButton(context, donor)),
              const SizedBox(width: 8),
              Expanded(child: _buildCallButton(context, donor)),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _buildRequestButton(context, donor)),
            ],
          );
        }
      },
    );
  }

  // Message button widget
  Widget _buildMessageButton(
    BuildContext context,
    UserModel donor, {
    bool isFullWidth = false,
  }) {
    return OutlinedButton.icon(
      onPressed: () {
        _launchSms(donor.phoneNumber);
      },
      icon: Icon(
        Icons.message,
        size: MediaQuery.of(context).size.width < 360 ? 12 : 16,
      ),
      label: Text(
        isFullWidth
            ? 'Message'
            : MediaQuery.of(context).size.width < 400
            ? 'SMS'
            : 'Message',
        style: TextStyle(fontSize: _getResponsiveFontSize(context, 14)),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        padding: EdgeInsets.symmetric(
          horizontal: _getResponsivePadding(context, isFullWidth ? 12 : 8),
          vertical: _getResponsivePadding(context, 6),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Call button widget
  Widget _buildCallButton(
    BuildContext context,
    UserModel donor, {
    bool isFullWidth = false,
  }) {
    return ElevatedButton.icon(
      onPressed: () {
        _launchCall(donor.phoneNumber);
      },
      icon: Icon(
        Icons.phone,
        size: MediaQuery.of(context).size.width < 360 ? 12 : 16,
      ),
      label: Text(
        'Call',
        style: TextStyle(fontSize: _getResponsiveFontSize(context, 14)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: _getResponsivePadding(context, isFullWidth ? 12 : 8),
          vertical: _getResponsivePadding(context, 6),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Request donation button widget
  Widget _buildRequestButton(
    BuildContext context,
    UserModel donor, {
    bool isFullWidth = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return OutlinedButton.icon(
      onPressed:
          donor.isAvailableToDonate ? () => _requestDonation(donor) : null,
      icon: Icon(Icons.bloodtype_outlined, size: screenWidth < 360 ? 12 : 16),
      label: Text(
        screenWidth < 320 && !isFullWidth ? 'Request' : 'Request Donation',
        style: TextStyle(fontSize: _getResponsiveFontSize(context, 14)),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppConstants.primaryColor,
        side: BorderSide(color: AppConstants.primaryColor, width: 1.5),
        padding: EdgeInsets.symmetric(
          horizontal: _getResponsivePadding(context, isFullWidth ? 12 : 8),
          vertical: _getResponsivePadding(context, 6),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

