import 'dart:math';

class AliasGenerator {
  static const List<String> _characters = [
    // Fictional & Anime
    'Kraken',
    'Goku',
    'Vegeta',
    'Naruto',
    'Sasuke',
    'Itachi',
    'Luffy',
    'Zoro',
    'Levi',
    'Eren',
    'Saitama',
    'Gojo',
    'Sukuna',
    'Ichigo',
    'Light',
    'L',
    'Midoriya',
    // Marvel & DC
    'Batman',
    'Superman',
    'Flash',
    'Spiderman',
    'Ironman',
    'Thor',
    'Hulk',
    'Deadpool',
    'Wolverine',
    'Venom',
    'Joker',
    'Magneto',
    'Daredevil',
  ];

  /// Generates a random character name and appends a random 4-digit number.
  /// Example: Goku4012, Ironman9824
  static String generate() {
    final random = Random();
    final char = _characters[random.nextInt(_characters.length)];
    final num = random.nextInt(9000) + 1000; // 1000 to 9999
    return '$char$num';
  }
}
