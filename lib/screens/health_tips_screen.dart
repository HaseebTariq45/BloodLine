import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/theme_helper.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/health_tips_card.dart';

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: const CustomAppBar(title: 'Blood Donation Health Tips'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Guide to Blood Donation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Blood donation is a simple procedure that can save multiple lives. These tips will help you prepare for donation, understand the benefits, and take care of yourself afterward.',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Health benefits card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.health_and_safety,
                            color: Colors.green,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Health Benefits of Donation',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                              ),
                              Text(
                                'Impact on your body and wellbeing',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildBenefitRow(
                      context: context,
                      icon: Icons.favorite,
                      title: 'Heart Health',
                      description: 'Reduces risk of heart attacks by up to 88% for regular donors',
                    ),
                    _buildBenefitRow(
                      context: context,
                      icon: Icons.local_fire_department,
                      title: 'Calorie Burn',
                      description: 'Burns approximately 650 calories per donation',
                    ),
                    _buildBenefitRow(
                      context: context,
                      icon: Icons.monitor_heart,
                      title: 'Blood Pressure',
                      description: 'May help lower blood pressure and improve blood flow',
                    ),
                    _buildBenefitRow(
                      context: context,
                      icon: Icons.psychology,
                      title: 'Mental Health',
                      description: 'Boosts mood through the "helper\'s high" phenomenon',
                    ),
                    _buildBenefitRow(
                      context: context,
                      icon: Icons.colorize,
                      title: 'Iron Balance',
                      description: 'Helps maintain healthy iron levels, reducing oxidative stress',
                    ),
                  ],
                ),
              ),
            ),
            
            // Tips carousel section
            const HealthTipsCard(showExtended: true),
            
            // Impact statistics card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: context.isDarkMode
                  ? AppConstants.primaryColor.withOpacity(0.15)
                  : AppConstants.primaryColor.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Donation Impact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImpactStat(
                            context,
                            value: '3',
                            label: 'Lives Saved',
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildImpactStat(
                            context,
                            value: '1 pint',
                            label: 'Blood Donated',
                            icon: Icons.opacity,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        Expanded(
                          child: _buildImpactStat(
                            context,
                            value: '56 days',
                            label: 'Until Next Donation',
                            icon: Icons.event,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: context.isDarkMode 
                                ? Colors.black.withOpacity(0.2)
                                : Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 2),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lightbulb,
                              color: Colors.amber,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Did You Know?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: context.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Every two seconds, someone in the world needs blood. Just one donation can help multiple patients!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.secondaryTextColor,
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
              ),
            ),
            
            // Eligibility check section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Eligibility Check',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildEligibilityItem(
                      context,
                      title: 'Age',
                      requirement: 'Must be at least 17 years old (16 with parental consent in some states)',
                      icon: Icons.cake,
                    ),
                    _buildEligibilityItem(
                      context,
                      title: 'Weight',
                      requirement: 'At least 110 pounds (50kg)',
                      icon: Icons.monitor_weight,
                    ),
                    _buildEligibilityItem(
                      context,
                      title: 'Health',
                      requirement: 'Generally good health and feeling well on donation day',
                      icon: Icons.health_and_safety,
                    ),
                    _buildEligibilityItem(
                      context,
                      title: 'Hemoglobin',
                      requirement: 'At least 12.5 g/dL for women and 13.0 g/dL for men',
                      icon: Icons.bloodtype,
                    ),
                    _buildEligibilityItem(
                      context,
                      title: 'Donation Frequency',
                      requirement: 'Wait at least 56 days between whole blood donations',
                      icon: Icons.calendar_today,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Note: Additional eligibility criteria may apply. Check with your local blood center for specific requirements.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBenefitRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 20,
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
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: context.textColor,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImpactStat(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: context.secondaryTextColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEligibilityItem(
    BuildContext context, {
    required String title,
    required String requirement,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.teal,
              size: 18,
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
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.textColor,
                  ),
                ),
                Text(
                  requirement,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 