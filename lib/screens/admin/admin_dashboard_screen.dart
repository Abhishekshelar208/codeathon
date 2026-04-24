import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/models/team_model.dart';
import 'package:codeathon/services/firebase_service.dart';
import 'package:codeathon/widgets/stat_card_widget.dart';
import 'package:codeathon/widgets/progress_ring_widget.dart';
import 'package:codeathon/widgets/activity_feed_widget.dart';
import 'package:codeathon/screens/admin/admin_team_list_screen.dart';
import 'package:codeathon/screens/admin/admin_qr_gallery_screen.dart';
import 'package:codeathon/screens/admin/admin_upload_screen.dart';
import 'package:codeathon/screens/admin/admin_volunteer_management_screen.dart';
import 'package:codeathon/models/volunteer_model.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Command Centre'),
            Text(AppConstants.kEventName,
              style: const TextStyle(
                fontSize: 11, color: AppTheme.kTextSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'Upload Excel',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminUploadScreen())),
          ),
        ],
      ),
      body: StreamBuilder<List<TeamModel>>(
        stream: FirebaseService.instance.teamsStream(AppConstants.kEventId),
        builder: (context, snapshot) {
          final teams = snapshot.data ?? [];
          final total   = teams.length;
          final arrived = teams.where((t) => t.arrivalStatus).length;
          final lunch   = teams.where((t) => t.lunchStatus).length;
          final pending = total - arrived;

          return RefreshIndicator(
            color: AppTheme.kPrimary,
            onRefresh: () async {},
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Connection status indicator
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const LinearProgressIndicator(
                      color: AppTheme.kPrimary,
                      backgroundColor: AppTheme.kCard,
                    ),

                  // Stat cards grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      StatCardWidget(
                        label: 'Total Teams',
                        value: total,
                        total: total == 0 ? 1 : total,
                        color: AppTheme.kAccentLight,
                        icon: Icons.groups_rounded,
                        animationDelay: 0,
                      ),
                      StatCardWidget(
                        label: 'Arrived',
                        value: arrived,
                        total: total == 0 ? 1 : total,
                        color: AppTheme.kPrimary,
                        icon: Icons.login_rounded,
                        animationDelay: 100,
                      ),
                      StatCardWidget(
                        label: 'Pending',
                        value: pending,
                        total: total == 0 ? 1 : total,
                        color: AppTheme.kPending,
                        icon: Icons.hourglass_empty_rounded,
                        animationDelay: 200,
                      ),
                      StatCardWidget(
                        label: 'Had Lunch',
                        value: lunch,
                        total: total == 0 ? 1 : total,
                        color: AppTheme.kSuccess,
                        icon: Icons.restaurant_rounded,
                        animationDelay: 300,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Donut chart
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.kCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.kCardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Attendance Overview',
                          style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 16),
                        ProgressRingWidget(
                          arrived: arrived, lunch: lunch, total: total),
                        const SizedBox(height: 16),
                        _buildLegend(),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 16),

                  // Quick action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          context,
                          label: 'Team List',
                          icon: Icons.list_alt_rounded,
                          color: AppTheme.kPrimary,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminTeamListScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionButton(
                          context,
                          label: 'QR Gallery',
                          icon: Icons.qr_code_2_rounded,
                          color: AppTheme.kAccent,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminQrGalleryScreen())),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 16),

                  _actionButton(
                    context,
                    label: 'Volunteer Food Management',
                    icon: Icons.person_add_rounded,
                    color: AppTheme.kAccentLight,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const AdminVolunteerManagementScreen())),
                  ).animate().fadeIn(delay: 550.ms),

                  const SizedBox(height: 24),

                  // Volunteer summary section
                  StreamBuilder<List<VolunteerModel>>(
                    stream: FirebaseService.instance
                        .volunteersStream(AppConstants.kEventId),
                    builder: (context, volSnap) {
                      final vols = volSnap.data ?? [];
                      final totalVols = vols.length;
                      final foodVols = vols.where((v) => v.foodStatus).length;
                      final pendingVols = totalVols - foodVols;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.kCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.kCardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Volunteer Food Tracking',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _simpleStat('Total', totalVols),
                                _simpleStat('Food Taken', foodVols,
                                    color: AppTheme.kSuccess),
                                _simpleStat('Pending', pendingVols,
                                    color: AppTheme.kPending),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 24),

                  // Activity Feed
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.kCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.kCardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Text('Live Activity',
                            style:
                                Theme.of(context).textTheme.headlineMedium),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<List<ActivityEntry>>(
                          stream: FirebaseService.instance
                              .activityStream(AppConstants.kEventId),
                          builder: (ctx, snap) {
                            final entries = snap.data ?? [];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: ActivityFeedWidget(entries: entries),
                            );
                          },
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(AppTheme.kSuccess, 'Lunch Done'),
        const SizedBox(width: 16),
        _legendDot(AppTheme.kPrimary, 'Arrived'),
        const SizedBox(width: 16),
        _legendDot(AppTheme.kCardBorder, 'Pending'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
          style: const TextStyle(
            fontSize: 11, color: AppTheme.kTextSecondary)),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _simpleStat(String label, int value, {Color? color}) {
    return Column(
      children: [
        Text(value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? AppTheme.kTextPrimary,
            )),
        Text(label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.kTextSecondary,
            )),
      ],
    );
  }
}
