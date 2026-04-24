import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/models/team_model.dart';
import 'package:codeathon/services/excel_parser_service.dart';
import 'package:codeathon/services/firebase_service.dart';
import 'package:codeathon/models/event_model.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  int _currentStep = 0;

  // Step 1 State
  String? _fileName;
  Uint8List? _fileBytes;
  List<String> _extractedHeaders = [];
  String? _step1Error;

  // Step 2 State
  final Map<String, String> _mapping = {};
  bool _trackMembers = false; // Configuration option

  // Step 3 State
  List<TeamModel>? _parsedTeams;
  List<RowError> _rowErrors = [];
  String? _step3Error;
  bool _uploading = false;
  bool _uploaded = false;

  final Map<String, String> _systemFields = {
    'teamName': 'Team Name (Required)',
    'collegeName': 'College Name',
    'leaderName': 'Leader Name',
    'leaderEmail': 'Leader Email (For QR)',
    'leaderPhone': 'Leader Contact',
    'member1Name': 'Member 1 Name',
    'member2Name': 'Member 2 Name',
    'member3Name': 'Member 3 Name',
    'member4Name': 'Member 4 Name',
  };

  Future<void> _pickFile() async {
    setState(() => _step1Error = null);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final bytes = result.files.single.bytes!;
    final name = result.files.single.name;

    try {
      final headers = ExcelParserService.instance.extractHeaders(bytes.toList());
      setState(() {
        _fileBytes = bytes;
        _fileName = name;
        _extractedHeaders = headers;
        // Auto-map if exact matches found (case-insensitive)
        _mapping.clear();
        for (var sysKey in _systemFields.keys) {
          final match = headers.cast<String?>().firstWhere(
            (h) => h?.toLowerCase().replaceAll(' ', '') ==
                   _systemFields[sysKey]?.toLowerCase().split(' (')[0].replaceAll(' ', ''),
            orElse: () => null,
          );
          if (match != null) _mapping[sysKey] = match;
        }
        _currentStep = 1;
      });
    } catch (e) {
      setState(() => _step1Error = e.toString());
    }
  }

  void _parseData() {
    setState(() {
      _step3Error = null;
      _parsedTeams = null;
      _rowErrors = [];
    });

    if (_mapping['teamName'] == null || _mapping['teamName']!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team Name must be mapped.'), backgroundColor: AppTheme.kError),
      );
      return;
    }

    final parsed = ExcelParserService.instance.parseWithMapping(
      _fileBytes!.toList(),
      _mapping,
      eventId: AppConstants.kEventId,
    );

    setState(() {
      if (parsed.isSuccess) {
        _parsedTeams = parsed.teams;
        _rowErrors = parsed.rowErrors;
        _currentStep = 2;
      } else {
        _step3Error = parsed.fatalError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_step3Error!), backgroundColor: AppTheme.kError),
        );
      }
    });
  }

  Future<void> _uploadToFirebase() async {
    if (_parsedTeams == null || _parsedTeams!.isEmpty) return;
    setState(() => _uploading = true);

    try {
      await FirebaseService.instance.saveEventMeta(EventModel(
        eventId: AppConstants.kEventId,
        name: AppConstants.kEventName,
        date: '2026-04-25',
        totalTeams: _parsedTeams!.length,
      ));
      
      await FirebaseService.instance.uploadTeams(AppConstants.kEventId, _parsedTeams!);

      if (mounted) {
        setState(() { _uploading = false; _uploaded = true; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Data successfully configured and uploaded!'),
            backgroundColor: AppTheme.kSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppTheme.kError),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Configuration Upload')),
      body: Stepper(
        currentStep: _currentStep,
        type: StepperType.vertical,
        controlsBuilder: (context, details) => const SizedBox.shrink(),
        steps: [
          Step(
            title: const Text('1. Select Excel File'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            content: _buildStep1(),
          ),
          Step(
            title: const Text('2. Map Columns & Configure'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
            content: _buildStep2(),
          ),
          Step(
            title: const Text('3. Preview & Upload'),
            isActive: _currentStep >= 2,
            state: _uploaded ? StepState.complete : StepState.editing,
            content: _buildStep3(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_step1Error != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            color: AppTheme.kError.withAlpha(26),
            child: Text('Error: $_step1Error', style: const TextStyle(color: AppTheme.kError)),
          ),
        GestureDetector(
          onTap: _pickFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _fileName != null ? AppTheme.kSuccess : AppTheme.kCardBorder,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _fileName != null ? Icons.file_present_rounded : Icons.upload_file_rounded,
                  size: 48,
                  color: _fileName != null ? AppTheme.kSuccess : AppTheme.kPrimary,
                ),
                const SizedBox(height: 12),
                Text(
                  _fileName ?? 'Tap to select Excel file (.xlsx)',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.kPrimary.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.kPrimary.withAlpha(76)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tracking Configuration', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kPrimary)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Track individual members during event'),
                subtitle: const Text('If off, scanner checks-in entire team at once. (QR is sent to Leader either way).'),
                value: _trackMembers,
                onChanged: (v) => setState(() => _trackMembers = v),
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.kPrimary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Map Excel columns to System Parameters:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ..._systemFields.entries.map((entry) {
          final isRequired = entry.key == 'teamName';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(entry.value, style: TextStyle(color: isRequired ? AppTheme.kError : AppTheme.kTextPrimary)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _mapping[entry.key],
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.kCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    hint: const Text('Unmapped'),
                    items: [
                      const DropdownMenuItem<String>(value: '', child: Text('Unmapped', style: TextStyle(color: Colors.grey))),
                      ..._extractedHeaders.map((h) => DropdownMenuItem(value: h, child: Text(h, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        if (val == null || val.isEmpty) {
                          _mapping.remove(entry.key);
                        } else {
                          _mapping[entry.key] = val;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(onPressed: () => setState(() => _currentStep = 0), child: const Text('Back')),
            ElevatedButton(onPressed: _parseData, child: const Text('Next: Preview & Validate')),
          ],
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildStep3() {
    if (_parsedTeams == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: AppTheme.kPrimaryGradient, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Valid Teams', '${_parsedTeams!.length}'),
              _statItem('Warnings', '${_rowErrors.length}'),
            ],
          ),
        ),
        if (_rowErrors.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.kWarning.withAlpha(20),
              border: Border.all(color: AppTheme.kWarning.withAlpha(76)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚠️ ${_rowErrors.length} items skipped:', style: const TextStyle(color: AppTheme.kWarning)),
                const SizedBox(height: 4),
                ..._rowErrors.take(5).map((e) => Text('Row ${e.row}: ${e.message}', style: const TextStyle(fontSize: 12))),
                if (_rowErrors.length > 5) const Text('...', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        const SizedBox(height: 24),
        if (_uploaded)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kSuccess),
            onPressed: null,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Upload Complete'),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               TextButton(onPressed: () => setState(() => _currentStep = 1), child: const Text('Edit Mapping')),
               ElevatedButton.icon(
                onPressed: _uploading ? null : _uploadToFirebase,
                icon: _uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.cloud_upload_rounded),
                label: Text(_uploading ? 'Processing...' : 'Confirm & Upload'),
              ),
            ],
          ),
      ],
    ).animate().fadeIn();
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      ],
    );
  }
}
