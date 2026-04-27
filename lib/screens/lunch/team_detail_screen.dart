import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/models/team_model.dart';
import 'package:codeathon/services/firebase_service.dart';
import 'package:codeathon/screens/lunch/lunch_scanner_screen.dart';

/// Shows full team details after passcode verification.
/// Volunteer can trigger lunch marking from here.
class TeamDetailScreen extends StatefulWidget {
  final TeamModel team;
  const TeamDetailScreen({super.key, required this.team});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  late TeamModel _team;
  bool _markingLunch = false;

  @override
  void initState() {
    super.initState();
    _team = widget.team;
  }

  // ── Lunch Flow ─────────────────────────────────────────────────────────────

  Future<void> _onMarkLunch() async {
    if (_team.lunchStatus) {
      _showAlreadyMarked();
      return;
    }

    // Navigate to scanner and wait for result
    final scanned = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LunchScannerScreen(teamId: _team.teamId),
      ),
    );

    if (!mounted || scanned != true) return;

    // Mark lunch in Firebase
    setState(() => _markingLunch = true);
    try {
      final result = await FirebaseService.instance
          .markLunch(AppConstants.kEventId, _team.teamId);

      if (!mounted) return;
      setState(() => _markingLunch = false);

      switch (result) {
        case LunchResult.success:
          // Refresh team data
          final updated = await FirebaseService.instance
              .fetchTeam(AppConstants.kEventId, _team.teamId);
          if (mounted && updated != null) {
            setState(() => _team = updated);
          }
          _showSuccess();
          break;
        case LunchResult.alreadyMarked:
          _showAlreadyMarked();
          break;
        case LunchResult.teamNotFound:
          _showError('Team not found in database.');
          break;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _markingLunch = false);
      _showError('Network error. Please try again.');
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Lunch marked successfully!'),
          ],
        ),
        backgroundColor: AppTheme.kSuccess,
      ),
    );
  }

  void _showAlreadyMarked() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppTheme.kWarning, size: 28),
            SizedBox(width: 10),
            Text('Already Marked',
                style: TextStyle(color: AppTheme.kWarning)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ Lunch already taken!',
              style: const TextStyle(
                  color: AppTheme.kTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _team.lunchStatus && _team.formattedLunchTime != '--:--'
                  ? 'This team already collected their meal at ${_team.formattedLunchTime}.'
                  : 'This team has already collected their meal.',
              style: const TextStyle(
                  color: AppTheme.kTextSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kWarning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.kError,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_team.teamId),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Team Header ──────────────────────────────────────────────
            _TeamHeader(team: _team).animate().fadeIn().scale(
                  begin: const Offset(0.95, 0.95),
                  curve: Curves.easeOut,
                ),

            const SizedBox(height: 20),

            // ── Status Cards ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatusCard(
                    label: 'Arrival',
                    isDone: _team.arrivalStatus,
                    time: _team.formattedArrivalTime,
                    icon: Icons.login_rounded,
                    doneColor: AppTheme.kPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusCard(
                    label: 'Lunch',
                    isDone: _team.lunchStatus,
                    time: _team.formattedLunchTime,
                    icon: Icons.restaurant_rounded,
                    doneColor: AppTheme.kSuccess,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08),

            const SizedBox(height: 20),

            // ── Members ───────────────────────────────────────────────────
            if (_team.members.isNotEmpty)
              _MembersSection(team: _team)
                  .animate()
                  .fadeIn(delay: 250.ms)
                  .slideY(begin: 0.08),

            const SizedBox(height: 24),

            // ── Lunch Action ──────────────────────────────────────────────
            _LunchActionButton(
              team: _team,
              loading: _markingLunch,
              onTap: _onMarkLunch,
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Team Header ───────────────────────────────────────────────────────────────

class _TeamHeader extends StatelessWidget {
  final TeamModel team;
  const _TeamHeader({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.kPrimary.withOpacity(0.15),
            AppTheme.kAccent.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.kPrimary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              gradient: AppTheme.kPrimaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kPrimary.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              team.teamId,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TEAM ID',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.kTextMuted,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  team.teamId,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.kCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.kCardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_rounded,
                          size: 13, color: AppTheme.kTextSecondary),
                      const SizedBox(width: 5),
                      Text(
                        'Paper: ${team.paperId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

// ── Status Card ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final String label;
  final bool isDone;
  final String time;
  final IconData icon;
  final Color doneColor;

  const _StatusCard({
    required this.label,
    required this.isDone,
    required this.time,
    required this.icon,
    required this.doneColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone ? doneColor : AppTheme.kTextMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? color.withOpacity(0.35) : AppTheme.kCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDone
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 5),
                Text(
                  isDone ? 'Done' : 'Pending',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          if (isDone && time != '--:--') ...[
            const SizedBox(height: 8),
            Text(
              'At $time',
              style: TextStyle(
                  color: color.withOpacity(0.8), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Members Section ───────────────────────────────────────────────────────────

class _MembersSection extends StatelessWidget {
  final TeamModel team;
  const _MembersSection({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
                  color: AppTheme.kTextSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: team.members.map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.kPrimary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_rounded,
                        size: 14, color: AppTheme.kPrimary),
                    const SizedBox(width: 5),
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppTheme.kTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Lunch Action Button ────────────────────────────────────────────────────────

class _LunchActionButton extends StatelessWidget {
  final TeamModel team;
  final bool loading;
  final VoidCallback onTap;

  const _LunchActionButton({
    required this.team,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = team.lunchStatus;

    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDone ? AppTheme.kCard : AppTheme.kSuccess,
          foregroundColor: isDone ? AppTheme.kSuccess : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: isDone
                ? const BorderSide(color: AppTheme.kSuccess, width: 1.5)
                : BorderSide.none,
          ),
          elevation: isDone ? 0 : 6,
          shadowColor: AppTheme.kSuccess.withOpacity(0.4),
        ),
        icon: loading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : Icons.qr_code_scanner_rounded,
                size: 26,
              ),
        label: Text(
          isDone
              ? 'Lunch Already Collected ✓'
              : 'Scan to Confirm Lunch',
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
