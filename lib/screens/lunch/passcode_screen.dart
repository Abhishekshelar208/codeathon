import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/services/firebase_service.dart';
import 'package:codeathon/screens/lunch/team_detail_screen.dart';

/// Passcode entry screen.
/// Team enters their 4-digit passcode to access team details.
class PasscodeScreen extends StatefulWidget {
  final String teamId;
  const PasscodeScreen({super.key, required this.teamId});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  final _codeCtrl  = TextEditingController();
  bool _verifying  = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 4) {
      setState(() => _error = 'Enter a 4-digit passcode');
      return;
    }

    setState(() { _verifying = true; _error = null; });

    try {
      final team = await FirebaseService.instance.verifyPasscode(
        AppConstants.kEventId,
        widget.teamId,
        code,
      );

      if (!mounted) return;
      setState(() => _verifying = false);

      if (team == null) {
        // Wrong passcode
        _codeCtrl.clear();
        setState(() => _error = 'Incorrect passcode. Try again.');
        HapticFeedback.heavyImpact();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TeamDetailScreen(team: team),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = 'Network error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.kHeroGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 48),

                // ── Lock Icon ─────────────────────────────────────────────
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: AppTheme.kAccentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.kAccent.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: Colors.white, size: 38),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      curve: Curves.elasticOut,
                      duration: 700.ms,
                    )
                    .fadeIn(),

                const SizedBox(height: 24),

                Text(
                  widget.teamId,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.kPrimary,
                    letterSpacing: 2,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 6),

                const Text(
                  'Enter your team passcode',
                  style: TextStyle(
                    color: AppTheme.kTextSecondary,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 10),

                const Text(
                  'You received this when you registered at the Entry Gate',
                  style: TextStyle(
                    color: AppTheme.kTextMuted,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 350.ms),

                const Spacer(),

                // ── Passcode Input ────────────────────────────────────────
                _PasscodeInput(
                  controller: _codeCtrl,
                  error: _error,
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => _verify(),
                ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),

                // ── Verify Button ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _verifying ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: AppTheme.kAccent.withOpacity(0.4),
                    ),
                    child: _verifying
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_open_rounded, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Verify Passcode',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                  ),
                ).animate().fadeIn(delay: 550.ms),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '← Back to Team List',
                    style: TextStyle(color: AppTheme.kTextSecondary),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Passcode Input Widget ─────────────────────────────────────────────────────

class _PasscodeInput extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _PasscodeInput({
    required this.controller,
    required this.error,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            letterSpacing: 20,
            color: AppTheme.kAccentLight,
          ),
          obscureText: false,
          showCursor: true,
          decoration: InputDecoration(
            hintText: '0000',
            hintStyle: const TextStyle(
              color: AppTheme.kTextMuted,
              fontSize: 48,
              letterSpacing: 16,
            ),
            errorText: error,
            errorStyle:
                const TextStyle(color: AppTheme.kError, fontSize: 13),
            filled: true,
            fillColor: AppTheme.kCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  const BorderSide(color: AppTheme.kCardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  const BorderSide(color: AppTheme.kAccent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  const BorderSide(color: AppTheme.kError, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 22),
          ),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }
}
