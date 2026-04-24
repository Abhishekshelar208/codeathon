import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/services/firebase_service.dart';
import 'package:codeathon/screens/volunteer/volunteer_scanner_screen.dart';

class VolunteerResultScreen extends StatefulWidget {
  final ScanUpdateResult? result;
  final String? errorMessage;
  final ScanMode mode;

  const VolunteerResultScreen({
    super.key,
    this.result,
    this.errorMessage,
    required this.mode,
  });

  @override
  State<VolunteerResultScreen> createState() => _VolunteerResultScreenState();
}

class _VolunteerResultScreenState extends State<VolunteerResultScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss after kResultAutoDismiss
    Future.delayed(AppConstants.kResultAutoDismiss, () {
      if (mounted) Navigator.pop(context);
    });
  }

  _ResultConfig get _config {
    // Invalid QR (parse error)
    if (widget.result == null) {
      return _ResultConfig(
        icon: Icons.qr_code_2_rounded,
        color: AppTheme.kError,
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        title: 'Invalid QR Code',
        subtitle: widget.errorMessage ?? 'Unrecognised QR code',
        teamName: null,
        collegeName: null,
      );
    }

    final r = widget.result!;

    switch (r.status) {
      case ScanStatus.success:
        final action = widget.mode == ScanMode.arrival
            ? 'Checked In ✓'
            : 'Lunch Marked ✓';
        return _ResultConfig(
          icon: Icons.check_circle_rounded,
          color: AppTheme.kSuccess,
          gradient: AppTheme.kSuccessGradient,
          title: action,
          subtitle: r.team?.collegeName ?? '',
          teamName: r.team?.teamName,
          collegeName: r.team?.collegeName,
        );
      case ScanStatus.duplicate:
        return _ResultConfig(
          icon: Icons.warning_amber_rounded,
          color: AppTheme.kWarning,
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          title: 'Already Scanned',
          subtitle: r.message ?? '',
          teamName: r.team?.teamName,
          collegeName: r.team?.collegeName,
        );
      case ScanStatus.teamNotFound:
        return _ResultConfig(
          icon: Icons.search_off_rounded,
          color: AppTheme.kError,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
          ),
          title: 'Team Not Found',
          subtitle: r.message ?? 'Not in the database',
          teamName: null,
          collegeName: null,
        );
      case ScanStatus.error:
        return _ResultConfig(
          icon: Icons.wifi_off_rounded,
          color: AppTheme.kError,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
          ),
          title: 'Error',
          subtitle: r.message ?? 'Something went wrong',
          teamName: r.team?.teamName,
          collegeName: r.team?.collegeName,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _config;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: c.gradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(c.icon, size: 100, color: Colors.white)
                  .animate()
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    curve: Curves.elasticOut,
                    duration: 600.ms,
                  )
                  .fadeIn(),

              const SizedBox(height: 28),

              Text(c.title,
                style: const TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

              if (c.teamName != null) ...[
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Column(
                    children: [
                      Text(c.teamName!,
                        style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(c.collegeName ?? '',
                        style: TextStyle(
                          fontSize: 14, color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 350.ms).scale(
                  begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
              ],

              const SizedBox(height: 16),
              Text(c.subtitle,
                style: TextStyle(
                  fontSize: 14, color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 48),

              // Auto-dismiss timer indicator
              SizedBox(
                width: 48, height: 48,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 0.0),
                  duration: AppConstants.kResultAutoDismiss,
                  builder: (ctx, value, _) => CircularProgressIndicator(
                    value: value,
                    color: Colors.white54,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Returning to scanner…',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),

              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Scan Next',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultConfig {
  final IconData icon;
  final Color color;
  final LinearGradient gradient;
  final String title;
  final String subtitle;
  final String? teamName;
  final String? collegeName;

  const _ResultConfig({
    required this.icon,
    required this.color,
    required this.gradient,
    required this.title,
    required this.subtitle,
    this.teamName,
    this.collegeName,
  });
}
