import 'package:flutter/material.dart';
import 'package:get/get.dart'; // ✅ ใช้ GetX สำหรับนำทาง
import 'package:get_storage/get_storage.dart';
import 'package:myapp/pages/saved_teams_page.dart'; // ✅ ไปหน้ารายการทีม
import 'package:myapp/services/github_image_service.dart';

class TeamBuilderPage extends StatefulWidget {
  const TeamBuilderPage({super.key});

  @override
  State<TeamBuilderPage> createState() => _TeamBuilderPageState();
}

class _TeamBuilderPageState extends State<TeamBuilderPage> {
  final _box = GetStorage();
  final _searchCtrl = TextEditingController();
  final _teamNameCtrl = TextEditingController();

  List<Map<String, dynamic>> allTeams = [];
  List<PokemonSprite> currentSelection = [];
  String? selectedTypeFilter;

  static const int maxPick = 3;

  late Future<List<PokemonSprite>> _future;

  // ✅ รายชื่อธาตุสำหรับฟิลเตอร์
  final List<String> allTypes = const [
    'Bug', 'Dark', 'Dragon', 'Electric', 'Fairy', 'Fighting', 'Fire', 'Flying',
    'Ghost', 'Grass', 'Ground', 'Ice', 'Normal', 'Poison', 'Psychic', 'Rock',
    'Steel', 'Water'
  ];

  @override
  void initState() {
    super.initState();
    _loadAllTeams();
    _future = GitHubImageService().fetchSprites(limit: 60);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _teamNameCtrl.dispose();
    super.dispose();
  }

  void _loadAllTeams() {
    final List savedTeams = _box.read('allTeams') ?? [];
    setState(() {
      allTeams = savedTeams.cast<Map<String, dynamic>>();
    });
  }

  void _saveNewTeam() {
    if (currentSelection.length == maxPick) {
      final newTeamData = {
        'teamName': _teamNameCtrl.text.isEmpty ? 'ทีมใหม่' : _teamNameCtrl.text,
        'members': currentSelection.map((e) => e.toJson()).toList(),
      };
      allTeams.add(newTeamData);
      _box.write('allTeams', allTeams);

      _resetSelection();
      _teamNameCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ทีมใหม่ถูกสร้างและบันทึกเรียบร้อยแล้ว!')),
      );
    }
  }

  void _selectTeam(Map<String, dynamic> team) {
    setState(() {
      _teamNameCtrl.text = team['teamName'];
      currentSelection =
          (team['members'] as List).map((m) => PokemonSprite.fromJson(m)).toList();
      _searchCtrl.clear();
      selectedTypeFilter = null;
    });
  }

  void _deleteTeam(int index) {
    setState(() {
      allTeams.removeAt(index);
      _box.write('allTeams', allTeams);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ทีมถูกลบเรียบร้อยแล้ว!')),
    );
  }

  void _editTeamName(int index, String currentName) {
    final editCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('แก้ไขชื่อทีม'),
        content: TextField(
          controller: editCtrl,
          decoration: const InputDecoration(hintText: 'ชื่อทีมใหม่'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () {
              if (editCtrl.text.trim().isNotEmpty) {
                setState(() {
                  allTeams[index]['teamName'] = editCtrl.text.trim();
                  _box.write('allTeams', allTeams);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('แก้ไขชื่อทีมเรียบร้อยแล้ว!')),
                );
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _resetSelection() {
    setState(() {
      currentSelection.clear();
      _searchCtrl.clear();
      selectedTypeFilter = null;
    });
  }

  void _togglePokemon(PokemonSprite pokemon) {
    setState(() {
      if (currentSelection.contains(pokemon)) {
        currentSelection.remove(pokemon);
      } else {
        if (currentSelection.length < maxPick) {
          currentSelection.add(pokemon);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เลือกได้สูงสุด 3 ตัว')),
          );
        }
      }
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ✅ Utilities: เดาธาตุจาก id ใน URL ถ้า service ไม่ให้มา + สีธาตุ
  // ────────────────────────────────────────────────────────────────────────────
  List<String> _typesOf(PokemonSprite p) {
    if (p.types.isNotEmpty) return p.types;

    // เดา id จาก URL เช่น .../pokemon/25.png
    final reg = RegExp(r'/pokemon/(\d+)\.png$');
    final m = reg.firstMatch(p.imageUrl);
    final id = m != null ? int.tryParse(m.group(1)!) ?? 1 : 1;

    // เดาธาตุแบบง่าย ๆ ให้พอใช้งานฟิลเตอร์/แสดงผล
    // หมุนวนตาม id
    final palette = [
      'grass','fire','water','electric','rock','ground','psychic','ghost',
      'ice','dragon','dark','fairy','steel','poison','bug','normal','fighting','flying'
    ];
    final t1 = palette[id % palette.length];
    // บางตัวมี 2 ธาตุ (สุ่มแบบ deterministic)
    final t2 = (id % 5 == 0) ? palette[(id + 7) % palette.length] : null;
    return [t1, if (t2 != null && t2 != t1) t2];
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire': return Colors.red;
      case 'water': return Colors.blue;
      case 'grass': return Colors.green;
      case 'electric': return Colors.amber.shade700;
      case 'psychic': return Colors.indigo.shade400;
      case 'ice': return Colors.lightBlue;
      case 'dragon': return Colors.indigo;
      case 'dark': return Colors.grey.shade800;
      case 'fairy': return Colors.pinkAccent.shade100;
      case 'fighting': return Colors.brown;
      case 'poison': return Colors.purple;
      case 'ground': return Colors.orange.shade300;
      case 'flying': return Colors.indigo.shade300;
      case 'bug': return Colors.lightGreen;
      case 'rock': return Colors.brown.shade400;
      case 'ghost': return Colors.deepPurple.shade400;
      case 'steel': return Colors.blueGrey;
      case 'normal': return Colors.grey;
      default: return Colors.grey.shade400;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Widgets
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildSelectedPokemonCard(PokemonSprite pokemon) {
    return Container(
      width: 90,
      height: 90,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(pokemon.imageUrl, width: 70, height: 70),
          Positioned(
            bottom: 0,
            child: Text(
              pokemon.displayName,
              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: () => _togglePokemon(pokemon),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade400,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPokemonCard(PokemonSprite pokemon) {
    final isSelected = currentSelection.contains(pokemon);
    final cp = (pokemon.displayName.hashCode.abs() % 1500) + 100;
    final types = _typesOf(pokemon);

    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        child: InkWell(
          onTap: () => _togglePokemon(pokemon),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.network(
                          pokemon.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.catching_pokemon,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      // ✅ Badge ธาตุหลัก
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor(types.first).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            types.first.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // ✅ มุมขวาล่าง: สถานะเลือก
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: AnimatedOpacity(
                          opacity: isSelected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.blue : Colors.grey.shade300,
                            ),
                            child: Icon(
                              isSelected ? Icons.check : Icons.add,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        pokemon.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'CP $cp',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // ✅ โชว์ธาตุ (1–2 ธาตุ)
                      Wrap(
                        spacing: 4,
                        alignment: WrapAlignment.center,
                        children: types.take(2).map((t) {
                          final c = _typeColor(t);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: c, width: 0.7),
                            ),
                            child: Text(
                              t.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: c,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // UI
  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ ปุ่มไปหน้ารายการทีมด้วย GetX
      appBar: AppBar(
        title: const Text('Team Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'ทีมที่บันทึกไว้',
            onPressed: () => Get.to(() => const SavedTeamsPage()),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE3F2FD),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟢 การ์ดทีมปัจจุบัน
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ทีมของคุณ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: _resetSelection,
                            icon: const Icon(Icons.refresh, size: 22),
                            label: const Text('ล้างการเลือก', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _teamNameCtrl,
                        decoration: InputDecoration(
                          hintText: 'ตั้งชื่อทีม...',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(maxPick, (i) {
                            if (i < currentSelection.length) {
                              return _buildSelectedPokemonCard(currentSelection[i]);
                            } else {
                              return Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Icon(Icons.add, size: 40, color: Colors.blue.shade300),
                              );
                            }
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: currentSelection.length == maxPick ? _saveNewTeam : null,
                          child: Text('บันทึกทีม (${currentSelection.length}/$maxPick)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🟢 ทีมที่บันทึกแล้ว (สรุป)
              if (allTeams.isNotEmpty)
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allTeams.length,
                    itemBuilder: (_, index) {
                      final team = allTeams[index];
                      return Card(
                        margin: const EdgeInsets.only(right: 10),
                        child: Container(
                          width: 160,
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      team['teamName'],
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editTeamName(index, team['teamName']);
                                      } else if (value == 'delete') {
                                        _deleteTeam(index);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'edit', child: Text('แก้ไขชื่อทีม')),
                                      PopupMenuItem(value: 'delete', child: Text('ลบทีม')),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: (team['members'] as List)
                                    .map((m) => Image.network(m['imageUrl'], width: 28, height: 28))
                                    .toList()
                                    .cast<Widget>(),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),

              // 🟢 ส่วนเลือกโปเกมอน + ฟิลเตอร์ธาตุ + ค้นหา
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('เลือกโปเกมอน', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'ค้นหาโปเกมอน...',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ✅ ชิพฟิลเตอร์ธาตุ
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ActionChip(
                              label: Text(selectedTypeFilter == null ? 'ทั้งหมด ✓' : 'ทั้งหมด'),
                              onPressed: () => setState(() => selectedTypeFilter = null),
                            ),
                            const SizedBox(width: 8),
                            ...allTypes.map((t) {
                              final selected = selectedTypeFilter == t;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  label: Text(t),
                                  backgroundColor: selected ? Colors.blue.shade100 : null,
                                  onPressed: () => setState(() {
                                    selectedTypeFilter = selected ? null : t;
                                  }),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<PokemonSprite>>(
                        future: _future,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(),
                            ));
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('โหลดรายชื่อไม่สำเร็จ: ${snapshot.error}'));
                          }
                          final list = snapshot.data!;
                          final q = _searchCtrl.text.trim().toLowerCase();

                          final filtered = list.where((p) {
                            final nameMatch = q.isEmpty || p.displayName.toLowerCase().contains(q);
                            if (!nameMatch) return false;

                            final types = _typesOf(p);
                            final typeMatch = selectedTypeFilter == null
                                ? true
                                : types.map((e) => e.toLowerCase())
                                       .contains(selectedTypeFilter!.toLowerCase());
                            return typeMatch;
                          }).toList();

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _buildPokemonCard(filtered[i]),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
