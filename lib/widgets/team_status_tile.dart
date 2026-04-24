import 'package:flutter/material.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/models/team_model.dart';

/// A single team row shown in the team list screen.
class TeamStatusTile extends StatelessWidget {
  final TeamModel team;
  final VoidCallback? onTap;

  const TeamStatusTile({super.key, required this.team, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.kCardBorder),
        ),
        child: Row(
          children: [
            // Avatar circle
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: team.arrivalStatus
                    ? AppTheme.kPrimaryGradient
                    : const LinearGradient(
                        colors: [AppTheme.kCardBorder, AppTheme.kCardBorder]),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  team.teamName.isNotEmpty
                      ? team.teamName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Team info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.teamName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(team.collegeName,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Status badges
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _badge(
                  label: 'Entry',
                  active: team.arrivalStatus,
                  activeColor: AppTheme.kPrimary,
                  time: team.arrivalTimestamp,
                ),
                const SizedBox(height: 4),
                _badge(
                  label: 'Lunch',
                  active: team.lunchStatus,
                  activeColor: AppTheme.kSuccess,
                  time: team.lunchTimestamp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge({
    required String label,
    required bool active,
    required Color activeColor,
    DateTime? time,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? activeColor.withOpacity(0.15)
            : AppTheme.kBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active ? activeColor.withOpacity(0.5) : AppTheme.kCardBorder,
        ),
      ),
      child: Text(
        active && time != null
            ? '$label ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
            : label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: active ? activeColor : AppTheme.kTextMuted,
        ),
      ),
    );
  }
}
