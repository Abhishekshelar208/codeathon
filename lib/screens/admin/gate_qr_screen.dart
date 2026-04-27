import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';

/// Screen to generate and share the Gate Registration QR code.
/// This is meant to be printed and posted at the college gate.
class GateQrScreen extends StatefulWidget {
  const GateQrScreen({super.key});

  @override
  State<GateQrScreen> createState() => _GateQrScreenState();
}

class _GateQrScreenState extends State<GateQrScreen> {
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

      final xFile = XFile.fromData(
        imageBytes,
        name: 'gtc2026_gate_registration_qr.png',
        mimeType: 'image/png',
      );

      await Share.shareXFiles(
        [xFile],
        subject: 'GTC 2026 — Gate Registration QR',
        text: 'Scan this QR at the college gate to register your team. — GTC 2026',
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
        title: const Text('Gate Registration QR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Instruction ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.kPrimary.withOpacity(0.4), width: 1.5),
              ),
              child: const Row(
                children: [
                  Icon(Icons.door_front_door_rounded, color: AppTheme.kPrimary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Print this and post it at the College Gate entry point.',
                      style: TextStyle(color: AppTheme.kPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // ── QR Poster ──
            Screenshot(
              controller: _screenshotCtrl,
              child: _GateQrPoster(),
            ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 24),

            // ── Action Button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _sharing ? null : _shareQr,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _sharing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.share_rounded),
                label: const Text('Share / Save Poster Image', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _GateQrPoster extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                const Text(
                  'WELCOME TO',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                const Text(
                  'GTC 2026',
                  style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                const Text(
                  'GLOBAL TECH CONFERENCE',
                  style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // QR Section
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const Text(
                  'TEAM REGISTRATION',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                  ),
                  child: QrImageView(
                    data: AppConstants.kGateQrPayload,
                    version: QrVersions.auto,
                    size: 240,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF4F46E5)),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1E1B4B)),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'SCAN TO START',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ],
            ),
          ),

          // Steps Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REGISTRATION STEPS:',
                  style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 16),
                _stepRow('1', 'ONLY TEAM LEADER should scan this QR to register the whole team.'),
                _stepRow('2', 'Enter your Paper ID and Member names.'),
                _stepRow('3', 'Show your screen to the Volunteer at the gate.'),
                _stepRow('4', 'Volunteer will verify and confirm your entry.'),
                _stepRow('5', 'IMPORTANT: Screenshot your Team ID and Passcode!'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
