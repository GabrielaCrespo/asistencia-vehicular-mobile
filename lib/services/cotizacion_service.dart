import 'dart:convert';
import 'package:http/http.dart' as http;

class CotizacionService {
  static const String baseUrl =
      'https://asistencia-vehicular-backend.onrender.com';

  /// Lista cotizaciones de un incidente (vista comparativa del cliente).
  static Future<Map<String, dynamic>> listarPorIncidente(
      int incidenteId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/cotizacion/incidente/$incidenteId'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'cotizaciones': data};
      }
      return {
        'success': false,
        'message': data['detail'] ?? 'Error al obtener cotizaciones'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  /// El cliente selecciona una cotización.
  static Future<Map<String, dynamic>> seleccionar({
    required int cotizacionId,
    required int usuarioId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cotizacion/seleccionar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cotizacion_id': cotizacionId,
          'usuario_id': usuarioId,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'asignacion_id': data['asignacion_id'],
        };
      }
      return {
        'success': false,
        'message': data['detail'] ?? 'Error al seleccionar cotización'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }
}
