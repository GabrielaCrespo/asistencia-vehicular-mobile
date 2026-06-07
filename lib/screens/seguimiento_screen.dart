import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../services/emergencia_service.dart';
import '../services/session_service.dart';
import '../services/calificacion_service.dart';
import 'calificacion_screen.dart';
import 'chat_screen.dart';

class SeguimientoScreen extends StatefulWidget {
  final int incidenteId;
  SeguimientoScreen({required this.incidenteId});

  @override
  _SeguimientoScreenState createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  Map<String, dynamic>? incidente;
  bool cargando = true;
  WebSocketChannel? _channel;
  MapController _mapController = MapController();

  LatLng? _tecnicoUbicacion;
  LatLng? _clienteUbicacion;

  bool _yaCalificado = false;
  bool _calificacionCargada = false;

  static const Set<String> _estadosFinalizados = {
    'atendido',
    'cerrada',
    'completado',
    'finalizado',
  };

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

  void _conectarWebSocket() async {
    final sesion = await SessionService.getSesion();
    final token = sesion['token'] as String?;
    if (token == null) return;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(
          'wss://asistencia-vehicular-backend.onrender.com/ws?token=$token',
        ),
      );

      _channel!.stream.listen(
        (mensaje) {
          final data = jsonDecode(mensaje);
          if (data['tipo'] == 'pong' || data['tipo'] == 'conexion_establecida')
            return;

          if (data['incidente_id'] == widget.incidenteId) {
            if (data['estado'] != null && incidente != null) {
              setState(() => incidente!['estado'] = data['estado']);
            }
            if (data['tipo'] == 'ubicacion_tecnico' &&
                data['latitud'] != null &&
                data['longitud'] != null) {
              setState(() {
                _tecnicoUbicacion = LatLng(
                  double.parse(data['latitud'].toString()),
                  double.parse(data['longitud'].toString()),
                );
              });
              _mapController.move(_tecnicoUbicacion!, 15);
            }
            cargarDetalle();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.notifications, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(child: Text(data['titulo'] ?? 'Actualización')),
                    ],
                  ),
                  backgroundColor: Colors.blue.shade700,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        },
        onDone: () => Future.delayed(Duration(seconds: 30), _conectarWebSocket),
        onError: (_) => _channel = null,
      );

      Stream.periodic(Duration(seconds: 30)).listen((_) {
        if (_channel != null) _channel!.sink.add('ping');
      });
    } catch (e) {
      print('[WS] Error: $e');
    }
  }

  void cargarDetalle() async {
    final resultado = await EmergenciaService.obtenerDetalle(
      widget.incidenteId,
    );
    if (resultado['success']) {
      final inc = resultado['incidente'];
      setState(() {
        incidente = inc;
        cargando = false;
        if (inc['latitud'] != null && inc['longitud'] != null) {
          _clienteUbicacion = LatLng(
            double.parse(inc['latitud'].toString()),
            double.parse(inc['longitud'].toString()),
          );
        }
      });
      final String estado = inc['estado'] ?? '';
      if (_estadosFinalizados.contains(estado) && !_calificacionCargada) {
        _verificarCalificacion();
      }
    } else {
      setState(() => cargando = false);
    }
  }

  Future<void> _verificarCalificacion() async {
    final result = await CalificacionService.getCalificacion(
      widget.incidenteId,
    );
    if (!mounted) return;
    setState(() {
      _calificacionCargada = true;
      _yaCalificado = result['exists'] == true;
    });
  }

  Color getColorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'asignada':
        return Colors.blue;
      case 'en_camino':
        return Colors.indigo;
      case 'en_servicio':
        return Colors.purple;
      case 'atendido':
        return Colors.green;
      case 'cerrada':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData getIconoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.access_time;
      case 'asignada':
        return Icons.store;
      case 'en_camino':
        return Icons.directions_car;
      case 'en_servicio':
        return Icons.build;
      case 'atendido':
        return Icons.check_circle;
      case 'cerrada':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String getTextoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'asignada':
        return 'Taller Asignado';
      case 'en_camino':
        return 'En Camino';
      case 'en_servicio':
        return 'Atendiendo';
      case 'atendido':
        return 'Atendido';
      case 'cerrada':
        return 'Completado';
      default:
        return estado;
    }
  }

  bool _paso(String estadoActual, String paso) {
    final orden = [
      'pendiente',
      'asignada',
      'en_camino',
      'en_servicio',
      'cerrada',
    ];
    return orden.indexOf(estadoActual) >= orden.indexOf(paso);
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
        title: Text(
          "Seguimiento",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Botón de chat (solo cuando está en camino o en servicio)
          if (incidente != null &&
              (incidente!['estado'] == 'en_camino' ||
                  incidente!['estado'] == 'en_servicio'))
            IconButton(
              icon: Icon(Icons.chat, color: Colors.blue),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    incidenteId: widget.incidenteId,
                    otroNombre: incidente!['taller_nombre'] ?? 'Técnico',
                  ),
                ),
              ),
            ),
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
                            color: getColorEstado(
                              incidente!['estado'],
                            ).withOpacity(0.1),
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
                        Text(
                          "Emergencia #${incidente!['incidente_id']}",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.circle, color: Colors.green, size: 10),
                            SizedBox(width: 5),
                            Text(
                              "Actualizando en tiempo real",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // TIMELINE VERTICAL
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Estado del servicio",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 20),
                          _buildPasoV(
                            "Solicitud enviada",
                            "Tu emergencia fue registrada",
                            true,
                            Icons.check_circle,
                            Colors.green,
                          ),
                          _buildPasoV(
                            "Taller asignado",
                            _paso(incidente!['estado'], 'asignada')
                                ? "Taller asignado"
                                : "Buscando el taller más cercano",
                            _paso(incidente!['estado'], 'asignada'),
                            _paso(incidente!['estado'], 'asignada')
                                ? Icons.check_circle
                                : Icons.access_time,
                            _paso(incidente!['estado'], 'asignada')
                                ? Colors.green
                                : Colors.orange,
                          ),
                          _buildPasoV(
                            "En camino",
                            _paso(incidente!['estado'], 'en_camino')
                                ? "El técnico está en camino"
                                : "Esperando confirmación",
                            _paso(incidente!['estado'], 'en_camino'),
                            _paso(incidente!['estado'], 'en_camino')
                                ? Icons.check_circle
                                : Icons.access_time,
                            _paso(incidente!['estado'], 'en_camino')
                                ? Colors.green
                                : Colors.grey,
                          ),
                          _buildPasoV(
                            "Servicio completado",
                            _paso(incidente!['estado'], 'cerrada')
                                ? "Tu vehículo fue atendido"
                                : "Pendiente",
                            _paso(incidente!['estado'], 'cerrada'),
                            _paso(incidente!['estado'], 'cerrada')
                                ? Icons.check_circle
                                : Icons.access_time,
                            _paso(incidente!['estado'], 'cerrada')
                                ? Colors.green
                                : Colors.grey,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // MAPA OSM
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(15),
                            child: Row(
                              children: [
                                Icon(Icons.map, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  "Ubicación del técnico",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Spacer(),
                                if (incidente!['estado'] == 'en_camino' &&
                                    _tecnicoUbicacion == null)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        "Esperando...",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          // Mensaje cuando aún no está en camino
                          if (incidente!['estado'] == 'pendiente' ||
                              incidente!['estado'] == 'asignada')
                            Padding(
                              padding: EdgeInsets.fromLTRB(15, 0, 15, 15),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Cuando el técnico esté en camino podrás ver su ubicación en tiempo real aquí.",
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Mapa OSM
                          if (incidente!['estado'] == 'en_camino' ||
                              incidente!['estado'] == 'en_servicio')
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                              child: SizedBox(
                                height: 280,
                                child: FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter:
                                        _tecnicoUbicacion ??
                                        _clienteUbicacion ??
                                        LatLng(-17.7833, -63.1821),
                                    initialZoom: 15,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.mobile_app',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        if (_clienteUbicacion != null)
                                          Marker(
                                            point: _clienteUbicacion!,
                                            width: 40,
                                            height: 40,
                                            child: Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                          ),
                                        if (_tecnicoUbicacion != null)
                                          Marker(
                                            point: _tecnicoUbicacion!,
                                            width: 40,
                                            height: 40,
                                            child: Icon(
                                              Icons.directions_car,
                                              color: Colors.blue,
                                              size: 40,
                                            ),
                                          ),
                                      ],
                                    ),
                                    // Línea de ruta entre técnico y cliente
                                    if (_tecnicoUbicacion != null &&
                                        _clienteUbicacion != null)
                                      PolylineLayer(
                                        polylines: [
                                          Polyline(
                                            points: [
                                              _tecnicoUbicacion!,
                                              _clienteUbicacion!,
                                            ],
                                            strokeWidth: 3,
                                            color: Colors.blue,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
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
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Taller asignado",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
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
                              title: Text(
                                incidente!['taller_nombre'],
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                incidente!['taller_direccion'] ?? '',
                              ),
                            ),
                            if (incidente!['tiempo_estimado_minutos'] != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Tiempo estimado: ${incidente!['tiempo_estimado_minutos']} minutos",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Vehículo",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 15),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.directions_car,
                                color: Colors.grey,
                              ),
                            ),
                            title: Text(
                              "${incidente!['marca']} ${incidente!['modelo']}",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text("Placa: ${incidente!['placa']}"),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // CALIFICACIÓN
                  if (_estadosFinalizados.contains(incidente!['estado']) &&
                      _calificacionCargada) ...[
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSeccionCalificacion(),
                    ),
                  ],

                  SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSeccionCalificacion() {
    if (_yaCalificado) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 26),
            const SizedBox(width: 10),
            Text(
              'Servicio calificado',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            '¿Cómo fue tu experiencia?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CalificacionScreen(
                    incidenteId: widget.incidenteId,
                    tallerNombre: incidente!['taller_nombre'] as String?,
                    tipoProblema: incidente!['tipo_problema'] as String?,
                    fechaCreacion: incidente!['fecha_creacion']?.toString(),
                  ),
                ),
              );
              _verificarCalificacion();
            },
            icon: const Icon(Icons.star_border_rounded, size: 22),
            label: const Text(
              'Calificar el servicio',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5cbdb9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasoV(
    String titulo,
    String subtitulo,
    bool completado,
    IconData icono,
    Color color, {
    bool isLast = false,
  }) {
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
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: completado ? Colors.black87 : Colors.grey,
                  ),
                ),
                Text(
                  subtitulo,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
