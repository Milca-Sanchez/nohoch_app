import '../models/app_user.dart';
import 'auth_service.dart';

class MockAuthService implements AuthService {
  @override
  Future<AppUser?> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    // Credenciales de prueba para desarrollo local
    if (username == 'admin' && password == 'contra1234') {
      return AppUser(
        id: '1',
        email: username,
        name: 'Administrador Principal',
        role: UserRole.administrador,
      );
    } else if (username == 'tesorero' && password == 'contra1234') {
      return AppUser(
        id: '2',
        email: username,
        name: 'Tesorero General',
        role: UserRole.tesorero,
      );
    } else if (username == 'materiales' && password == 'contra1234') {
      return AppUser(
        id: '3',
        email: username,
        name: 'Gestor de Materiales',
        role: UserRole.materiales,
      );
    }
    throw Exception('Usuario o contraseña incorrectos');
  }

  @override
  Future<void> logout() async {}
}