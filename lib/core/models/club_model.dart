class ClubModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String logoUrl;
  final int memberCount;
  final int eventCount;
  final String facultyMentor;
  final int totalRegistrations;

  const ClubModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.logoUrl,
    required this.memberCount,
    required this.eventCount,
    this.facultyMentor = '',
    this.totalRegistrations = 0,
  });

  /// Returns up to 2 initials from the club name for avatar display.
  String get initials {
    final words = name.trim().split(' ');
    if (words.length == 1) return words[0].substring(0, 2).toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}
