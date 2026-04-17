import 'package:shared_preferences/shared_preferences.dart';

class SessionService {

  // Guardar sesión después del login
  static Future<void> guardarSesion({
    required int usuarioId,
    required String nombre,
    required String email,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('usuario_id', usuarioId);
    await prefs.setString('nombre', nombre);
    await prefs.setString('email', email);
    await prefs.setString('token', token);
  }

  // Obtener datos de la sesión
  static Future<Map<String, dynamic>> getSesion() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'usuario_id': prefs.getInt('usuario_id'),
      'nombre': prefs.getString('nombre'),
      'email': prefs.getString('email'),
      'token': prefs.getString('token'),
    };
  }

  // Verificar si hay sesión activa
  static Future<bool> haySesion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  // Cerrar sesión
  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}