import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cliente_model.dart';

class ClienteService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  // REGISTRO
  static Future<Map<String, dynamic>> registrar({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
    required String documentoIdentidad,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cliente/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'telefono': telefono,
          'password': password,
          'documento_identidad': documentoIdentidad,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Error al registrar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cliente/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Credenciales inválidas'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // OBTENER PERFIL
  static Future<Map<String, dynamic>> getPerfil(int usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/cliente/profile/$usuarioId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': ClienteModel.fromJson(data['user'])};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Error al obtener perfil'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // ACTUALIZAR PERFIL
  static Future<Map<String, dynamic>> updatePerfil({
    required int usuarioId,
    required String nombre,
    required String telefono,
    required String documentoIdentidad,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/cliente/profile/$usuarioId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'telefono': telefono,
          'documento_identidad': documentoIdentidad,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Perfil actualizado'};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Error al actualizar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }
}