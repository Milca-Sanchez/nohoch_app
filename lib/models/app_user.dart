enum UserRole {
  administrador,
  tesorero,
  materiales,
  ninguno
}

class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });
}
