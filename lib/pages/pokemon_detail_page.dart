import 'package:flutter/material.dart';
import 'package:myapp/services/github_image_service.dart';

class PokemonDetailPage extends StatelessWidget {
  final PokemonSprite pokemon;

  const PokemonDetailPage({super.key, required this.pokemon});

  // ฟังก์ชันสำหรับกำหนดสีตามประเภท
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire': return Colors.red;
      case 'water': return Colors.blue;
      case 'grass': return Colors.green;
      case 'electric': return Colors.yellow.shade700;
      case 'psychic': return Colors.indigo.shade400;
      case 'ice': return Colors.lightBlue;
      case 'dragon': return Colors.indigo;
      case 'dark': return Colors.grey.shade800;
      case 'fairy': return Colors.teal.shade300;
      case 'fighting': return Colors.brown;
      case 'poison': return Colors.purple;
      case 'ground': return Colors.orange.shade300;
      case 'flying': return Colors.indigo.shade300;
      case 'bug': return Colors.lightGreen;
      case 'rock': return Colors.brown.shade400;
      case 'ghost': return Colors.indigo.shade400;
      case 'steel': return Colors.grey;
      default: return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = (pokemon.displayName.hashCode.abs() % 1500) + 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(pokemon.displayName),
        backgroundColor: Colors.blue.shade300,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    pokemon.imageUrl,
                    height: 150,
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    pokemon.displayName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'CP: $cp',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: pokemon.types.map((type) {
                      return Chip(
                        label: Text(
                          type.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: _getTypeColor(type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      // สามารถเพิ่มฟังก์ชันเลือกโปเกมอนจากหน้ารายละเอียดได้ที่นี่
                      // Navigator.of(context).pop(pokemon);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('กลับสู่หน้าเลือกโปเกมอน'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}