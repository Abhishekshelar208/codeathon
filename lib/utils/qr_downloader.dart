import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Conditional import logic for web
import 'package:codeathon/utils/web_helper_stub.dart'
    if (dart.library.html) 'dart:html' as html;

class QrDownloader {
  QrDownloader._();
  static final QrDownloader instance = QrDownloader._();

  /// Captures the widget tree attached to [key] as a PNG and returns the bytes.
  Future<Uint8List?> captureQr(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('QrDownloader.captureQr error: $e');
      return null;
    }
  }

  /// Saves QR PNG bytes and triggers sharing.
  /// On Web: Attempts system share, falls back to download.
  /// On Mobile: Triggers system share sheet.
  Future<void> shareQr(Uint8List bytes, String teamName, {Rect? origin}) async {
    final safe = teamName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final fileName = 'qr_$safe.png';

    // On Web, try to use Web Share API first
    if (kIsWeb) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile.fromData(bytes, name: fileName, mimeType: 'image/png')],
            text: 'QR Code for $teamName — Global Tech Conference 2026',
          ),
        );
        return; // Success
      } catch (e) {
        debugPrint('Web share failed, falling back to download: $e');
        _triggerWebDownload(bytes, fileName);
        return;
      }
    }

    // Native Mobile Implementation
    try {
      // Use XFile.fromData directly to avoid manual file management where possible,
      // but some platforms still prefer a physical file for native sharing.
      // SharePlus handles XFile.fromData by creating a temp file internally on native.
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, name: fileName, mimeType: 'image/png')],
          text: 'QR Code for $teamName — Global Tech Conference 2026',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      debugPrint('Mobile share error: $e');
    }
  }

  void _triggerWebDownload(Uint8List bytes, String fileName) {
    try {
      final base64 = base64Encode(bytes);
      // Works because of conditional import above
      html.AnchorElement(
          href: 'data:application/octet-stream;base64,$base64')
        ..setAttribute('download', fileName)
        ..click();
      debugPrint('Download triggered for $fileName');
    } catch (e) {
       debugPrint('Web download error: $e');
    }
  }

  /// Saves QR PNG bytes to the device storage (Native Only).
  Future<String?> saveQrToDevice(Uint8List bytes, String teamName) async {
    if (kIsWeb) return null; // Web uses download via shareQr
    
    try {
      final dir = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();
      if (dir == null) return null;
      final safe = teamName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final path = '${dir.path}/qr_$safe.png';
      await File(path).writeAsBytes(bytes);
      return path;
    } catch (e) {
      debugPrint('QrDownloader.saveQrToDevice error: $e');
      return null;
    }
  }
}
