/// Represents a single volunteer in the system.
class VolunteerModel {
  final String volunteerId;
  final String eventId;
  final String name;
  final String qrPayload;
  final bool foodStatus;
  final DateTime? foodTimestamp;
  final int createdAt;

  const VolunteerModel({
    required this.volunteerId,
    required this.eventId,
    required this.name,
    required this.qrPayload,
    this.foodStatus = false,
    this.foodTimestamp,
    required this.createdAt,
  });

  factory VolunteerModel.fromJson(String id, Map<dynamic, dynamic> json) {
    return VolunteerModel(
      volunteerId: id,
      eventId: json['eventId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      qrPayload: json['qrPayload'] as String? ?? '',
      foodStatus: json['foodStatus'] as bool? ?? false,
      foodTimestamp: json['foodTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['foodTimestamp'] as num).toInt())
          : null,
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'volunteerId': volunteerId,
        'eventId': eventId,
        'name': name,
        'qrPayload': qrPayload,
        'foodStatus': foodStatus,
        'foodTimestamp': foodTimestamp?.millisecondsSinceEpoch,
        'createdAt': createdAt,
      };

  VolunteerModel copyWith({
    String? name,
    bool? foodStatus,
    DateTime? foodTimestamp,
  }) {
    return VolunteerModel(
      volunteerId: volunteerId,
      eventId: eventId,
      name: name ?? this.name,
      qrPayload: qrPayload,
      foodStatus: foodStatus ?? this.foodStatus,
      foodTimestamp: foodTimestamp ?? this.foodTimestamp,
      createdAt: createdAt,
    );
  }
}
