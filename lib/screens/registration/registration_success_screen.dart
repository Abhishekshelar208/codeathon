import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/models/team_model.dart';
import 'package:codeathon/screens/home_screen.dart';

/// Shown after successful team registration.
/// Displays Team ID, Paper ID, passcode, and arrival time.
/// Strongly urges the user to screenshot the page.
class RegistrationSuccessScreen extends StatelessWidget {
  final TeamModel team;
  const RegistrationSuccessScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevent accidental back-press
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0E27), Color(0xFF0d2640)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // ── Success Icon ──────────────────────────────────────────
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: AppTheme.kSuccessGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kSuccess.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 48),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.3, 0.3),
                        curve: Curves.elasticOut,
                        duration: 800.ms,
                      )
                      .fadeIn(),

                  const SizedBox(height: 20),

                  Text(
                    'Registration Successful!',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.kSuccess,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                  const SizedBox(height: 6),

                  Text(
                    'Welcome to GTC 2026',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 450.ms),

                  const SizedBox(height: 28),

                  // ── Screenshot Warning ────────────────────────────────────
                  _WarningBanner().animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // ── Team Info Card ────────────────────────────────────────
                  _TeamInfoCard(team: team)
                      .animate()
                      .fadeIn(delay: 600.ms)
                      .slideY(begin: 0.15),

                  const SizedBox(height: 24),

                  // ── Members ───────────────────────────────────────────────
                  if (team.members.isNotEmpty)
                    _MembersCard(team: team)
                        .animate()
                        .fadeIn(delay: 750.ms)
                        .slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // ── Done Button ───────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.kSuccess,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor:
                            AppTheme.kSuccess.withOpacity(0.4),
                      ),
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HomeScreen()),
                        (_) => false,
                      ),
                      icon: const Icon(Icons.home_rounded),
                      label: const Text(
                        'Done — Back to Home',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.1),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Warning Banner ────────────────────────────────────────────────────────────

class _WarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.kWarning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppTheme.kWarning.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.camera_alt_rounded,
              color: AppTheme.kWarning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️  Take a Screenshot NOW',
                  style: TextStyle(
                    color: AppTheme.kWarning,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your Team ID and Passcode are required at the Lunch Station. They will NOT be shown again.',
                  style: TextStyle(
                    color: AppTheme.kWarning,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Team Info Card ────────────────────────────────────────────────────────────

class _TeamInfoCard extends StatelessWidget {
  final TeamModel team;
  const _TeamInfoCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.kPrimary.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kPrimary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.kPrimary.withOpacity(0.2),
                  AppTheme.kAccent.withOpacity(0.1),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(Icons.badge_rounded, color: AppTheme.kPrimary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Your Registration Details',
                  style: TextStyle(
                    color: AppTheme.kPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Fields
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Team ID — large and prominent
                _buildRow(
                  context,
                  label: 'Team ID',
                  value: team.teamId,
                  valueStyle: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.kPrimary,
                    letterSpacing: 2,
                  ),
                ),

                const _Divider(),

                _buildRow(
                  context,
                  label: 'Paper ID',
                  value: team.paperId,
                  valueStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.kTextPrimary,
                    letterSpacing: 1,
                  ),
                ),

                const _Divider(),

                // Passcode — highlighted box
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PASSCODE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.kTextSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.kAccent.withOpacity(0.2),
                            AppTheme.kAccentLight.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.kAccent.withOpacity(0.5),
                            width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_rounded,
                              color: AppTheme.kAccentLight, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            team.passcode,
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.kAccentLight,
                              letterSpacing: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '🔐 Required at Lunch Station — Keep it safe!',
                      style: TextStyle(
                          color: AppTheme.kAccentLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                const _Divider(),

                _buildRow(
                  context,
                  label: 'Checked In At',
                  value: team.formattedArrivalTime,
                  icon: Icons.access_time_rounded,
                  valueStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.kSuccess,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String label,
    required String value,
    TextStyle? valueStyle,
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppTheme.kTextSecondary, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.kTextSecondary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(color: AppTheme.kCardBorder, height: 1),
    );
  }
}

// ── Members Card ──────────────────────────────────────────────────────────────

class _MembersCard extends StatelessWidget {
  final TeamModel team;
  const _MembersCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.group_rounded,
                  color: AppTheme.kTextSecondary, size: 18),
              SizedBox(width: 8),
              Text(
                'TEAM MEMBERS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.kTextSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...team.members.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.kPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: AppTheme.kPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    entry.value,
                    style: const TextStyle(
                      color: AppTheme.kTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
