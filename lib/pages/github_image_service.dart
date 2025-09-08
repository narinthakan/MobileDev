class PokemonSprite {
  final String imageUrl;
  final String displayName;
  final List<String> types; // ✅ ธาตุ

  PokemonSprite({
    required this.imageUrl,
    required this.displayName,
    required this.types,
  });

  factory PokemonSprite.fromJson(Map<String, dynamic> json) {
    return PokemonSprite(
      imageUrl: json['imageUrl'] as String,
      displayName: json['displayName'] as String,
      types: (json['types'] as List?)?.cast<String>() ?? <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'displayName': displayName,
      'types': types,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokemonSprite && displayName == other.displayName;

  @override
  int get hashCode => displayName.hashCode;
}

class GitHubImageService {
  final String baseUrl =
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/';

  // ✅ ธาตุ mock เบื้องต้น (เติมเพิ่มได้ตามต้องการ)
  static const Map<int, List<String>> _typeById = {
    1: ['grass', 'poison'],   // Bulbasaur
    2: ['grass', 'poison'],
    3: ['grass', 'poison'],
    4: ['fire'],              // Charmander
    5: ['fire'],
    6: ['fire', 'flying'],    // Charizard
    7: ['water'],             // Squirtle
    8: ['water'],
    9: ['water'],
    25: ['electric'],         // Pikachu
    143: ['normal'],          // Snorlax
  };

  Future<List<PokemonSprite>> fetchSprites({int limit = 30}) async {
    final List<PokemonSprite> sprites = [];
    for (int i = 1; i <= limit; i++) {
      final imageUrl = '$baseUrl$i.png';
      final displayName = 'Pokémon #$i';
      final types = _typeById[i] ?? ['normal']; // ถ้าไม่รู้ให้เป็น normal
      sprites.add(PokemonSprite(
        imageUrl: imageUrl,
        displayName: displayName,
        types: types,
      ));
    }
    return sprites;
  }
}
