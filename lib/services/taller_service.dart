import 'dart:convert';
import 'package:http/http.dart' as http;

class TallerService {
  //static const String baseUrl = 'https://asistencia-vehicular-backend-3ii1.onrender.com';
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> obtenerCandidatos({
    required double latitud,
    required double longitud,
    String? tipoProblema,
  }) async {
    try {
      String url = '$baseUrl/api/talleres/candidatos?latitud=$latitud&longitud=$longitud';
      if (tipoProblema != null) {
        url += '&tipo_problema=$tipoProblema';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'talleres': data['talleres']};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }
}