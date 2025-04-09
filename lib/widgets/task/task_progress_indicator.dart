import 'package:flutter/material.dart';
import '../../config/constants.dart';

class TaskProgressIndicator extends StatelessWidget {
  final double progress;
  final bool showPercentage;
  final double height;

  const TaskProgressIndicator({
    Key? key,
    required this.progress,
    this.showPercentage = true,
    this.height = 6.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Progression: ${(progress * 100).toInt()}%',
              style: theme.textTheme.bodySmall,
            ),
          ),
        Stack(
          children: [
            // Background
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
            // Progress
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: _getProgressColor(progress),
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) {
      return AppConstants.progressLowColor;
    } else if (progress < 0.7) {
      return AppConstants.progressMediumColor;
    } else {
      return AppConstants.progressHighColor;
    }
  }
}