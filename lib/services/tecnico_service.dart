import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_service.dart';

class TecnicoService {
  //static const String baseUrl = 'https://asistencia-vehicular-backend-3ii1.onrender.com';
  static const String baseUrl = 'http://127.0.0.1:8000';

  // LOGIN TÉCNICO
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/tecnico/login'),
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

  // OBTENER ASIGNACIÓN ACTIVA
  static Future<Map<String, dynamic>> getAsignacion(int tecnicoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tecnico/asignacion/$tecnicoId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'asignacion': data['asignacion']};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // ACTUALIZAR ESTADO DEL SERVICIO
  static Future<Map<String, dynamic>> actualizarEstado({
  required int asignacionId,
  required String estado,
}) async {
  try {
    final sesion = await SessionService.getSesion();
    final token = sesion['token'] ?? '';

    final response = await http.put(
      Uri.parse('$baseUrl/api/tecnico/asignacion/$asignacionId/estado'),
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode({'estado': estado}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'message': data['message']};
    } else {
      return {'success': false, 'message': data['detail'] ?? 'Error'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Error de conexión'};
  }
}

  // REGISTRAR PAGO Y FINALIZAR
  static Future<Map<String, dynamic>> registrarPago({
  required int asignacionId,
  required int tallerId,
  required double monto,
  required String observaciones,
  String? metodoPago,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/api/tecnico/asignacion/$asignacionId/finalizar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'observaciones': observaciones,
        'costo': monto,
        'metodo_pago': metodoPago ?? 'efectivo',
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'message': data['message']};
    } else {
      return {'success': false, 'message': data['detail'] ?? 'Error'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Error de conexión'};
  }
}
}