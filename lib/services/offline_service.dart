import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'emergencia_service.dart';

class OfflineService {
  static const String _keyEmergencias = 'emergencias_pendientes';

  // ── GUARDAR EMERGENCIA OFFLINE ─────────────────────────────────
  static Future<void> guardarEmergenciaPendiente(Map<String, dynamic> datos) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = await obtenerPendientes();

    datos['local_id'] = DateTime.now().millisecondsSinceEpoch.toString();
    datos['estado_sync'] = 'pendiente';
    datos['fecha_local'] = DateTime.now().toIso8601String();

    lista.add(datos);
    await prefs.setString(_keyEmergencias, jsonEncode(lista));
    print('[Offline] Emergencia guardada localmente: ${datos['local_id']}');
  }

  // ── OBTENER PENDIENTES ─────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> obtenerPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyEmergencias);
    if (json == null) return [];
    final lista = jsonDecode(json) as List;
    return lista.cast<Map<String, dynamic>>();
  }

  // ── CONTAR PENDIENTES ──────────────────────────────────────────
  static Future<int> contarPendientes() async {
    final lista = await obtenerPendientes();
    return lista.where((e) => e['estado_sync'] == 'pendiente').length;
  }

  // ── MARCAR COMO SINCRONIZADA ───────────────────────────────────
  static Future<void> marcarSincronizada(String localId) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = await obtenerPendientes();
    final actualizada = lista.where((e) => e['local_id'] != localId).toList();
    await prefs.setString(_keyEmergencias, jsonEncode(actualizada));
    print('[Offline] ✅ Emergencia sincronizada: $localId');
  }

  // ── MARCAR ERROR ───────────────────────────────────────────────
  static Future<void> marcarError(String localId, String error) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = await obtenerPendientes();
    final actualizada = lista.map((e) {
      if (e['local_id'] == localId) {
        return {...e, 'estado_sync': 'error', 'error_msg': error};
      }
      return e;
    }).toList();
    await prefs.setString(_keyEmergencias, jsonEncode(actualizada));
  }

  // ── VERIFICAR CONEXIÓN ─────────────────────────────────────────
  static Future<bool> tieneConexion() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // ── SINCRONIZAR PENDIENTES ─────────────────────────────────────
  static Future<SyncResult> sincronizarPendientes() async {
    if (!await tieneConexion()) {
      return SyncResult(sincronizadas: 0, errores: 0, mensaje: 'Sin conexión');
    }

    final pendientes = await obtenerPendientes();
    final soloSinSync = pendientes.where((e) => e['estado_sync'] == 'pendiente').toList();

    if (soloSinSync.isEmpty) {
      return SyncResult(sincronizadas: 0, errores: 0, mensaje: 'No hay pendientes');
    }

    int sincronizadas = 0;
    int errores = 0;

    for (final emergencia in soloSinSync) {
      try {
        final resultado = await EmergenciaService.registrar(
          usuarioId: emergencia['usuario_id'],
          vehiculoId: emergencia['vehiculo_id'],
          descripcion: emergencia['descripcion'],
          latitud: double.parse(emergencia['latitud'].toString()),
          longitud: double.parse(emergencia['longitud'].toString()),
          tipoProblema: emergencia['tipo_problema'],
          imagenPath: emergencia['imagen_path'],
          audioPath: emergencia['audio_path'],
        );

        if (resultado['success']) {
          await marcarSincronizada(emergencia['local_id']);
          sincronizadas++;
        } else {
          await marcarError(emergencia['local_id'], resultado['message'] ?? 'Error');
          errores++;
        }
      } catch (e) {
        await marcarError(emergencia['local_id'], e.toString());
        errores++;
        print('[Offline] ❌ Error sincronizando: $e');
      }
    }

    return SyncResult(
      sincronizadas: sincronizadas,
      errores: errores,
      mensaje: '$sincronizadas sincronizadas, $errores errores',
    );
  }

  // ── ESCUCHAR CAMBIOS DE CONECTIVIDAD ──────────────────────────
  static Stream<bool> escucharConexion() {
    return Connectivity().onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }
}

class SyncResult {
  final int sincronizadas;
  final int errores;
  final String mensaje;

  SyncResult({
    required this.sincronizadas,
    required this.errores,
    required this.mensaje,
  });
}