// utils/helpers.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/task_model.dart';
import '../models/project_model.dart';

class Helpers {
  /// Get color for project status
  static Color getProjectStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.pending:
        return Colors.grey;
      case ProjectStatus.inProgress:
        return Colors.blue;
      case ProjectStatus.completed:
        return Colors.green;
      case ProjectStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get color for task priority
  static Color getTaskPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.amber;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get text for project status
  static String getProjectStatusText(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.pending:
        return 'En attente';
      case ProjectStatus.inProgress:
        return 'En cours';
      case ProjectStatus.completed:
        return 'Terminé';
      case ProjectStatus.cancelled:
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  /// Get text for task priority
  static String getTaskPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Basse';
      case TaskPriority.medium:
        return 'Moyenne';
      case TaskPriority.high:
        return 'Haute';
      case TaskPriority.urgent:
        return 'Urgente';
      default:
        return 'Inconnue';
    }
  }

  /// Show a custom toast message
  static void showToast(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Erreur' : 'Information',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red.shade100 : Colors.green.shade100,
      colorText: isError ? Colors.red.shade900 : Colors.green.shade900,
      margin: const EdgeInsets.all(8),
      duration: Duration(seconds: 3),
    );
  }

  /// Calculate project progress based on tasks
  static double calculateProjectProgress(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return 0.0;
    }

    int totalTasks = tasks.length;
    double totalProgress = tasks.fold(0.0, (sum, task) => sum + task.completionPercentage);

    return totalProgress / totalTasks;
  }

  /// Get appropriate icon for project status
  static IconData getProjectStatusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.pending:
        return Icons.schedule;
      case ProjectStatus.inProgress:
        return Icons.play_circle_outline;
      case ProjectStatus.completed:
        return Icons.check_circle_outline;
      case ProjectStatus.cancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  /// Format user name
  static String formatUserName(String firstName, String lastName) {
    return '$firstName ${lastName[0]}.';
  }

  /// Generate initials from name
  static String getInitials(String firstName, String lastName) {
    if (firstName.isEmpty && lastName.isEmpty) {
      return '?';
    }

    String firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';

    return '$firstInitial$lastInitial';
  }
}