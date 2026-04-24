import 'package:codeathon/core/constants.dart';

/// Validates and parses QR code payloads produced by this system.
class QrValidator {
  QrValidator._();

  /// Returns [QrParseResult] from a raw scanned string.
  static QrParseResult parse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return QrParseResult.invalid('Empty QR code');
    }

    final parts = raw.split(AppConstants.kQrDelimiter);
    if (parts.length != 2) {
      return QrParseResult.invalid('Unrecognised QR format');
    }

    final eventId = parts[0].trim();
    final teamId = parts[1].trim();

    if (eventId.isEmpty || teamId.isEmpty) {
      return QrParseResult.invalid('Malformed QR payload');
    }

    if (eventId != AppConstants.kEventId) {
      return QrParseResult.invalid(
          'QR belongs to a different event ($eventId)');
    }

    return QrParseResult.valid(eventId: eventId, teamId: teamId);
  }
}

/// The result of parsing a QR payload.
class QrParseResult {
  final bool isValid;
  final String? eventId;
  final String? teamId;
  final String? errorMessage;

  const QrParseResult._({
    required this.isValid,
    this.eventId,
    this.teamId,
    this.errorMessage,
  });

  factory QrParseResult.valid({
    required String eventId,
    required String teamId,
  }) =>
      QrParseResult._(isValid: true, eventId: eventId, teamId: teamId);

  factory QrParseResult.invalid(String message) =>
      QrParseResult._(isValid: false, errorMessage: message);
}
