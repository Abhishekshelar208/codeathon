import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/services/firebase_service.dart';
import 'package:codeathon/utils/validators.dart';
import 'package:codeathon/screens/volunteer/volunteer_result_screen.dart';

enum ScanMode { arrival, lunch, volunteerFood }

class VolunteerScannerScreen extends StatefulWidget {
  final ScanMode mode;
  const VolunteerScannerScreen({super.key, required this.mode});

  @override
  State<VolunteerScannerScreen> createState() =>
      _VolunteerScannerScreenState();
}

class _VolunteerScannerScreenState extends State<VolunteerScannerScreen> {
  late final MobileScannerController _controller;

  /// Tracks whether a scan is currently being processed.
  bool _processing = false;

  /// Mirrors of the controller state for reactive UI.
  bool _isRunning = false;
  MobileScannerException? _cameraError;

  @override
  void initState() {
    super.initState();

    _controller = MobileScannerController(
      // v6 uses similar constructor.
      facing: CameraFacing.back,
      autoStart: false, // We will start manually after check
    );

    _controller.addListener(_onControllerStateChange);

    // Initial permission check & start
    _initScanner();
  }

  Future<void> _initScanner() async {
    if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        Fluttertoast.showToast(
          msg: "Camera permission is required to scan QR codes.",
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

  void _onControllerStateChange() {
    if (!mounted) return;
    final s = _controller.value;
    setState(() {
      _isRunning = s.isRunning;
      _cameraError = s.error;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChange);
    _controller.dispose();
    super.dispose();
  }

  // ── Scan handler ───────────────────────────────────────────────────────────

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    // Immediate feedback
    Fluttertoast.showToast(
      msg: "QR Detected! Processing...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: _modeColor.withAlpha(200),
      textColor: Colors.white,
    );

    setState(() => _processing = true);

    // Pause the camera stream while processing.
    try {
      await _controller.stop();
    } catch (_) {
      // Safe to ignore — may already be stopped.
    }

    final parsed = QrValidator.parse(raw);

    ScanUpdateResult? result;
    String? errorMsg;

    if (!parsed.isValid) {
      errorMsg = parsed.errorMessage;
    } else {
      try {
        if (widget.mode == ScanMode.arrival) {
          result = await FirebaseService.instance
              .markArrival(parsed.eventId!, parsed.id!);
        } else if (widget.mode == ScanMode.lunch) {
          result = await FirebaseService.instance
              .markLunch(parsed.eventId!, parsed.id!);
        } else {
          // Volunteer Food mode
          if (!parsed.isVolunteer) {
            errorMsg = "This is not a volunteer QR code.";
          } else {
            result = await FirebaseService.instance
                .markVolunteerFood(parsed.eventId!, parsed.id!);
          }
        }
      } catch (e) {
        result = ScanUpdateResult.error('Network error: $e');
      }
    }

    if (!mounted) return;

    // Show the result screen with a smooth fade (no black flash on web).
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => VolunteerResultScreen(
          result: result,
          errorMessage: errorMsg,
          mode: widget.mode,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );

    // Resume scanning.
    if (mounted) {
      try {
        await _controller.start();
      } catch (_) {}
      setState(() => _processing = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _modeLabel {
    if (widget.mode == ScanMode.arrival) return 'Entry Gate';
    if (widget.mode == ScanMode.lunch) return 'Lunch Area';
    return 'Volunteer Food';
  }

  Color get _modeColor {
    if (widget.mode == ScanMode.arrival) return AppTheme.kPrimary;
    if (widget.mode == ScanMode.lunch) return AppTheme.kWarning;
    return AppTheme.kAccent;
  }

  bool get _permissionDenied =>
      _cameraError?.errorCode == MobileScannerErrorCode.permissionDenied;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera layer ─────────────────────────────────────────────────
          Positioned.fill(child: _buildCameraLayer()),

          // ── Top gradient (readability) ───────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: 160,
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

          // ── Bottom gradient ──────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: 220,
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

          // ── Overlay UI ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                // Only show the scan frame once camera is actually live.
                if (_isRunning && !_processing) ...[
                  _ScanFrame(color: _modeColor),
                  const SizedBox(height: 24),
                  _buildHint(),
                ],
                const Spacer(),
                if (kIsWeb && _isRunning) _buildWebNote(),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // ── Processing overlay ───────────────────────────────────────────
          if (_processing)
            Container(
              color: const Color(0xAA000000),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                        color: AppTheme.kPrimary, strokeWidth: 3),
                    const SizedBox(height: 16),
                    const Text(
                      'Processing scan…',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildCameraLayer() {
    // Step 1: Camera permission was explicitly denied.
    if (_permissionDenied) {
      return _PermissionDeniedCard(
        onRetry: () async {
          try { await _controller.start(); } catch (_) {}
        },
      );
    }

    // Step 2: Camera errored for another reason.
    if (_cameraError != null && !_permissionDenied) {
      return _errorOverlay(
        '⚠️ Camera error: ${_cameraError!.errorDetails?.message ?? "unknown"}',
        isDenied: false,
      );
    }

    // Step 3: Camera widget — shows placeholder while Chrome permission dialog
    // is pending, then switches to live feed once permission is granted.
    return MobileScanner(
      controller: _controller,
      onDetect: _onDetect,
      // Shown while browser permission dialog is open / camera is starting.
      placeholderBuilder: (ctx) => _buildLoadingPlaceholder(),
      // Shown if a mid-session error occurs (e.g., camera disconnected).
      errorBuilder: (ctx, error) {
        final denied =
            error.errorCode == MobileScannerErrorCode.permissionDenied;
        return _errorOverlay(
          denied
              ? '🚫 Camera access was blocked by the browser'
              : '⚠️ ${error.errorDetails?.message ?? "Camera error"}',
          isDenied: denied,
        );
      },
    );
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
                color: AppTheme.kPrimary, strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            const Text(
              '📷  Requesting camera access…',
              style: TextStyle(color: Colors.white70, fontSize: 17,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text(
              kIsWeb
                  ? 'Chrome will show a permission popup at the top of the page.\n'
                    'Click "Allow" to start scanning.'
                  : 'Please grant camera permission when prompted.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _errorOverlay(String message, {required bool isDenied}) {
    return Container(
      color: const Color(0xFF0A0E1A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDenied
                    ? Icons.no_photography_rounded
                    : Icons.error_outline_rounded,
                color: AppTheme.kError, size: 64,
              ),
              const SizedBox(height: 20),
              Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 16, height: 1.5)),
              if (isDenied) ...[
                const SizedBox(height: 12),
                const Text(
                  'Open your browser\'s site settings\n'
                  'and allow camera access, then tap Retry.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white38, fontSize: 13, height: 1.5)),
              ],
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () async {
                  try { await _controller.start(); } catch (_) {}
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Back button
          Material(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color.fromARGB(51, _modeColor.r.toInt(),
                  _modeColor.g.toInt(), _modeColor.b.toInt()),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _modeColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.mode == ScanMode.arrival
                      ? Icons.login_rounded
                      : Icons.restaurant_rounded,
                  color: _modeColor, size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _modeLabel,
                  style: TextStyle(
                    color: _modeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Torch — hidden on web (not supported by browser API)
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
            const SizedBox(width: 44), // balance layout
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner_rounded, color: _modeColor, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Point camera at the team QR code',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(begin: 0.5, duration: 900.ms);
  }

  Widget _buildWebNote() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, color: Colors.white24, size: 13),
          const SizedBox(width: 5),
          Text(
            'Secure context · Camera stream stays in-browser',
            style: TextStyle(
                color: Colors.white.withAlpha(51), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Permission Denied Card ────────────────────────────────────────────────────

class _PermissionDeniedCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionDeniedCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0E1A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.kError.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.no_photography_rounded,
                    color: AppTheme.kError, size: 52),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    curve: Curves.elasticOut,
                    duration: 700.ms,
                  ),

              const SizedBox(height: 24),
              const Text(
                'Camera Access Denied',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your browser blocked camera access.\n\n'
                '① Click the 🔒 lock icon in Chrome\'s address bar\n'
                '② Set Camera → "Allow"\n'
                '③ Reload the page, then tap Retry',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white54, fontSize: 14, height: 1.7),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kPrimary,
                  foregroundColor: AppTheme.kBackground,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Camera',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Animated QR Scan Frame ────────────────────────────────────────────────────

class _ScanFrame extends StatelessWidget {
  final Color color;
  const _ScanFrame({required this.color});

  @override
  Widget build(BuildContext context) {
    const size = 260.0;
    const cornerLen = 32.0;
    const thickness = 4.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Subtle dimmed inner box
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withAlpha(51), width: 1),
              ),
            ),
          ),
          // Animated laser scan line
          _LaserLine(color: color),
          // Corner brackets
          ..._buildCorners(color, cornerLen, thickness),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(end: 1.03, duration: 1500.ms, curve: Curves.easeInOut);
  }

  List<Widget> _buildCorners(Color c, double len, double t) => [
        Positioned(top: 0, left: 0,
            child: _corner(c, t, len, top: true, left: true)),
        Positioned(top: 0, right: 0,
            child: _corner(c, t, len, top: true, left: false)),
        Positioned(bottom: 0, left: 0,
            child: _corner(c, t, len, top: false, left: true)),
        Positioned(bottom: 0, right: 0,
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

// ── Laser scan line (sweeps top → bottom → top in a loop) ────────────────────

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
    _anim = Tween<double>(begin: 0.02, end: 0.98).animate(
        CurvedAnimation(parent: _ac, curve: Curves.easeInOut));
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
      builder: (_, _) {
        return Positioned(
          top: 260 * _anim.value - 1,
          left: 0, right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  widget.color.withAlpha(200),
                  widget.color,
                  widget.color.withAlpha(200),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                    color: widget.color.withAlpha(100), blurRadius: 6),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Corner painter ────────────────────────────────────────────────────────────

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

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width : -size.width;
    final dy = top ? size.height : -size.height;

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
