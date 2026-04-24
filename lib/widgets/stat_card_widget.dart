import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';

/// A compact animated stat card used in the admin dashboard.
class StatCardWidget extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  final IconData icon;
  final int animationDelay; // milliseconds

  const StatCardWidget({
    super.key,
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.icon,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : value / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: Duration(milliseconds: 800 + animationDelay),
            curve: Curves.easeOut,
            builder: (_, v, __) => Text(
              '$v',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: Duration(milliseconds: 900 + animationDelay),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 4,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: animationDelay))
        .slideY(begin: 0.3, curve: Curves.easeOut);
  }
}
