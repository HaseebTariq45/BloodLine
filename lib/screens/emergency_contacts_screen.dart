import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../models/emergency_contact_model.dart';
import '../providers/app_provider.dart';
import '../utils/theme_helper.dart';
import '../widgets/custom_alert_dialog.dart';
import 'package:flutter/gestures.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedContactType = 'personal';
  String _selectedRelationship = '';
  final _formKey = GlobalKey<FormState>();

  StreamSubscription? _contactsSubscription;
  List<EmergencyContactModel> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupContactsStream();
  }

  void _setupContactsStream() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Set initial loading state
    setState(() {
      _isLoading = true;
    });

    // Subscribe to contacts stream
    _contactsSubscription = appProvider.getEmergencyContactsStream().listen(
      (contacts) {
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      },
      onError: (error) {
        debugPrint('Error in contacts stream: $error');
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    _addressController.dispose();
    _contactsSubscription?.cancel();
    super.dispose();
  }

  // Make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
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
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error opening phone dialer: $error');
    }
  }

  // Handle adding a new contact
  void _showAddContactDialog() {
    // Reset form fields
    _nameController.clear();
    _phoneController.clear();
    _relationshipController.clear();
    _addressController.clear();
    _selectedContactType = 'personal';
    _selectedRelationship = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildContactForm(context),
    );
  }

  // Build the contact form modal
  Widget _buildContactForm(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final textTheme = Theme.of(context).textTheme;

    // Calculate responsive padding
    final double verticalPadding = screenHeight * 0.02;
    final double horizontalPadding = mediaQuery.size.width * 0.05;

    return Container(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
        top: verticalPadding,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85, // Limit max height to 85% of screen
      ),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusL),
          topRight: Radius.circular(AppConstants.radiusL),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form title
              Center(
                child: Container(
                  height: 4,
                  width: mediaQuery.size.width * 0.1,
                  margin: EdgeInsets.only(bottom: verticalPadding),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Add Emergency Contact',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: verticalPadding),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  labelStyle: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.person, color: AppConstants.primaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.5,
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
                      color: Colors.red.shade300,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.red.shade500,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.isDarkMode 
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: verticalPadding * 0.75),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  labelStyle: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.phone, color: AppConstants.primaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.5,
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
                      color: Colors.red.shade300,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.red.shade500,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.isDarkMode 
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: verticalPadding * 0.75),

              // Relationship field
              DropdownButtonFormField<String>(
                value: _selectedRelationship.isEmpty ? null : _selectedRelationship,
                decoration: InputDecoration(
                  labelText: 'Relationship',
                  labelStyle: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.people, color: AppConstants.primaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppConstants.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.isDarkMode 
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                hint: Text(
                  'Select Relationship',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                icon: Icon(
                  Icons.arrow_drop_down_circle,
                  color: AppConstants.primaryColor,
                ),
                iconSize: 24,
                elevation: 8,
                isExpanded: true,
                dropdownColor: context.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                items: [
                  DropdownMenuItem(
                    value: 'Spouse',
                    child: Row(
                      children: [
                        Icon(Icons.favorite, size: 18, color: Colors.pink),
                        const SizedBox(width: 12),
                        const Text('Spouse'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Parent',
                    child: Row(
                      children: [
                        Icon(Icons.family_restroom, size: 18, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text('Parent'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Child',
                    child: Row(
                      children: [
                        Icon(Icons.child_care, size: 18, color: Colors.green),
                        const SizedBox(width: 12),
                        const Text('Child'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Sibling',
                    child: Row(
                      children: [
                        Icon(Icons.people_outline, size: 18, color: Colors.purple),
                        const SizedBox(width: 12),
                        const Text('Sibling'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Relative',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 18, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Text('Relative'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Friend',
                    child: Row(
                      children: [
                        Icon(Icons.emoji_people, size: 18, color: Colors.amber),
                        const SizedBox(width: 12),
                        const Text('Friend'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Colleague',
                    child: Row(
                      children: [
                        Icon(Icons.work_outline, size: 18, color: Colors.brown),
                        const SizedBox(width: 12),
                        const Text('Colleague'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Doctor',
                    child: Row(
                      children: [
                        Icon(Icons.medical_services, size: 18, color: Colors.red),
                        const SizedBox(width: 12),
                        const Text('Doctor'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Caregiver',
                    child: Row(
                      children: [
                        Icon(Icons.healing, size: 18, color: AppConstants.primaryColor),
                        const SizedBox(width: 12),
                        const Text('Caregiver'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Row(
                      children: [
                        Icon(Icons.more_horiz, size: 18, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Text('Other'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRelationship = value;
                      _relationshipController.text = value;
                    });
                  }
                },
              ),
              SizedBox(height: verticalPadding * 0.75),

              // Address field
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.location_on, color: AppConstants.primaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppConstants.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.isDarkMode 
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                maxLines: 2,
              ),
              SizedBox(height: verticalPadding * 0.75),

              // Contact type dropdown
              DropdownButtonFormField<String>(
                value: _selectedContactType,
                decoration: InputDecoration(
                  labelText: 'Contact Type',
                  labelStyle: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.category, color: AppConstants.primaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppConstants.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.isDarkMode 
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                icon: Icon(
                  Icons.arrow_drop_down_circle,
                  color: AppConstants.primaryColor,
                ),
                iconSize: 24,
                elevation: 8,
                isExpanded: true,
                dropdownColor: context.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                items: [
                  DropdownMenuItem(
                    value: 'personal',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text('Personal'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'hospital',
                    child: Row(
                      children: [
                        Icon(Icons.local_hospital, size: 18, color: Colors.red),
                        const SizedBox(width: 12),
                        const Text('Hospital'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'blood_bank',
                    child: Row(
                      children: [
                        Icon(Icons.bloodtype, size: 18, color: AppConstants.primaryColor),
                        const SizedBox(width: 12),
                        const Text('Blood Bank'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ambulance',
                    child: Row(
                      children: [
                        Icon(Icons.emergency, size: 18, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Text('Ambulance'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedContactType = value;
                    });
                  }
                },
              ),
              SizedBox(height: verticalPadding * 1.25),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.06,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save, size: 20),
                  label: const Text(
                    'Save Contact',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: AppConstants.primaryColor.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _saveContact,
                ),
              ),
              SizedBox(height: verticalPadding),
            ],
          ),
        ),
      ),
    );
  }

  // Show success dialog for contact saved
  void _showContactSavedDialog() {
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
                  'Contact Saved',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
            content: Text(
              'The emergency contact has been saved successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: context.textColor,
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
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
                    'OK',
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

  // Save a new contact
  void _saveContact() async {
    if (_formKey.currentState?.validate() ?? false) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Create a new contact
      final newContact = EmergencyContactModel(
        id: '',
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        relationship: _relationshipController.text.trim(),
        address: _addressController.text.trim(),
        contactType: _selectedContactType,
        createdAt: DateTime.now(),
        userId: appProvider.currentUser.id,
      );

      // Show loading indicator
      if (mounted) {
        Navigator.pop(context); // Close the form
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Add the contact
      final success = await appProvider.addEmergencyContact(newContact);

      // Close loading indicator
      if (mounted) {
        Navigator.pop(context);
      }

      // Show result
      if (mounted) {
        if (success) {
          _showContactSavedDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to add contact'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Confirm and delete a contact
  void _confirmDeleteContact(EmergencyContactModel contact) {
    showDialog(
      context: context,
      builder:
          (context) => CustomAlertDialog(
            title: 'Delete Contact',
            content: 'Are you sure you want to delete ${contact.name}?',
            confirmText: 'Delete',
            cancelText: 'Cancel',
            confirmColor: Colors.red,
            onConfirm: () async {
              Navigator.pop(context); // Close dialog

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) =>
                        const Center(child: CircularProgressIndicator()),
              );

              // Delete the contact
              final appProvider = Provider.of<AppProvider>(
                context,
                listen: false,
              );
              final success = await appProvider.deleteEmergencyContact(
                contact.id,
              );

              // Close loading
              if (mounted) {
                Navigator.pop(context);
              }

              // Show result
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Contact deleted' : 'Failed to delete contact',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
          ),
    );
  }

  // Build a contact card
  Widget _buildContactCard(
    EmergencyContactModel contact, {
    required double horizontalPadding,
  }) {
    // Determine icon based on contact type
    IconData typeIcon;
    Color iconColor;

    switch (contact.contactType) {
      case 'hospital':
        typeIcon = Icons.local_hospital;
        iconColor = Colors.red;
        break;
      case 'blood_bank':
        typeIcon = Icons.bloodtype;
        iconColor = AppConstants.primaryColor;
        break;
      case 'ambulance':
        typeIcon = Icons.emergency;
        iconColor = Colors.orange;
        break;
      case 'personal':
      default:
        typeIcon = Icons.person;
        iconColor = Colors.blue;
    }

    final bool isSystemContact = contact.userId == 'system';
    final mediaQuery = MediaQuery.of(context);
    final bool isSmallScreen = mediaQuery.size.width < 360;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes based on card width
        final double avatarSize = constraints.maxWidth * 0.15;
        final double iconSize = avatarSize * 0.6;
        final double spacing = constraints.maxWidth * 0.04;

        return Card(
          margin: EdgeInsets.only(bottom: mediaQuery.size.height * 0.015),
          elevation: 3,
          shadowColor: iconColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: contact.isPinned
                ? BorderSide(color: AppConstants.primaryColor, width: 1.5)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _makePhoneCall(contact.phoneNumber),
            splashColor: iconColor.withOpacity(0.3),
            highlightColor: iconColor.withOpacity(0.1),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.isDarkMode
                        ? context.cardColor
                        : Colors.white,
                    context.isDarkMode
                        ? context.cardColor
                        : iconColor.withOpacity(0.05),
                  ],
                  stops: const [0.85, 1.0],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(mediaQuery.size.width * 0.035),
                child: Row(
                  children: [
                    // Contact avatar with subtle gradient
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            iconColor.withOpacity(0.15),
                            iconColor.withOpacity(0.25),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(typeIcon, color: iconColor, size: iconSize),
                      ),
                    ),
                    SizedBox(width: spacing),

                    // Contact info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    contact.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 14 : 16,
                                      color: context.textColor,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              if (contact.isPinned)
                                Container(
                                  margin: EdgeInsets.only(left: spacing * 0.5),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.push_pin,
                                    size: isSmallScreen ? 12 : 14,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: mediaQuery.size.height * 0.005),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.call,
                                  size: isSmallScreen ? 10 : 12,
                                  color: Colors.blue[700],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  contact.phoneNumber,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (contact.relationship.isNotEmpty) ...[
                            SizedBox(height: mediaQuery.size.height * 0.005),
                            Row(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: isSmallScreen ? 10 : 12,
                                  color: context.secondaryTextColor,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    contact.relationship,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 13,
                                      color: context.secondaryTextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Actions
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Call button
                        Container(
                          height: isSmallScreen ? 35 : 40,
                          width: isSmallScreen ? 35 : 40,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              splashColor: Colors.green.withOpacity(0.3),
                              onTap: () => _makePhoneCall(contact.phoneNumber),
                              child: Icon(
                                Icons.call,
                                color: Colors.green,
                                size: isSmallScreen ? 20 : 24,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 4),
                        
                        // Pin/unpin or delete button (only for user contacts)
                        if (!isSystemContact)
                          Container(
                            height: isSmallScreen ? 35 : 40,
                            width: isSmallScreen ? 35 : 40,
                            decoration: BoxDecoration(
                              color: context.isDarkMode 
                                  ? Colors.grey.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.more_vert,
                                color: context.secondaryTextColor,
                                size: isSmallScreen ? 20 : 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: context.backgroundColor,
                              elevation: 8,
                              offset: const Offset(0, 10),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: context.textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: context.textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!contact.isPinned)
                                  PopupMenuItem(
                                    value: 'pin',
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppConstants.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            Icons.push_pin,
                                            size: 18,
                                            color: AppConstants.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Pin to Top',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: context.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  PopupMenuItem(
                                    value: 'unpin',
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            Icons.push_pin_outlined,
                                            size: 18,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Unpin',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: context.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _confirmDeleteContact(contact);
                                } else if (value == 'pin') {
                                  _togglePinContact(contact, true);
                                } else if (value == 'unpin') {
                                  _togglePinContact(contact, false);
                                } else if (value == 'edit') {
                                  _showEditContactDialog(contact);
                                }
                              },
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
      },
    );
  }

  // Build contacts tab
  Widget _buildContactsTab() {
    final mediaQuery = MediaQuery.of(context);
    final horizontalPadding = mediaQuery.size.width * 0.04;
    final bottomPadding = mediaQuery.size.height * 0.1; // For FAB

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_contacts.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double iconSize = constraints.maxWidth * 0.2;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize * 1.5,
                  height: iconSize * 1.5,
                  decoration: BoxDecoration(
                    color: context.isDarkMode 
                        ? AppConstants.primaryColor.withOpacity(0.1)
                        : AppConstants.primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.contacts_outlined, 
                      size: iconSize, 
                      color: AppConstants.primaryColor.withOpacity(0.5),
                    ),
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.04),
                Text(
                  'No Emergency Contacts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.02),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Text(
                    'Add important contacts that you might need in emergency situations',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: context.secondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.05),
                ElevatedButton.icon(
                  onPressed: _showAddContactDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Your First Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Filter contacts by system and user
    final systemContacts =
        _contacts.where((c) => c.userId == 'system').toList();
    final userContacts = _contacts.where((c) => c.userId != 'system').toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        mediaQuery.size.height * 0.01,
        horizontalPadding,
        bottomPadding,
      ),
      children: [
        // System contacts section
        if (systemContacts.isNotEmpty) ...[
          Container(
            margin: EdgeInsets.symmetric(
              vertical: mediaQuery.size.height * 0.015,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.red.withOpacity(0.2),
                  Colors.red.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_hospital_outlined,
                  size: 20,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Emergency Services',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: mediaQuery.size.width < 360 ? 14 : 16,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
          ...systemContacts.map(
            (contact) => _buildContactCard(
              contact,
              horizontalPadding: horizontalPadding,
            ),
          ),
          Divider(
            height: mediaQuery.size.height * 0.04,
            thickness: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
        ],

        // User contacts section
        if (userContacts.isNotEmpty) ...[
          Container(
            margin: EdgeInsets.symmetric(
              vertical: mediaQuery.size.height * 0.015,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppConstants.primaryColor.withOpacity(0.2),
                  AppConstants.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 20,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'My Contacts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: mediaQuery.size.width < 360 ? 14 : 16,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
          ...userContacts.map(
            (contact) => _buildContactCard(
              contact,
              horizontalPadding: horizontalPadding,
            ),
          ),
        ],
      ],
    );
  }

  // Build the quick dial tab
  Widget _buildQuickDialTab() {
    final mediaQuery = MediaQuery.of(context);
    final bool isSmallScreen = mediaQuery.size.width < 360;
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive grid layout
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;

        // Determine grid columns based on orientation and screen size
        final int crossAxisCount;
        final double childAspectRatio;

        if (isLandscape) {
          // Landscape mode has more horizontal space
          crossAxisCount = availableWidth > 600 ? 4 : 3;
          childAspectRatio = 1.3;
        } else {
          // Portrait mode
          crossAxisCount = availableWidth > 600 ? 3 : 2;
          childAspectRatio = isSmallScreen ? 0.9 : 1.0;
        }

        // Calculate responsive padding and spacing
        final double padding = availableWidth * 0.04;
        final double spacing = availableWidth * 0.02;

        return GridView.count(
          physics: const BouncingScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          padding: EdgeInsets.all(padding),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          children: [
            _buildQuickDialCard(
              title: 'Ambulance',
              phoneNumber: '108',
              icon: Icons.emergency,
              color: Colors.red,
              constraints: constraints,
            ),
            _buildQuickDialCard(
              title: 'Emergency',
              phoneNumber: '112',
              icon: Icons.phone_in_talk,
              color: Colors.orange,
              constraints: constraints,
            ),
            _buildQuickDialCard(
              title: 'Blood Bank',
              phoneNumber: '104',
              icon: Icons.bloodtype,
              color: AppConstants.primaryColor,
              constraints: constraints,
            ),
            _buildQuickDialCard(
              title: 'Police',
              phoneNumber: '100',
              icon: Icons.local_police,
              color: Colors.blue[800]!,
              constraints: constraints,
            ),
            _buildQuickDialCard(
              title: 'Fire',
              phoneNumber: '101',
              icon: Icons.local_fire_department,
              color: Colors.deepOrange,
              constraints: constraints,
            ),
            _buildQuickDialCard(
              title: 'Women Helpline',
              phoneNumber: '1091',
              icon: Icons.people,
              color: Colors.purple,
              constraints: constraints,
            ),
          ],
        );
      },
    );
  }

  // Build a quick dial card
  Widget _buildQuickDialCard({
    required String title,
    required String phoneNumber,
    required IconData icon,
    required Color color,
    required BoxConstraints constraints,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final bool isSmallScreen = mediaQuery.size.width < 360;
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Card(
      elevation: 3,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _makePhoneCall(phoneNumber),
        splashColor: color.withOpacity(0.3),
        highlightColor: color.withOpacity(0.1),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.isDarkMode 
                    ? context.cardColor
                    : Colors.white,
                context.isDarkMode 
                    ? Colors.grey.withOpacity(0.05)
                    : color.withOpacity(0.05),
              ],
              stops: const [0.8, 1.0],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(constraints.maxWidth * 0.02),
            child: LayoutBuilder(
              builder: (context, cardConstraints) {
                // Calculate responsive sizes based on available card space
                final double iconSize = cardConstraints.maxWidth * 0.3;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon container with flexible sizing
                    Container(
                      height: cardConstraints.maxHeight * 0.45,
                      width: iconSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.15),
                            color.withOpacity(0.25),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(icon, color: color, size: iconSize * 0.6),
                      ),
                    ),

                    // Flexible spacing
                    SizedBox(height: cardConstraints.maxHeight * 0.05),

                    // Title with fitted text
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 16,
                        color: context.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Phone number with call icon
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.call,
                            size: isSmallScreen ? 12 : 14,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            phoneNumber,
                            style: TextStyle(
                              color: color,
                              fontSize: isSmallScreen ? 13 : 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Toggle pin status of a contact
  void _togglePinContact(EmergencyContactModel contact, bool isPinned) async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.toggleContactPinStatus(contact.id, isPinned);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPinned ? 'Contact pinned to top' : 'Contact unpinned'),
          backgroundColor: AppConstants.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating contact: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show dialog to edit an existing contact
  void _showEditContactDialog(EmergencyContactModel contact) {
    // Set form fields to current values
    _nameController.text = contact.name;
    _phoneController.text = contact.phoneNumber;
    _relationshipController.text = contact.relationship ?? '';
    _addressController.text = contact.address ?? '';
    _selectedContactType = contact.contactType;
    
    // Only set _selectedRelationship if it matches one of our predefined options, otherwise set to empty
    String relationshipValue = contact.relationship ?? '';
    final List<String> validRelationships = [
      'Spouse', 'Parent', 'Child', 'Sibling', 'Relative', 
      'Friend', 'Colleague', 'Doctor', 'Caregiver', 'Other'
    ];
    
    _selectedRelationship = validRelationships.contains(relationshipValue) 
        ? relationshipValue 
        : '';
        
    // If the relationship doesn't match our dropdown options but has a value,
    // we'll keep it in the controller for saving but not select it in the dropdown
    if (!validRelationships.contains(relationshipValue) && relationshipValue.isNotEmpty) {
      _relationshipController.text = relationshipValue;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEditContactForm(context, contact),
    );
  }

  // Build the edit contact form
  Widget _buildEditContactForm(BuildContext context, EmergencyContactModel contact) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final textTheme = Theme.of(context).textTheme;

    // Calculate responsive padding
    final double verticalPadding = screenHeight * 0.02;
    final double horizontalPadding = mediaQuery.size.width * 0.05;

    return Container(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
        top: verticalPadding,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85, // Limit max height to 85% of screen
      ),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusL),
          topRight: Radius.circular(AppConstants.radiusL),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form title
              Center(
                child: Container(
                  height: 4,
                  width: mediaQuery.size.width * 0.1,
                  margin: EdgeInsets.only(bottom: verticalPadding),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Edit Emergency Contact',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: verticalPadding),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  labelStyle: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.person, color: AppConstants.primaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.5,
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
                      color: Colors.red.shade300,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.red.shade500,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.isDarkMode 
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: verticalPadding * 0.75),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  labelStyle: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.phone, color: AppConstants.primaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.5,
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
                      color: Colors.red.shade300,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.red.shade500,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.isDarkMode 
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: verticalPadding * 0.75),

              // Relationship field
              DropdownButtonFormField<String>(
                value: _selectedRelationship.isEmpty ? null : _selectedRelationship,
                decoration: InputDecoration(
                  labelText: 'Relationship',
                  labelStyle: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.people, color: AppConstants.primaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppConstants.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.isDarkMode 
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                hint: Text(
                  'Select Relationship',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                icon: Icon(
                  Icons.arrow_drop_down_circle,
                  color: AppConstants.primaryColor,
                ),
                iconSize: 24,
                elevation: 8,
                isExpanded: true,
                dropdownColor: context.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                items: [
                  DropdownMenuItem(
                    value: 'Spouse',
                    child: Row(
                      children: [
                        Icon(Icons.favorite, size: 18, color: Colors.pink),
                        const SizedBox(width: 12),
                        const Text('Spouse'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Parent',
                    child: Row(
                      children: [
                        Icon(Icons.family_restroom, size: 18, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text('Parent'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Child',
                    child: Row(
                      children: [
                        Icon(Icons.child_care, size: 18, color: Colors.green),
                        const SizedBox(width: 12),
                        const Text('Child'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Sibling',
                    child: Row(
                      children: [
                        Icon(Icons.people_outline, size: 18, color: Colors.purple),
                        const SizedBox(width: 12),
                        const Text('Sibling'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Relative',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 18, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Text('Relative'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Friend',
                    child: Row(
                      children: [
                        Icon(Icons.emoji_people, size: 18, color: Colors.amber),
                        const SizedBox(width: 12),
                        const Text('Friend'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Colleague',
                    child: Row(
                      children: [
                        Icon(Icons.work_outline, size: 18, color: Colors.brown),
                        const SizedBox(width: 12),
                        const Text('Colleague'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Doctor',
                    child: Row(
                      children: [
                        Icon(Icons.medical_services, size: 18, color: Colors.red),
                        const SizedBox(width: 12),
                        const Text('Doctor'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Caregiver',
                    child: Row(
                      children: [
                        Icon(Icons.healing, size: 18, color: AppConstants.primaryColor),
                        const SizedBox(width: 12),
                        const Text('Caregiver'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Row(
                      children: [
                        Icon(Icons.more_horiz, size: 18, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Text('Other'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRelationship = value;
                      _relationshipController.text = value;
                    });
                  }
                },
              ),
              SizedBox(height: verticalPadding * 0.75),

              // Address field
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.location_on, color: AppConstants.primaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppConstants.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.isDarkMode 
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                maxLines: 2,
              ),
              SizedBox(height: verticalPadding * 0.75),

              // Contact type dropdown
              DropdownButtonFormField<String>(
                value: _selectedContactType,
                decoration: InputDecoration(
                  labelText: 'Contact Type',
                  labelStyle: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.category, color: AppConstants.primaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppConstants.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.isDarkMode 
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                icon: Icon(
                  Icons.arrow_drop_down_circle,
                  color: AppConstants.primaryColor,
                ),
                iconSize: 24,
                elevation: 8,
                isExpanded: true,
                dropdownColor: context.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                items: [
                  DropdownMenuItem(
                    value: 'personal',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text('Personal'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'hospital',
                    child: Row(
                      children: [
                        Icon(Icons.local_hospital, size: 18, color: Colors.red),
                        const SizedBox(width: 12),
                        const Text('Hospital'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'blood_bank',
                    child: Row(
                      children: [
                        Icon(Icons.bloodtype, size: 18, color: AppConstants.primaryColor),
                        const SizedBox(width: 12),
                        const Text('Blood Bank'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ambulance',
                    child: Row(
                      children: [
                        Icon(Icons.emergency, size: 18, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Text('Ambulance'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedContactType = value;
                    });
                  }
                },
              ),
              SizedBox(height: verticalPadding * 1.5),

              // Submit button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        backgroundColor: Colors.grey[300],
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.018,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: mediaQuery.size.width * 0.04),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateContact(contact),
                      icon: const Icon(Icons.save),
                      label: const Text('Update Contact'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.018,
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

  // Update an existing contact
  void _updateContact(EmergencyContactModel contact) async {
    if (_formKey.currentState!.validate()) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      Navigator.pop(context); // Close the dialog

      try {
        final updatedContact = EmergencyContactModel(
          id: contact.id,
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          relationship: _relationshipController.text.trim(),
          address: _addressController.text.trim(),
          contactType: _selectedContactType,
          createdAt: contact.createdAt,
          userId: contact.userId,
        );

        await appProvider.updateEmergencyContact(updatedContact);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error updating contact: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating contact: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Delete a contact
  void _deleteContact(EmergencyContactModel contact) async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.deleteEmergencyContact(contact.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting contact: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting contact: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final tabIconSize = isSmallScreen ? 20.0 : 24.0;
    final tabLabelFontSize = isSmallScreen ? 11.0 : 14.0;

    // Use a safe area to avoid system intrusions
    return SafeArea(
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: const Text('Emergency Contacts'),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor, 
                  Colors.redAccent.shade700
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3.0,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            dividerColor: Colors.transparent,
            isScrollable: false,
            labelPadding: EdgeInsets.zero,
            indicatorSize: TabBarIndicatorSize.tab,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            // Add tab indicator decoration
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            splashBorderRadius: BorderRadius.circular(30),
            tabs: [
              Tab(
                icon: Icon(Icons.contacts, size: tabIconSize),
                text: 'Contacts',
                iconMargin: const EdgeInsets.only(bottom: 4),
              ),
              Tab(
                icon: Icon(Icons.call, size: tabIconSize),
                text: 'Quick Dial',
                iconMargin: const EdgeInsets.only(bottom: 4),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildContactsTab(), _buildQuickDialTab()],
        ),
        floatingActionButton: Container(
          height: mediaQuery.size.height * 0.06,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _showAddContactDialog,
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Add Contact',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
