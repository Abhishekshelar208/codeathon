import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/models/team_model.dart';
import 'package:codeathon/services/firebase_service.dart';
import 'package:codeathon/screens/lunch/passcode_screen.dart';

/// Shows all registered teams for the lunch station.
/// Volunteer taps a team → passcode verification → team details.
class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Lunch Station'),
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
      ),
      body: StreamBuilder<List<TeamModel>>(
        stream: FirebaseService.instance.teamsStream(AppConstants.kEventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.kWarning),
            );
          }

          if (snapshot.hasError) {
            return _ErrorView(message: snapshot.error.toString());
          }

          final allTeams = snapshot.data ?? [];

          // Filter
          final filtered = _query.isEmpty
              ? allTeams
              : allTeams
                  .where((t) =>
                      t.teamId
                          .toLowerCase()
                          .contains(_query.toLowerCase()) ||
                      t.paperId
                          .toLowerCase()
                          .contains(_query.toLowerCase()) ||
                      t.members.any((m) =>
                          m.toLowerCase().contains(_query.toLowerCase())))
                  .toList();

          return Column(
            children: [
              // ── Stats Bar ────────────────────────────────────────────────
              _StatsBar(teams: allTeams),

              // ── Search Bar ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by Team ID or Paper ID…',
                    prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.kTextMuted),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppTheme.kTextMuted),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              // ── Team Count ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} team${filtered.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: AppTheme.kTextSecondary, fontSize: 12),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.kWarning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.kWarning.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.restaurant_rounded,
                              color: AppTheme.kWarning, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Tap team to verify',
                            style: TextStyle(
                                color: AppTheme.kWarning, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── List ─────────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(query: _query)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final team = filtered[i];
                          return _TeamTile(
                            team: team,
                            index: i,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PasscodeScreen(teamId: team.teamId),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Stats Bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final List<TeamModel> teams;
  const _StatsBar({required this.teams});

  @override
  Widget build(BuildContext context) {
    final total   = teams.length;
    final lunch   = teams.where((t) => t.lunchStatus).length;
    final pending = total - lunch;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.kWarning.withOpacity(0.12),
            AppTheme.kSuccess.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.kWarning.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Total', total, AppTheme.kTextSecondary),
          _divider(),
          _stat('Lunch Done', lunch, AppTheme.kSuccess),
          _divider(),
          _stat('Pending', pending, AppTheme.kWarning),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms);
  }

  Widget _stat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: color),
        ),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppTheme.kTextSecondary)),
      ],
    );
  }

  Widget _divider() => Container(
        height: 36,
        width: 1,
        color: AppTheme.kCardBorder,
      );
}

// ── Team Tile ─────────────────────────────────────────────────────────────────

class _TeamTile extends StatelessWidget {
  final TeamModel team;
  final int index;
  final VoidCallback onTap;

  const _TeamTile({
    required this.team,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lunchDone = team.lunchStatus;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: lunchDone
                ? AppTheme.kSuccess.withOpacity(0.4)
                : AppTheme.kCardBorder,
          ),
        ),
        child: Row(
          children: [
            // Team ID Badge
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: lunchDone
                    ? AppTheme.kSuccessGradient
                    : AppTheme.kPrimaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (lunchDone
                            ? AppTheme.kSuccess
                            : AppTheme.kPrimary)
                        .withOpacity(0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                team.teamId,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paper ID: ${team.paperId}',
                    style: const TextStyle(
                      color: AppTheme.kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (team.members.isNotEmpty)
                    Text(
                      team.displayMembers,
                      style: const TextStyle(
                        color: AppTheme.kTextSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        lunchDone
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_empty_rounded,
                        size: 13,
                        color: lunchDone
                            ? AppTheme.kSuccess
                            : AppTheme.kWarning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lunchDone
                            ? 'Lunch collected at ${team.formattedLunchTime}'
                            : 'Lunch pending',
                        style: TextStyle(
                          color: lunchDone
                              ? AppTheme.kSuccess
                              : AppTheme.kWarning,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.lock_rounded,
              size: 18,
              color: AppTheme.kTextMuted,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 80 + index * 40))
        .slideX(begin: 0.06, curve: Curves.easeOut);
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 60, color: AppTheme.kTextMuted),
          const SizedBox(height: 16),
          Text(
            query.isEmpty
                ? 'No teams registered yet'
                : 'No teams match "$query"',
            style: const TextStyle(
                color: AppTheme.kTextSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 60, color: AppTheme.kError),
            const SizedBox(height: 16),
            const Text('Connection Error',
                style: TextStyle(
                    color: AppTheme.kError,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.kTextSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
