import 'package:flutter/material.dart';
import 'package:myapp/services/github_image_service.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';

class PlayerSelectionPage extends StatefulWidget {
  const PlayerSelectionPage({super.key});

  @override
  State<PlayerSelectionPage> createState() => _PlayerSelectionPageState();
}

class _PlayerSelectionPageState extends State<PlayerSelectionPage> {
  final _svc = GitHubImageService();
  final _searchCtrl = TextEditingController();
  final _teamNameCtrl = TextEditingController();
  final _box = GetStorage();

  List<PokemonSprite> selected = [];
  static const int maxPick = 3;

  late Future<List<PokemonSprite>> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.fetchSprites(limit: 30);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _teamNameCtrl.dispose();
    super.dispose();
  }

  // Save the new team
  void _saveNewTeam() {
    final List allTeamsJson = _box.read('allTeams') ?? [];

    final newTeamData = {
      'teamName': _teamNameCtrl.text.isEmpty ? 'My Team' : _teamNameCtrl.text,
      'members': selected.map((e) => e.toJson()).toList(),
    };

    allTeamsJson.add(newTeamData);
    _box.write('allTeams', allTeamsJson); // Save teams in GetStorage
    print('✅ New team saved successfully! Total teams: ${allTeamsJson.length}');
  }

  void _toggle(PokemonSprite item) {
    setState(() {
      if (selected.contains(item)) {
        selected.remove(item);
      } else {
        if (selected.length < maxPick) {
          selected.add(item);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เลือกได้สูงสุด 3 คน'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  void _reset() {
    setState(() {
      selected.clear();
      _searchCtrl.clear();
      _teamNameCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างทีมใหม่'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFEEF5), Color(0xFFFBE4FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Select Players',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: selected.isEmpty ? null : _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
                // Input for Team Name
                // Input for search box
                // Display selected Pokémon list as chips
                Expanded(
                  child: FutureBuilder<List<PokemonSprite>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('โหลดรายชื่อไม่สำเร็จ: ${snapshot.error}'),
                        );
                      }
                      final list = snapshot.data!;
                      final q = _searchCtrl.text.trim().toLowerCase();
                      final filtered = q.isEmpty
                          ? list
                          : list
                              .where((e) =>
                                  e.displayName.toLowerCase().contains(q))
                              .toList();

                      return ListView.separated(
                        padding: const EdgeInsets.only(top: 6, bottom: 90),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final item = filtered[idx];
                          final isSelected = selected.contains(item);

                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: isSelected ? 1.0 : 0.55,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _toggle(item),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                          isSelected ? 0.10 : 0.06),
                                      blurRadius: isSelected ? 14 : 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.green.shade400,
                                          width: 2)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(item.imageUrl),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.displayName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      transitionBuilder: (c, a) =>
                                          ScaleTransition(scale: a, child: c),
                                      child: isSelected
                                          ? const Icon(Icons.check,
                                              key: ValueKey('check'),
                                              color: Colors.green)
                                          : const SizedBox(
                                              key: ValueKey('blank'),
                                              width: 24),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: selected.length == maxPick
                      ? () {
                          _saveNewTeam();
                          Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    'สร้างทีม (${selected.length}/$maxPick)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
