import 'dart:convert';

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
      types: (json['types'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
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
      other is PokemonSprite && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}