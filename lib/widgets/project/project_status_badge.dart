import 'package:flutter/material.dart';
import '../../config/themes.dart';
import '../../config/constants.dart';

/// A badge widget to display project status with appropriate colors
class ProjectStatusBadge extends StatelessWidget {
  /// Status text to display
  final String status;

  /// Size of the badge (small, medium, large)
  final BadgeSize size;

  /// Whether to show the icon
  final bool showIcon;

  /// Custom background color (overrides the default color for the status)
  final Color? backgroundColor;

  /// Custom text color (overrides the default text color)
  final Color? textColor;

  /// Constructor for ProjectStatusBadge
  const ProjectStatusBadge({
    Key? key,
    required this.status,
    this.size = BadgeSize.medium,
    this.showIcon = true,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine colors based on status
    final statusColor = backgroundColor ?? AppThemes.getStatusColor(status);
    final labelColor = textColor ?? Colors.white;

    // Determine icon based on status
    IconData statusIcon = Icons.hourglass_empty;
    switch (status) {
      case AppConstants.statusPending:
        statusIcon = Icons.hourglass_empty;
        break;
      case AppConstants.statusInProgress:
        statusIcon = Icons.autorenew;
        break;
      case AppConstants.statusCompleted:
        statusIcon = Icons.check_circle_outline;
        break;
      case AppConstants.statusCancelled:
        statusIcon = Icons.cancel_outlined;
        break;
    }

    // Determine text and icon size based on badge size
    double fontSize;
    double iconSize;
    EdgeInsets padding;

    switch (size) {
      case BadgeSize.small:
        fontSize = 10.0;
        iconSize = 12.0;
        padding = const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0);
        break;
      case BadgeSize.medium:
        fontSize = 12.0;
        iconSize = 14.0;
        padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0);
        break;
      case BadgeSize.large:
        fontSize = 14.0;
        iconSize = 18.0;
        padding = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              statusIcon,
              color: labelColor,
              size: iconSize,
            ),
            SizedBox(width: size == BadgeSize.small ? 2.0 : 4.0),
          ],
          Text(
            status,
            style: TextStyle(
              color: labelColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Enum for badge sizes
enum BadgeSize {
  small,
  medium,
  large,
}