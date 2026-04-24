import 'package:flutter/material.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/services/firebase_service.dart';

/// Live scrolling feed of the last N scan events.
class ActivityFeedWidget extends StatelessWidget {
  final List<ActivityEntry> entries;

  const ActivityFeedWidget({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text('No activity yet',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(
        color: AppTheme.kCardBorder, height: 1,
      ),
      itemBuilder: (_, i) => _ActivityTile(entry: entries[i]),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityEntry entry;
  const _ActivityTile({required this.entry});

  bool get _isArrival => entry.action == 'arrived';

  @override
  Widget build(BuildContext context) {
    final color = _isArrival ? AppTheme.kPrimary : AppTheme.kSuccess;
    final icon = _isArrival
        ? Icons.login_rounded
        : Icons.restaurant_rounded;
    final label = _isArrival ? 'Entry' : 'Lunch';

    final t = entry.timestamp;
    final time =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.teamName,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(entry.collegeName,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(label,
                  style: TextStyle(
                    fontSize: 10, color: color,
                    fontWeight: FontWeight.w600,
                  )),
              ),
              const SizedBox(height: 2),
              Text(time,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
