import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/models/team_model.dart';
import 'package:codeathon/services/firebase_service.dart';
import 'package:codeathon/utils/qr_downloader.dart';

class AdminQrGalleryScreen extends StatefulWidget {
  const AdminQrGalleryScreen({super.key});

  @override
  State<AdminQrGalleryScreen> createState() => _AdminQrGalleryScreenState();
}

class _AdminQrGalleryScreenState extends State<AdminQrGalleryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Gallery')),
      body: FutureBuilder<List<TeamModel>>(
        future: FirebaseService.instance
            .fetchTeamsOnce(AppConstants.kEventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.kPrimary));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No teams found. Upload Excel first.',
                  style: Theme.of(context).textTheme.bodyMedium),
            );
          }
          final teams = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: teams.length,
            itemBuilder: (_, i) =>
                _QrCard(team: teams[i], index: i),
          );
        },
      ),
    );
  }
}

class _QrCard extends StatefulWidget {
  final TeamModel team;
  final int index;
  const _QrCard({required this.team, required this.index});

  @override
  State<_QrCard> createState() => _QrCardState();
}

class _QrCardState extends State<_QrCard> {
  final _repaintKey = GlobalKey();
  bool _saving = false;

  Future<void> _share(BuildContext context) async {
    setState(() => _saving = true);
    
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final rect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    final bytes = await QrDownloader.instance.captureQr(_repaintKey);
    if (bytes != null) {
      await QrDownloader.instance.shareQr(
        bytes, 
        widget.team.teamName,
        origin: rect,
      );
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreenQr(context, widget.team),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.kCardBorder),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // QR code
            RepaintBoundary(
              key: _repaintKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: QrImageView(
                  data: widget.team.qrPayload,
                  version: QrVersions.auto,
                  size: 130,
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
              ),
            ),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                widget.team.teamName,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                widget.team.collegeName,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            // Share button
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SizedBox(
                width: double.infinity,
                child: Builder(
                  builder: (btnCtx) => ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kAccent,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _saving ? null : () => _share(btnCtx),
                    icon: _saving
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ))
                        : const Icon(Icons.share_rounded, size: 14),
                    label: Text(_saving ? 'Saving…' : 'Share',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: widget.index * 40))
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut);
  }

  void _showFullScreenQr(BuildContext context, TeamModel team) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: AppTheme.kCard,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.kCardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(team.teamName,
                      style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold,
                        color: AppTheme.kTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(team.collegeName,
                      style: const TextStyle(
                        fontSize: 14, color: AppTheme.kTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Main QR
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: QrImageView(
                  data: team.qrPayload,
                  version: QrVersions.auto,
                  size: 280,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              // Close Button
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: IconButton.filled(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.kPrimary,
                    minimumSize: const Size(60, 60),
                  ),
                ),
              ),
            ],
          ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
        ),
      ),
    );
  }
}
