import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../constants/app_constants.dart';
import '../utils/localization/app_localization.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
    final double subTitleFontSize = isSmallScreen ? 14.0 : 16.0;
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
        title: 'privacy_policy'.tr(context),
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
                    'privacy_last_updated'.tr(context),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: lastUpdatedFontSize,
                    ),
                  ),
                  SizedBox(height: verticalPadding * 1.2),

                  // Introduction
                  _buildSectionTitle(
                    context,
                    'privacy_intro_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'privacy_intro_content',
                    paragraphFontSize,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Information We Collect
                  _buildSectionTitle(
                    context,
                    'privacy_collect_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'privacy_collect_content',
                    paragraphFontSize,
                  ),

                  // Personal Information
                  _buildSubSectionTitle(
                    context,
                    'privacy_personal_title',
                    subTitleFontSize,
                  ),
                  _buildBulletPoints(
                    context,
                    [
                      'privacy_personal_point1',
                      'privacy_personal_point2',
                      'privacy_personal_point3',
                      'privacy_personal_point4',
                      'privacy_personal_point5',
                    ],
                    bulletFontSize,
                    bulletLeftPadding,
                  ),

                  // Health Information
                  _buildSubSectionTitle(
                    context,
                    'privacy_health_title',
                    subTitleFontSize,
                  ),
                  _buildBulletPoints(
                    context,
                    [
                      'privacy_health_point1',
                      'privacy_health_point2',
                      'privacy_health_point3',
                      'privacy_health_point4',
                    ],
                    bulletFontSize,
                    bulletLeftPadding,
                  ),

                  // Usage Information
                  _buildSubSectionTitle(
                    context,
                    'privacy_usage_title',
                    subTitleFontSize,
                  ),
                  _buildBulletPoints(
                    context,
                    [
                      'privacy_usage_point1',
                      'privacy_usage_point2',
                      'privacy_usage_point3',
                    ],
                    bulletFontSize,
                    bulletLeftPadding,
                  ),
                  SizedBox(height: sectionSpacing),

                  // How We Use Your Information
                  _buildSectionTitle(
                    context,
                    'privacy_use_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'privacy_use_content',
                    paragraphFontSize,
                  ),
                  _buildBulletPoints(
                    context,
                    [
                      'privacy_use_point1',
                      'privacy_use_point2',
                      'privacy_use_point3',
                      'privacy_use_point4',
                      'privacy_use_point5',
                      'privacy_use_point6',
                    ],
                    bulletFontSize,
                    bulletLeftPadding,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Sharing Your Information
                  _buildSectionTitle(
                    context,
                    'privacy_share_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'privacy_share_content',
                    paragraphFontSize,
                  ),
                  _buildBulletPoints(
                    context,
                    [
                      'privacy_share_point1',
                      'privacy_share_point2',
                      'privacy_share_point3',
                      'privacy_share_point4',
                    ],
                    bulletFontSize,
                    bulletLeftPadding,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Data Security
                  _buildSectionTitle(
                    context,
                    'privacy_security_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'privacy_security_content',
                    paragraphFontSize,
                  ),
                  _buildBulletPoints(
                    context,
                    [
                      'privacy_security_point1',
                      'privacy_security_point2',
                      'privacy_security_point3',
                    ],
                    bulletFontSize,
                    bulletLeftPadding,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Data Retention
                  _buildSectionTitle(
                    context,
                    'privacy_retention_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'privacy_retention_content',
                    paragraphFontSize,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Your Rights
                  _buildSectionTitle(
                    context,
                    'privacy_rights_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'privacy_rights_content',
                    paragraphFontSize,
                  ),
                  _buildBulletPoints(
                    context,
                    [
                      'privacy_rights_point1',
                      'privacy_rights_point2',
                      'privacy_rights_point3',
                      'privacy_rights_point4',
                      'privacy_rights_point5',
                    ],
                    bulletFontSize,
                    bulletLeftPadding,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Children's Privacy
                  _buildSectionTitle(
                    context,
                    'privacy_children_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'privacy_children_content',
                    paragraphFontSize,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Changes to Privacy Policy
                  _buildSectionTitle(
                    context,
                    'privacy_changes_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'privacy_changes_content',
                    paragraphFontSize,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Contact Information
                  _buildSectionTitle(
                    context,
                    'privacy_contact_title',
                    titleFontSize,
                  ),
                  _buildParagraph(
                    context,
                    'privacy_contact_content',
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

  Widget _buildSubSectionTitle(
    BuildContext context,
    String key,
    double fontSize,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        key.tr(context),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: AppConstants.darkTextColor,
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
