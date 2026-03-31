class UserModel {
  final String id;
  final String email;
  final String name;
  final String aliasName;
  final String role;
  final String? avatarUrl;
  final List<String> registeredEventIds;
  final String? branch;
  final String? year;
  final String? bio;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.aliasName,
    required this.role,
    this.avatarUrl,
    this.registeredEventIds = const [],
    this.branch,
    this.year,
    this.bio,
  });

  UserModel copyWith({
    String? name,
    String? aliasName,
    String? avatarUrl,
    List<String>? registeredEventIds,
    String? branch,
    String? year,
    String? bio,
  }) =>
      UserModel(
        id: id,
        email: email,
        name: name ?? this.name,
        aliasName: aliasName ?? this.aliasName,
        role: role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        registeredEventIds: registeredEventIds ?? this.registeredEventIds,
        branch: branch ?? this.branch,
        year: year ?? this.year,
        bio: bio ?? this.bio,
      );
}
