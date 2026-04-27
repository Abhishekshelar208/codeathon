import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/screens/registration/registration_form_screen.dart';
import 'package:codeathon/screens/lunch/team_list_screen.dart';
import 'package:codeathon/screens/admin/admin_dashboard_screen.dart';

/// Landing screen shown to both teams and volunteers.
/// Two big action cards: Entry Gate (Registration) and Lunch Station.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Admin PIN dialog ────────────────────────────────────────────────────────
  Future<void> _openAdminLogin() async {
    final pinCtrl  = TextEditingController();
    String? pinError;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppTheme.kCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.admin_panel_settings_rounded,
                  color: AppTheme.kAccent, size: 36),
              SizedBox(height: 10),
              Text(
                'Admin Access',
                style: TextStyle(
                    color: AppTheme.kTextPrimary,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: TextField(
            controller: pinCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            obscureText: true,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 12,
              color: AppTheme.kAccentLight,
            ),
            decoration: InputDecoration(
              hintText: '• • • •',
              hintStyle: const TextStyle(
                  color: AppTheme.kTextMuted, letterSpacing: 8),
              errorText: pinError,
            ),
            onSubmitted: (_) {
              if (pinCtrl.text == AppConstants.kAdminPin) {
                Navigator.pop(ctx, true);
              } else {
                setDlg(() => pinError = 'Wrong PIN');
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.kTextSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (pinCtrl.text == AppConstants.kAdminPin) {
                  Navigator.pop(ctx, true);
                } else {
                  setDlg(() => pinError = 'Wrong PIN');
                }
              },
              child: const Text('Enter'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || ok != true) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.kHeroGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),

                // ── Header ──────────────────────────────────────────────────
                Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.kPrimaryGradient.createShader(bounds),
                      child: const Text(
                        'Global Tech\nConference',
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
                      '2026 — Team Registration & Tracking',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Event Badge ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.kPrimary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.kSuccess,
                          shape: BoxShape.circle,
                        ),
                      ).animate(onPlay: (c) => c.repeat())
                          .fadeIn(duration: 600.ms)
                          .then()
                          .fadeOut(duration: 600.ms),
                      const SizedBox(width: 8),
                      const Text(
                        'LIVE — Event in Progress',
                        style: TextStyle(
                          color: AppTheme.kPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const Spacer(),

                // ── Instruction ──────────────────────────────────────────────
                Text(
                  'Select your station',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(color: AppTheme.kTextPrimary),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 24),

                // ── Entry Gate Card ──────────────────────────────────────────
                _StationCard(
                  title: 'Entry Gate',
                  subtitle: 'Register your team &\nget your Team ID + Passcode',
                  icon: Icons.how_to_reg_rounded,
                  gradient: AppTheme.kPrimaryGradient,
                  glowColor: AppTheme.kPrimary,
                  badgeText: 'ARRIVAL',
                  delay: 550,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegistrationFormScreen()),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Lunch Station Card ────────────────────────────────────────
                _StationCard(
                  title: 'Lunch Station',
                  subtitle: 'Verify your team &\ncollect your meal',
                  icon: Icons.restaurant_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  glowColor: AppTheme.kWarning,
                  badgeText: 'LUNCH',
                  delay: 700,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TeamListScreen()),
                  ),
                ),

                const Spacer(),

                // ── Admin Button ───────────────────────────────────────────
                GestureDetector(
                  onTap: _openAdminLogin,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.kAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.kAccent.withOpacity(0.25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.admin_panel_settings_rounded,
                            color: AppTheme.kAccent, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            color: AppTheme.kAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 850.ms),

                const SizedBox(height: 10),

                Text(
                  '© 2026 Global Tech Conference',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                          color: AppTheme.kTextMuted, fontSize: 11),
                ).animate().fadeIn(delay: 950.ms),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Station Card ──────────────────────────────────────────────────────────────

class _StationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final String badgeText;
  final int delay;
  final VoidCallback onTap;

  const _StationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.badgeText,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              glowColor.withOpacity(0.14),
              glowColor.withOpacity(0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: glowColor.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.12),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 34),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: glowColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: glowColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
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
        .slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }
}
