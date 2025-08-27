import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
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
  List<String> allTypes = ['Bug', 'Fire', 'Flying', 'Grass', 'Normal', 'Poison', 'Water'];

  @override
  void initState() {
    super.initState();
    _loadAllTeams();
    _future = GitHubImageService().fetchSprites(limit: 30);
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
      currentSelection = (team['members'] as List).map((m) => PokemonSprite.fromJson(m)).toList();
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
    TextEditingController editCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('แก้ไขชื่อทีม'),
          content: TextField(
            controller: editCtrl,
            decoration: const InputDecoration(hintText: 'ชื่อทีมใหม่'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('บันทึก'),
              onPressed: () {
                if (editCtrl.text.isNotEmpty) {
                  setState(() {
                    allTeams[index]['teamName'] = editCtrl.text;
                    _box.write('allTeams', allTeams);
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('แก้ไขชื่อทีมเรียบร้อยแล้ว!')),
                  );
                }
              },
            ),
          ],
        );
      },
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

  Widget _buildPokemonCard(PokemonSprite pokemon) {
    final isSelected = currentSelection.contains(pokemon);
    final cp = (pokemon.displayName.hashCode.abs() % 1500) + 100;
    
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
          child: Container(
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
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.catching_pokemon,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _getTypeColor(pokemon.types.isNotEmpty ? pokemon.types.first : 'normal'),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                      Wrap(
                        spacing: 2,
                        alignment: WrapAlignment.center,
                        children: pokemon.types.take(2).map((type) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: _getTypeColor(type).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _getTypeColor(type),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getTypeColor(type),
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

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Colors.red;
      case 'water':
        return Colors.blue;
      case 'grass':
        return Colors.green;
      case 'electric':
        return Colors.yellow.shade700;
      case 'psychic':
        return Colors.indigo.shade400;
      case 'ice':
        return Colors.lightBlue;
      case 'dragon':
        return Colors.indigo;
      case 'dark':
        return Colors.grey.shade800;
      case 'fairy':
        return Colors.teal.shade300;
      case 'fighting':
        return Colors.brown;
      case 'poison':
        return Colors.purple;
      case 'ground':
        return Colors.orange.shade300;
      case 'flying':
        return Colors.indigo.shade300;
      case 'bug':
        return Colors.lightGreen;
      case 'rock':
        return Colors.brown.shade400;
      case 'ghost':
        return Colors.indigo.shade400;
      case 'steel':
        return Colors.grey;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          const Text(
                            'ทีมของคุณ',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: _resetSelection,
                            icon: const Icon(Icons.refresh, size: 22),
                            label: const Text('ล้างการเลือก', style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade100,
                              foregroundColor: Colors.blue.shade800,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _teamNameCtrl,
                        decoration: InputDecoration(
                          hintText: 'ตั้งชื่อทีม...',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(maxPick, (index) {
                            if (index < currentSelection.length) {
                              final pokemon = currentSelection[index];
                              return _buildSelectedPokemonCard(pokemon);
                            } else {
                              return Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade200, style: BorderStyle.solid),
                                ),
                                child: Icon(Icons.add, size: 40, color: Colors.blue.shade300),
                              );
                            }
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: currentSelection.length == maxPick ? _saveNewTeam : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentSelection.length == maxPick ? Colors.green : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('บันทึกทีม (${currentSelection.length}/$maxPick)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (allTeams.isNotEmpty) ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ทีมที่บันทึกแล้ว', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: allTeams.length,
                            itemBuilder: (context, index) {
                              final team = allTeams[index];
                              return InkWell(
                                onTap: () => _selectTeam(team),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  color: Colors.white,
                                  child: Container(
                                    width: 120,
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(team['teamName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                                            ),
                                            PopupMenuButton<String>(
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _editTeamName(index, team['teamName']);
                                                } else if (value == 'delete') {
                                                  _deleteTeam(index);
                                                }
                                              },
                                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                                const PopupMenuItem<String>(
                                                  value: 'edit',
                                                  child: Text('แก้ไขชื่อทีม'),
                                                ),
                                                const PopupMenuItem<String>(
                                                  value: 'delete',
                                                  child: Text('ลบทีม'),
                                                ),
                                              ],
                                              icon: const Icon(Icons.more_vert, size: 20),
                                              offset: const Offset(0, 30),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 4,
                                          children: (team['members'] as List).map((m) => Image.network(m['imageUrl'], width: 28, height: 28)).toList(),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('เลือกโปเกมอน', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (value) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'ค้นหาโปเกมอน...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: allTypes.map((type) {
                          final isSelected = selectedTypeFilter == type;
                          return ActionChip(
                            label: Text(type, style: const TextStyle(fontSize: 14)),
                            backgroundColor: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
                            onPressed: () {
                              setState(() {
                                selectedTypeFilter = isSelected ? null : type;
                              });
                            },
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<PokemonSprite>>(
                        future: _future,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('โหลดรายชื่อไม่สำเร็จ: ${snapshot.error}'));
                          }
                          final list = snapshot.data!;
                          final q = _searchCtrl.text.trim().toLowerCase();
                          
                          final filtered = list.where((pokemon) {
                            final matchesSearch = q.isEmpty || pokemon.displayName.toLowerCase().contains(q);
                            final matchesType = selectedTypeFilter == null || pokemon.types.contains(selectedTypeFilter!.toLowerCase());
                            return matchesSearch && matchesType;
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
                            itemBuilder: (context, index) {
                              final pokemon = filtered[index];
                              return _buildPokemonCard(pokemon);
                            },
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