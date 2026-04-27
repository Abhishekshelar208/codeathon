/// Represents a single registered team in the GTC 2026 self-registration system.
class TeamModel {
  final String teamId;        // "T1", "T2", ...
  final String paperId;       // unique paper/poster ID
  final List<String> members; // up to 4 names (may be empty strings)
  final bool arrivalStatus;
  final DateTime? arrivalTimestamp;
  final bool lunchStatus;
  final DateTime? lunchTimestamp;
  final String passcode;      // random 4-digit string
  final int createdAt;        // epoch ms

  const TeamModel({
    required this.teamId,
    required this.paperId,
    required this.members,
    this.arrivalStatus = true,
    this.arrivalTimestamp,
    this.lunchStatus = false,
    this.lunchTimestamp,
    required this.passcode,
    required this.createdAt,
  });

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory TeamModel.fromJson(String teamId, Map<dynamic, dynamic> json) {
    final rawMembers = json['members'];
    List<String> members = [];
    if (rawMembers is List) {
      members = rawMembers
          .map((m) => m?.toString() ?? '')
          .where((m) => m.isNotEmpty)
          .toList();
    }

    return TeamModel(
      teamId: teamId,
      paperId: json['paperId'] as String? ?? '',
      members: members,
      arrivalStatus: json['arrivalStatus'] as bool? ?? true,
      arrivalTimestamp: json['arrivalTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['arrivalTimestamp'] as num).toInt())
          : null,
      lunchStatus: json['lunchStatus'] as bool? ?? false,
      lunchTimestamp: json['lunchTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['lunchTimestamp'] as num).toInt())
          : null,
      passcode: json['passcode'] as String? ?? '',
      createdAt: (json['createdAt'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'paperId': paperId,
        'members': members,
        'arrivalStatus': arrivalStatus,
        'arrivalTimestamp': arrivalTimestamp?.millisecondsSinceEpoch,
        'lunchStatus': lunchStatus,
        'lunchTimestamp': lunchTimestamp?.millisecondsSinceEpoch,
        'passcode': passcode,
        'createdAt': createdAt,
      };

  TeamModel copyWith({
    bool? lunchStatus,
    DateTime? lunchTimestamp,
  }) {
    return TeamModel(
      teamId: teamId,
      paperId: paperId,
      members: members,
      arrivalStatus: arrivalStatus,
      arrivalTimestamp: arrivalTimestamp,
      lunchStatus: lunchStatus ?? this.lunchStatus,
      lunchTimestamp: lunchTimestamp ?? this.lunchTimestamp,
      passcode: passcode,
      createdAt: createdAt,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get displayMembers =>
      members.where((m) => m.isNotEmpty).join(', ');

  String get formattedArrivalTime => _fmt(arrivalTimestamp);
  String get formattedLunchTime   => _fmt(lunchTimestamp);

  static String _fmt(DateTime? dt) {
    if (dt == null) return '--:--';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
