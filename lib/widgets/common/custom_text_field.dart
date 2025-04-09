import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A customizable text field for consistent styling across the app
class CustomTextField extends StatelessWidget {
  /// Controller for the text field
  final TextEditingController? controller;

  /// Label text displayed above input
  final String? labelText;

  /// Hint text displayed when input is empty
  final String? hintText;

  /// Error text displayed when validation fails
  final String? errorText;

  /// Prefix icon
  final IconData? prefixIcon;

  /// Suffix icon
  final IconData? suffixIcon;

  /// Suffix icon action
  final VoidCallback? onSuffixIconPressed;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// Callback when field is submitted
  final ValueChanged<String>? onSubmitted;

  /// Validator function
  final String? Function(String?)? validator;

  /// Is the field obscured (for passwords)
  final bool obscureText;

  /// Is the field enabled
  final bool enabled;

  /// Maximum text length
  final int? maxLength;

  /// Maximum lines
  final int? maxLines;

  /// Minimum lines
  final int? minLines;

  /// Keyboard type
  final TextInputType keyboardType;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Auto focus
  final bool autofocus;

  /// Focus node
  final FocusNode? focusNode;

  /// Text field border radius
  final double borderRadius;

  /// Allow auto correction
  final bool autocorrect;

  /// Initialize with focused state
  final bool initiallyFocused;

  /// Helper text
  final String? helperText;

  /// Make the text field read-only
  final bool readOnly;

  /// Constructor for CustomTextField
  const CustomTextField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.obscureText = false,
    this.enabled = true,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.autofocus = false,
    this.focusNode,
    this.borderRadius = 8.0,
    this.autocorrect = true,
    this.initiallyFocused = false,
    this.helperText,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLength: maxLength,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      autofocus: autofocus || initiallyFocused,
      focusNode: focusNode,
      inputFormatters: inputFormatters,
      autocorrect: autocorrect,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
          icon: Icon(suffixIcon),
          onPressed: onSuffixIconPressed,
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        filled: true,
        fillColor: enabled
            ? theme.inputDecorationTheme.fillColor
            : theme.disabledColor.withOpacity(0.1),
      ),
    );
  }
}