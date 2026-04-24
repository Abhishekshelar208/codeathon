import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/models/volunteer_model.dart';
import 'package:codeathon/utils/qr_downloader.dart';

class VolunteerQrScreen extends StatefulWidget {
  final VolunteerModel volunteer;
  const VolunteerQrScreen({super.key, required this.volunteer});

  @override
  State<VolunteerQrScreen> createState() => _VolunteerQrScreenState();
}

class _VolunteerQrScreenState extends State<VolunteerQrScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _exporting = false;

  Future<void> _shareQr(BuildContext context) async {
    setState(() => _exporting = true);
    
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final rect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    final bytes = await QrDownloader.instance.captureQr(_repaintKey);
    if (bytes != null) {
      await QrDownloader.instance.shareQr(
        bytes,
        'volunteer_${widget.volunteer.name}',
        origin: rect,
      );
    }
    
    if (mounted) setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volunteer Pass')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QR Card
              RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(
                        data: widget.volunteer.qrPayload,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.volunteer.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Text(
                        'OFFICIAL VOLUNTEER',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.kPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ).animate().scale(
                    begin: const Offset(0.8, 0.8),
                    curve: Curves.easeOutBack,
                    duration: 600.ms,
                  ),

              const SizedBox(height: 48),

              // Actions
              Builder(
                builder: (btnCtx) => Column(
                  children: [
                    SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
                        onPressed: _exporting ? null : () => _shareQr(btnCtx),
                        icon: _exporting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.share_rounded),
                        label: Text(_exporting ? 'Processing...' : 'Share Pass'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.kAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sharing allows sending via WhatsApp, Gmail, etc.',
                      style: TextStyle(
                        color: AppTheme.kTextSecondary.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
