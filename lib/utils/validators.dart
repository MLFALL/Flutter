// utils/validators.dart
import 'package:intl/intl.dart';

class Validators {
  /// Méthode pour valider un nom
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre nom complet';
    }

    // Vous pouvez ajouter d'autres validations selon vos besoins (par exemple, longueur minimale)
    if (value.length < 3) {
      return 'Le nom doit contenir au moins 3 caractères';
    }

    return null;
  }

  /// Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer une adresse email';
    }

    // Simple regex for email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(value)) {
      return 'Veuillez entrer une adresse email valide';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value, {bool isRegistering = false}) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }

    if (isRegistering) {
      if (value.length < 8) {
        return 'Le mot de passe doit contenir au moins 8 caractères';
      }

      if (!value.contains(RegExp(r'[A-Z]'))) {
        return 'Le mot de passe doit contenir au moins une majuscule';
      }

      if (!value.contains(RegExp(r'[0-9]'))) {
        return 'Le mot de passe doit contenir au moins un chiffre';
      }

      if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        return 'Le mot de passe doit contenir au moins un caractère spécial';
      }
    }

    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }

    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer $fieldName';
    }

    return null;
  }


  /// Validate project name
  static String? validateProjectName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un nom de projet';
    }

    if (value.length < 3) {
      return 'Le nom du projet doit contenir au moins 3 caractères';
    }

    if (value.length > 50) {
      return 'Le nom du projet ne doit pas dépasser 50 caractères';
    }

    return null;
  }

  /// Validate project description
  static String? validateProjectDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer une description du projet';
    }

    if (value.length < 10) {
      return 'La description doit contenir au moins 10 caractères';
    }

    return null;
  }

  /// Validate date
  static String? validateDate(DateTime? value, {DateTime? minDate, DateTime? maxDate}) {
    if (value == null) {
      return 'Veuillez sélectionner une date';
    }

    if (minDate != null && value.isBefore(minDate)) {
      return 'La date ne peut pas être antérieure au ${DateFormat('dd/MM/yyyy').format(minDate)}';
    }

    if (maxDate != null && value.isAfter(maxDate)) {
      return 'La date ne peut pas être postérieure au ${DateFormat('dd/MM/yyyy').format(maxDate)}';
    }

    return null;
  }

  /// Validate task name
  static String? validateTaskName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un nom de tâche';
    }

    if (value.length < 3) {
      return 'Le nom de la tâche doit contenir au moins 3 caractères';
    }

    if (value.length > 100) {
      return 'Le nom de la tâche ne doit pas dépasser 100 caractères';
    }

    return null;
  }

  /// Validate percentage
  static String? validatePercentage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un pourcentage';
    }

    final percentage = int.tryParse(value);
    if (percentage == null) {
      return 'Veuillez entrer un nombre valide';
    }

    if (percentage < 0 || percentage > 100) {
      return 'Le pourcentage doit être entre 0 et 100';
    }

    return null;
  }
}