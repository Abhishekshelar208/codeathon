import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/models/team_model.dart';
import 'package:codeathon/services/firebase_service.dart';
import 'package:codeathon/screens/admin/lunch_qr_screen.dart';
import 'package:codeathon/screens/admin/gate_qr_screen.dart';

/// Admin dashboard — real-time overview of all registrations and lunch status.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _filter = 'all'; // 'all' | 'pending' | 'lunch'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Admin Dashboard'),
            Text(
              AppConstants.kEventName,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.kTextSecondary),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // ── Gate QR Button ──
          Tooltip(
            message: 'Generate Gate QR',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GateQrScreen()),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.kPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.kPrimary.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.door_front_door_rounded, color: AppTheme.kPrimary, size: 18),
                    SizedBox(width: 5),
                    Text(
                      'Gate QR',
                      style: TextStyle(color: AppTheme.kPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // ── Generate Lunch QR button ─────────────────────────
          Tooltip(
            message: 'Generate Lunch QR',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LunchQrScreen()),
              ),
              child: Container(
                margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.kSuccess.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.kSuccess.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_2_rounded,
                        color: AppTheme.kSuccess, size: 18),
                    SizedBox(width: 5),
                    Text(
                      'Lunch QR',
                      style: TextStyle(
                        color: AppTheme.kSuccess,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<TeamModel>>(
        stream:
            FirebaseService.instance.teamsStream(AppConstants.kEventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.kAccent),
            );
          }

          final allTeams = snapshot.data ?? [];
          final arrived = allTeams.length; // all registered = arrived
          final lunchDone =
              allTeams.where((t) => t.lunchStatus).length;
          final lunchPending = arrived - lunchDone;

          final filtered = _filter == 'pending'
              ? allTeams.where((t) => !t.lunchStatus).toList()
              : _filter == 'lunch'
                  ? allTeams.where((t) => t.lunchStatus).toList()
                  : allTeams;

          return Column(
            children: [
              // ── Stats Row ────────────────────────────────────────────────
              _StatsRow(
                total: arrived,
                lunchDone: lunchDone,
                lunchPending: lunchPending,
              ),

              // ── Filter Chips ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _chip('All', 'all'),
                    const SizedBox(width: 8),
                    _chip('Lunch Pending', 'pending'),
                    const SizedBox(width: 8),
                    _chip('Lunch Done', 'lunch'),
                  ],
                ),
              ),

              // ── Count ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} team${filtered.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: AppTheme.kTextMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // ── Team List ─────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('No teams yet.',
                            style: TextStyle(
                                color: AppTheme.kTextSecondary)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) =>
                            _AdminTeamTile(team: filtered[i], index: i),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.kAccent.withOpacity(0.15)
              : AppTheme.kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.kAccent
                : AppTheme.kCardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected ? AppTheme.kAccent : AppTheme.kTextSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int total, lunchDone, lunchPending;
  const _StatsRow(
      {required this.total,
      required this.lunchDone,
      required this.lunchPending});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.kAccent.withOpacity(0.12),
            AppTheme.kPrimary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.kAccent.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Registered', total, AppTheme.kPrimary),
          _divider(),
          _stat('Lunch Done', lunchDone, AppTheme.kSuccess),
          _divider(),
          _stat('Pending', lunchPending, AppTheme.kWarning),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms);
  }

  Widget _stat(String label, int val, Color color) => Column(
        children: [
          Text(val.toString(),
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.kTextSecondary)),
        ],
      );

  Widget _divider() =>
      Container(height: 36, width: 1, color: AppTheme.kCardBorder);
}

// ── Admin Team Tile ───────────────────────────────────────────────────────────

class _AdminTeamTile extends StatelessWidget {
  final TeamModel team;
  final int index;
  const _AdminTeamTile({required this.team, required this.index});

  @override
  Widget build(BuildContext context) {
    final lunchDone = team.lunchStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: lunchDone
              ? AppTheme.kSuccess.withOpacity(0.35)
              : AppTheme.kCardBorder,
        ),
      ),
      child: Row(
        children: [
          // Team ID badge
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: lunchDone
                  ? AppTheme.kSuccessGradient
                  : AppTheme.kPrimaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              team.teamId,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Paper: ${team.paperId}',
                      style: const TextStyle(
                        color: AppTheme.kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.kAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Pass: ${team.passcode}',
                        style: const TextStyle(
                          color: AppTheme.kAccentLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                if (team.members.isNotEmpty)
                  Text(
                    team.displayMembers,
                    style: const TextStyle(
                        color: AppTheme.kTextSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _badge(
                      Icons.login_rounded,
                      'Arrived ${team.formattedArrivalTime}',
                      AppTheme.kPrimary,
                    ),
                    const SizedBox(width: 8),
                    _badge(
                      lunchDone
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_empty_rounded,
                      lunchDone
                          ? 'Lunch ${team.formattedLunchTime}'
                          : 'No lunch',
                      lunchDone ? AppTheme.kSuccess : AppTheme.kTextMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 60 + index * 35))
        .slideX(begin: 0.05, curve: Curves.easeOut);
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
