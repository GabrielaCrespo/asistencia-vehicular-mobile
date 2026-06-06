import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_service.dart';

class CalificacionService {
  static const String baseUrl =
      'https://asistencia-vehicular-backend.onrender.com';

  /// Registra una nueva calificación para un incidente finalizado.
  static Future<Map<String, dynamic>> registrar({
    required int incidenteId,
    required int puntuacion,
    int? puntuacionServicio,
    String? comentario,
  }) async {
    try {
      final sesion = await SessionService.getSesion();
      final token = sesion['token'] ?? '';

      final body = <String, dynamic>{
        'incidente_id': incidenteId,
        'puntuacion': puntuacion,
      };
      if (puntuacionServicio != null) {
        body['puntuacion_servicio'] = puntuacionServicio;
      }
      if (comentario != null && comentario.isNotEmpty) {
        body['comentario'] = comentario;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/calificacion'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Error al registrar calificación',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  /// Consulta si un incidente ya tiene calificación registrada.
  static Future<Map<String, dynamic>> getCalificacion(int incidenteId) async {
    try {
      final sesion = await SessionService.getSesion();
      final token = sesion['token'] ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/api/calificacion/incidente/$incidenteId'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'exists': data['exists'] ?? false,
          'calificacion': data['calificacion'],
        };
      } else {
        return {'success': false, 'exists': false, 'calificacion': null};
      }
    } catch (e) {
      return {'success': false, 'exists': false, 'calificacion': null};
    }
  }
}
