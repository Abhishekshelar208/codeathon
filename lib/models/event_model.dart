/// Represents event-level metadata stored at /events/{eventId}/meta.
class EventModel {
  final String eventId;
  final String name;
  final String date;
  final int totalTeams;

  const EventModel({
    required this.eventId,
    required this.name,
    required this.date,
    required this.totalTeams,
  });

  factory EventModel.fromJson(String eventId, Map<dynamic, dynamic> json) =>
      EventModel(
        eventId: eventId,
        name: json['name'] as String? ?? '',
        date: json['date'] as String? ?? '',
        totalTeams: (json['totalTeams'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'date': date,
        'totalTeams': totalTeams,
      };
}
