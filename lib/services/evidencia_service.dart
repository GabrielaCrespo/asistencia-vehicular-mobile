import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EvidenciaService {
  static const String baseUrl = 'https://asistencia-vehicular-backend.onrender.com';
  static final ImagePicker _picker = ImagePicker();

  // Seleccionar imagen desde galería
  static Future<Map<String, dynamic>> seleccionarDeGaleria() async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (imagen == null) {
        return {'success': false, 'message': 'No se seleccionó imagen'};
      }

      return {
        'success': true,
        'path': imagen.path,
        'nombre': imagen.name,
        'xfile': imagen,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Tomar foto desde cámara
  static Future<Map<String, dynamic>> tomarFoto() async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (imagen == null) {
        return {'success': false, 'message': 'No se tomó foto'};
      }

      return {
        'success': true,
        'path': imagen.path,
        'nombre': imagen.name,
        'xfile': imagen,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Subir imagen al backend
  static Future<Map<String, dynamic>> subirImagen(XFile imagen) async {
    try {
      final bytes = await imagen.readAsBytes();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/emergencia/subir-imagen'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'imagen',
          bytes,
          filename: imagen.name,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'imagen_path': data['imagen_path'],
        };
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Error al subir'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}