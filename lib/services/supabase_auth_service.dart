import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import 'auth_service.dart';

class SupabaseAuthService implements AuthService {
  final _supabase = Supabase.instance.client;

  @override
  Future<AppUser?> login(String username, String password) async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();
      if (response == null) throw Exception('Usuario o contraseña incorrectos');
      final role = _stringToRole(response['rol'] as String);
      if (role == UserRole.ninguno) throw Exception('Rol inválido');
      return AppUser(
        id: response['id'] as String,
        email: response['username'] as String,
        name: response['nombre'] as String,
        role: role,
      );
    } catch (e) {
      throw Exception('Error de autenticación');
    }
  }

  UserRole _stringToRole(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador': return UserRole.administrador;
      case 'tesorero': return UserRole.tesorero;
      case 'materiales': return UserRole.materiales;
      default: return UserRole.ninguno;
    }
  }

  @override
  Future<void> logout() async {}
}