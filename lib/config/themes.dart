import 'package:flutter/material.dart';

class AppThemes {
  // Light theme colors
  static const Color _lightPrimaryColor = Color(0xFF1565C0); // Deep Blue
  static const Color _lightAccentColor = Color(0xFF2196F3); // Blue
  static const Color _lightBackgroundColor = Color(0xFFF5F5F5); // Light Grey
  static const Color _lightCardColor = Colors.white;
  static const Color _lightTextColor = Color(0xFF212121); // Almost Black
  static const Color _lightSecondaryTextColor = Color(0xFF757575); // Grey

  // Dark theme colors
  static const Color _darkPrimaryColor = Color(0xFF1E88E5); // Lighter Blue
  static const Color _darkAccentColor = Color(0xFF42A5F5); // Light Blue
  static const Color _darkBackgroundColor = Color(0xFF121212); // Dark Background
  static const Color _darkCardColor = Color(0xFF1E1E1E); // Dark Card
  static const Color _darkTextColor = Colors.white;
  static const Color _darkSecondaryTextColor = Color(0xFFB3B3B3); // Light Grey

  // Priority colors (consistent across themes)
  static const Color lowPriorityColor = Color(0xFF4CAF50); // Green
  static const Color mediumPriorityColor = Color(0xFFFFA000); // Amber
  static const Color highPriorityColor = Color(0xFFF57C00); // Orange
  static const Color urgentPriorityColor = Color(0xFFD32F2F); // Red

  // Status colors (consistent across themes)
  static const Color pendingStatusColor = Color(0xFF757575); // Grey
  static const Color inProgressStatusColor = Color(0xFF1976D2); // Blue
  static const Color completedStatusColor = Color(0xFF388E3C); // Green
  static const Color cancelledStatusColor = Color(0xFFE53935); // Red

  // Get light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _lightPrimaryColor,
    colorScheme: ColorScheme.light(
      primary: _lightPrimaryColor,
      secondary: _lightAccentColor,
      background: _lightBackgroundColor,
      surface: _lightCardColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: _lightTextColor,
      onSurface: _lightTextColor,
    ),
    scaffoldBackgroundColor: _lightBackgroundColor,
    cardColor: _lightCardColor,
    appBarTheme: AppBarTheme(
      backgroundColor: _lightPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(color: _lightTextColor, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: _lightTextColor, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: _lightTextColor, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: _lightTextColor, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: _lightTextColor),
      titleSmall: TextStyle(color: _lightSecondaryTextColor),
      bodyLarge: TextStyle(color: _lightTextColor),
      bodyMedium: TextStyle(color: _lightTextColor),
      bodySmall: TextStyle(color: _lightSecondaryTextColor),
    ),
    iconTheme: IconThemeData(
      color: _lightPrimaryColor,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _lightAccentColor,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _lightPrimaryColor,
        side: BorderSide(color: _lightPrimaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _lightPrimaryColor,
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: _lightPrimaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.red),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
    ),
    cardTheme: CardTheme(
      color: _lightCardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade300,
      thickness: 1.0,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade200,
      disabledColor: Colors.grey.shade300,
      selectedColor: _lightPrimaryColor.withOpacity(0.1),
      secondarySelectedColor: _lightPrimaryColor.withOpacity(0.2),
      labelStyle: TextStyle(color: _lightTextColor),
      secondaryLabelStyle: TextStyle(color: _lightPrimaryColor),
      padding: EdgeInsets.all(8.0),
    ),
  );

  // Get dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _darkPrimaryColor,
    colorScheme: ColorScheme.dark(
      primary: _darkPrimaryColor,
      secondary: _darkAccentColor,
      background: _darkBackgroundColor,
      surface: _darkCardColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: _darkTextColor,
      onSurface: _darkTextColor,
    ),
    scaffoldBackgroundColor: _darkBackgroundColor,
    cardColor: _darkCardColor,
    appBarTheme: AppBarTheme(
      backgroundColor: _darkCardColor,
      foregroundColor: _darkTextColor,
      elevation: 0,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(color: _darkTextColor, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: _darkTextColor, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: _darkTextColor, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: _darkTextColor, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: _darkTextColor),
      titleSmall: TextStyle(color: _darkSecondaryTextColor),
      bodyLarge: TextStyle(color: _darkTextColor),
      bodyMedium: TextStyle(color: _darkTextColor),
      bodySmall: TextStyle(color: _darkSecondaryTextColor),
    ),
    iconTheme: IconThemeData(
      color: _darkPrimaryColor,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _darkAccentColor,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimaryColor,
        side: BorderSide(color: _darkPrimaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkPrimaryColor,
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: _darkPrimaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.red),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
    ),
    cardTheme: CardTheme(
      color: _darkCardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade800,
      thickness: 1.0,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade800,
      disabledColor: Colors.grey.shade700,
      selectedColor: _darkPrimaryColor.withOpacity(0.3),
      secondarySelectedColor: _darkPrimaryColor.withOpacity(0.4),
      labelStyle: TextStyle(color: _darkTextColor),
      secondaryLabelStyle: TextStyle(color: _darkPrimaryColor),
      padding: EdgeInsets.all(8.0),
    ),
  );

  // Method to get priority color
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return lowPriorityColor;
      case 'medium':
        return mediumPriorityColor;
      case 'high':
        return highPriorityColor;
      case 'urgent':
        return urgentPriorityColor;
      default:
        return mediumPriorityColor;
    }
  }

  // Method to get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'en attente':
        return pendingStatusColor;
      case 'in progress':
      case 'en cours':
        return inProgressStatusColor;
      case 'completed':
      case 'terminé':
        return completedStatusColor;
      case 'cancelled':
      case 'annulé':
        return cancelledStatusColor;
      default:
        return pendingStatusColor;
    }
  }
}