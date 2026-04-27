import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/screens/admin/admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscure = true;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'Enter the admin PIN');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    if (pin == AppConstants.kAdminPin) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
    } else {
      setState(() { _error = 'Incorrect PIN. Try again.'; _loading = false; });
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.kHeroGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo / icon
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.kPrimaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kPrimary.withOpacity(0.35),
                          blurRadius: 24, spreadRadius: 4,
                        )
                      ],
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: AppTheme.kBackground, size: 40),
                  )
                  .animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.7, 0.7)),

                  const SizedBox(height: 24),
                  Text('Admin Access',
                    style: Theme.of(context).textTheme.displayMedium,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text('TrackFloww',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 48),

                  // PIN field
                  TextField(
                    controller: _pinController,
                    focusNode: _focusNode,
                    obscureText: _obscure,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(
                      fontSize: 22, letterSpacing: 8,
                      color: AppTheme.kTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••',
                      hintStyle: GoogleFonts.outfit(
                        letterSpacing: 8, fontSize: 22,
                        color: AppTheme.kTextMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppTheme.kPrimary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_rounded
                                   : Icons.visibility_rounded,
                          color: AppTheme.kTextSecondary,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _submit(),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.kBackground,
                              ))
                          : const Text('Enter Admin Panel'),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
