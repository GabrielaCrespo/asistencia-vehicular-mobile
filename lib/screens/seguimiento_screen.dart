import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../services/emergencia_service.dart';
import '../services/session_service.dart';

class SeguimientoScreen extends StatefulWidget {
  final int incidenteId;
  SeguimientoScreen({required this.incidenteId});

  @override
  _SeguimientoScreenState createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  Map<String, dynamic>? incidente;
  bool cargando = true;
  String? _mensajeWs;

  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    cargarDetalle();
    _conectarWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  // ── WebSocket ──────────────────────────────────────────────────
  void _conectarWebSocket() async {
    final sesion = await SessionService.getSesion();
    final token = sesion['token'] as String?;
    if (token == null) return;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://10.0.2.2:8000/ws?token=$token'),
      );

      _channel!.stream.listen(
        (mensaje) {
          final data = jsonDecode(mensaje);
          if (data['tipo'] == 'pong' || data['tipo'] == 'conexion_establecida') return;

          // Actualizar estado si viene un cambio de estado
          if (data['incidente_id'] == widget.incidenteId) {
            setState(() {
              _mensajeWs = data['titulo'] ?? data['mensaje'];
              if (data['estado'] != null && incidente != null) {
                incidente!['estado'] = data['estado'];
              }
            });

            // Recargar detalle completo para reflejar todos los cambios
            cargarDetalle();

            // Mostrar snackbar con la notificación
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.notifications, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(child: Text(data['titulo'] ?? 'Actualización recibida')),
                    ],
                  ),
                  backgroundColor: Colors.blue.shade700,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        },
        onError: (error) {
          print('[WS] Error: $error');
          // Reconectar después de 5 segundos
          Future.delayed(Duration(seconds: 5), _conectarWebSocket);
        },
        onDone: () {
          print('[WS] Conexión cerrada, reconectando...');
          Future.delayed(Duration(seconds: 5), _conectarWebSocket);
        },
      );

      // Ping cada 30s para mantener conexión viva
      Stream.periodic(Duration(seconds: 30)).listen((_) {
        if (_channel != null) _channel!.sink.add('ping');
      });

    } catch (e) {
      print('[WS] Error conectando: $e');
    }
  }

  // ── Cargar detalle ─────────────────────────────────────────────
  void cargarDetalle() async {
    final resultado = await EmergenciaService.obtenerDetalle(widget.incidenteId);
    if (resultado['success']) {
      setState(() {
        incidente = resultado['incidente'];
        cargando = false;
      });
    } else {
      setState(() => cargando = false);
    }
  }

  // ── Helpers de estado ──────────────────────────────────────────
  Color getColorEstado(String estado) {
    switch (estado) {
      case 'pendiente': return Colors.orange;
      case 'asignada':  return Colors.blue;
      case 'en_camino': return Colors.blue;
      case 'en_servicio': return Colors.purple;
      case 'atendido':  return Colors.green;
      case 'cerrada':   return Colors.green;
      default:          return Colors.grey;
    }
  }

  IconData getIconoEstado(String estado) {
    switch (estado) {
      case 'pendiente':   return Icons.access_time;
      case 'asignada':    return Icons.store;
      case 'en_camino':   return Icons.directions_car;
      case 'en_servicio': return Icons.build;
      case 'atendido':    return Icons.check_circle;
      case 'cerrada':     return Icons.check_circle;
      default:            return Icons.help;
    }
  }

  String getTextoEstado(String estado) {
    switch (estado) {
      case 'pendiente':   return 'Pendiente';
      case 'asignada':    return 'Taller Asignado';
      case 'en_camino':   return 'En Camino';
      case 'en_servicio': return 'Atendiendo';
      case 'atendido':    return 'Atendido';
      case 'cerrada':     return 'Completado';
      default:            return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Seguimiento",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // Indicador de conexión WebSocket
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.circle,
              color: _channel != null ? Colors.green : Colors.grey,
              size: 14,
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue),
            onPressed: cargarDetalle,
          ),
        ],
      ),

      body: cargando
          ? Center(child: CircularProgressIndicator())
          : incidente == null
              ? Center(child: Text("No se encontró la emergencia"))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // HEADER ESTADO
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: getColorEstado(incidente!['estado']).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                getIconoEstado(incidente!['estado']),
                                size: 50,
                                color: getColorEstado(incidente!['estado']),
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              getTextoEstado(incidente!['estado']),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: getColorEstado(incidente!['estado']),
                              ),
                            ),
                            SizedBox(height: 5),
                            Text("Emergencia #${incidente!['incidente_id']}",
                                style: TextStyle(color: Colors.grey, fontSize: 13)),
                            // Indicador tiempo real
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.circle, color: Colors.green, size: 10),
                                SizedBox(width: 5),
                                Text("Actualizando en tiempo real",
                                    style: TextStyle(color: Colors.green, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // TIMELINE
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Estado del servicio",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              SizedBox(height: 20),
                              _buildPaso("Solicitud enviada", "Tu emergencia fue registrada",
                                  true, Icons.check_circle, Colors.green),
                              _buildPaso(
                                "Taller asignado",
                                incidente!['taller_nombre'] != null
                                    ? "Taller asignado"
                                    : "Buscando el taller más cercano",
                                incidente!['taller_nombre'] != null,
                                incidente!['taller_nombre'] != null
                                    ? Icons.check_circle
                                    : Icons.access_time,
                                incidente!['taller_nombre'] != null ? Colors.green : Colors.orange,
                              ),
                              _buildPaso(
                                "En camino",
                                ['en_camino', 'en_servicio', 'atendido', 'cerrada'].contains(incidente!['estado'])
                                    ? "El técnico está en camino"
                                    : "Esperando confirmación",
                                ['en_camino', 'en_servicio', 'atendido', 'cerrada'].contains(incidente!['estado']),
                                ['en_camino', 'en_servicio', 'atendido', 'cerrada'].contains(incidente!['estado'])
                                    ? Icons.check_circle
                                    : Icons.access_time,
                                ['en_camino', 'en_servicio', 'atendido', 'cerrada'].contains(incidente!['estado'])
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              _buildPaso(
                                "Servicio completado",
                                ['atendido', 'cerrada'].contains(incidente!['estado'])
                                    ? "Tu vehículo fue atendido"
                                    : "Pendiente",
                                ['atendido', 'cerrada'].contains(incidente!['estado']),
                                ['atendido', 'cerrada'].contains(incidente!['estado'])
                                    ? Icons.check_circle
                                    : Icons.access_time,
                                ['atendido', 'cerrada'].contains(incidente!['estado'])
                                    ? Colors.green
                                    : Colors.grey,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // INFO TALLER
                      if (incidente!['taller_nombre'] != null)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Taller asignado",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                SizedBox(height: 15),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.store, color: Colors.blue),
                                  ),
                                  title: Text(incidente!['taller_nombre'],
                                      style: TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(incidente!['taller_direccion'] ?? ''),
                                ),
                                if (incidente!['tiempo_estimado_minutos'] != null)
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, color: Colors.orange, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        "Tiempo estimado: ${incidente!['tiempo_estimado_minutos']} minutos",
                                        style: TextStyle(
                                            color: Colors.orange, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),

                      SizedBox(height: 20),

                      // INFO VEHICULO
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Vehículo",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              SizedBox(height: 15),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.directions_car, color: Colors.grey),
                                ),
                                title: Text("${incidente!['marca']} ${incidente!['modelo']}",
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text("Placa: ${incidente!['placa']}"),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPaso(String titulo, String subtitulo, bool completado,
      IconData icono, Color color, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icono, color: color, size: 24),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: completado ? Colors.green : Colors.grey.shade300,
              ),
          ],
        ),
        SizedBox(width: 15),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: completado ? Colors.black87 : Colors.grey)),
                Text(subtitulo, style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}