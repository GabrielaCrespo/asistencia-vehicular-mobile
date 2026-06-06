import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'session_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? fcmToken;

  static Future<void> initialize() async {
    // Pedir permisos
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('[FCM] Permisos concedidos');

      // Obtener token
      fcmToken = await _messaging.getToken();
      print('[FCM] Token: $fcmToken');

      // Escuchar cuando el token se refresca
      _messaging.onTokenRefresh.listen((newToken) {
        fcmToken = newToken;
        _registrarTokenEnBackend(newToken);
      });

      // Notificaciones cuando la app está en PRIMER PLANO
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('[FCM] Notificación en primer plano: ${message.notification?.title}');
        _mostrarNotificacionLocal(message);
      });

      // Cuando el usuario toca la notificación y la app estaba en background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('[FCM] App abierta desde notificación: ${message.notification?.title}');
      });
    }
  }

  // Registrar el token FCM en el backend después del login
  static Future<void> registrarToken() async {
    if (fcmToken == null) return;
    await _registrarTokenEnBackend(fcmToken!);
  }

  static Future<void> _registrarTokenEnBackend(String token) async {
    try {
      final sesion = await SessionService.getSesion();
      final authToken = sesion['token'];
      if (authToken == null) return;

      final response = await http.post(
        Uri.parse('https://asistencia-vehicular-backend.onrender.com/api/notificaciones/registrar-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (response.statusCode == 200) {
        print('[FCM] Token registrado en backend correctamente');
      } else {
        print('[FCM] Error registrando token: ${response.body}');
      }
    } catch (e) {
      print('[FCM] Error: $e');
    }
  }

  // Mostrar notificación local cuando la app está en primer plano
  static void _mostrarNotificacionLocal(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Usamos un GlobalKey para mostrar el SnackBar desde cualquier parte
    final titulo = notification.title ?? 'Asistencia Vehicular';
    final cuerpo = notification.body ?? '';

    print('[FCM] 🔔 $titulo: $cuerpo');
  }

  // Limpiar token al cerrar sesión
  static Future<void> limpiarToken() async {
    try {
      final sesion = await SessionService.getSesion();
      final authToken = sesion['token'];
      if (authToken == null) return;

      await http.delete(
        Uri.parse('https://asistencia-vehicular-backend.onrender.com/api/notificaciones/eliminar-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );
    } catch (e) {
      print('[FCM] Error limpiando token: $e');
    }
    fcmToken = null;
  }
}