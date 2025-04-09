import 'package:flutter/material.dart';

/// A customizable button widget for consistent styling across the app
class CustomButton extends StatelessWidget {
  /// Text displayed on the button
  final String text;

  /// Callback function when button is pressed
  final VoidCallback onPressed;

  /// Primary color of the button
  final Color? color;

  /// Text color
  final Color? textColor;

  /// Icon to display before text (optional)
  final IconData? icon;

  /// Full width or wrap content
  final bool fullWidth;

  /// Button is in loading state
  final bool isLoading;

  /// Button is disabled
  final bool isDisabled;

  /// Button height
  final double height;

  final ButtonSize size; // Paramètre ajouté


  /// Button style - primary (filled), secondary (outlined), text
  final ButtonStyle buttonStyle;

  /// Button radius
  final double borderRadius;

  /// Constructor for CustomButton
  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.fullWidth = true,
    this.isLoading = false,
    this.isDisabled = false,
    this.height = 50.0,
    this.size = ButtonSize.medium, // Valeur par défau
    this.buttonStyle = ButtonStyle.primary,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.primaryColor;
    final onPrimaryColor = textColor ?? Colors.white;
    double buttonHeight;

    // Déterminez la hauteur du bouton en fonction de la taille choisie
    switch (size) {
      case ButtonSize.small:
        buttonHeight = 40.0;
        break;
      case ButtonSize.medium:
        buttonHeight = 50.0;
        break;
      case ButtonSize.large:
        buttonHeight = 60.0;
        break;
    }
    // Determine the button implementation based on style
    Widget buttonImplementation;

    switch (buttonStyle) {
      case ButtonStyle.primary:
        buttonImplementation = ElevatedButton(
          onPressed: (isDisabled || isLoading) ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: onPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          child: _buildButtonContent(theme),
        );
        break;

      case ButtonStyle.secondary:
        buttonImplementation = OutlinedButton(
          onPressed: (isDisabled || isLoading) ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: BorderSide(color: primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          child: _buildButtonContent(theme, isOutlined: true),
        );
        break;

      case ButtonStyle.text:
        buttonImplementation = TextButton(
          onPressed: (isDisabled || isLoading) ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          child: _buildButtonContent(theme, isOutlined: true),
        );
        break;
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: buttonImplementation,
    );
  }

  /// Builds the internal content of the button (icon, text, loading spinner)
  Widget _buildButtonContent(ThemeData theme, {bool isOutlined = false}) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? theme.primaryColor : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}

/// Enum for different button styles
enum ButtonStyle {
  primary, // Filled button (default)
  secondary, // Outlined button
  text // Text-only button
}
enum ButtonSize { small, medium, large }
