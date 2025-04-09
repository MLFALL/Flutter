import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_controller.dart';
import '../../models/task_model.dart';
import '../../controllers/task_controller.dart';
import '../../config/constants.dart';
import 'task_priority_badge.dart';
import 'task_progress_indicator.dart';
import '../user/user_avatar.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isDetailed;
  final Function()? onTap;

  const TaskCard({
    Key? key,
    required this.task,
    this.isDetailed = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TaskController taskController = Get.find<TaskController>();
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(task.priority),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TaskPriorityBadge(priority: task.priority),
                ],
              ),
              if (isDetailed || task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: theme.textTheme.bodyMedium,
                  maxLines: isDetailed ? null : 2,
                  overflow: isDetailed ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              TaskProgressIndicator(progress: task.completionPercentage),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDueDate(task.dueDate),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (task.assignedTo != null && task.assignedTo!.isNotEmpty)
                    Row(
                      children: [
                        ...task.assignedTo!.take(3).map((userId) {
                          final user = Get
                              .find<UserController>()
                              .getUserById(userId)
                              .value;

                          if (user == null) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: UserAvatar(
                              user: user,
                              size: 24,
                              showBorder: true,
                            ),
                          );
                        }).toList(),
                        if ((task.assignedTo?.length ?? 0) > 3)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '+${task.assignedTo!.length - 3}',
                                style: TextStyle(
                                  color: theme.colorScheme.onSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(TaskPriority priority) {
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

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue: ${date.day}/${date.month}/${date.year}';
    } else if (difference == 0) {
      return 'Due Today';
    } else if (difference == 1) {
      return 'Due Tomorrow';
    } else if (difference < 7) {
      return 'Due in $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}