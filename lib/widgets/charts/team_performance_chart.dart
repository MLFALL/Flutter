import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/admin_controller.dart';
import '../../config/constants.dart';

class TeamPerformanceChart extends StatelessWidget {
  final double height;

  const TeamPerformanceChart({
    Key? key,
    this.height = 250,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AdminController adminController = Get.find<AdminController>();
    final theme = Theme.of(context);

    return Obx(() {
      final teamPerformanceData = adminController.getTeamPerformanceData();

      if (teamPerformanceData.isEmpty) {
        return SizedBox(
          height: height,
          child: Center(
            child: Text(
              'Aucune donnée de performance à afficher',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        );
      }

      // Sort teams by performance for better visualization
      final sortedData = teamPerformanceData.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return SizedBox(
        height: height,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: theme.colorScheme.surface,
                tooltipPadding: const EdgeInsets.all(8),
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${sortedData[groupIndex].key}: ${rod.toY.toStringAsFixed(1)}%',
                    TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value >= 0 && value < sortedData.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _abbreviateTeamName(sortedData[value.toInt()].key),
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        '${value.toInt()}%',
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            barGroups: List.generate(
              sortedData.length,
                  (index) {
                final performance = sortedData[index].value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: performance,
                      color: _getPerformanceColor(performance),
                      width: 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              },
            ),
            gridData: FlGridData(
              show: true,
              horizontalInterval: 20,
              checkToShowHorizontalLine: (value) => value % 20 == 0,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.dividerColor,
                  strokeWidth: 0.5,
                  dashArray: [5, 5],
                );
              },
            ),
          ),
        ),
      );
    });
  }

  String _abbreviateTeamName(String name) {
    if (name.length <= 5) return name;
    final words = name.split(' ');
    if (words.length == 1) return name.substring(0, 5) + '...';

    return words.map((word) => word[0]).join('');
  }

  Color _getPerformanceColor(double performance) {
    if (performance < 50) {
      return AppConstants.performanceLowColor;
    } else if (performance < 75) {
      return AppConstants.performanceMediumColor;
    } else {
      return AppConstants.performanceHighColor;
    }
  }
}