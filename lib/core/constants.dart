/// Central constants for the GTC 2026 self-registration tracking system.
class AppConstants {
  AppConstants._();

  // ── Event Identity ───────────────────────────────────────────────────────
  static const String kEventId   = 'gtc2026';
  static const String kEventName = 'Global Tech Conference 2026';

  // ── Firebase Paths ────────────────────────────────────────────────────────
  static String teamsPath(String eventId)              => 'events/$eventId/teams';
  static String teamPath(String eventId, String teamId)=> 'events/$eventId/teams/$teamId';
  static String counterPath(String eventId)            => 'events/$eventId/meta/teamCounter';

  // ── Security ──────────────────────────────────────────────────────────────
  /// PIN entered by volunteer at entry gate to authorize a new registration.
  static const String kVerificationPin = '8488';

  /// Admin dashboard access PIN.
  static const String kAdminPin = '1234';

  // ── Timing ───────────────────────────────────────────────────────────────
  static const Duration kResultAutoDismiss = Duration(seconds: 3);

  // ── QR Payload Identifiers ────────────────────────────────────────────────
  /// Value encoded inside the Gate QR (Registration QR).
  static const String kGateQrPayload  = 'gtc2026::gate';

  /// Value encoded inside the Lunch QR.
  static const String kLunchQrPayload = 'gtc2026::lunch';
}
