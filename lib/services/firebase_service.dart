import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/models/team_model.dart';
import 'package:codeathon/models/event_model.dart';
import 'package:codeathon/models/volunteer_model.dart';
import 'package:uuid/uuid.dart';

/// All Firebase Realtime Database interactions are centralised here.
/// Consumers observe [Stream]s for live updates or call one-shot methods.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ── Event Meta ────────────────────────────────────────────────────────────

  Future<void> saveEventMeta(EventModel event) async {
    await _db
        .ref(AppConstants.eventMetaPath(event.eventId))
        .set(event.toJson());
  }

  // ── Team CRUD ─────────────────────────────────────────────────────────────

  /// Writes a list of teams to Firebase under the given event.
  /// Uses a batch write (multi-path update) for efficiency.
  Future<void> uploadTeams(
      String eventId, List<TeamModel> teams) async {
    final updates = <String, dynamic>{};
    for (final team in teams) {
      updates[AppConstants.teamPath(eventId, team.teamId)] = team.toJson();
    }
    await _db.ref().update(updates);
  }

  /// Fetches all teams for an event once (non-streaming).
  Future<List<TeamModel>> fetchTeamsOnce(String eventId) async {
    final snapshot =
        await _db.ref(AppConstants.teamsPath(eventId)).get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final raw = (snapshot.value as Map).cast<String, dynamic>();
    return raw.entries
        .map((e) => TeamModel.fromJson(e.key, e.value as Map))
        .toList()
      ..sort((a, b) => a.teamName.compareTo(b.teamName));
  }

  /// Fetches a single team by id.
  Future<TeamModel?> fetchTeam(String eventId, String teamId) async {
    final snapshot =
        await _db.ref(AppConstants.teamPath(eventId, teamId)).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return TeamModel.fromJson(
        teamId, (snapshot.value as Map).cast<dynamic, dynamic>());
  }

  // ── Real-time Streams ─────────────────────────────────────────────────────

  /// Live stream of all teams for the given event.
  Stream<List<TeamModel>> teamsStream(String eventId) {
    return _db
        .ref(AppConstants.teamsPath(eventId))
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <TeamModel>[];
      final raw = (event.snapshot.value as Map).cast<String, dynamic>();
      final list = raw.entries
          .map((e) => TeamModel.fromJson(e.key, e.value as Map))
          .toList();
      list.sort((a, b) => a.teamName.compareTo(b.teamName));
      return list;
    });
  }

  /// Live stream of the activity log (last N entries).
  Stream<List<ActivityEntry>> activityStream(String eventId) {
    return _db
        .ref(AppConstants.activityLogPath(eventId))
        .limitToLast(AppConstants.kActivityFeedMax)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <ActivityEntry>[];
      final raw = (event.snapshot.value as Map).cast<String, dynamic>();
      final list = raw.entries
          .map((e) => ActivityEntry.fromJson(e.value as Map))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  // ── Volunteer Management ──────────────────────────────────────────────────

  /// Creates a new volunteer in the system.
  Future<void> createVolunteer(String eventId, String name) async {
    final volId = const Uuid().v4().substring(0, 8); // Simple suffix
    final volunteerId = 'vol_$volId';
    final volunteer = VolunteerModel(
      volunteerId: volunteerId,
      eventId: eventId,
      name: name,
      qrPayload: AppConstants.buildVolunteerQrPayload(eventId, volId),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _db
        .ref(AppConstants.volunteerPath(eventId, volunteerId))
        .set(volunteer.toJson());
  }

  /// Updates an existing volunteer's details.
  Future<void> updateVolunteer(String eventId, VolunteerModel volunteer) async {
    await _db
        .ref(AppConstants.volunteerPath(eventId, volunteer.volunteerId))
        .update(volunteer.toJson());
  }

  /// Deletes a volunteer from the system.
  Future<void> deleteVolunteer(String eventId, String volunteerId) async {
    await _db.ref(AppConstants.volunteerPath(eventId, volunteerId)).remove();
  }

  /// Live stream of all volunteers for the given event.
  Stream<List<VolunteerModel>> volunteersStream(String eventId) {
    return _db
        .ref(AppConstants.volunteersPath(eventId))
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <VolunteerModel>[];
      final raw = (event.snapshot.value as Map).cast<String, dynamic>();
      final list = raw.entries
          .map((e) => VolunteerModel.fromJson(e.key, e.value as Map))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  /// Fetches a single volunteer by id.
  Future<VolunteerModel?> fetchVolunteer(
      String eventId, String volunteerId) async {
    final snapshot =
        await _db.ref(AppConstants.volunteerPath(eventId, volunteerId)).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return VolunteerModel.fromJson(
        volunteerId, (snapshot.value as Map).cast<dynamic, dynamic>());
  }

  /// Marks a volunteer as having had food and logs the activity.
  Future<ScanUpdateResult> markVolunteerFood(
      String eventId, String volunteerId) async {
    final vol = await fetchVolunteer(eventId, volunteerId);
    if (vol == null) return ScanUpdateResult.error('Volunteer not found');

    if (vol.foodStatus) {
      return ScanUpdateResult.duplicate(
          'Already collected food at ${_fmtTime(vol.foodTimestamp)}',
          null,
          vol);
    }

    final now = DateTime.now();
    await _db.ref(AppConstants.volunteerPath(eventId, volunteerId)).update({
      'foodStatus': true,
      'foodTimestamp': now.millisecondsSinceEpoch,
    });

    await _logActivity(
        eventId,
        ActivityEntry(
          teamId: volunteerId,
          teamName: vol.name,
          collegeName: 'Volunteer',
          action: 'volunteer_food',
          timestamp: now,
        ));

    return ScanUpdateResult.successVolunteer(vol.copyWith(
      foodStatus: true,
      foodTimestamp: now,
    ));
  }

  // ── Status Updates ────────────────────────────────────────────────────────

  /// Marks a team as arrived and logs the activity.
  Future<ScanUpdateResult> markArrival(
      String eventId, String teamId) async {
    final team = await fetchTeam(eventId, teamId);
    if (team == null) return ScanUpdateResult.teamNotFound();

    if (team.arrivalStatus) {
      return ScanUpdateResult.duplicate(
          'Already checked in at ${_fmtTime(team.arrivalTimestamp)}',
          team);
    }

    final now = DateTime.now();
    await _db.ref(AppConstants.teamPath(eventId, teamId)).update({
      'arrivalStatus': true,
      'arrivalTimestamp': now.millisecondsSinceEpoch,
    });

    await _logActivity(eventId, ActivityEntry(
      teamId: teamId,
      teamName: team.teamName,
      collegeName: team.collegeName,
      action: 'arrived',
      timestamp: now,
    ));

    return ScanUpdateResult.success(team.copyWith(
        arrivalStatus: true, arrivalTimestamp: now));
  }

  /// Marks a team as having had lunch and logs the activity.
  Future<ScanUpdateResult> markLunch(
      String eventId, String teamId) async {
    final team = await fetchTeam(eventId, teamId);
    if (team == null) return ScanUpdateResult.teamNotFound();

    if (!team.arrivalStatus) {
      return ScanUpdateResult.error(
          'Team has not checked in yet', team);
    }

    if (team.lunchStatus) {
      return ScanUpdateResult.duplicate(
          'Lunch already marked at ${_fmtTime(team.lunchTimestamp)}',
          team);
    }

    final now = DateTime.now();
    await _db.ref(AppConstants.teamPath(eventId, teamId)).update({
      'lunchStatus': true,
      'lunchTimestamp': now.millisecondsSinceEpoch,
    });

    await _logActivity(eventId, ActivityEntry(
      teamId: teamId,
      teamName: team.teamName,
      collegeName: team.collegeName,
      action: 'lunch',
      timestamp: now,
    ));

    return ScanUpdateResult.success(team.copyWith(
        lunchStatus: true, lunchTimestamp: now));
  }

  // ── Internal Helpers ──────────────────────────────────────────────────────

  Future<void> _logActivity(
      String eventId, ActivityEntry entry) async {
    await _db
        .ref(AppConstants.activityLogPath(eventId))
        .push()
        .set(entry.toJson());
  }

  String _fmtTime(DateTime? dt) {
    if (dt == null) return '--:--';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Result Types ──────────────────────────────────────────────────────────────

enum ScanStatus { success, duplicate, teamNotFound, error }

class ScanUpdateResult {
  final ScanStatus status;
  final TeamModel? team;
  final VolunteerModel? volunteer;
  final String? message;

  const ScanUpdateResult._({
    required this.status,
    this.team,
    this.volunteer,
    this.message,
  });

  factory ScanUpdateResult.success(TeamModel team) =>
      ScanUpdateResult._(status: ScanStatus.success, team: team);

  factory ScanUpdateResult.successVolunteer(VolunteerModel vol) =>
      ScanUpdateResult._(status: ScanStatus.success, volunteer: vol);

  factory ScanUpdateResult.duplicate(String msg, [TeamModel? team, VolunteerModel? vol]) =>
      ScanUpdateResult._(
          status: ScanStatus.duplicate, team: team, volunteer: vol, message: msg);

  factory ScanUpdateResult.teamNotFound() =>
      ScanUpdateResult._(
          status: ScanStatus.teamNotFound,
          message: 'Team not found in database');

  factory ScanUpdateResult.error(String msg, [TeamModel? team]) =>
      ScanUpdateResult._(
          status: ScanStatus.error, team: team, message: msg);
}

// ── Activity Log Entry ────────────────────────────────────────────────────────

class ActivityEntry {
  final String teamId;
  final String teamName;
  final String collegeName;
  final String action; // 'arrived' | 'lunch'
  final DateTime timestamp;

  const ActivityEntry({
    required this.teamId,
    required this.teamName,
    required this.collegeName,
    required this.action,
    required this.timestamp,
  });

  factory ActivityEntry.fromJson(Map<dynamic, dynamic> json) => ActivityEntry(
        teamId: json['teamId'] as String? ?? '',
        teamName: json['teamName'] as String? ?? '',
        collegeName: json['collegeName'] as String? ?? '',
        action: json['action'] as String? ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            (json['timestamp'] as num?)?.toInt() ?? 0),
      );

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'teamName': teamName,
        'collegeName': collegeName,
        'action': action,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };
}
