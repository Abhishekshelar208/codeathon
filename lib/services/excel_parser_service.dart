import 'package:excel/excel.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/models/team_model.dart';
import 'package:uuid/uuid.dart';

class ExcelParserService {
  ExcelParserService._();
  static final ExcelParserService instance = ExcelParserService._();

  /// Extracts the headers from the first data row of the first non-empty sheet.
  /// Returns a list of string headers.
  List<String> extractHeaders(List<int> bytes) {
    Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (_) {
      throw Exception('Could not decode Excel file.');
    }

    final sheetName = excel.tables.keys.firstWhere(
      (k) => (excel.tables[k]?.rows.isNotEmpty ?? false),
      orElse: () => '',
    );

    if (sheetName.isEmpty) {
      throw Exception('The Excel file appears to be empty.');
    }

    final rows = excel.tables[sheetName]!.rows;
    if (rows.isEmpty) {
      throw Exception('No data rows found.');
    }

    // Assume first row is header
    final headerRow = rows[0];
    final headers = <String>[];
    for (int i = 0; i < headerRow.length; i++) {
      final val = _cell(headerRow[i]);
      headers.add(val.isEmpty ? 'Column\_$i' : val);
    }

    return headers;
  }

  /// Parses raw Excel bytes into a [ExcelParseResult] based on the parsed map.
  /// [fieldMapping] maps system fields (e.g., 'teamName', 'leaderEmail') to Excel headers.
  ExcelParseResult parseWithMapping(
    List<int> bytes,
    Map<String, String> fieldMapping, {
    String? eventId,
  }) {
    final eid = eventId ?? AppConstants.kEventId;

    Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (_) {
      return ExcelParseResult.failure('Could not decode Excel file.');
    }

    final sheetName = excel.tables.keys.firstWhere(
      (k) => (excel.tables[k]?.rows.isNotEmpty ?? false),
      orElse: () => '',
    );
    if (sheetName.isEmpty) {
      return ExcelParseResult.failure('The Excel file appears to be empty.');
    }

    final rows = excel.tables[sheetName]!.rows;
    if (rows.length < 2) {
      return ExcelParseResult.failure('Need at least one data row (plus header).');
    }

    final headerRow = rows[0];
    final headerMap = <String, int>{}; // header name -> column index
    for (int i = 0; i < headerRow.length; i++) {
      final val = _cell(headerRow[i]);
      headerMap[val.isEmpty ? 'Column\_$i' : val] = i;
    }

    final teams = <TeamModel>[];
    final errors = <RowError>[];
    final uuid = const Uuid();

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((c) => _cell(c).isEmpty)) continue;

      // Extract basic fields
      final teamName = _extractField(row, headerMap, fieldMapping['teamName']);
      if (teamName.isEmpty) {
        errors.add(RowError(row: i + 1, message: 'Required Team Name is empty'));
        continue;
      }

      final collegeName = _extractField(row, headerMap, fieldMapping['collegeName']);
      final leaderName = _extractField(row, headerMap, fieldMapping['leaderName']);
      final leaderEmail = _extractField(row, headerMap, fieldMapping['leaderEmail']);
      final leaderPhone = _extractField(row, headerMap, fieldMapping['leaderPhone']);

      // Extract members dynamically based on mapping: member1Name, member1Email, etc.
      // Up to 10 members supported logic
      final members = <MemberModel>[];
      for (int m = 1; m <= 10; m++) {
        final mName = _extractField(row, headerMap, fieldMapping['member${m}Name']);
        final mEmail = _extractField(row, headerMap, fieldMapping['member${m}Email']);
        final mPhone = _extractField(row, headerMap, fieldMapping['member${m}Phone']);

        if (mName.isNotEmpty) {
          members.add(MemberModel(name: mName, email: mEmail, phone: mPhone));
        }
      }

      // Any remaining headers not mapped go into extraAttributes
      final mappedHeaders = fieldMapping.values.where((v) => v.isNotEmpty).toSet();
      final extraAttributes = <String, String>{};
      
      for (final header in headerMap.keys) {
        if (!mappedHeaders.contains(header)) {
          final colIdx = headerMap[header]!;
          final val = _cell(row.elementAtOrNull(colIdx));
          if (val.isNotEmpty) {
            extraAttributes[header] = val;
          }
        }
      }

      final teamId = 'team_${uuid.v4().substring(0, 8)}_${i}';
      teams.add(TeamModel(
        teamId: teamId,
        eventId: eid,
        teamName: teamName,
        collegeName: collegeName,
        leaderName: leaderName,
        leaderEmail: leaderEmail,
        leaderPhone: leaderPhone,
        members: members,
        extraAttributes: extraAttributes,
        qrPayload: AppConstants.buildQrPayload(eid, teamId),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    return ExcelParseResult.success(teams: teams, errors: errors);
  }

  String _extractField(List<Data?> row, Map<String, int> headerMap, String? headerName) {
    if (headerName == null || headerName.isEmpty) return '';
    final colIdx = headerMap[headerName];
    if (colIdx == null) return '';
    return _cell(row.elementAtOrNull(colIdx));
  }

  String _cell(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString().trim();
  }
}

class ExcelParseResult {
  final bool isSuccess;
  final List<TeamModel> teams;
  final List<RowError> rowErrors;
  final String? fatalError;

  const ExcelParseResult._({
    required this.isSuccess,
    this.teams = const [],
    this.rowErrors = const [],
    this.fatalError,
  });

  factory ExcelParseResult.success({
    required List<TeamModel> teams,
    List<RowError> errors = const [],
  }) =>
      ExcelParseResult._(isSuccess: true, teams: teams, rowErrors: errors);

  factory ExcelParseResult.failure(String error) =>
      ExcelParseResult._(isSuccess: false, fatalError: error);
}

class RowError {
  final int row;
  final String message;
  const RowError({required this.row, required this.message});
}
