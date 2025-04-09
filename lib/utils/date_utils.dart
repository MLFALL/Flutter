// utils/date_utils.dart
import 'package:intl/intl.dart';

class DateUtil {
  /// Format date to readable string
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format date with time
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Format relative time (e.g., "2 days ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks sem';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }

  /// Calculate days remaining until deadline
  static int daysRemaining(DateTime deadline) {
    final now = DateTime.now();
    return deadline.difference(now).inDays;
  }

  /// Determine if task is overdue
  static bool isOverdue(DateTime deadline) {
    final now = DateTime.now();
    return deadline.isBefore(now);
  }

  /// Format deadline status
  static String formatDeadlineStatus(DateTime deadline) {
    final daysLeft = daysRemaining(deadline);

    if (daysLeft < 0) {
      return 'En retard de ${-daysLeft} jour${-daysLeft > 1 ? 's' : ''}';
    } else if (daysLeft == 0) {
      return 'Dû aujourd\'hui';
    } else if (daysLeft == 1) {
      return 'Dû demain';
    } else {
      return '$daysLeft jours restants';
    }
  }

  /// Get deadline status color
  static int getDeadlineStatusColor(DateTime deadline) {
    final daysLeft = daysRemaining(deadline);

    if (daysLeft < 0) {
      return 0xFFEF5350; // Red
    } else if (daysLeft < 2) {
      return 0xFFFF9800; // Orange
    } else if (daysLeft < 7) {
      return 0xFFFDD835; // Yellow
    } else {
      return 0xFF4CAF50; // Green
    }
  }

  /// Format time elapsed since date
  static String getTimeElapsed(DateTime startDate) {
    final now = DateTime.now();
    final difference = now.difference(startDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    }
  }
}