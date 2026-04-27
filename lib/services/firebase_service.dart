import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/models/team_model.dart';

/// All Firebase Realtime Database interactions — centralised singleton.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ── Team Counter (Atomic) ──────────────────────────────────────────────────

  /// Atomically increments the team counter and returns the next team number.
  /// Uses a Firebase transaction to avoid race conditions.
  Future<int> _nextTeamNumber(String eventId) async {
    final ref = _db.ref(AppConstants.counterPath(eventId));
    int nextNumber = 1;

    await ref.runTransaction((current) {
      final currentVal = (current as int?) ?? 0;
      nextNumber = currentVal + 1;
      return Transaction.success(nextNumber);
    });

    return nextNumber;
  }

  // ── Paper ID Validation ───────────────────────────────────────────────────

  /// Returns true if the Paper ID is already used by another team.
  Future<bool> paperIdExists(String eventId, String paperId) async {
    final snap = await _db.ref(AppConstants.teamsPath(eventId)).get();
    if (!snap.exists || snap.value == null) return false;
    final raw = (snap.value as Map).cast<String, dynamic>();
    return raw.values.any((v) {
      final map = v as Map?;
      return map?['paperId']?.toString().trim().toLowerCase() ==
          paperId.trim().toLowerCase();
    });
  }

  // ── Create Team ────────────────────────────────────────────────────────────

  /// Creates a new team entry in Firebase.
  ///
  /// Returns the created [TeamModel] on success.
  /// Throws [DuplicatePaperIdException] if the Paper ID is already taken.
  Future<TeamModel> createTeam({
    required String eventId,
    required String paperId,
    required List<String> members,
  }) async {
    // 1. Validate uniqueness
    final exists = await paperIdExists(eventId, paperId.trim());
    if (exists) throw DuplicatePaperIdException(paperId);

    // 2. Atomic counter → teamId
    final num = await _nextTeamNumber(eventId);
    final teamId = 'T$num';

    // 3. Generate 4-digit passcode
    final passcode = _generatePasscode();

    // 4. Build model
    final now = DateTime.now();
    final team = TeamModel(
      teamId: teamId,
      paperId: paperId.trim(),
      members: members.map((m) => m.trim()).where((m) => m.isNotEmpty).toList(),
      arrivalStatus: true,
      arrivalTimestamp: now,
      lunchStatus: false,
      passcode: passcode,
      createdAt: now.millisecondsSinceEpoch,
    );

    // 5. Write to Firebase
    await _db
        .ref(AppConstants.teamPath(eventId, teamId))
        .set(team.toJson());

    return team;
  }

  // ── Teams Stream ──────────────────────────────────────────────────────────

  /// Live stream of all teams sorted by numeric teamId (T1, T2...).
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
      // Sort by numeric part: T1, T2, T10...
      list.sort((a, b) => _teamNum(a.teamId).compareTo(_teamNum(b.teamId)));
      return list;
    });
  }

  /// One-shot fetch of all teams.
  Future<List<TeamModel>> fetchTeamsOnce(String eventId) async {
    final snap = await _db.ref(AppConstants.teamsPath(eventId)).get();
    if (!snap.exists || snap.value == null) return [];
    final raw = (snap.value as Map).cast<String, dynamic>();
    final list = raw.entries
        .map((e) => TeamModel.fromJson(e.key, e.value as Map))
        .toList();
    list.sort((a, b) => _teamNum(a.teamId).compareTo(_teamNum(b.teamId)));
    return list;
  }

  /// Fetches a single team.
  Future<TeamModel?> fetchTeam(String eventId, String teamId) async {
    final snap = await _db.ref(AppConstants.teamPath(eventId, teamId)).get();
    if (!snap.exists || snap.value == null) return null;
    return TeamModel.fromJson(
        teamId, (snap.value as Map).cast<dynamic, dynamic>());
  }

  // ── Mark Lunch ────────────────────────────────────────────────────────────

  /// Marks a team's lunch as collected.
  ///
  /// Returns [LunchResult.success], [LunchResult.alreadyMarked],
  /// or [LunchResult.teamNotFound].
  Future<LunchResult> markLunch(String eventId, String teamId) async {
    final team = await fetchTeam(eventId, teamId);
    if (team == null) return LunchResult.teamNotFound;

    if (team.lunchStatus) return LunchResult.alreadyMarked;

    await _db.ref(AppConstants.teamPath(eventId, teamId)).update({
      'lunchStatus': true,
      'lunchTimestamp': DateTime.now().millisecondsSinceEpoch,
    });
    return LunchResult.success;
  }

  // ── Passcode Verification ─────────────────────────────────────────────────

  /// Verifies a passcode against the stored value for the given teamId.
  /// Returns null if the team is not found.
  Future<TeamModel?> verifyPasscode(
      String eventId, String teamId, String passcode) async {
    final team = await fetchTeam(eventId, teamId);
    if (team == null) return null;
    if (team.passcode != passcode.trim()) return null;
    return team;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static int _teamNum(String teamId) {
    final numeric = teamId.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numeric) ?? 0;
  }

  static String _generatePasscode() {
    final rng = Random();
    // 1000–9999 (always 4 digits)
    final code = 1000 + rng.nextInt(9000);
    return code.toString();
  }
}

// ── Result Types ──────────────────────────────────────────────────────────────

enum LunchResult { success, alreadyMarked, teamNotFound }

class DuplicatePaperIdException implements Exception {
  final String paperId;
  DuplicatePaperIdException(this.paperId);

  @override
  String toString() =>
      'Paper ID "$paperId" is already registered. Each Paper ID must be unique.';
}
