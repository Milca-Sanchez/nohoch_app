import '../models/app_user.dart';

abstract class AuthService {
  Future<AppUser?> login(String username, String password);
  Future<void> logout();
}