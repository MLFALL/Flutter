import 'package:flutter/material.dart';

/// A widget for displaying empty states with illustration and message
class EmptyState extends StatelessWidget {
  /// Title of the empty state
  final String title;

  /// Description of the empty state (optional)
  final String? description;

  /// Icon to display
  final IconData icon;

  /// Action button text (optional)
  final String? actionText;

  /// Action button callback (optional)
  final VoidCallback? onAction;

  /// Image asset path (optional - used instead of icon if provided)
  final String? imagePath;

  /// Size of the illustration/icon
  final double imageSize;

  /// Color of the icon
  final Color? iconColor;

  /// Empty state container padding
  final EdgeInsetsGeometry padding;

  /// Text style for title
  final TextStyle? titleStyle;

  /// Text style for description
  final TextStyle? descriptionStyle;

  /// Constructor for EmptyState
  const EmptyState({
    Key? key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.actionText,
    this.onAction,
    this.imagePath,
    this.imageSize = 120.0,
    this.iconColor,
    this.padding = const EdgeInsets.all(24.0),
    this.titleStyle,
    this.descriptionStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emptyStateIconColor = iconColor ?? theme.colorScheme.primary.withOpacity(0.7);

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon or image
            if (imagePath != null) ...[
              Image.asset(
                imagePath!,
                width: imageSize,
                height: imageSize,
              ),
            ] else ...[
              Icon(
                icon,
                size: imageSize,
                color: emptyStateIconColor,
              ),
            ],
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: titleStyle ?? theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 12),
              Text(
                description!,
                style: descriptionStyle ?? theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action button
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}