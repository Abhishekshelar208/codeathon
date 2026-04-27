import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';

/// Displays the Lunch Area QR code that is printed and placed outside the lunch area.
/// Teams scan this QR on the LunchScannerScreen to confirm their meal.
class LunchQrScreen extends StatefulWidget {
  const LunchQrScreen({super.key});

  @override
  State<LunchQrScreen> createState() => _LunchQrScreenState();
}

class _LunchQrScreenState extends State<LunchQrScreen> {
  final ScreenshotController _screenshotCtrl = ScreenshotController();
  bool _sharing = false;

  Future<void> _shareQr() async {
    setState(() => _sharing = true);
    try {
      final Uint8List? imageBytes = await _screenshotCtrl.capture(
        pixelRatio: 3.0,
      );
      if (imageBytes == null) {
        throw Exception('Could not capture QR image.');
      }

      // ✅ XFile.fromData — shares raw bytes directly, no path_provider needed
      final xFile = XFile.fromData(
        imageBytes,
        name: 'gtc2026_lunch_qr.png',
        mimeType: 'image/png',
      );

      await Share.shareXFiles(
        [xFile],
        subject: 'GTC 2026 — Lunch Area QR Code',
        text:
            'Scan this QR at the lunch station to mark your meal. — GTC 2026',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: AppTheme.kError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lunch Area QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _sharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.kPrimary),
                  )
                : const Icon(Icons.share_rounded),
            tooltip: 'Share / Save QR',
            onPressed: _sharing ? null : _shareQr,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Instruction Banner ─────────────────────────────────────────
            _InstructionBanner().animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 28),

            // ── QR Card (captured for sharing) ────────────────────────────
            Screenshot(
              controller: _screenshotCtrl,
              child: _QrCard(),
            ).animate().fadeIn(delay: 250.ms).scale(
                  begin: const Offset(0.92, 0.92),
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 28),

            // ── Share Button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _sharing ? null : _shareQr,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kSuccess,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: AppTheme.kSuccess.withOpacity(0.4),
                ),
                icon: _sharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.share_rounded),
                label: Text(
                  _sharing ? 'Preparing…' : 'Share / Save QR Image',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 16),

            // ── How to use ────────────────────────────────────────────────
            _HowToUse().animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Instruction Banner ────────────────────────────────────────────────────────

class _InstructionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.kWarning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppTheme.kWarning.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.print_rounded, color: AppTheme.kWarning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Print & Display at Lunch Area',
                  style: TextStyle(
                    color: AppTheme.kWarning,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Share this QR as an image, print it, and stick it outside the lunch area. Teams scan it to confirm their meal.',
                  style: TextStyle(
                    color: AppTheme.kWarning,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── QR Card ───────────────────────────────────────────────────────────────────

class _QrCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kSuccess.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const Icon(Icons.restaurant_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(height: 6),
                const Text(
                  'LUNCH AREA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppConstants.kEventName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // QR Code
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFFE2E8F0), width: 2),
                  ),
                  child: QrImageView(
                    data: AppConstants.kLunchQrPayload,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF059669),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF064E3B),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Scan to Confirm Meal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF064E3B),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Open the GTC 2026 app → Lunch Station\n→ Select your team → Scan this code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Payload label (small, for reference)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    AppConstants.kLunchQrPayload,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Color(0xFF059669),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: const Text(
              '🌐  Global Tech Conference 2026',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── How To Use ────────────────────────────────────────────────────────────────

class _HowToUse extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline_rounded,
                  color: AppTheme.kPrimary, size: 18),
              SizedBox(width: 8),
              Text(
                'HOW IT WORKS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.kPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _step('1', 'Share & print this QR code image',
              Icons.print_rounded, AppTheme.kWarning),
          _step('2', 'Stick it outside the lunch area',
              Icons.push_pin_rounded, AppTheme.kAccentLight),
          _step('3', 'Team opens app → Lunch Station → selects team',
              Icons.touch_app_rounded, AppTheme.kPrimary),
          _step('4', 'Enters passcode → taps "Scan to Confirm Lunch"',
              Icons.lock_open_rounded, AppTheme.kSuccess),
          _step('5', 'Scans this QR → Lunch marked ✓',
              Icons.qr_code_scanner_rounded, AppTheme.kSuccess,
              isLast: true),
        ],
      ),
    );
  }

  Widget _step(String num, String label, IconData icon, Color color,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              num,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.kTextPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
