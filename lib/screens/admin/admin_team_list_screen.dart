import 'package:flutter/material.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/core/constants.dart';
import 'package:codeathon/models/team_model.dart';
import 'package:codeathon/services/firebase_service.dart';
import 'package:codeathon/widgets/team_status_tile.dart';

enum _FilterMode { all, arrived, notArrived, lunch }

class AdminTeamListScreen extends StatefulWidget {
  const AdminTeamListScreen({super.key});

  @override
  State<AdminTeamListScreen> createState() => _AdminTeamListScreenState();
}

class _AdminTeamListScreenState extends State<AdminTeamListScreen> {
  final _searchController = TextEditingController();
  _FilterMode _filter = _FilterMode.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TeamModel> _applyFilters(List<TeamModel> teams) {
    var list = teams;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((t) =>
              t.teamName.toLowerCase().contains(q) ||
              t.collegeName.toLowerCase().contains(q))
          .toList();
    }
    switch (_filter) {
      case _FilterMode.arrived:
        list = list.where((t) => t.arrivalStatus).toList();
        break;
      case _FilterMode.notArrived:
        list = list.where((t) => !t.arrivalStatus).toList();
        break;
      case _FilterMode.lunch:
        list = list.where((t) => t.lunchStatus).toList();
        break;
      case _FilterMode.all:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Teams')),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search team name or college…',
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppTheme.kTextSecondary),
              ),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('All', _FilterMode.all),
                  const SizedBox(width: 8),
                  _chip('Arrived', _FilterMode.arrived),
                  const SizedBox(width: 8),
                  _chip('Not Arrived', _FilterMode.notArrived),
                  const SizedBox(width: 8),
                  _chip('Had Lunch', _FilterMode.lunch),
                ],
              ),
            ),
          ),

          // Team list
          Expanded(
            child: StreamBuilder<List<TeamModel>>(
              stream: FirebaseService.instance
                  .teamsStream(AppConstants.kEventId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.kPrimary));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('No teams found.\nUpload an Excel file first.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final filtered = _applyFilters(snapshot.data!);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text('No teams match this filter.',
                        style: Theme.of(context).textTheme.bodyMedium),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) =>
                      TeamStatusTile(team: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _FilterMode mode) {
    final active = _filter == mode;
    return GestureDetector(
      onTap: () => setState(() => _filter = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.kPrimary.withOpacity(0.15)
              : AppTheme.kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppTheme.kPrimary : AppTheme.kCardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? AppTheme.kPrimary : AppTheme.kTextSecondary,
          ),
        ),
      ),
    );
  }
}
