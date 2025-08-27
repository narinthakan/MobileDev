class PokemonSprite {
  final String name;
  final String imageUrl;
  final String displayName;

  PokemonSprite({
    required this.name,
    required this.imageUrl,
    required this.displayName,
  });

  factory PokemonSprite.fromJson(Map<String, dynamic> json) {
    return PokemonSprite(
      name: json['name'],
      imageUrl: json['imageUrl'],
      displayName: json['displayName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'displayName': displayName,
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
