import 'package:flutter/material.dart';

/// A customizable widget for displaying error messages
class ErrorMessage extends StatelessWidget {
  /// Error message to display
  final String message;

  /// Action text for retry button (optional)
  final String? actionText;

  /// Callback for retry button (optional)
  final VoidCallback? onAction;

  /// Icon to display with error message
  final IconData icon;

  /// Color of the error message
  final Color? color;

  /// Size of the icon
  final double iconSize;

  /// Whether to show as full-page error
  final bool isFullPage;

  /// Text style for the error message
  final TextStyle? textStyle;

  /// Ajoutez ce paramètre pour contrôler la visibilité du message d'erreur
  final bool isVisible;

  

  /// Constructor for ErrorMessage
  const ErrorMessage({
    Key? key,
    required this.message,
    this.actionText,
    this.onAction,
    this.icon = Icons.error_outline,
    this.color,
    this.iconSize = 48.0,
    this.isFullPage = false,
    this.textStyle,
    this.isVisible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = color ?? theme.colorScheme.error;
    final useTextStyle = textStyle ?? theme.textTheme.bodyLarge;

    final errorContent = Column(
      mainAxisSize: isFullPage ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: errorColor,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: useTextStyle?.copyWith(color: theme.colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
        if (actionText != null && onAction != null) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh),
            label: Text(actionText!),
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: theme.colorScheme.onError,
            ),
          ),
        ],
      ],
    );

    if (isFullPage) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: errorContent,
        ),
      );
    }

    // Utilisation de Visibility pour contrôler l'affichage du message
    return Visibility(
      visible: isVisible,  // Ce paramètre contrôle la visibilité
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: errorColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: errorColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: useTextStyle?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (actionText != null && onAction != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onAction,
                      child: Text(actionText!),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: errorColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: errorColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: useTextStyle?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (actionText != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onAction,
                    child: Text(actionText!),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: errorColor,
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

  /// Factory constructor for creating a full page error
  factory ErrorMessage.fullPage({
    required String message,
    String? actionText,
    VoidCallback? onAction,
    IconData icon = Icons.error_outline,
    Color? color,
    double iconSize = 64.0,
    TextStyle? textStyle,
  }) {
    return ErrorMessage(
      message: message,
      actionText: actionText,
      onAction: onAction,
      icon: icon,
      color: color,
      iconSize: iconSize,
      isFullPage: true,
      textStyle: textStyle,
      isVisible: true,
    );
  }
}