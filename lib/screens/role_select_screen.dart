import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/screens/admin/admin_login_screen.dart';
import 'package:codeathon/screens/volunteer/volunteer_mode_select_screen.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.kHeroGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Header
                Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.kPrimaryGradient.createShader(bounds),
                      child: const Text(
                        'TrackFloww',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
                    const SizedBox(height: 8),
                    Text(
                      'Team Tracker',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),

                const Spacer(),

                // Role cards
                Text('Who are you?',
                  style: Theme.of(context).textTheme.headlineLarge,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 24),

                _RoleCard(
                  title: 'Organiser / Admin',
                  subtitle: 'Upload teams, view dashboard,\nmanage QR codes',
                  icon: Icons.admin_panel_settings_rounded,
                  gradient: AppTheme.kAccentGradient,
                  glowColor: AppTheme.kAccent,
                  delay: 500,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminLoginScreen()),
                  ),
                ),

                const SizedBox(height: 16),

                _RoleCard(
                  title: 'Volunteer',
                  subtitle: 'Scan QR codes at entry\nand lunch stations',
                  icon: Icons.qr_code_scanner_rounded,
                  gradient: AppTheme.kPrimaryGradient,
                  glowColor: AppTheme.kPrimary,
                  delay: 650,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VolunteerModeSelectScreen()),
                  ),
                ),

                const Spacer(),

                Text('© 2026 TrackFloww',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.kTextMuted, fontSize: 11),
                ).animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final int delay;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.glowColor,
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
          gradient: LinearGradient(
            colors: [
              glowColor.withOpacity(0.12),
              glowColor.withOpacity(0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: glowColor.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 62, height: 62,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.4),
                    blurRadius: 16,
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
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(color: glowColor),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: glowColor.withOpacity(0.6)),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideY(begin: 0.25, curve: Curves.easeOut);
  }
}
