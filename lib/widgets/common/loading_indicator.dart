import 'package:flutter/material.dart';

/// A customizable loading indicator with optional text
class LoadingIndicator extends StatelessWidget {
  /// Optional text to display alongside the loading indicator
  final String? message;

  /// Size of the loading indicator
  final double size;

  /// Color of the loading indicator - defaults to theme primary color
  final Color? color;

  /// Whether to show the text message
  final bool showMessage;

  /// Text style for the message
  final TextStyle? textStyle;

  /// Horizontal or vertical layout
  final Axis direction;

  /// Background color for the loading overlay
  final Color? overlayColor;

  /// Whether to show as a full screen overlay
  final bool isFullScreen;

  /// Constructor for LoadingIndicator
  const LoadingIndicator({
    Key? key,
    this.message,
    this.size = 36.0,
    this.color,
    this.showMessage = true,
    this.textStyle,
    this.direction = Axis.vertical,
    this.overlayColor,
    this.isFullScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingColor = color ?? theme.primaryColor;
    final textStyleToUse = textStyle ?? theme.textTheme.bodyMedium;

    // Basic loading indicator with optional text
    Widget loadingContent = direction == Axis.vertical
        ? Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
            strokeWidth: 3.0,
          ),
        ),
        if (showMessage && message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: textStyleToUse,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    )
        : Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
            strokeWidth: 3.0,
          ),
        ),
        if (showMessage && message != null) ...[
          const SizedBox(width: 16),
          Text(
            message!,
            style: textStyleToUse,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    // If not fullscreen, just return the content
    if (!isFullScreen) {
      return Center(child: loadingContent);
    }

    // For fullscreen, add a background overlay
    return Container(
      color: overlayColor ?? theme.colorScheme.background.withOpacity(0.7),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: loadingContent,
          ),
        ),
      ),
    );
  }

  /// Factory constructor for creating a fullscreen loading overlay
  factory LoadingIndicator.fullScreen({
    String? message,
    double size = 48.0,
    Color? color,
    Color? overlayColor,
    TextStyle? textStyle,
  }) {
    return LoadingIndicator(
      message: message,
      size: size,
      color: color,
      overlayColor: overlayColor,
      textStyle: textStyle,
      isFullScreen: true,
    );
  }
}