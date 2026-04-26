import 'dart:convert';
import 'package:http/http.dart' as http;

class EmergenciaService {
  //static const String baseUrl = 'https://asistencia-vehicular-backend-3ii1.onrender.com';
  static const String baseUrl = 'http://127.0.0.1:8000';

  // REGISTRAR EMERGENCIA
  static Future<Map<String, dynamic>> registrar({
    required int usuarioId,
    required int vehiculoId,
    required String descripcion,
    required double latitud,
    required double longitud,
    String? tipoProblema,
     String? imagenPath, 
      String? audioPath,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/emergencia/registrar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario_id': usuarioId,
          'vehiculo_id': vehiculoId,
          'descripcion': descripcion,
          'latitud': latitud,
          'longitud': longitud,
          'tipo_problema': tipoProblema,
          'imagen_path': imagenPath, 
          'audio_path': audioPath,          
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

  // LISTAR EMERGENCIAS
  static Future<Map<String, dynamic>> listar(int usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/emergencia/listar/$usuarioId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'emergencias': data['emergencias']};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Error al listar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }
  // OBTENER DETALLE
static Future<Map<String, dynamic>> obtenerDetalle(int incidenteId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/emergencia/detalle/$incidenteId'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'incidente': data['incidente']};
    } else {
      return {'success': false, 'message': data['detail'] ?? 'Error'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Error de conexión'};
  }
}
}