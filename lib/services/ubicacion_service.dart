import 'package:geolocator/geolocator.dart';

class UbicacionService {

  // Verificar y solicitar permisos
  static Future<bool> verificarPermisos() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      return false;
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        return false;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Obtener ubicación actual
  static Future<Map<String, dynamic>> obtenerUbicacion() async {
    try {
      bool tienePermiso = await verificarPermisos();

      if (!tienePermiso) {
        return {
          'success': false,
          'message': 'No se tienen permisos de ubicación'
        };
      }

      Position posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return {
        'success': true,
        'latitud': posicion.latitude,
        'longitud': posicion.longitude,
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener ubicación: $e'
      };
    }
  }
}