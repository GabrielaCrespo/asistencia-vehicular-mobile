import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EvidenciaService {
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
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}