import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/services/firebase_service.dart';
import 'package:codeathon/screens/registration/registration_success_screen.dart';

/// Entry-gate screen: team self-registers with Paper ID + member names.
/// A volunteer PIN (8488) is required to confirm submission.
class RegistrationFormScreen extends StatefulWidget {
  const RegistrationFormScreen({super.key});

  @override
  State<RegistrationFormScreen> createState() =>
      _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _paperIdCtrl = TextEditingController();
  final _m1Ctrl     = TextEditingController();
  final _m2Ctrl     = TextEditingController();
  final _m3Ctrl     = TextEditingController();
  final _m4Ctrl     = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _paperIdCtrl.dispose();
    _m1Ctrl.dispose();
    _m2Ctrl.dispose();
    _m3Ctrl.dispose();
    _m4Ctrl.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Check Paper ID uniqueness first (quick feedback before PIN dialog)
    setState(() => _submitting = true);
    try {
      final exists = await FirebaseService.instance
          .paperIdExists(AppConstants.kEventId, _paperIdCtrl.text.trim());
      if (!mounted) return;
      if (exists) {
        setState(() => _submitting = false);
        _showError(
            'Paper ID "${_paperIdCtrl.text.trim()}" is already registered.\nPlease check your Paper ID.');
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError('Network error. Please try again.\n$e');
      return;
    }
    setState(() => _submitting = false);

    // 2. Show PIN verification dialog
    final pinOk = await _showPinDialog();
    if (!mounted || pinOk != true) return;

    // 3. Create team
    setState(() => _submitting = true);
    try {
      final team = await FirebaseService.instance.createTeam(
        eventId: AppConstants.kEventId,
        paperId: _paperIdCtrl.text.trim(),
        members: [
          _m1Ctrl.text.trim(),
          _m2Ctrl.text.trim(),
          _m3Ctrl.text.trim(),
          _m4Ctrl.text.trim(),
        ],
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              RegistrationSuccessScreen(team: team),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } on DuplicatePaperIdException {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError('Paper ID already registered. Please verify your Paper ID.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError('Failed to register. Check your connection.\n$e');
    }
  }

  // ── PIN Dialog ─────────────────────────────────────────────────────────────

  Future<bool?> _showPinDialog() async {
    final pinCtrl = TextEditingController();
    String? pinError;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.kCard,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.kAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: AppTheme.kAccent, size: 32),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Volunteer Verification',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ask the volunteer for the code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.kTextSecondary, fontSize: 13),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pinCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 12,
                    color: AppTheme.kTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '• • • •',
                    hintStyle: const TextStyle(
                        color: AppTheme.kTextMuted, letterSpacing: 8),
                    errorText: pinError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppTheme.kCardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppTheme.kAccent, width: 2),
                    ),
                  ),
                  onSubmitted: (_) {
                    if (pinCtrl.text == AppConstants.kVerificationPin) {
                      Navigator.pop(ctx, true);
                    } else {
                      setDialogState(
                          () => pinError = 'Incorrect code. Try again.');
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.kTextSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (pinCtrl.text == AppConstants.kVerificationPin) {
                    Navigator.pop(ctx, true);
                  } else {
                    setDialogState(
                        () => pinError = 'Incorrect code. Try again.');
                  }
                },
                child: const Text('Verify'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.kError,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ── Header Banner ──────────────────────────────────────────────
              _buildBanner(),
              const SizedBox(height: 28),

              // ── Paper ID ───────────────────────────────────────────────────
              _sectionLabel('Paper ID', isRequired: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _paperIdCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppTheme.kPrimary,
                    letterSpacing: 1.5),
                decoration: InputDecoration(
                  hintText: 'e.g. ABC-123',
                  prefixIcon: const Icon(Icons.badge_rounded,
                      color: AppTheme.kPrimary),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.kPrimary, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Paper ID is required';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),

              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.kPrimary.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: AppTheme.kPrimary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is the ID on your project/poster. Each Paper ID can only register once.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.kPrimary),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 28),

              // ── Team Members ───────────────────────────────────────────────
              _sectionLabel('Team Members', isRequired: false),
              const SizedBox(height: 4),
              Text(
                'Enter member names (at least 1 recommended)',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 12),

              _memberField(_m1Ctrl, 'Member 1', delay: 200),
              const SizedBox(height: 12),
              _memberField(_m2Ctrl, 'Member 2', delay: 250),
              const SizedBox(height: 12),
              _memberField(_m3Ctrl, 'Member 3', delay: 300),
              const SizedBox(height: 12),
              _memberField(_m4Ctrl, 'Member 4', delay: 350),

              const SizedBox(height: 36),

              // ── Submit ─────────────────────────────────────────────────────
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kPrimary,
                    foregroundColor: AppTheme.kBackground,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppTheme.kPrimary.withOpacity(0.4),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: AppTheme.kBackground, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Register Team',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub Widgets ────────────────────────────────────────────────────────────

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.kPrimary.withOpacity(0.15),
            AppTheme.kAccent.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.kPrimary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.kPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.how_to_reg_rounded,
                color: AppTheme.kPrimary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Entry Registration',
                  style: TextStyle(
                    color: AppTheme.kPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Fill in your team details. A volunteer will verify your submission.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _sectionLabel(String label, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.kTextPrimary,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text('*',
              style: TextStyle(color: AppTheme.kError, fontSize: 16)),
        ],
      ],
    );
  }

  Widget _memberField(TextEditingController ctrl, String label,
      {required int delay}) {
    return TextFormField(
      controller: ctrl,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: const Icon(Icons.person_outline_rounded,
            color: AppTheme.kTextMuted, size: 20),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: -0.05);
  }
}
