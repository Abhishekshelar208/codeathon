/// Represents a single team participating in the event.
class TeamModel {
  final String teamId;
  final String eventId;
  final String teamName;
  final String collegeName;
  final String leaderName;
  final String leaderEmail;
  final String leaderPhone;
  final List<MemberModel> members;
  final Map<String, String> extraAttributes;
  final String qrPayload;
  final bool arrivalStatus;
  final DateTime? arrivalTimestamp;
  final bool lunchStatus;
  final DateTime? lunchTimestamp;
  final int createdAt;

  const TeamModel({
    required this.teamId,
    required this.eventId,
    required this.teamName,
    required this.collegeName,
    this.leaderName = '',
    this.leaderEmail = '',
    this.leaderPhone = '',
    required this.members,
    this.extraAttributes = const {},
    required this.qrPayload,
    this.arrivalStatus = false,
    this.arrivalTimestamp,
    this.lunchStatus = false,
    this.lunchTimestamp,
    required this.createdAt,
  });

  factory TeamModel.fromJson(String teamId, Map<dynamic, dynamic> json) {
    final rawMembers = json['members'];
    List<MemberModel> members = [];
    if (rawMembers is List) {
      members = rawMembers
          .whereType<Map>()
          .map((m) => MemberModel.fromJson(m.cast<String, dynamic>()))
          .toList();
    }

    final rawExtra = json['extraAttributes'];
    Map<String, String> extra = {};
    if (rawExtra is Map) {
      extra = Map<String, String>.from(rawExtra);
    }

    return TeamModel(
      teamId: teamId,
      eventId: json['eventId'] as String? ?? '',
      teamName: json['teamName'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      leaderName: json['leaderName'] as String? ?? '',
      leaderEmail: json['leaderEmail'] as String? ?? '',
      leaderPhone: json['leaderPhone'] as String? ?? '',
      members: members,
      extraAttributes: extra,
      qrPayload: json['qrPayload'] as String? ?? '',
      arrivalStatus: json['arrivalStatus'] as bool? ?? false,
      arrivalTimestamp: json['arrivalTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['arrivalTimestamp'] as num).toInt())
          : null,
      lunchStatus: json['lunchStatus'] as bool? ?? false,
      lunchTimestamp: json['lunchTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['lunchTimestamp'] as num).toInt())
          : null,
      createdAt: (json['createdAt'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'eventId': eventId,
        'teamName': teamName,
        'collegeName': collegeName,
        'leaderName': leaderName,
        'leaderEmail': leaderEmail,
        'leaderPhone': leaderPhone,
        'members': members.map((m) => m.toJson()).toList(),
        'extraAttributes': extraAttributes,
        'qrPayload': qrPayload,
        'arrivalStatus': arrivalStatus,
        'arrivalTimestamp':
            arrivalTimestamp?.millisecondsSinceEpoch,
        'lunchStatus': lunchStatus,
        'lunchTimestamp': lunchTimestamp?.millisecondsSinceEpoch,
        'createdAt': createdAt,
      };

  TeamModel copyWith({
    bool? arrivalStatus,
    DateTime? arrivalTimestamp,
    bool? lunchStatus,
    DateTime? lunchTimestamp,
  }) {
    return TeamModel(
      teamId: teamId,
      eventId: eventId,
      teamName: teamName,
      collegeName: collegeName,
      leaderName: leaderName,
      leaderEmail: leaderEmail,
      leaderPhone: leaderPhone,
      members: members,
      extraAttributes: extraAttributes,
      qrPayload: qrPayload,
      arrivalStatus: arrivalStatus ?? this.arrivalStatus,
      arrivalTimestamp: arrivalTimestamp ?? this.arrivalTimestamp,
      lunchStatus: lunchStatus ?? this.lunchStatus,
      lunchTimestamp: lunchTimestamp ?? this.lunchTimestamp,
      createdAt: createdAt,
    );
  }
}

/// Represents one member within a team.
class MemberModel {
  final String name;
  final String email;
  final String phone;

  const MemberModel({required this.name, this.email = '', this.phone = ''});

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'phone': phone};
}
