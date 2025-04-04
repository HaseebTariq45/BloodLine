import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/theme_helper.dart';

class HealthTipsCard extends StatefulWidget {
  final bool showExtended;
  
  const HealthTipsCard({
    super.key,
    this.showExtended = false,
  });

  @override
  State<HealthTipsCard> createState() => _HealthTipsCardState();
}

class _HealthTipsCardState extends State<HealthTipsCard> {
  int _currentTipIndex = 0;
  late List<Map<String, dynamic>> _allTips;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _initializeTips();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  void _initializeTips() {
    _allTips = [
      {
        'category': 'Before Donation',
        'icon': Icons.access_time_filled,
        'color': Colors.blue,
        'title': 'Preparation Tips',
        'tips': [
          'Get a good night\'s sleep (7-8 hours)',
          'Eat a healthy meal 2-3 hours before donating',
          'Drink extra water (at least 16 oz) before donation',
          'Avoid fatty foods before donating',
          'Wear comfortable clothing with sleeves that can be rolled up',
          'Bring your ID and donor card if you have one',
          'Have a list of medications you\'re taking',
          'Avoid strenuous exercise right before donating'
        ],
        'fact': 'The actual blood donation process only takes about 8-10 minutes, though the entire appointment may take 45-60 minutes for first-time donors.'
      },
      {
        'category': 'Health Benefits',
        'icon': Icons.favorite,
        'color': Colors.red,
        'title': 'Benefits of Donating',
        'tips': [
          'Free mini health screening (blood pressure, pulse, temperature)',
          'Reduction in risk of heart disease',
          'Burns calories (about 650 calories per donation)',
          'Stimulates blood cell production',
          'Reduces iron stores which may lower risk of heart attacks',
          'May lower cancer risk',
          'Regular blood donations can help detect health issues early'
        ],
        'fact': 'According to studies, regular blood donors have an 88% lower risk of heart attacks and 33% lower risk of severe cardiovascular events.'
      },
      {
        'category': 'After Donation',
        'icon': Icons.local_hospital,
        'color': Colors.green,
        'title': 'Post-Donation Care',
        'tips': [
          'Rest for 10-15 minutes after donating',
          'Drink extra fluids for the next 48 hours',
          'Avoid alcohol for 24 hours after donation',
          'Don\'t lift heavy objects for 24 hours',
          'Keep the bandage on for at least 4-5 hours',
          'Eat iron-rich foods like spinach, red meat and beans',
          'Take it easy on exercise for the rest of the day',
          'If you feel dizzy, lie down with your feet elevated'
        ],
        'fact': 'Your body replaces the fluid lost during donation within 24 hours, but it takes about 4-6 weeks to completely replace the donated red blood cells.'
      },
      {
        'category': 'Blood Facts',
        'icon': Icons.science,
        'color': Colors.purple,
        'title': 'Amazing Blood Facts',
        'tips': [
          'Blood makes up about 7-8% of your body weight',
          'The average adult has 10-12 pints (5-6 liters) of blood',
          'A single donation can save up to 3 lives',
          'Red blood cells live for about 120 days',
          'Blood is always in demand - someone needs blood every 2 seconds',
          'Only 37% of the population is eligible to donate blood',
          'Less than 10% of eligible donors actually donate',
          'AB negative is the rarest blood type (less than 1% of population)'
        ],
        'fact': 'There\'s no substitute for human blood. Despite advances in medical science, blood cannot be manufactured - it must come from donors.'
      },
      {
        'category': 'Nutrition',
        'icon': Icons.food_bank,
        'color': Colors.orange,
        'title': 'Nutrition for Donors',
        'tips': [
          'Increase iron intake with lean red meat, beans, and fortified cereals',
          'Vitamin C helps with iron absorption - pair iron-rich foods with citrus',
          'Stay well-hydrated before and after donation',
          'Include protein in your post-donation meal',
          'B vitamins help with red blood cell production',
          'Folate-rich foods like leafy greens help with cell regeneration',
          'Avoid caffeine right before and after donating',
          'Choose complex carbs for sustained energy'
        ],
        'fact': 'Iron is essential for rebuilding hemoglobin levels after donation. Women need about 18mg of iron daily, while men need about 8mg.'
      },
      {
        'category': 'Eligibility',
        'icon': Icons.check_circle,
        'color': Colors.teal,
        'title': 'Donation Eligibility',
        'tips': [
          'Must be at least 17 years old in most states (16 with parental consent)',
          'Must weigh at least 110 pounds (50kg)',
          'Must be in good general health',
          'Must have adequate hemoglobin levels',
          'Wait 56 days between whole blood donations',
          'Wait 112 days between double red cell donations',
          'Most medications don\'t disqualify you from donating',
          'Travel to certain countries may temporarily defer donation'
        ],
        'fact': 'The most common reason people are deferred from donating is low hemoglobin levels. Iron supplements can help boost these levels for future donations.'
      },
      {
        'category': 'Blood Types',
        'icon': Icons.bloodtype,
        'color': AppConstants.primaryColor,
        'title': 'Understanding Blood Types',
        'tips': [
          'O- is the universal donor for red blood cells',
          'AB+ is the universal recipient',
          'O+ is the most common blood type (about 39% of population)',
          'Your blood type is inherited from your parents',
          'Blood type can impact your susceptibility to certain diseases',
          'Rh factor (+ or -) refers to a specific protein on blood cells',
          'Identical twins can have different blood types',
          'Your blood type can affect your diet needs (Blood Type Diet)'
        ],
        'fact': 'There are 8 main blood types: A+, A-, B+, B-, AB+, AB-, O+, and O-. Your blood type is determined by the presence or absence of A and B antigens and the Rh factor.'
      },
      {
        'category': 'Plasma Donation',
        'icon': Icons.water_drop,
        'color': Colors.amber,
        'title': 'Plasma Donation Facts',
        'tips': [
          'Plasma makes up about 55% of your blood',
          'You can donate plasma more frequently than whole blood (every 28 days)',
          'Plasma donation takes longer (about 1-2 hours)',
          'Plasma is quickly replaced in your body (within 24-48 hours)',
          'AB blood type individuals are universal plasma donors',
          'Plasma is used for patients with burns, shock, and bleeding disorders',
          'You receive your red blood cells back during plasma donation',
          'Stay well-hydrated before plasma donation'
        ],
        'fact': 'Plasma can be frozen for up to one year and still retain all its lifesaving properties. This makes it invaluable for emergency preparedness.'
      }
    ];
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  void _nextTip() {
    setState(() {
      _currentTipIndex = (_currentTipIndex + 1) % _allTips.length;
    });
  }

  void _previousTip() {
    setState(() {
      _currentTipIndex = (_currentTipIndex - 1 + _allTips.length) % _allTips.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTip = _allTips[_currentTipIndex];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentTip['color'].withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: currentTip['color'].withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    currentTip['icon'],
                    color: currentTip['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTip['category'],
                        style: TextStyle(
                          color: currentTip['color'],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        currentTip['title'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.showExtended)
                  Text(
                    '${_currentTipIndex + 1}/${_allTips.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          
          // Tips content
          if (widget.showExtended)
            _buildExtendedView(context, currentTip)
          else
            _buildCompactView(context, currentTip),
        ],
      ),
    );
  }
  
  Widget _buildCompactView(BuildContext context, Map<String, dynamic> tip) {
    final tips = tip['tips'] as List;
    final tipIndex = 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Random tip
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    size: 18,
                    color: tip['color'],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Health Tip:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: tip['color'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tips[tipIndex],
                style: TextStyle(
                  fontSize: 15,
                  color: context.textColor,
                ),
              ),
            ],
          ),
        ),
        
        // Fact section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[context.isDarkMode ? 800 : 100],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: tip['color'],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Did You Know?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: tip['color'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tip['fact'],
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: context.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: AppConstants.primaryColor,
                    ),
                    onPressed: _previousTip,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/health_tips');
                    },
                    child: Row(
                      children: [
                        Text(
                          'More Health Tips',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: AppConstants.primaryColor,
                        )
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppConstants.primaryColor,
                    ),
                    onPressed: _nextTip,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildExtendedView(BuildContext context, Map<String, dynamic> tip) {
    final tips = tip['tips'] as List;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tips list
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < tips.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: tip['color'].withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              color: tip['color'],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tips[i],
                          style: TextStyle(
                            fontSize: 14,
                            color: context.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Fact section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[context.isDarkMode ? 800 : 100],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: tip['color'],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Did You Know?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: tip['color'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tip['fact'],
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: context.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 18,
                      color: AppConstants.primaryColor,
                    ),
                    onPressed: _previousTip,
                  ),
                  Text(
                    '${_currentTipIndex + 1}/${_allTips.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: AppConstants.primaryColor,
                    ),
                    onPressed: _nextTip,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
} 