// lib/controllers/team_builder_controller.dart
import 'package:get/get.dart';
import 'package:myapp/models/pokemon_sprite.dart';

class TeamBuilderController extends GetxController {
  static const int maxPick = 6;
  final allPokemon = <PokemonSprite>[].obs;
  final currentSelection = <PokemonSprite>[].obs;
  final allTeams = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPokemon();
    loadTeams();
  }

  void fetchPokemon() {
    // โค้ดสำหรับดึงข้อมูลโปเกมอนทั้งหมดจาก API หรือแหล่งข้อมูล
    // ในตัวอย่างนี้ ใช้ข้อมูล mock (จำลอง)
    final mockPokemon = [
      PokemonSprite(id: 1, name: 'Bulbasaur', sprite: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png'),
      PokemonSprite(id: 4, name: 'Charmander', sprite: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/4.png'),
      PokemonSprite(id: 7, name: 'Squirtle', sprite: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/7.png'),
      PokemonSprite(id: 25, name: 'Pikachu', sprite: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png'),
      PokemonSprite(id: 143, name: 'Snorlax', sprite: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/143.png'),
      PokemonSprite(id: 6, name: 'Charizard', sprite: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/6.png'),
    ];
    allPokemon.assignAll(mockPokemon);
  }

  void loadTeams() {
    // โค้ดสำหรับโหลดทีมที่บันทึกไว้จาก Local Storage หรือ Firebase
    // ในตัวอย่างนี้ ใช้ข้อมูล mock
    final mockTeams = [
      {
        'name': 'ทีมเริ่มต้น',
        'pokemon': [
          PokemonSprite(id: 1, name: 'Bulbasaur', sprite: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png'),
          PokemonSprite(id: 4, name: 'Charmander', sprite: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/4.png'),
        ]
      },
    ];
    allTeams.assignAll(mockTeams);
  }

  void saveNewTeam() {
    if (currentSelection.length == maxPick) {
      final newTeam = {
        'name': 'ทีมใหม่ #${allTeams.length + 1}',
        'pokemon': List<PokemonSprite>.from(currentSelection),
      };
      allTeams.add(newTeam);
      clearCurrentSelection();
      // โค้ดสำหรับบันทึกข้อมูลลงฐานข้อมูล
    }
  }

  void addPokemonToTeam(PokemonSprite pokemon) {
    if (currentSelection.length < maxPick && !currentSelection.contains(pokemon)) {
      currentSelection.add(pokemon);
      update();
    }
  }

  void removePokemonFromTeam(PokemonSprite pokemon) {
    currentSelection.remove(pokemon);
    update();
  }

  void removeSavedTeam(int index) {
    allTeams.removeAt(index);
    update();
    // โค้ดสำหรับลบข้อมูลจากฐานข้อมูล
  }

  void editSavedTeamName(int index, String newName) {
    if (index >= 0 && index < allTeams.length) {
      allTeams[index]['name'] = newName;
      update();
    }
  }

  void clearCurrentSelection() {
    currentSelection.clear();
    update();
  }
}