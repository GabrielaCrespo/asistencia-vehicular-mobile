import 'dart:convert';
import 'package:http/http.dart' as http;

class VehiculoService {
  static const String baseUrl = 'https://asistencia-vehicular-backend-3ii1.onrender.com';
  //static const String baseUrl = 'http://127.0.0.1:8000';

  // LISTAR VEHICULOS
  static Future<Map<String, dynamic>> listar(int usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/vehiculo/listar/$usuarioId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'vehiculos': data['vehiculos']};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Error al listar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // REGISTRAR VEHICULO
  static Future<Map<String, dynamic>> registrar({
    required int usuarioId,
    required String placa,
    required String marca,
    required String modelo,
    required int anio,
    required String color,
    String tipo = "auto",
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/vehiculo/registrar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario_id': usuarioId,
          'placa': placa,
          'marca': marca,
          'modelo': modelo,
          'anio': anio,
          'color': color,
          'tipo': tipo,
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

  // ELIMINAR VEHICULO
  static Future<Map<String, dynamic>> eliminar(int vehiculoId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/vehiculo/eliminar/$vehiculoId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Error al eliminar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }
}