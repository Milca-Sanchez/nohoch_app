import '../models/app_user.dart';

class MockAuthService {
  Future<AppUser?> login(String email, String password) async {
    // Simulamos un retraso de red
    await Future.delayed(const Duration(seconds: 1));

    if (password != '123456') {
      throw Exception('Contraseña incorrecta. (Usa 123456)');
    }

    switch (email.toLowerCase().trim()) {
      case 'admin@nohoch.com':
        return AppUser(id: '1', email: email, name: 'Administrador Principal', role: UserRole.administrador);
      case 'tesorero@nohoch.com':
        return AppUser(id: '2', email: email, name: 'Tesorero General', role: UserRole.tesorero);
      case 'materiales@nohoch.com':
        return AppUser(id: '3', email: email, name: 'Gestor de Materiales', role: UserRole.materiales);
      default:
        throw Exception('Usuario no encontrado. (Prueba admin@..., tesorero@..., materiales@... con dominio nohoch.com)');
    }
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
