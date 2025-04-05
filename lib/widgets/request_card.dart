import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/blood_request_model.dart';
import '../utils/theme_helper.dart';

class RequestCard extends StatelessWidget {
  final BloodRequestModel request;
  final bool showActions;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onCancel;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const RequestCard({
    super.key,
    required this.request,
    this.showActions = false,
    this.actionLabel,
    this.onAction,
    this.onCancel,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(request.status);
    
    return Card(
      elevation: 4,
      shadowColor: statusColor.withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    Theme.of(context).cardColor,
                    Theme.of(context).cardColor.withOpacity(0.8),
                  ]
                : [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Enhanced status indicator with subtle gradient
          Container(
              height: 10,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    statusColor.withOpacity(0.7),
                    statusColor,
                  ],
                ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.25),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                    spreadRadius: 1,
                  ),
                ],
            ),
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                      // Enhanced blood type badge
                      _buildBloodTypeBadge(request.bloodType, context),
                      const SizedBox(width: 12),
                      // Request title with icon
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
                                Icons.volunteer_activism,
                                size: 15,
                                color: isDarkMode ? Colors.grey.shade300 : Colors.blueGrey.shade700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                        'Blood Request',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.textColor,
                        ),
                            ),
                          ],
                      ),
                    ),
                      // Enhanced status badge
                      _buildStatusBadge(request.status, context),
                  ],
                ),
                  const SizedBox(height: 18),
                // Information rows with improved spacing and organization
                _buildInfoSection(context),
                if (request.notes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    // Enhanced notes section
                  Container(
                      padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDarkMode
                              ? [
                                  Theme.of(context).cardColor.withOpacity(0.6),
                                  Theme.of(context).cardColor.withOpacity(0.3),
                                ]
                              : [
                                  Colors.grey.shade50,
                                  Colors.grey.shade100.withOpacity(0.5),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.15),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey.shade800.withOpacity(0.5)
                              : Colors.grey.shade300.withOpacity(0.5),
                          width: 1,
                        ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                  Icons.note_outlined,
                                  size: 15,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Additional Notes',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey.shade900.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              request.notes,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                              ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Action buttons with improved styling
                if (showActions &&
                    (onAction != null ||
                        onCancel != null ||
                        onSecondaryAction != null)) ...[
                  const SizedBox(height: 16),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0x0F000000),
                    ),
                    const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;

                      // For smaller screens, buttons need more vertical layout
                      if (availableWidth < 400 && onSecondaryAction != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (onSecondaryAction != null)
                              ElevatedButton.icon(
                                onPressed: onSecondaryAction,
                                icon: const Icon(Icons.info_outline, size: 16),
                                label: Text(
                                  secondaryActionLabel ?? 'View Details',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                    elevation: 2,
                                    shadowColor: Colors.blue.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                      vertical: 12,
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
                                  ),
                                ),
                              const SizedBox(height: 10),
                            Row(
                              children: [
                                if (onCancel != null)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: onCancel,
                                      icon: const Icon(Icons.close, size: 16),
                                        label: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
                                            width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                            vertical: 12,
                                          ),
                                        ).copyWith(
                                          overlayColor: MaterialStateProperty.resolveWith<Color?>(
                                            (Set<MaterialState> states) {
                                              if (states.contains(MaterialState.pressed)) {
                                                return Colors.red.withOpacity(0.05);
                                              }
                                              return null;
                                            },
                                          ),
                                      ),
                                    ),
                                  ),
                                if (onCancel != null && onAction != null)
                                    const SizedBox(width: 10),
                                if (onAction != null)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: onAction,
                                      icon: const Icon(Icons.check, size: 16),
                                        label: Text(
                                          actionLabel ?? 'Action',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppConstants.primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shadowColor: AppConstants.primaryColor
                                              .withOpacity(0.4),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
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
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        // Default horizontal layout for buttons
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (onSecondaryAction != null) ...[
                              ElevatedButton.icon(
                                onPressed: onSecondaryAction,
                                icon: const Icon(Icons.info_outline, size: 16),
                                label: Text(
                                  secondaryActionLabel ?? 'View Details',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                    elevation: 2,
                                    shadowColor: Colors.blue.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
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
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (onCancel != null)
                              OutlinedButton.icon(
                                onPressed: onCancel,
                                icon: const Icon(Icons.close, size: 16),
                                  label: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ).copyWith(
                                    overlayColor: MaterialStateProperty.resolveWith<Color?>(
                                      (Set<MaterialState> states) {
                                        if (states.contains(MaterialState.pressed)) {
                                          return Colors.red.withOpacity(0.05);
                                        }
                                        return null;
                                      },
                                    ),
                                ),
                              ),
                            if (onAction != null) ...[
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: onAction,
                                icon: const Icon(Icons.check, size: 16),
                                  label: Text(
                                    actionLabel ?? 'Action',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shadowColor: AppConstants.primaryColor
                                      .withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
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
                                  ),
                                ),
                              ],
                          ],
                        );
                      }
                    },
                  ),
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
  Widget _buildBloodTypeBadge(String bloodType, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
          color: AppConstants.primaryColor.withOpacity(isDarkMode ? 0.5 : 0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        bloodType,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  // Enhanced status badge
  Widget _buildStatusBadge(String status, BuildContext context) {
    final statusColor = _getStatusColor(status);
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // Organized information section
  Widget _buildInfoSection(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    
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
          _buildInfoRow(
            icon: Icons.person,
            title: 'Requester',
            value: request.requesterName,
            context: context,
          ),
          Divider(
            height: 16,
            thickness: 0.5,
            color: isDarkMode ? Colors.grey.shade700.withOpacity(0.5) : Colors.grey.shade200,
          ),
          _buildInfoRow(
            icon: Icons.phone,
            title: 'Contact',
            value: request.contactNumber,
            context: context,
          ),
          Divider(
            height: 16,
            thickness: 0.5,
            color: isDarkMode ? Colors.grey.shade700.withOpacity(0.5) : Colors.grey.shade200,
          ),
          _buildInfoRow(
            icon: Icons.location_on,
            title: 'Location',
            value: request.location,
            context: context,
          ),
          Divider(
            height: 16,
            thickness: 0.5,
            color: isDarkMode ? Colors.grey.shade700.withOpacity(0.5) : Colors.grey.shade200,
          ),
          _buildInfoRow(
            icon: Icons.location_city,
            title: 'City',
            value: request.city.isNotEmpty ? request.city : 'Not specified',
            context: context,
          ),
          Divider(
            height: 16,
            thickness: 0.5,
            color: isDarkMode ? Colors.grey.shade700.withOpacity(0.5) : Colors.grey.shade200,
          ),
          _buildInfoRow(
            icon: Icons.calendar_today,
            title: 'Requested',
            value: request.formattedDate,
            isLast: true,
            context: context,
          ),
        ],
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
    final isDarkMode = context.isDarkMode;
    
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
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700]
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'fulfilled':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      case 'in progress':
        return Colors.blue.shade600;
      case 'accepted':
        return Colors.purple.shade600;
      default:
        return Colors.grey;
    }
  }
}
