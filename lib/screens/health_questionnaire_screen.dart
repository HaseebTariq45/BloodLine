import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/theme_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/services.dart'; // For haptic feedback
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/temp_list_field.dart'; // Import the temporary list field widget

// Custom CheckMark painter for animating the checkmark
class CheckMarkPainter extends CustomPainter {
  final double animation;
  final Color color;
  final double strokeWidth;

  CheckMarkPainter({required this.animation, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Calculate the check mark points based on size
    final double startX = size.width * 0.2;
    final double midY = size.height * 0.65;
    final double midX = size.width * 0.45;
    final double endX = size.width * 0.8;
    final double endY = size.height * 0.35;
    
    // First part of the check mark (shorter line)
    if (animation < 0.5) {
      final pct = animation * 2;
      path.moveTo(startX, midY);
      path.lineTo(startX + (midX - startX) * pct, midY - (midY - endY) * pct);
    } else {
      path.moveTo(startX, midY);
      path.lineTo(midX, endY);
      
      // Second part of the check mark (longer line)
      final pct = (animation - 0.5) * 2;
      path.lineTo(midX + (endX - midX) * pct, endY + (midY - endY) * pct);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckMarkPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class HealthQuestionnaireScreen extends StatefulWidget {
  final bool isPostSignup;
  
  const HealthQuestionnaireScreen({
    super.key,
    this.isPostSignup = false,
  });

  @override
  State<HealthQuestionnaireScreen> createState() => _HealthQuestionnaireScreenState();
}

class _HealthQuestionnaireScreenState extends State<HealthQuestionnaireScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  final ScrollController _scrollController = ScrollController();
  
  // Animation controllers for dialogs
  late AnimationController _successAnimationController;
  late Animation<double> _successAnimation;
  late AnimationController _errorAnimationController;
  late Animation<double> _errorAnimation;
  late AnimationController _scrollAnimationController;

  // Form controllers
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _lastDonationController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _diseasesController = TextEditingController();
  
  // List to store medications and allergies
  List<String> _medicationsList = [];
  List<String> _allergiesList = [];
  List<String> _diseasesList = [];
  
  // Controllers for adding new items
  final _newMedicationController = TextEditingController();
  final _newAllergyController = TextEditingController();
  final _newDiseaseController = TextEditingController();

  // Form values
  String _gender = 'Male';
  bool _hasTattoo = false;
  bool _hasPiercing = false;
  bool _hasTraveled = false;
  bool _hasSurgery = false;
  bool _hasTransfusion = false;
  bool _hasPregnancy = false;
  bool _hasDisease = false;
  bool _hasMedication = false;
  bool _hasAllergies = false;

  // Health status indicators
  String _healthStatus = 'Good';
  Color _healthStatusColor = Colors.green;
  String _nextDonationDate = '';

  @override
  void initState() {
    super.initState();
    _loadHealthInfo();
    
    // Initialize animation controllers
    _successAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _successAnimation = CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.easeInOut,
    );
    
    _errorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _errorAnimation = CurvedAnimation(
      parent: _errorAnimationController,
      curve: Curves.easeInOut,
    );
    
    _scrollAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Add scroll listener for animations
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > 50 && !_scrollAnimationController.isCompleted) {
        _scrollAnimationController.forward();
      } else if (_scrollController.position.pixels <= 50 && _scrollAnimationController.isCompleted) {
        _scrollAnimationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _heightController.dispose();
    _weightController.dispose();
    _lastDonationController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _diseasesController.dispose();
    _newMedicationController.dispose();
    _newAllergyController.dispose();
    _newDiseaseController.dispose();
    _successAnimationController.dispose();
    _errorAnimationController.dispose();
    _scrollAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateHealthStatus() {
    if (_hasDisease || _hasMedication || _hasAllergies) {
      _healthStatus = 'Needs Review';
      _healthStatusColor = Colors.orange;
    } else if (_hasTattoo || _hasPiercing || _hasTraveled || _hasSurgery || _hasTransfusion || _hasPregnancy) {
      _healthStatus = 'Temporary Deferral';
      _healthStatusColor = Colors.red;
    } else {
      _healthStatus = 'Good';
      _healthStatusColor = Colors.green;
    }

    // Calculate next donation date
    if (_lastDonationController.text.isNotEmpty) {
      try {
        final lastDonation = DateTime.parse(_lastDonationController.text);
        // Standard waiting period is 56 days (8 weeks) between whole blood donations
        final nextDonation = lastDonation.add(const Duration(days: 56));
        _nextDonationDate = nextDonation.toString().split(' ')[0];
        debugPrint('Calculated next donation date: $_nextDonationDate');
      } catch (e) {
        debugPrint('Error calculating next donation date: $e');
        _nextDonationDate = '';
      }
    } else {
      _nextDonationDate = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        elevation: 0,
        title: Text(
          'Health Questionnaire',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
        leading: widget.isPostSignup
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
        actions: [
          if (_hasUnsavedChanges)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              child: Tooltip(
                message: 'You have unsaved changes',
                child: Icon(
                    Icons.info_outline,
                    color: Colors.amber[800],
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _scrollAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 100 * (1 - _scrollAnimationController.value)),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _scrollAnimationController.value,
              child: FloatingActionButton(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );
                },
                backgroundColor: AppConstants.primaryColor,
                child: const Icon(Icons.arrow_upward_rounded),
                mini: true,
              ),
            ),
          );
        },
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your health information...',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isPostSignup)
                        FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _successAnimationController,
                            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _successAnimationController,
                              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                            )),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppConstants.primaryColor.withOpacity(0.15),
                                    AppConstants.primaryColor.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppConstants.primaryColor.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                    ),
                    child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                      children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppConstants.primaryColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                          Icons.info_outline,
                          color: AppConstants.primaryColor,
                                      size: 24,
                        ),
                                  ),
                                  const SizedBox(width: 16),
                        Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Complete Your Profile',
                            style: TextStyle(
                              color: AppConstants.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Please complete your health questionnaire to continue. This information is important for blood donation eligibility.',
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white.withOpacity(0.8)
                                                : Colors.black87.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                                            height: 1.4,
                            ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                        ),
                                      ],
                          ),
                        ),
                      ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _successAnimationController,
                          curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _successAnimationController,
                            curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
                          )),
                          child: _buildHealthStatusIndicator(),
                        ),
                      ),
                const SizedBox(height: 24),
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _successAnimationController,
                          curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _successAnimationController,
                            curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
                          )),
                          child: _buildSectionCard(
                  title: 'Basic Information',
                  icon: Icons.person_outline,
                  child: Column(
                    children: [
                      _buildCustomField(
                        controller: _heightController,
                        label: 'Height (cm)',
                        icon: Icons.height,
                        hint: 'Enter your height',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your height';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildCustomField(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        icon: Icons.monitor_weight_outlined,
                        hint: 'Enter your weight',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your weight';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        label: 'Gender',
                        value: _gender,
                        items: ['Male', 'Female', 'Other'],
                        icon: Icons.person,
                        onChanged: (value) {
                          setState(() {
                            _gender = value!;
                            _hasUnsavedChanges = true;
                          });
                          _startAutoSaveTimer();
                        },
                      ),
                    ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _successAnimationController,
                          curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _successAnimationController,
                            curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
                          )),
                          child: _buildSectionCard(
                  title: 'Donation History',
                  icon: Icons.history,
                  child: Column(
                    children: [
                      _buildCustomField(
                        controller: _lastDonationController,
                        label: 'Last Donation Date',
                        icon: Icons.calendar_today,
                        isDate: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a date';
                          }
                          return null;
                        },
                      ),
                    ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _successAnimationController,
                          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _successAnimationController,
                            curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                          )),
                          child: _buildSectionCard(
                  title: 'Health Status',
                  icon: Icons.health_and_safety,
                  child: Column(
                    children: [
                      _buildSwitchField(
                        title: 'Recent Tattoo',
                        subtitle: 'Tattoo within the last 6 months',
                        value: _hasTattoo,
                        onChanged: (value) {
                          setState(() {
                            _hasTattoo = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        title: 'Recent Piercing',
                        subtitle: 'Piercing within the last 6 months',
                        value: _hasPiercing,
                        onChanged: (value) {
                          setState(() {
                            _hasPiercing = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        title: 'Recent Travel',
                        subtitle: 'Traveled outside the country in the last 6 months',
                        value: _hasTraveled,
                        onChanged: (value) {
                          setState(() {
                            _hasTraveled = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        title: 'Recent Surgery',
                        subtitle: 'Surgery within the last 6 months',
                        value: _hasSurgery,
                        onChanged: (value) {
                          setState(() {
                            _hasSurgery = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        title: 'Recent Blood Transfusion',
                        subtitle: 'Blood transfusion within the last 6 months',
                        value: _hasTransfusion,
                        onChanged: (value) {
                          setState(() {
                            _hasTransfusion = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        title: 'Recent Pregnancy',
                        subtitle: 'Pregnant or planning to become pregnant',
                        value: _hasPregnancy,
                        onChanged: (value) {
                          setState(() {
                            _hasPregnancy = value;
                          });
                        },
                      ),
                      _buildSwitchField(
                        title: 'Chronic Disease',
                        subtitle: 'Any chronic disease or condition',
                        value: _hasDisease,
                        onChanged: (value) {
                          setState(() {
                            _hasDisease = value;
                          });
                        },
                      ),
                      if (_hasDisease) ...[
                        const SizedBox(height: 16),
                        buildListField(
                          context: context,
                          title: 'Chronic Diseases',
                          hintText: 'Add a disease or condition',
                          items: _diseasesList,
                          controller: _newDiseaseController,
                          onAdd: _addDisease,
                          onRemove: _removeDisease,
                          itemIcon: Icons.health_and_safety,
                        ),
                      ],
                      _buildSwitchField(
                        title: 'Current Medications',
                        subtitle: 'Taking any medications',
                        value: _hasMedication,
                        onChanged: (value) {
                          setState(() {
                            _hasMedication = value;
                          });
                        },
                      ),
                      if (_hasMedication) ...[
                        const SizedBox(height: 16),
                        buildListField(
                          context: context,
                          title: 'Medications',
                          hintText: 'Add a medication',
                          items: _medicationsList,
                          controller: _newMedicationController,
                          onAdd: _addMedication,
                          onRemove: _removeMedication,
                          itemIcon: Icons.medication,
                        ),
                      ],
                      _buildSwitchField(
                        title: 'Allergies',
                        subtitle: 'Allergies to any substances',
                        value: _hasAllergies,
                        onChanged: (value) {
                          setState(() {
                            _hasAllergies = value;
                          });
                        },
                      ),
                      if (_hasAllergies) ...[
                        const SizedBox(height: 16),
                        buildListField(
                          context: context,
                          title: 'Allergies',
                          hintText: 'Add an allergy',
                          items: _allergiesList,
                          controller: _newAllergyController,
                          onAdd: _addAllergy,
                          onRemove: _removeAllergy,
                          itemIcon: Icons.warning_amber,
                        ),
                      ],
                    ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                      if (_hasUnsavedChanges)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.amber[700],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You have unsaved changes. Save to update your health information.',
                                  style: TextStyle(
                                    color: Colors.amber[800],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                  width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppConstants.primaryColor,
                              AppConstants.primaryColor.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveHealthInfo,
                    style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                      ),
                            elevation: 0,
                    ),
                    child: _isLoading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.isPostSignup ? Icons.check_circle_outline : Icons.save_outlined,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                            widget.isPostSignup ? 'Complete Profile' : 'Save Health Information',
                            style: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.25) 
                : Colors.grey.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppConstants.primaryColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                  AppConstants.primaryColor.withOpacity(isDarkMode ? 0.15 : 0.08),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: AppConstants.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    color: isDarkMode 
                        ? Colors.white 
                        : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Section Content with subtle background
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.grey[850] 
                  : Colors.grey[50]!.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool isDate = false,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: isDate,
      onTap: isDate ? () => _selectDate(controller) : null,
      validator: validator,
      onChanged: (_) {
        setState(() {
          _hasUnsavedChanges = true;
        });
        _startAutoSaveTimer();
      },
        style: TextStyle(
          fontSize: 16,
          color: isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
          icon,
          color: AppConstants.primaryColor,
              size: 20,
            ),
          ),
          suffixIcon: isDate
              ? Icon(
                  Icons.calendar_today_rounded,
                  color: AppConstants.primaryColor.withOpacity(0.7),
                  size: 20,
                )
              : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppConstants.primaryColor,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.redAccent,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty
          ? DateTime.parse(controller.text)
          : now.subtract(const Duration(days: 60)), // Default to 60 days ago
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppConstants.primaryColor,
                ),
            dialogBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        controller.text = "${picked.toIso8601String().split('T')[0]}";
        _updateHealthStatus();
        _hasUnsavedChanges = true;
      });
      _startAutoSaveTimer();
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    int? maxLines,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      onTap: onTap,
      validator: validator,
      onChanged: (_) {
        setState(() {
          _hasUnsavedChanges = true;
        });
        _startAutoSaveTimer();
      },
      style: TextStyle(
          fontSize: 16,
        color: isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
          prefixIcon,
          color: AppConstants.primaryColor,
              size: 20,
            ),
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppConstants.primaryColor,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 1.5,
          ),
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            fontWeight: FontWeight.w500,
        ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
      child: DropdownButtonFormField<String>(
        value: value,
          icon: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_drop_down_rounded,
              color: AppConstants.primaryColor,
              size: 28,
            ),
          ),
        iconSize: 24,
        decoration: InputDecoration(
          labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            prefixIcon: icon != null 
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          border: InputBorder.none,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              fontWeight: FontWeight.w500,
          ),
        ),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 16,
            fontWeight: FontWeight.w500,
        ),
        dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          menuMaxHeight: 300,
          isExpanded: true,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _hasUnsavedChanges = true;
          });
          onChanged(newValue);
        },
        ),
      ),
    );
  }

  Widget _buildSwitchField({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: value
              ? [
                  AppConstants.primaryColor.withOpacity(isDarkMode ? 0.25 : 0.15),
                  AppConstants.primaryColor.withOpacity(isDarkMode ? 0.15 : 0.05),
                ]
              : [
                  isDarkMode ? Colors.grey[800]! : Colors.grey[50]!,
                  isDarkMode ? Colors.grey[850]! : Colors.grey[100]!,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value 
              ? AppConstants.primaryColor.withOpacity(isDarkMode ? 0.6 : 0.4)
              : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
          width: value ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (value)
            BoxShadow(
              color: AppConstants.primaryColor.withOpacity(isDarkMode ? 0.15 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          else
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              onChanged(!value);
              _updateHealthStatus();
            },
            splashColor: AppConstants.primaryColor.withOpacity(0.15),
            highlightColor: value 
                ? AppConstants.primaryColor.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: value
                                ? AppConstants.primaryColor.withOpacity(isDarkMode ? 0.9 : 1.0)
                                : (isDarkMode ? Colors.white : Colors.black87),
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
          subtitle,
          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: _buildCustomSwitch(
        value: value,
        onChanged: (newValue) {
                        HapticFeedback.mediumImpact();
          onChanged(newValue);
          _updateHealthStatus();
        },
        activeColor: AppConstants.primaryColor,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Custom switch with smooth animation
  Widget _buildCustomSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value 
              ? activeColor 
              : isDarkMode ? Colors.grey[700] : Colors.grey[300],
          boxShadow: [
            BoxShadow(
              color: value
                  ? activeColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 0.5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Stack(
            children: [
              // Track overlay
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: value ? 2 : 0,
                right: value ? 0 : 2,
                top: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: value ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          activeColor.withOpacity(0.1),
                          activeColor.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Knob
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: value
                            ? activeColor.withOpacity(0.4)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: value ? 1.0 : 0.0,
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activeColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthStatusIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _healthStatusColor.withOpacity(isDarkMode ? 0.25 : 0.15),
            _healthStatusColor.withOpacity(isDarkMode ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _healthStatusColor.withOpacity(isDarkMode ? 0.4 : 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _healthStatusColor.withOpacity(isDarkMode ? 0.2 : 0.15),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          ClipRRect(
              borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _healthStatusColor.withOpacity(isDarkMode ? 0.45 : 0.35),
                    _healthStatusColor.withOpacity(isDarkMode ? 0.30 : 0.20),
                  ],
              ),
            ),
            child: Row(
              children: [
                Container(
                    padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _healthStatusColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                          spreadRadius: 1,
                        ),
                      ],
                  ),
                  child: Icon(
                    _getHealthStatusIcon(),
                    color: _healthStatusColor,
                      size: 28,
                  ),
                ),
                  const SizedBox(width: 16),
                Text(
                  'Donation Eligibility',
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.white
                        : Colors.black87,
                      fontSize: 20,
                    fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
              ),
            ),
          ),
          // Status Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                      ? Colors.black.withOpacity(0.15)
                      : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _healthStatusColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Current Status',
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black87.withOpacity(0.6),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _healthStatusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: _healthStatusColor.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getHealthStatusIcon(),
                              color: _healthStatusColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _healthStatus,
                              style: TextStyle(
                                color: _healthStatusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (_nextDonationDate.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                        ? Colors.black.withOpacity(0.15)
                        : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkMode 
                            ? Colors.grey.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppConstants.primaryColor.withOpacity(0.8),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Next Donation Date',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.black87.withOpacity(0.6),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _nextDonationDate,
                            style: TextStyle(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getHealthStatusIcon() {
    switch (_healthStatus) {
      case 'Good':
        return Icons.check_circle;
      case 'Needs Review':
        return Icons.info;
      case 'Temporary Deferral':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  Future<void> _loadHealthInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Load health questionnaire data
        final doc = await FirebaseFirestore.instance
            .collection('health_questionnaires')
            .doc(userId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          _heightController.text = data['height'] ?? '';
          _weightController.text = data['weight'] ?? '';
          _lastDonationController.text = data['lastDonationDate'] ?? '';
          _gender = data['gender'] ?? 'Male';
          _hasTattoo = data['hasTattoo'] ?? false;
          _hasPiercing = data['hasPiercing'] ?? false;
          _hasTraveled = data['hasTraveled'] ?? false;
          _hasSurgery = data['hasSurgery'] ?? false;
          _hasTransfusion = data['hasTransfusion'] ?? false;
          _hasPregnancy = data['hasPregnancy'] ?? false;
          _hasDisease = data['hasDisease'] ?? false;
          _hasMedication = data['hasMedication'] ?? false;
          _hasAllergies = data['hasAllergies'] ?? false;
          _medicationsController.text = data['medications'] ?? '';
          _allergiesController.text = data['allergies'] ?? '';
          _diseasesController.text = data['diseases'] ?? '';
          
          // Parse the medications and allergies lists from strings
          _parseSavedLists();
        }
        
        // If lastDonationDate is empty, try to get it from the user profile
        if (_lastDonationController.text.isEmpty) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
                
            if (userDoc.exists && userDoc.data() != null) {
              final userData = userDoc.data()!;
              
              if (userData['lastDonationDate'] != null) {
                DateTime lastDonation;
                
                if (userData['lastDonationDate'] is Timestamp) {
                  lastDonation = (userData['lastDonationDate'] as Timestamp).toDate();
                } else if (userData['lastDonationDate'] is int) {
                  lastDonation = DateTime.fromMillisecondsSinceEpoch(userData['lastDonationDate']);
                } else if (userData['lastDonationDate'] is String) {
                  lastDonation = DateTime.parse(userData['lastDonationDate']);
                } else {
                  throw Exception('Unsupported lastDonationDate format');
                }
                
                // Format as YYYY-MM-DD
                _lastDonationController.text = lastDonation.toString().split(' ')[0];
              }
            }
          } catch (e) {
            debugPrint('Error fetching user data: $e');
          }
        }
        
        _updateHealthStatus();
      }
    } catch (e) {
      debugPrint('Error loading health info: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text('Error loading health information: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
        setState(() {
          _isLoading = false;
        });
      
      // Start animations after loading is complete
      _successAnimationController.forward();
    }
  }

  Future<void> _saveHealthInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Save to health_questionnaires collection
        await FirebaseFirestore.instance
            .collection('health_questionnaires')
            .doc(userId)
            .set({
          'height': _heightController.text,
          'weight': _weightController.text,
          'lastDonationDate': _lastDonationController.text,
          'gender': _gender,
          'hasTattoo': _hasTattoo,
          'hasPiercing': _hasPiercing,
          'hasTraveled': _hasTraveled,
          'hasSurgery': _hasSurgery,
          'hasTransfusion': _hasTransfusion,
          'hasPregnancy': _hasPregnancy,
          'hasDisease': _hasDisease,
          'hasMedication': _hasMedication,
          'hasAllergies': _hasAllergies,
          'medications': _medicationsController.text,
          'allergies': _allergiesController.text,
          'diseases': _diseasesController.text,
        });

        // Update lastDonationDate in users collection if it has been set
        if (_lastDonationController.text.isNotEmpty) {
          try {
            // Convert string date to timestamp
            final lastDonationDate = DateTime.parse(_lastDonationController.text);
            
            // Update the user document
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({
              'lastDonationDate': lastDonationDate.millisecondsSinceEpoch,
            });
            
            // Also update the user model in the app provider
            final appProvider = Provider.of<AppProvider>(context, listen: false);
            final currentUser = appProvider.currentUser;
            final updatedUser = currentUser.copyWith(
              lastDonationDate: lastDonationDate,
            );
            await appProvider.updateUserProfile(updatedUser);
            
            debugPrint('Updated lastDonationDate in users collection: ${lastDonationDate.toIso8601String()}');
          } catch (e) {
            debugPrint('Error updating lastDonationDate in users collection: $e');
            // Continue with the rest of the function even if this update fails
          }
        }

        if (mounted) {
          // Provide haptic feedback when data is saved
          HapticFeedback.mediumImpact();
          
          // Clear the unsaved changes flag
          setState(() {
            _hasUnsavedChanges = false;
          });
          
          // Show a visually appealing success popup instead of a simple snackbar
          _showSaveSuccessDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        // Vibrate with error pattern for failure
        HapticFeedback.vibrate();
        
        // Show a visually appealing error popup
        _showErrorDialog('Error saving health information: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Custom visually appealing success dialog
  void _showSaveSuccessDialog() {
    // Reset and start the animation
    _successAnimationController.reset();
    _successAnimationController.forward();
    
    // Refresh app provider data
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.refreshUserData();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Container(); // Not used
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _successAnimationController,
                        builder: (context, child) {
                          return Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Growing circle animation
                                Transform.scale(
                                  scale: _successAnimation.value,
                                  child: Container(
                                    width: 75,
                                    height: 75,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                // Check mark animation
                                CustomPaint(
                                  size: const Size(40, 40),
                                  painter: CheckMarkPainter(
                                    animation: _successAnimation.value,
                                    color: Colors.green,
                                    strokeWidth: 4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _successAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _successAnimation.value,
                            child: Text(
                              'Success!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.headlineMedium?.color,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      // Animated text with fade and slide
                      AnimatedBuilder(
                        animation: _successAnimationController,
                        builder: (context, child) {
                          // Determine if we should show this element based on animation progress
                          final showElement = _successAnimation.value >= 0.3; // Show after 30% of animation
                          final elementAnimation = showElement 
                            ? (_successAnimation.value - 0.3) / 0.7 // Normalize to 0-1 for the remaining 70%
                            : 0.0;
                          
                          return Opacity(
                            opacity: elementAnimation,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - elementAnimation)),
                              child: Text(
                                'Your health information has been saved successfully.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 25),
                      // Animated button with fade
                      AnimatedBuilder(
                        animation: _successAnimationController,
                        builder: (context, child) {
                          // Determine if we should show this element based on animation progress
                          final showElement = _successAnimation.value >= 0.5; // Show after 50% of animation
                          final elementAnimation = showElement 
                            ? (_successAnimation.value - 0.5) / 0.5 // Normalize to 0-1 for the remaining 50%
                            : 0.0;
                          
                          return Opacity(
                            opacity: elementAnimation,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                if (widget.isPostSignup) {
                                  Navigator.pushReplacementNamed(context, '/home');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'OK',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Error dialog for save failures
  void _showErrorDialog(String errorMessage) {
    // Reset and start the animation
    _errorAnimationController.reset();
    _errorAnimationController.forward();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Container(); // Not used
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _errorAnimationController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Transform.rotate(
                              angle: (1.0 - _errorAnimation.value) * 0.2,
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 60,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _errorAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _errorAnimation.value,
                            child: Text(
                              'Error!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.headlineMedium?.color,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      AnimatedBuilder(
                        animation: _errorAnimationController,
                        builder: (context, child) {
                          final showElement = _errorAnimation.value >= 0.3;
                          final elementAnimation = showElement 
                            ? (_errorAnimation.value - 0.3) / 0.7
                            : 0.0;
                          
                          return Opacity(
                            opacity: elementAnimation,
                            child: Text(
                              'Something went wrong while saving your data.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: _errorAnimationController,
                        builder: (context, child) {
                          final showElement = _errorAnimation.value >= 0.4;
                          final elementAnimation = showElement 
                            ? (_errorAnimation.value - 0.4) / 0.6
                            : 0.0;
                          
                          return Opacity(
                            opacity: elementAnimation,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                errorMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      AnimatedBuilder(
                        animation: _errorAnimationController,
                        builder: (context, child) {
                          final showElement = _errorAnimation.value >= 0.5;
                          final elementAnimation = showElement 
                            ? (_errorAnimation.value - 0.5) / 0.5
                            : 0.0;
                          
                          return Opacity(
                            opacity: elementAnimation,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[300],
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _saveHealthInfo(); // Try again
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstants.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Try Again',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Handle auto-save functionality
  void _startAutoSaveTimer() {
    // Cancel any existing timer first
    _autoSaveTimer?.cancel();
    
    // Start new timer with 2 second delay
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      // Only proceed if there are unsaved changes
      if (_hasUnsavedChanges) {
        _updateHealthStatus(); // Update health status before saving
        _saveHealthInfo();
      }
    });
  }

  // Add a medication to the list
  void _addMedication() {
    final medication = _newMedicationController.text.trim();
    if (medication.isNotEmpty) {
      setState(() {
        _medicationsList.add(medication);
        _newMedicationController.clear();
        _hasUnsavedChanges = true;
      });
      
      // Update the string representation for backward compatibility
      _updateMedicationsController();
      _updateHealthStatus();
    }
  }
  
  // Remove a medication from the list
  void _removeMedication(int index) {
    setState(() {
      _medicationsList.removeAt(index);
      _hasUnsavedChanges = true;
    });
    
    // Update the string representation for backward compatibility
    _updateMedicationsController();
    _updateHealthStatus();
  }
  
  // Add an allergy to the list
  void _addAllergy() {
    final allergy = _newAllergyController.text.trim();
    if (allergy.isNotEmpty) {
      setState(() {
        _allergiesList.add(allergy);
        _newAllergyController.clear();
        _hasUnsavedChanges = true;
      });
      
      // Update the string representation for backward compatibility
      _updateAllergiesController();
      _updateHealthStatus();
    }
  }
  
  // Remove an allergy from the list
  void _removeAllergy(int index) {
    setState(() {
      _allergiesList.removeAt(index);
      _hasUnsavedChanges = true;
    });
    
    // Update the string representation for backward compatibility
    _updateAllergiesController();
    _updateHealthStatus();
  }
  
  // Update medications controller for backward compatibility
  void _updateMedicationsController() {
    _medicationsController.text = _medicationsList.join(', ');
  }
  
  // Update allergies controller for backward compatibility
  void _updateAllergiesController() {
    _allergiesController.text = _allergiesList.join(', ');
  }
  
  // Parse stored values into lists
  void _parseSavedLists() {
    // Parse medications
    if (_medicationsController.text.isNotEmpty) {
      _medicationsList = _medicationsController.text
          .split(',')
          .map((med) => med.trim())
          .where((med) => med.isNotEmpty)
          .toList();
    }
    
    // Parse allergies
    if (_allergiesController.text.isNotEmpty) {
      _allergiesList = _allergiesController.text
          .split(',')
          .map((allergy) => allergy.trim())
          .where((allergy) => allergy.isNotEmpty)
          .toList();
    }
    
    // Parse diseases
    if (_diseasesController.text.isNotEmpty) {
      _diseasesList = _diseasesController.text
          .split(',')
          .map((disease) => disease.trim())
          .where((disease) => disease.isNotEmpty)
          .toList();
    }
  }
  
  // Add disease to the list
  void _addDisease() {
    final disease = _newDiseaseController.text.trim();
    if (disease.isNotEmpty) {
      setState(() {
        _diseasesList.add(disease);
        _newDiseaseController.clear();
        _hasUnsavedChanges = true;
      });
      
      // Update the string representation for backward compatibility
      _updateDiseasesController();
      _updateHealthStatus();
    }
  }
  
  // Remove disease from the list
  void _removeDisease(int index) {
    setState(() {
      _diseasesList.removeAt(index);
      _hasUnsavedChanges = true;
    });
    
    // Update the string representation for backward compatibility
    _updateDiseasesController();
    _updateHealthStatus();
  }
  
  // Update diseases controller for backward compatibility
  void _updateDiseasesController() {
    _diseasesController.text = _diseasesList.join(', ');
  }
} 