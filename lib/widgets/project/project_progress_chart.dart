import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../config/themes.dart';

/// A circular progress chart for visualizing project completion
class ProjectProgressChart extends StatelessWidget {
  /// Project data to visualize
  final ProjectModel project;

  /// Size of the chart
  final double size;

  /// Stroke width for the progress arc
  final double strokeWidth;

  /// Show percentage text in center
  final bool showPercentage;

  /// Show label text under chart
  final bool showLabel;

  /// Background color for the chart
  final Color? backgroundColor;

  /// Progress color for the chart (if null, will use status color)
  final Color? progressColor;

  /// Animation duration
  final Duration animationDuration;

  /// Constructor for ProjectProgressChart
  const ProjectProgressChart({
    Key? key,
    required this.project,
    this.size = 100.0,
    this.strokeWidth = 10.0,
    this.showPercentage = true,
    this.showLabel = true,
    this.backgroundColor,
    this.progressColor,
    this.animationDuration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Determine colors for chart
    final bgColor = backgroundColor ?? theme.colorScheme.primary.withOpacity(0.2);
    final progColor = progressColor ?? AppThemes.getStatusColor(project.status.name);


    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: project.completionPercentage / 100),
          duration: animationDuration,
          builder: (context, double value, child) {
            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: strokeWidth,
                      valueColor: AlwaysStoppedAnimation<Color>(bgColor),
                    ),
                  ),

                  // Progress arc
                  SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: strokeWidth,
                      valueColor: AlwaysStoppedAnimation<Color>(progColor),
                    ),
                  ),

                  // Center percentage text
                  if (showPercentage)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(value * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: size / 4,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (project.status.name.isNotEmpty) ...[
                          SizedBox(height: size / 25),
                          Text(
                            project.status.name,
                            style: TextStyle(
                              fontSize: size / 9,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            );
          },
        ),

        // Label text
        if (showLabel) ...[
          const SizedBox(height: 8),
          Text(
            project.title,
            style: textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}