import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/models/volunteer_model.dart';
import 'package:codeathon/services/firebase_service.dart';
import 'package:codeathon/screens/admin/volunteer_qr_screen.dart';
import 'package:codeathon/screens/volunteer/volunteer_scanner_screen.dart';

class AdminVolunteerManagementScreen extends StatefulWidget {
  const AdminVolunteerManagementScreen({super.key});

  @override
  State<AdminVolunteerManagementScreen> createState() =>
      _AdminVolunteerManagementScreenState();
}

class _AdminVolunteerManagementScreenState
    extends State<AdminVolunteerManagementScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _creating = false;

  Future<void> _createVolunteer() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _creating = true);
    try {
      await FirebaseService.instance
          .createVolunteer(AppConstants.kEventId, name);
      _nameController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Volunteer created successfully!'),
            backgroundColor: AppTheme.kSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.kError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _editVolunteer(VolunteerModel volunteer) async {
    final controller = TextEditingController(text: volunteer.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Volunteer'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != volunteer.name) {
      await FirebaseService.instance.updateVolunteer(
        AppConstants.kEventId,
        volunteer.copyWith(name: newName),
      );
    }
  }

  Future<void> _deleteVolunteer(VolunteerModel volunteer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${volunteer.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseService.instance.deleteVolunteer(
        AppConstants.kEventId,
        volunteer.volunteerId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Management'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VolunteerScannerScreen(
                    mode: ScanMode.volunteerFood),
              ),
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan Volunteer Pass',
          ),
        ],
      ),
      body: StreamBuilder<List<VolunteerModel>>(
        stream: FirebaseService.instance
            .volunteersStream(AppConstants.kEventId),
        builder: (context, snapshot) {
          final allVolunteers = snapshot.data ?? [];
          final collected = allVolunteers.where((v) => v.foodStatus).toList();
          final pending = allVolunteers.where((v) => !v.foodStatus).toList();

          return Column(
            children: [
              // Analysis / Summary Section
              if (allVolunteers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      _buildAnalyticCard('Total', allVolunteers.length, AppTheme.kPrimary),
                      const SizedBox(width: 8),
                      _buildAnalyticCard('Collected', collected.length, AppTheme.kSuccess),
                      const SizedBox(width: 8),
                      _buildAnalyticCard('Pending', pending.length, AppTheme.kPending),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.1),

              // Input Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.kCardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add New Volunteer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Name',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                filled: true,
                                fillColor: AppTheme.kBackground.withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _creating ? null : _createVolunteer,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: _creating
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),
              ),

              const Divider(height: 1, color: AppTheme.kCardBorder),

              // List Section with Filter tabs
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: false,
                        labelColor: AppTheme.kAccent,
                        unselectedLabelColor: AppTheme.kTextSecondary,
                        indicatorColor: AppTheme.kAccent,
                        tabs: const [
                          Tab(text: 'All'),
                          Tab(text: 'Pending'),
                          Tab(text: 'Collected'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildList(context, allVolunteers),
                            _buildList(context, pending),
                            _buildList(context, collected),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnalyticCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<VolunteerModel> volunteers) {
    if (volunteers.isEmpty) {
      return const Center(
        child: Text(
          'No records found.',
          style: TextStyle(color: AppTheme.kTextSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: volunteers.length,
      itemBuilder: (context, index) {
        final volunteer = volunteers[index];
        return _VolunteerTile(
          volunteer: volunteer,
          index: index,
          onEdit: () => _editVolunteer(volunteer),
          onDelete: () => _deleteVolunteer(volunteer),
        );
      },
    );
  }
}

class _VolunteerTile extends StatelessWidget {
  final VolunteerModel volunteer;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VolunteerTile({
    required this.volunteer,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.kCardBorder),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VolunteerQrScreen(volunteer: volunteer),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: AppTheme.kPrimary.withOpacity(0.1),
          child: const Icon(Icons.person_rounded, color: AppTheme.kPrimary),
        ),
        title: Text(
          volunteer.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.kTextPrimary,
          ),
        ),
        subtitle: Text(
          volunteer.foodStatus ? 'Food Collected' : 'Food Pending',
          style: TextStyle(
            color: volunteer.foodStatus
                ? AppTheme.kSuccess
                : AppTheme.kTextSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_rounded,
              color: AppTheme.kTextSecondary,
              size: 20,
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') {
                  onEdit();
                } else if (val == 'delete') {
                  onDelete();
                }
              },
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.kTextSecondary),
              color: AppTheme.kCard,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 18, color: AppTheme.kAccent),
                      SizedBox(width: 8),
                      Text('Edit Name'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, size: 18, color: AppTheme.kError),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppTheme.kError)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideX(begin: 0.1);
  }
}
