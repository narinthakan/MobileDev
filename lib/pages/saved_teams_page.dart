import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class SavedTeamsPage extends StatefulWidget {
  const SavedTeamsPage({super.key});

  @override
  State<SavedTeamsPage> createState() => _SavedTeamsPageState();
}

class _SavedTeamsPageState extends State<SavedTeamsPage> {
  final _box = GetStorage();
  List<Map<String, dynamic>> allTeams = [];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  void _loadTeams() {
    final List saved = _box.read('allTeams') ?? [];
    setState(() {
      allTeams = saved.cast<Map<String, dynamic>>();
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

  void _editTeamName(int index) {
    final team = allTeams[index];
    final controller = TextEditingController(text: team['teamName']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('แก้ไขชื่อทีม'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'ชื่อทีมใหม่'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  allTeams[index]['teamName'] = controller.text.trim();
                  _box.write('allTeams', allTeams);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ทีมที่สร้างไว้')),
      body: allTeams.isEmpty
          ? const Center(child: Text('ยังไม่มีทีมที่บันทึก'))
          : ListView.builder(
              itemCount: allTeams.length,
              itemBuilder: (context, index) {
                final team = allTeams[index];
                final members = (team['members'] as List?) ?? [];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(team['teamName'] ?? 'ทีมไม่มีชื่อ'),
                    subtitle: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: members
                          .map((m) => Image.network(m['imageUrl'], width: 32, height: 32))
                          .toList()
                          .cast<Widget>(),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _editTeamName(index);
                        if (value == 'delete') _deleteTeam(index);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('แก้ไขชื่อทีม')),
                        PopupMenuItem(value: 'delete', child: Text('ลบทีม')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
