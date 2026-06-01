import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'emergencia_screen.dart';
import 'vehiculos_screen.dart';
import '../services/session_service.dart';
import 'login_screen.dart';
import 'perfil_screen.dart';
import '../services/emergencia_service.dart';
import 'seguimiento_screen.dart';
import 'historial_screen.dart';

class ClienteScreen extends StatefulWidget {
  @override
  _ClienteScreenState createState() => _ClienteScreenState();
}

class _ClienteScreenState extends State<ClienteScreen> {
  String nombre = "";
  String email = "";
  int _selectedIndex = 0;
  Map<String, dynamic>? emergenciaActiva;
  WebSocketChannel? _channel;
  MapController _mapController = MapController();
  LatLng? _tecnicoUbicacion;
  LatLng? _clienteUbicacion;

  @override
  void initState() {
    super.initState();
    cargarSesion();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  void cargarSesion() async {
    final sesion = await SessionService.getSesion();
    setState(() {
      nombre = sesion['nombre'] ?? "Cliente";
      email = sesion['email'] ?? "";
    });

    final usuarioId = sesion['usuario_id'] ?? 0;
    final resultado = await EmergenciaService.listar(usuarioId);
    if (resultado['success']) {
      final lista = List<Map<String, dynamic>>.from(resultado['emergencias']);
      final activa = lista.firstWhere(
        (e) => ['pendiente', 'asignada', 'en_camino', 'en_servicio'].contains(e['estado']),
        orElse: () => {},
      );

      setState(() {
        emergenciaActiva = activa.isEmpty ? null : activa;
        if (emergenciaActiva != null && emergenciaActiva!['latitud'] != null) {
          _clienteUbicacion = LatLng(
            double.parse(emergenciaActiva!['latitud'].toString()),
            double.parse(emergenciaActiva!['longitud'].toString()),
          );
        }
      });

      if (emergenciaActiva != null) {
        _conectarWebSocket(sesion['token'] ?? '');
      }
    }
  }

  void _conectarWebSocket(String token) {
    if (token.isEmpty) return;
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://asistencia-vehicular-backend.onrender.com/ws?token=$token'),
      );

      _channel!.stream.listen(
        (mensaje) {
          final data = jsonDecode(mensaje);
          if (data['tipo'] == 'pong' || data['tipo'] == 'conexion_establecida') return;

          if (emergenciaActiva != null &&
              data['incidente_id'] == emergenciaActiva!['incidente_id']) {
            if (data['estado'] != null) {
              setState(() => emergenciaActiva!['estado'] = data['estado']);
            }
            if (data['tipo'] == 'ubicacion_tecnico' && data['latitud'] != null) {
              setState(() {
                _tecnicoUbicacion = LatLng(
                  double.parse(data['latitud'].toString()),
                  double.parse(data['longitud'].toString()),
                );
              });
              _mapController.move(_tecnicoUbicacion!, 15);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    Icon(Icons.notifications, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(child: Text(data['titulo'] ?? 'Actualización')),
                  ]),
                  backgroundColor: Colors.blue.shade700,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        },
        onDone: () {},
        onError: (_) => _channel = null,
      );

      Stream.periodic(Duration(seconds: 30)).listen((_) {
        if (_channel != null) _channel!.sink.add('ping');
      });
    } catch (e) {
      print('[WS] Error: $e');
    }
  }

  void cerrarSesion() async {
    await SessionService.cerrarSesion();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialScreen()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilScreen()));
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  bool _paso(String estadoActual, String paso) {
    final orden = ['pendiente', 'asignada', 'en_camino', 'en_servicio', 'cerrada'];
    return orden.indexOf(estadoActual) >= orden.indexOf(paso);
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'pendiente': return 'Buscando taller...';
      case 'asignada': return 'Taller asignado';
      case 'en_camino': return 'Técnico en camino';
      case 'en_servicio': return 'Siendo atendido';
      case 'cerrada': return 'Completado';
      default: return estado;
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente': return Colors.orange;
      case 'asignada': return Colors.blue;
      case 'en_camino': return Colors.indigo;
      case 'en_servicio': return Colors.purple;
      case 'cerrada': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text("Inicio",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.logout, color: Colors.grey), onPressed: cerrarSesion),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hola, ${nombre.split(' ')[0]} 👋",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  SizedBox(height: 5),
                  Row(children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text("Santa Cruz - Bolivia", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ]),
                ],
              ),
            ),

            SizedBox(height: 20),

            // ═══════════ EMERGENCIA ACTIVA ═══════════
            if (emergenciaActiva != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Emergencia activa",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                    Row(children: [
                      Icon(Icons.circle, color: Colors.green, size: 10),
                      SizedBox(width: 4),
                      Text("En vivo", style: TextStyle(color: Colors.green, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
              SizedBox(height: 12),

              // CARD CON ESTADO Y TIMELINE HORIZONTAL
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SeguimientoScreen(incidenteId: emergenciaActiva!['incidente_id']),
                  )),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        // Estado actual
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            color: _colorEstado(emergenciaActiva!['estado']).withOpacity(0.1),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                          ),
                          child: Row(children: [
                            Icon(Icons.emergency, color: _colorEstado(emergenciaActiva!['estado'])),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Emergencia #${emergenciaActiva!['incidente_id']}",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                  Text(_textoEstado(emergenciaActiva!['estado']),
                                      style: TextStyle(
                                          color: _colorEstado(emergenciaActiva!['estado']),
                                          fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ]),
                        ),

                        // TIMELINE HORIZONTAL siempre visible
                        Padding(
                          padding: EdgeInsets.all(20),
                          child: Row(
                            children: [
                              _buildPasoH('Solicitud\nenviada', Icons.send, true),
                              _buildLineaH(_paso(emergenciaActiva!['estado'], 'asignada')),
                              _buildPasoH('Taller\nasignado', Icons.store,
                                  _paso(emergenciaActiva!['estado'], 'asignada')),
                              _buildLineaH(_paso(emergenciaActiva!['estado'], 'en_camino')),
                              _buildPasoH('En\ncamino', Icons.directions_car,
                                  _paso(emergenciaActiva!['estado'], 'en_camino')),
                              _buildLineaH(_paso(emergenciaActiva!['estado'], 'cerrada')),
                              _buildPasoH('Servicio\ncompletado', Icons.check_circle,
                                  _paso(emergenciaActiva!['estado'], 'cerrada')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 15),

              // MAPA OSM
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(15),
                        child: Row(children: [
                          Icon(Icons.map, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("Técnico en tiempo real",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ]),
                      ),

                      // Mensaje cuando aún no está en camino
                      if (emergenciaActiva!['estado'] == 'pendiente' ||
                          emergenciaActiva!['estado'] == 'asignada') ...[
                        Padding(
                          padding: EdgeInsets.fromLTRB(15, 0, 15, 8),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Cuando el técnico esté en camino podrás ver su ubicación en tiempo real aquí.",
                                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                                ),
                              ),
                            ]),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(15, 0, 15, 15),
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.location_searching, color: Colors.grey, size: 28),
                                  SizedBox(height: 6),
                                  Text("El mapa estará disponible cuando el técnico esté en camino",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Mapa OSM cuando está en camino o en servicio
                      if (emergenciaActiva!['estado'] == 'en_camino' ||
                          emergenciaActiva!['estado'] == 'en_servicio')
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                          child: SizedBox(
                            height: 220,
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _tecnicoUbicacion ??
                                    _clienteUbicacion ??
                                    LatLng(-17.7833, -63.1821),
                                initialZoom: 15,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.mobile_app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    if (_clienteUbicacion != null)
                                      Marker(
                                        point: _clienteUbicacion!,
                                        width: 40, height: 40,
                                        child: Icon(Icons.location_on, color: Colors.red, size: 40),
                                      ),
                                    if (_tecnicoUbicacion != null)
                                      Marker(
                                        point: _tecnicoUbicacion!,
                                        width: 40, height: 40,
                                        child: Icon(Icons.directions_car, color: Colors.blue, size: 40),
                                      ),
                                  ],
                                ),
                                if (_tecnicoUbicacion != null && _clienteUbicacion != null)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: [_tecnicoUbicacion!, _clienteUbicacion!],
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
            ],

            // ═══════════ SIN EMERGENCIA ═══════════
            if (emergenciaActiva == null) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text("¿Necesitas ayuda?",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
              ),
              SizedBox(height: 15),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmergenciaScreen())),
                  child: Container(
                    width: 180, height: 180,
                    decoration: BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0xFFE53935).withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.white, size: 40),
                        SizedBox(height: 8),
                        Text("EMERGENCIA",
                            style: TextStyle(color: Colors.white, fontSize: 16,
                                fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 25),
            ],

            // ACCESOS RAPIDOS
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("Accesos rápidos",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.directions_car, color: Colors.blue),
                  ),
                  title: Text("Mis Vehículos", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("Gestiona tus vehículos registrados"),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VehiculosScreen())),
                ),
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey,
        elevation: 10,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Historial"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  Widget _buildPasoH(String label, IconData icono, bool activo) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activo ? Colors.green : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: activo ? Colors.white : Colors.grey, size: 18),
          ),
          SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                color: activo ? Colors.green : Colors.grey,
              )),
        ],
      ),
    );
  }

  Widget _buildLineaH(bool activo) {
    return Expanded(
      child: Container(
        height: 2,
        margin: EdgeInsets.only(bottom: 28),
        color: activo ? Colors.green : Colors.grey.shade300,
      ),
    );
  }
}