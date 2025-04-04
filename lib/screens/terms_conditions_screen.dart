import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../constants/app_constants.dart';
import '../utils/localization/app_localization.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;

    // Calculate responsive sizes
    final double titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final double paragraphFontSize = isSmallScreen ? 13.0 : 15.0;
    final double bulletFontSize = isSmallScreen ? 13.0 : 15.0;
    final double lastUpdatedFontSize = isSmallScreen ? 12.0 : 14.0;

    // Calculate padding based on screen size
    final double horizontalPadding = screenWidth * 0.05;
    final double verticalPadding = screenHeight * 0.02;
    final double sectionSpacing = isSmallScreen ? 12.0 : 16.0;
    final double bulletLeftPadding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'terms_of_service'.tr(context),
        showBackButton: true,
        showProfilePicture: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Last Updated
                  Text(
                    'terms_last_updated'.tr(context),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: lastUpdatedFontSize,
                    ),
                  ),
                  SizedBox(height: verticalPadding * 1.2),

                  // Introduction
                  _buildSectionTitle(
                    context,
                    'terms_intro_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'terms_intro_content',
                    paragraphFontSize,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Eligibility
                  _buildSectionTitle(
                    context,
                    'terms_eligibility_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'terms_eligibility_content',
                    paragraphFontSize,
                  ),
                  _buildBulletPoints(
                    context,
                    [
                      'terms_eligibility_point1',
                      'terms_eligibility_point2',
                      'terms_eligibility_point3',
                      'terms_eligibility_point4',
                    ],
                    bulletFontSize,
                    bulletLeftPadding,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Account Responsibilities
                  _buildSectionTitle(
                    context,
                    'terms_account_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'terms_account_content',
                    paragraphFontSize,
                  ),
                  _buildBulletPoints(
                    context,
                    [
                      'terms_account_point1',
                      'terms_account_point2',
                      'terms_account_point3',
                      'terms_account_point4',
                    ],
                    bulletFontSize,
                    bulletLeftPadding,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Code of Conduct
                  _buildSectionTitle(
                    context,
                    'terms_conduct_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'terms_conduct_content',
                    paragraphFontSize,
                  ),
                  _buildBulletPoints(
                    context,
                    [
                      'terms_conduct_point1',
                      'terms_conduct_point2',
                      'terms_conduct_point3',
                      'terms_conduct_point4',
                      'terms_conduct_point5',
                    ],
                    bulletFontSize,
                    bulletLeftPadding,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Blood Donation Rules
                  _buildSectionTitle(
                    context,
                    'terms_donation_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'terms_donation_content',
                    paragraphFontSize,
                  ),
                  _buildBulletPoints(
                    context,
                    [
                      'terms_donation_point1',
                      'terms_donation_point2',
                      'terms_donation_point3',
                      'terms_donation_point4',
                    ],
                    bulletFontSize,
                    bulletLeftPadding,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Intellectual Property
                  _buildSectionTitle(context, 'terms_ip_title', titleFontSize),
                  _buildParagraph(
                    context,
                    'terms_ip_content',
                    paragraphFontSize,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Limitation of Liability
                  _buildSectionTitle(
                    context,
                    'terms_liability_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'terms_liability_content',
                    paragraphFontSize,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Termination
                  _buildSectionTitle(
                    context,
                    'terms_termination_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'terms_termination_content',
                    paragraphFontSize,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Changes to Terms
                  _buildSectionTitle(
                    context,
                    'terms_changes_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'terms_changes_content',
                    paragraphFontSize,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Contact Information
                  _buildSectionTitle(
                    context,
                    'terms_contact_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'terms_contact_content',
                    paragraphFontSize,
                  ),
                  SizedBox(height: verticalPadding * 1.6),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String key, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        key.tr(context),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String key, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        key.tr(context),
        style: TextStyle(fontSize: fontSize, height: 1.5),
      ),
    );
  }

  Widget _buildBulletPoints(
    BuildContext context,
    List<String> points,
    double fontSize,
    double leftPadding,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: leftPadding, top: 8.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            points
                .map((point) => _buildBulletPoint(context, point, fontSize))
                .toList(),
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String key, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          Expanded(
            child: Text(
              key.tr(context),
              style: TextStyle(fontSize: fontSize, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
