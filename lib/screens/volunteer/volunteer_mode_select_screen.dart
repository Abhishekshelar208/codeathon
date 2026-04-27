import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/screens/volunteer/volunteer_scanner_screen.dart';

class VolunteerModeSelectScreen extends StatelessWidget {
  const VolunteerModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volunteer Panel')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Text('Select Scan Mode',
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(),

            const SizedBox(height: 8),
            Text('Choose the station you are working at',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 60),

            // Entry Gate button
            _ModeButton(
              label: 'Entry Gate',
              description: 'Scan team QR when they arrive on campus',
              icon: Icons.login_rounded,
              color: AppTheme.kPrimary,
              delay: 0,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VolunteerScannerScreen(
                    mode: ScanMode.arrival,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Lunch button
            _ModeButton(
              label: 'Lunch Area',
              description: 'Scan team QR when they collect their meal',
              icon: Icons.restaurant_rounded,
              color: AppTheme.kSuccess,
              delay: 120,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VolunteerScannerScreen(
                    mode: ScanMode.lunch,
                  ),
                ),
              ),
            ),

            const Spacer(),

            Text('TrackFloww',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.kTextMuted),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: color.withOpacity(0.6)),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: 0.2, curve: Curves.easeOut);
  }
}
