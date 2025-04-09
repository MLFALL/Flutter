import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/project_controller.dart';
import '../../models/project_model.dart';
import '../../config/constants.dart';

class ProjectStatusChart extends StatelessWidget {
  final double height;
  final double width;
  final int pendingCount;
  final int inProgressCount;
  final int completedCount;
  final int cancelledCount;

  const ProjectStatusChart({
    Key? key,
    this.height = 200,
    this.width = 200,
    required this.pendingCount,
    required this.inProgressCount,
    required this.completedCount,
    required this.cancelledCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Count projects by status
    final Map<ProjectStatus, int> statusCount = {
      ProjectStatus.pending: pendingCount,
      ProjectStatus.inProgress: inProgressCount,
      ProjectStatus.completed: completedCount,
      ProjectStatus.cancelled: cancelledCount,
    };

    // Check if we have any projects
    final bool hasProjects = statusCount.values.fold(0, (sum, count) => sum + count) > 0;

    if (!hasProjects) {
      return SizedBox(
        height: height,
        width: width,
        child: Center(
          child: Text(
            'Aucun projet à afficher',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: height,
          width: width,
          child: PieChart(
            PieChartData(
              sections: _getSections(statusCount),
              centerSpaceRadius: 30,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Handle touch events if needed
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: ProjectStatus.values.map((status) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_getStatusLabel(status)}: ${statusCount[status]}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getSections(Map<ProjectStatus, int> statusCount) {
    final total = statusCount.values.fold(0, (sum, count) => sum + count);

    return statusCount.entries.map((entry) {
      final status = entry.key;
      final count = entry.value;
      final percentage = total > 0 ? count / total : 0;

      return PieChartSectionData(
        color: _getStatusColor(status),
        value: count.toDouble(),
        title: '${(percentage * 100).toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.pending:
        return AppConstants.statusPendingColor;
      case ProjectStatus.inProgress:
        return AppConstants.statusInProgressColor;
      case ProjectStatus.completed:
        return AppConstants.statusCompletedColor;
      case ProjectStatus.cancelled:
        return AppConstants.statusCancelledColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(ProjectStatus status) {
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
}