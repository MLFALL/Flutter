import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../config/constants.dart';

class TaskPriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  final bool isSmall;

  const TaskPriorityBadge({
    Key? key,
    required this.priority,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _getColor(priority).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getColor(priority),
          width: 1,
        ),
      ),
      child: Text(
        _getLabel(priority),
        style: TextStyle(
          color: _getColor(priority),
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return AppConstants.priorityLowColor;
      case TaskPriority.medium:
        return AppConstants.priorityMediumColor;
      case TaskPriority.high:
        return AppConstants.priorityHighColor;
      case TaskPriority.urgent:
        return AppConstants.priorityUrgentColor;
      default:
        return Colors.grey;
    }
  }

  String _getLabel(TaskPriority priority) {
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
        return 'Unknown';
    }
  }
}