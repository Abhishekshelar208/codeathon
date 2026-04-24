import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:codeathon/core/app_theme.dart';

/// Donut (ring) chart showing arrived / lunch / pending breakdown.
class ProgressRingWidget extends StatelessWidget {
  final int arrived;
  final int lunch;
  final int total;

  const ProgressRingWidget({
    super.key,
    required this.arrived,
    required this.lunch,
    required this.total,
  });

  int get pending => total - arrived;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 3,
              centerSpaceRadius: 64,
              sections: _buildSections(),
            ),
          ),
          // Centre text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$arrived',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.kTextPrimary,
                ),
              ),
              const Text(
                'Arrived',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.kTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: AppTheme.kCardBorder,
          radius: 20,
          showTitle: false,
        ),
      ];
    }

    final sections = <PieChartSectionData>[];

    if (lunch > 0) {
      sections.add(PieChartSectionData(
        value: lunch.toDouble(),
        color: AppTheme.kSuccess,
        radius: 22,
        showTitle: false,
      ));
    }

    if (arrived - lunch > 0) {
      sections.add(PieChartSectionData(
        value: (arrived - lunch).toDouble(),
        color: AppTheme.kPrimary,
        radius: 20,
        showTitle: false,
      ));
    }

    if (pending > 0) {
      sections.add(PieChartSectionData(
        value: pending.toDouble(),
        color: AppTheme.kCardBorder,
        radius: 18,
        showTitle: false,
      ));
    }

    return sections;
  }
}
