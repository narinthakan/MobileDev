import 'package:get/get.dart';
import 'package:myapp/services/github_image_service.dart';

class PlayerSelectionController extends GetxController {
  var allPokemon = <PokemonSprite>[].obs;
  var filteredPokemon = <PokemonSprite>[].obs;
  var isLoading = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchPokemon();
  }

  void fetchPokemon() async {
    try {
      isLoading.value = true;
      final pokemonList = await GitHubImageService().fetchSprites(limit: 30);
      allPokemon.value = pokemonList;
      filteredPokemon.value = pokemonList;
    } finally {
      isLoading.value = false;
    }
  }

  void filterPokemon(String query) {
    if (query.isEmpty) {
      filteredPokemon.value = allPokemon;
    } else {
      filteredPokemon.value = allPokemon
          .where((pokemon) =>
              pokemon.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}