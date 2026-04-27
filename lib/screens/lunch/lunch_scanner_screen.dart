import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';

/// QR scanner used to confirm lunch.
/// Expects to scan the Lunch QR whose payload is [AppConstants.kLunchQrPayload].
/// Returns `true` via Navigator.pop when the correct QR is scanned.
class LunchScannerScreen extends StatefulWidget {
  final String teamId;
  const LunchScannerScreen({super.key, required this.teamId});

  @override
  State<LunchScannerScreen> createState() => _LunchScannerScreenState();
}

class _LunchScannerScreenState extends State<LunchScannerScreen> {
  late final MobileScannerController _controller;
  bool _processing = false;
  bool _isRunning  = false;
  MobileScannerException? _cameraError;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      autoStart: false,
    );
    _controller.addListener(_onState);
    _initScanner();
  }

  Future<void> _initScanner() async {
    if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        Fluttertoast.showToast(
          msg: 'Camera permission is required.',
          backgroundColor: AppTheme.kError,
          textColor: Colors.white,
        );
        return;
      }
    }
    try {
      await _controller.start();
    } catch (e) {
      debugPrint('Scanner start error: $e');
    }
  }

  void _onState() {
    if (!mounted) return;
    setState(() {
      _isRunning   = _controller.value.isRunning;
      _cameraError = _controller.value.error;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onState);
    _controller.dispose();
    super.dispose();
  }

  // ── Scan Handler ──────────────────────────────────────────────────────────

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _processing = true);
    try {
      await _controller.stop();
    } catch (_) {}

    if (raw == AppConstants.kLunchQrPayload) {
      // ✅ Correct Lunch QR
      Fluttertoast.showToast(
        msg: '✅ Lunch QR Verified!',
        backgroundColor: AppTheme.kSuccess,
        textColor: Colors.white,
      );
      if (mounted) Navigator.pop(context, true); // signal success
    } else {
      // ❌ Wrong QR
      Fluttertoast.showToast(
        msg: '❌ Wrong QR Code. Please scan the Lunch QR.',
        backgroundColor: AppTheme.kError,
        textColor: Colors.white,
      );
      if (mounted) {
        setState(() => _processing = false);
        try {
          await _controller.start();
        } catch (_) {}
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera ──────────────────────────────────────────────────────
          Positioned.fill(child: _buildCamera()),

          // ── Top Gradient ─────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0, height: 180,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Bottom Gradient ───────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0, height: 240,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Overlay ──────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                if (_isRunning && !_processing) ...[
                  _ScanFrame(color: AppTheme.kWarning),
                  const SizedBox(height: 20),
                  _buildHint(),
                ],
                const Spacer(),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // ── Processing Overlay ────────────────────────────────────────────
          if (_processing)
            Container(
              color: const Color(0xAA000000),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                        color: AppTheme.kWarning, strokeWidth: 3),
                    SizedBox(height: 16),
                    Text('Verifying…',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 15)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCamera() {
    if (_cameraError != null &&
        _cameraError!.errorCode ==
            MobileScannerErrorCode.permissionDenied) {
      return _permissionDenied();
    }
    if (_cameraError != null) {
      return _cameraErrorWidget();
    }
    return MobileScanner(
      controller: _controller,
      onDetect: _onDetect,
      placeholderBuilder: (_) => _buildLoadingPlaceholder(),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Material(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context, false),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          const Spacer(),
          // Mode badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.kWarning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.kWarning, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restaurant_rounded,
                    color: AppTheme.kWarning, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Lunch — ${widget.teamId}',
                  style: const TextStyle(
                    color: AppTheme.kWarning,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Torch
          if (!kIsWeb)
            Material(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _controller.toggleTorch(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.flash_on_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner_rounded,
              color: AppTheme.kWarning, size: 18),
          SizedBox(width: 8),
          Text(
            'Scan the Lunch QR code to confirm',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(begin: 0.5, duration: 900.ms);
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: const Color(0xFF0A0E1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 52, height: 52,
              child: CircularProgressIndicator(
                  color: AppTheme.kWarning, strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            const Text(
              '📷  Requesting camera…',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _permissionDenied() {
    return Container(
      color: const Color(0xFF0A0E1A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_rounded,
                  color: AppTheme.kError, size: 60),
              const SizedBox(height: 20),
              const Text('Camera Permission Denied',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text(
                'Allow camera access in settings, then tap Retry.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await _controller.start();
                  } catch (_) {}
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cameraErrorWidget() {
    return Container(
      color: const Color(0xFF0A0E1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppTheme.kError, size: 60),
            const SizedBox(height: 16),
            Text(
              _cameraError?.errorDetails?.message ?? 'Camera error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try { await _controller.start(); } catch (_) {}
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated Scan Frame ────────────────────────────────────────────────────────

class _ScanFrame extends StatelessWidget {
  final Color color;
  const _ScanFrame({required this.color});

  @override
  Widget build(BuildContext context) {
    const size = 260.0;
    const cornerLen = 32.0;
    const thickness = 4.0;

    return SizedBox(
      width: size, height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
            ),
          ),
          _LaserLine(color: color),
          ..._corners(color, cornerLen, thickness),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(end: 1.03, duration: 1500.ms, curve: Curves.easeInOut);
  }

  List<Widget> _corners(Color c, double len, double t) => [
        Positioned(
            top: 0, left: 0,
            child: _corner(c, t, len, top: true, left: true)),
        Positioned(
            top: 0, right: 0,
            child: _corner(c, t, len, top: true, left: false)),
        Positioned(
            bottom: 0, left: 0,
            child: _corner(c, t, len, top: false, left: true)),
        Positioned(
            bottom: 0, right: 0,
            child: _corner(c, t, len, top: false, left: false)),
      ];

  Widget _corner(Color c, double t, double len,
      {required bool top, required bool left}) {
    return SizedBox(
      width: len, height: len,
      child: CustomPaint(
          painter: _CornerPainter(
              color: c, thickness: t, top: top, left: left)),
    );
  }
}

class _LaserLine extends StatefulWidget {
  final Color color;
  const _LaserLine({required this.color});

  @override
  State<_LaserLine> createState() => _LaserLineState();
}

class _LaserLineState extends State<_LaserLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.02, end: 0.98)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Positioned(
        top: 260 * _anim.value - 1,
        left: 0, right: 0,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                widget.color.withOpacity(0.8),
                widget.color,
                widget.color.withOpacity(0.8),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                  color: widget.color.withOpacity(0.4), blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool top, left;

  const _CornerPainter({
    required this.color,
    required this.thickness,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x  = left ? 0.0 : size.width;
    final y  = top  ? 0.0 : size.height;
    final dx = left ? size.width  : -size.width;
    final dy = top  ? size.height : -size.height;

    canvas.drawPath(
      Path()
        ..moveTo(x + dx, y)
        ..lineTo(x, y)
        ..lineTo(x, y + dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
