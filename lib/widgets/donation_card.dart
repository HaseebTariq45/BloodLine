import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/donation_model.dart';
import '../utils/theme_helper.dart';

class DonationCard extends StatelessWidget {
  final DonationModel donation;
  final bool showActions;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onContactRecipient;
  final VoidCallback? onCancel;
  final bool isDonor;
  final bool isAccepted;

  const DonationCard({
    super.key,
    required this.donation,
    this.showActions = false,
    this.actionLabel,
    this.onAction,
    this.onContactRecipient,
    this.onCancel,
    this.isDonor = true,
    this.isAccepted = false,
  });

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor() {
    switch (donation.status.toLowerCase()) {
      case 'pending':
        return AppConstants.accentColor;
      case 'scheduled':
        return Colors.blue.shade600;
      case 'completed':
        return AppConstants.successColor;
      case 'cancelled':
        return AppConstants.errorColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 4,
      shadowColor: _getStatusColor().withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _getStatusColor().withOpacity(0.2), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDarkMode
                ? [
                    context.cardColor,
                    context.cardColor.withOpacity(0.85),
                  ]
                : [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator bar at the top
            Container(
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _getStatusColor().withOpacity(0.7),
                    _getStatusColor(),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor().withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Blood type badge
                      _buildBloodTypeBadge(donation.bloodType, isDarkMode),
                      const SizedBox(width: 10),
                      // Center name with icon
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDarkMode 
                                  ? Colors.blueGrey.withOpacity(0.2) 
                                  : Colors.blueGrey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.local_hospital,
                                size: 15,
                                color: isDarkMode ? Colors.grey.shade300 : Colors.blueGrey.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                donation.centerName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: context.textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      _buildStatusBadge(donation.status, context),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Information rows with better organization
                  _buildInfoSection(context),

                  // Action buttons section
                  if (showActions) ...[
                    const SizedBox(height: 16),
                    _buildActionButtons(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced blood type badge
  Widget _buildBloodTypeBadge(String bloodType, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor.withOpacity(isDarkMode ? 0.3 : 0.15),
            AppConstants.primaryColor.withOpacity(isDarkMode ? 0.15 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode 
            ? AppConstants.primaryColor.withOpacity(0.5)
            : AppConstants.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        bloodType,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode 
            ? AppConstants.primaryColor.withAlpha(240)
            : AppConstants.primaryColor,
          fontSize: 16,
        ),
      ),
    );
  }

  // Enhanced status badge
  Widget _buildStatusBadge(String status, BuildContext context) {
    final statusColor = _getStatusColor();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(isDarkMode ? 0.25 : 0.15),
            statusColor.withOpacity(isDarkMode ? 0.15 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(isDarkMode ? 0.5 : 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 2,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Organized information section
  Widget _buildInfoSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode 
            ? [
                Theme.of(context).cardColor.withOpacity(0.7),
                Theme.of(context).cardColor.withOpacity(0.4),
              ]
            : [
                Colors.white,
                Colors.grey.shade50,
              ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.05)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode 
            ? Colors.grey.shade800.withOpacity(0.5)
            : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (donation.recipientName.isNotEmpty)
            _buildInfoRow(
              icon: Icons.person,
              title: 'Recipient',
              value: donation.recipientName,
              context: context,
            ),
          if (donation.recipientName.isNotEmpty) 
            Divider(
              height: 16, 
              thickness: 0.5,
              color: isDarkMode ? Colors.grey.shade700.withOpacity(0.5) : Colors.grey.shade200,
            ),

          if (donation.donorName.isNotEmpty)
            _buildInfoRow(
              icon: Icons.volunteer_activism,
              title: 'Donor',
              value: donation.donorName,
              context: context,
            ),
          if (donation.donorName.isNotEmpty) 
            Divider(
              height: 16, 
              thickness: 0.5,
              color: isDarkMode ? Colors.grey.shade700.withOpacity(0.5) : Colors.grey.shade200,
            ),

          _buildInfoRow(
            icon: Icons.calendar_today,
            title: 'Date',
            value: _formatDate(donation.date.toString()),
            context: context,
          ),

          if (donation.address.isNotEmpty) ...[
            Divider(
              height: 16, 
              thickness: 0.5,
              color: isDarkMode ? Colors.grey.shade700.withOpacity(0.5) : Colors.grey.shade200,
            ),
            _buildInfoRow(
              icon: Icons.location_on,
              title: 'Location',
              value: donation.address,
              isLast: true,
              context: context,
            ),
          ],
        ],
      ),
    );
  }

  // Action buttons section
  Widget _buildActionButtons(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableWidth = mediaQuery.size.width - 32; // accounting for padding
    final bool isExtraSmallScreen = availableWidth < 300;
    final bool isSmallScreen = availableWidth >= 300 && availableWidth < 380;
    
    // Choose layout based on screen width
    if (isExtraSmallScreen) {
      // For extra small screens - stack buttons vertically
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onAction != null) _buildPrimaryButton(context),
          if (onAction != null) const SizedBox(height: 8),
          if (onContactRecipient != null) _buildContactButton(context),
          if (onContactRecipient != null && onCancel != null) const SizedBox(height: 8),
          if (onCancel != null) _buildCancelButton(context),
        ],
      );
    } else if (isSmallScreen) {
      // For small screens - arrange in 2 rows if needed
      if (onAction != null && onContactRecipient != null && onCancel != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _buildPrimaryButton(context)),
                const SizedBox(width: 8),
                Expanded(child: _buildContactButton(context)),
              ],
            ),
            const SizedBox(height: 8),
            _buildCancelButton(context),
          ],
        );
      }
    }
    
    // Default layout for medium/large screens or fewer buttons
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (onAction != null)
          Expanded(flex: 2, child: _buildPrimaryButton(context)),
        if (onAction != null && (onContactRecipient != null || onCancel != null))
          const SizedBox(width: 8),
        if (onContactRecipient != null)
          Expanded(child: _buildContactButton(context)),
        if (onContactRecipient != null && onCancel != null)
          const SizedBox(width: 8),
        if (onCancel != null)
          Expanded(child: _buildCancelButton(context)),
      ],
    );
  }
  
  // Primary action button
  Widget _buildPrimaryButton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ElevatedButton.icon(
      onPressed: onAction,
      icon: Icon(
        isDonor 
          ? Icons.check_circle_outline
          : isAccepted
              ? Icons.bloodtype
              : Icons.check_circle_outline,
        size: 16,
      ),
      label: Text(
        actionLabel ?? 'ACCEPT',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.white.withOpacity(0.1);
            }
            return null;
          },
        ),
        shadowColor: MaterialStateProperty.all<Color>(
          AppConstants.primaryColor.withOpacity(0.4),
        ),
      ),
    );
  }
  
  // Contact button
  Widget _buildContactButton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = Colors.blue.shade600;
    
    return OutlinedButton.icon(
      onPressed: onContactRecipient,
      icon: const Icon(Icons.phone, size: 16),
      label: const Text(
        'CALL',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: buttonColor,
        side: BorderSide(color: buttonColor, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return buttonColor.withOpacity(0.1);
            }
            return null;
          },
        ),
      ),
    );
  }
  
  // Cancel button
  Widget _buildCancelButton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final errorColor = AppConstants.errorColor;
    
    return OutlinedButton.icon(
      onPressed: onCancel,
      icon: const Icon(Icons.cancel_outlined, size: 16),
      label: const Text(
        'CANCEL',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: errorColor,
        side: BorderSide(color: errorColor, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return errorColor.withOpacity(0.1);
            }
            return null;
          },
        ),
      ),
    );
  }

  // Enhanced info row with better typography
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isLast = false,
    required BuildContext context,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        Colors.grey.shade800,
                        Colors.grey.shade900,
                      ]
                    : [
                        Colors.grey.shade100,
                        Colors.grey.shade200,
                      ],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              icon, 
              size: 16, 
              color: isDarkMode 
                ? Colors.grey[400] 
                : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
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
