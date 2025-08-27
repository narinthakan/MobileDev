import 'dart:convert';
import 'package:http/http.dart' as http;

class PokemonSprite {
  final String name;
  final String imageUrl;
  final String displayName;
  final List<String> types;

  PokemonSprite({
    required this.name,
    required this.imageUrl,
    required this.displayName,
    required this.types,
  });

  factory PokemonSprite.fromJson(Map<String, dynamic> json) {
    return PokemonSprite(
      name: json['name'],
      imageUrl: json['imageUrl'],
      displayName: json['displayName'],
      types: (json['types'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'displayName': displayName,
      'types': types,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokemonSprite &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class GitHubImageService {
  static const _api = 'https://api.github.com/repos/HybridShivam/Pokemon/contents/assets/images';
  static const _pokeApi = 'https://pokeapi.co/api/v2/pokemon/';

  Future<List<PokemonSprite>> fetchSprites({int limit = 30}) async {
    final res = await http.get(Uri.parse(_api));
    if (res.statusCode != 200) {
      throw Exception('GitHub API error ${res.statusCode}');
    }

    final List data = jsonDecode(res.body);
    final files = data
        .where((e) =>
            e is Map &&
            e['type'] == 'file' &&
            (e['name'] as String).toLowerCase().endsWith('.png'))
        .take(limit);

    List<PokemonSprite> pokemonList = [];

    for (var e in files) {
      final fileName = (e['name'] as String);
      final number = int.tryParse(fileName.split('.').first) ?? 0;
      final url = e['download_url'] as String;

      final pokeRes = await http.get(Uri.parse('$_pokeApi$number'));
      if (pokeRes.statusCode == 200) {
        final pokemonData = jsonDecode(pokeRes.body);
        final displayName = pokemonData['name'];
        final types = (pokemonData['types'] as List)
            .map((t) => t['type']['name'] as String)
            .toList();

        pokemonList.add(PokemonSprite(
          name: fileName,
          imageUrl: url,
          displayName: displayName,
          types: types,
        ));
      }
    }
    return pokemonList;
  }
}