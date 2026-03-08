class UserModel {
  final String id;
  final String email;
  final String aliasName;
  final String role;
  final String? avatarUrl;
  final List<String> registeredEventIds;

  const UserModel({
    required this.id,
    required this.email,
    required this.aliasName,
    required this.role,
    this.avatarUrl,
    this.registeredEventIds = const [],
  });

  UserModel copyWith({
    String? aliasName,
    String? avatarUrl,
    List<String>? registeredEventIds,
  }) =>
      UserModel(
        id: id,
        email: email,
        aliasName: aliasName ?? this.aliasName,
        role: role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        registeredEventIds: registeredEventIds ?? this.registeredEventIds,
      );
}
