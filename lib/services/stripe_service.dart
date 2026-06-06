import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'session_service.dart';

class StripeService {
  static const String _baseUrl =
      'https://asistencia-vehicular-backend.onrender.com';

  static Future<void> initStripe() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/stripe/config'));
    if (response.statusCode != 200) {
      throw Exception('No se pudo obtener la configuración de Stripe');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    Stripe.publishableKey = data['publishable_key'] as String;
    await Stripe.instance.applySettings();
  }

  /// Retorna info del pago de un incidente, o null si no existe.
  static Future<Map<String, dynamic>?> getPagoIncidente(int incidenteId) async {
    final sesion = await SessionService.getSesion();
    final token = sesion['token'] as String? ?? '';

    final response = await http.get(
      Uri.parse('$_baseUrl/api/stripe/pago-incidente/$incidenteId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) return null;
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Paga el servicio mediante Stripe (Payment Sheet nativa).
  static Future<void> pagarConStripe(int pagoId) async {
    final sesion = await SessionService.getSesion();
    final token = sesion['token'] as String? ?? '';

    final response = await http.post(
      Uri.parse('$_baseUrl/api/stripe/payment-intent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'pago_id': pagoId}),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Error al crear el pago');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final clientSecret = data['client_secret'] as String;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Asistencia Vehicular',
        style: ThemeMode.light,
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }

  /// Confirma un pago presencial (efectivo, QR, transferencia) desde el cliente.
  static Future<void> confirmarPagoEfectivo(int pagoId, String metodoPago) async {
    final sesion = await SessionService.getSesion();
    final token = sesion['token'] as String? ?? '';

    final response = await http.post(
      Uri.parse('$_baseUrl/api/stripe/confirmar-pago-efectivo'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'pago_id': pagoId, 'metodo_pago': metodoPago}),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Error al confirmar el pago');
    }
  }
}
