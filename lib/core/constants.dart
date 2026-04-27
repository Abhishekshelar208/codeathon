/// Central constants for the TrackFloww tracking system.
/// To support a new event, update [kEventId] and [kEventName].
class AppConstants {
  AppConstants._();

  // ── Event Identity ───────────────────────────────────────────────────────
  static const String kEventId = 'gtc2026';
  static const String kEventName = 'TrackFloww';

  // ── Firebase Paths ────────────────────────────────────────────────────────
  static String teamsPath(String eventId) => 'events/$eventId/teams';
  static String teamPath(String eventId, String teamId) =>
      'events/$eventId/teams/$teamId';
  static String eventMetaPath(String eventId) => 'events/$eventId/meta';
  static String activityLogPath(String eventId) =>
      'events/$eventId/activity_log';
  static String volunteersPath(String eventId) => 'events/$eventId/volunteers';
  static String volunteerPath(String eventId, String volunteerId) =>
      'events/$eventId/volunteers/$volunteerId';

  // ── QR Payload ────────────────────────────────────────────────────────────
  /// Format: "eventId::teamId"
  static String buildQrPayload(String eventId, String teamId) =>
      '$eventId::$teamId';

  static String buildVolunteerQrPayload(String eventId, String volId) =>
      '$eventId::vol_$volId';

  static const String kQrDelimiter = '::';

  // ── Admin Auth ────────────────────────────────────────────────────────────
  /// Hardcoded admin PIN for the event.  Change before go-live.
  static const String kAdminPin = '1234';

  // ── Timing ───────────────────────────────────────────────────────────────
  /// How long the scan-result overlay stays visible before auto-dismiss.
  static const Duration kResultAutoDismiss = Duration(seconds: 3);

  // ── Activity Log ─────────────────────────────────────────────────────────
  static const int kActivityFeedMax = 20;
}
