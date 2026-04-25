import 'package:record/record.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  static final AudioRecorder _recorder = AudioRecorder();

  static Future<Map<String, dynamic>> iniciarGrabacion() async {
    try {
      bool tienePermiso = await _recorder.hasPermission();
      if (!tienePermiso) {
        return {'success': false, 'message': 'Sin permisos de micrófono'};
      }

      String ruta = '';

      if (!kIsWeb) {
        final directorio = await getTemporaryDirectory();
        ruta = '${directorio.path}/audio_emergencia_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: ruta,
      );

      return {'success': true, 'message': 'Grabando...'};
    } catch (e) {
      return {'success': false, 'message': 'Error al grabar: $e'};
    }
  }

  static Future<Map<String, dynamic>> detenerGrabacion() async {
    try {
      final ruta = await _recorder.stop();
      return {'success': true, 'path': ruta ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<bool> estaGrabando() async {
    return await _recorder.isRecording();
  }
}