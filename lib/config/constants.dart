import 'package:flutter/material.dart';

class AppConstants {
  // App information
  static const String appName = "ProjectFlow";
  static const String appVersion = "1.0.0";

  // Firebase collection names
  static const String usersCollection = "users";
  static const String projectsCollection = "projects";
  static const String tasksCollection = "tasks";
  static const String commentsCollection = "comments";
  static const String filesCollection = "files";

  // User roles
  static const String roleAdmin = "admin";
  static const String roleProjectManager = "project_manager";
  static const String roleTeamMember = "team_member";

  // Project statuses
  static const String statusPending = "En attente";
  static const String statusInProgress = "En cours";
  static const String statusCompleted = "Terminé";
  static const String statusCancelled = "Annulé";

  // Task priorities
  static const String priorityLow = "Basse";
  static const String priorityMedium = "Moyenne";
  static const String priorityHigh = "Haute";
  static const String priorityUrgent = "Urgente";

  // Couleurs associées aux statuts
  static Map<String, Color> get statusColors => {
    'En attente': statusPendingColor,
    'En cours': statusInProgressColor,
    'Terminé': statusCompletedColor,
    'Annulé': statusCancelledColor,
  };


  // File size limits (in bytes)
  static const int maxFileSizeAdmin = 50 * 1024 * 1024; // 50MB
  static const int maxFileSizeProjectManager = 25 * 1024 * 1024; // 25MB
  static const int maxFileSizeTeamMember = 10 * 1024 * 1024; // 10MB

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // Validation constants
  static const int minPasswordLength = 8;
  static const int minProjectNameLength = 3;
  static const int maxProjectNameLength = 50;
  static const int minTaskNameLength = 3;
  static const int maxTaskNameLength = 50;

  // Dashboard refresh interval
  static const Duration dashboardRefreshInterval = Duration(minutes: 5);

  // Error messages
  static const String genericErrorMessage = "Une erreur s'est produite. Veuillez réessayer.";
  static const String networkErrorMessage = "Problème de connexion réseau. Veuillez vérifier votre connexion.";
  static const String authErrorMessage = "Erreur d'authentification. Veuillez vous reconnecter.";
  static const String permissionErrorMessage = "Vous n'avez pas les permissions nécessaires pour cette action.";

  // Success messages
  static const String projectCreatedMessage = "Projet créé avec succès !";
  static const String taskCreatedMessage = "Tâche créée avec succès !";
  static const String projectUpdatedMessage = "Projet mis à jour avec succès !";
  static const String taskUpdatedMessage = "Tâche mise à jour avec succès !";
  static const String profileUpdatedMessage = "Profil mis à jour avec succès !";

  // File Types
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'];

  // Date formats
  static const String dateFormatDisplay = 'dd/MM/yyyy';
  static const String dateTimeFormatDisplay = 'dd/MM/yyyy HH:mm';

  // Custom status colors
  static const Color statusPendingColor = Color(0xFFFFA726); // Orange clair
  static const Color statusInProgressColor = Color(0xFF42A5F5); // Bleu clair
  static const Color statusCompletedColor = Color(0xFF66BB6A); // Vert clair
  static const Color statusCancelledColor = Color(0xFFEF5350); // Rouge clair

  // Custom performance colors
  static const Color performanceLowColor = Color(0xFFE57373); // Rouge clair
  static const Color performanceMediumColor = Color(0xFFFFB74D); // Orange doux
  static const Color performanceHighColor = Color(0xFF81C784); // Vert clair

  // Custom user status colors
  static const Color userStatusActiveColor = Color(0xFF4CAF50); // Vert doux
  static const Color userStatusInactiveColor = Color(0xFFBDBDBD); // Gris clair

  // Role colors
  static const Color adminRoleColor = Color(0xFFE53935);   // Rouge vif
  static const Color managerRoleColor = Color(0xFFFFA726); // Orange doux
  static const Color memberRoleColor = Color(0xFF42A5F5);  // Bleu clair

  // Priority colors
  static const Color priorityLowColor = Color(0xFF81C784);     // Vert
  static const Color priorityMediumColor = Color(0xFFFFF176);  // Jaune
  static const Color priorityHighColor = Color(0xFFFFB74D);    // Orange
  static const Color priorityUrgentColor = Color(0xFFE57373);  // Rouge

  // Progress colors
  static const Color progressLowColor = Color(0xFFE57373);     // Rouge clair
  static const Color progressMediumColor = Color(0xFFFFB74D);  // Orange
  static const Color progressHighColor = Color(0xFF81C784);    // Vert


}