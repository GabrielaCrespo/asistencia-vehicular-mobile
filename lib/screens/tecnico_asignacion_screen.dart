import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import '../services/tecnico_service.dart';
import '../services/session_service.dart';
import 'chat_screen.dart';

class TecnicoAsignacionScreen extends StatefulWidget {
  final Map<String, dynamic> asignacion;
  final int tallerId;
  final VoidCallback onActualizar;

  TecnicoAsignacionScreen({
    required this.asignacion,
    required this.tallerId,
    required this.onActualizar,
  });

  @override
  _TecnicoAsignacionScreenState createState() =>
      _TecnicoAsignacionScreenState();
}

class _TecnicoAsignacionScreenState extends State<TecnicoAsignacionScreen> {
  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController montoController = TextEditingController();
  String metodoPago = "efectivo";
  bool procesando = false;

  // GPS
  WebSocketChannel? _channel;
  Timer? _gpsTimer;
  bool _enviandoUbicacion = false;

  // Mapa
  MapController _mapController = MapController();
  LatLng? _tecnicoUbicacion;
  LatLng? _clienteUbicacion;

  @override
  void initState() {
    super.initState();
    // Cargar ubicación del cliente
    if (widget.asignacion['latitud'] != null) {
      _clienteUbicacion = LatLng(
        double.parse(widget.asignacion['latitud'].toString()),
        double.parse(widget.asignacion['longitud'].toString()),
      );
    }
    if (widget.asignacion['estado'] == 'en_camino') {
      _iniciarEnvioUbicacion();
    }
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _abrirRutaEnMaps() async {
    final lat = widget.asignacion['latitud'];
    final lng = widget.asignacion['longitud'];
    if (lat == null || lng == null) return;
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _iniciarEnvioUbicacion() async {
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return;
    }

    final sesion = await SessionService.getSesion();
    final token = sesion['token'] ?? '';
    if (token.isEmpty) return;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(
          'wss://asistencia-vehicular-backend.onrender.com/ws?token=$token',
        ),
      );
      setState(() => _enviandoUbicacion = true);

      _gpsTimer = Timer.periodic(Duration(seconds: 10), (_) async {
        try {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          setState(() {
            _tecnicoUbicacion = LatLng(pos.latitude, pos.longitude);
          });
          _mapController.move(_tecnicoUbicacion!, 15);

          if (_channel != null) {
            _channel!.sink.add(
              jsonEncode({
                'tipo': 'ubicacion_tecnico',
                'incidente_id': widget.asignacion['incidente_id'],
                'latitud': pos.latitude,
                'longitud': pos.longitude,
              }),
            );
          }
        } catch (e) {
          print('[GPS] Error: $e');
        }
      });
    } catch (e) {
      print('[WS] Error: $e');
    }
  }

  void _detenerEnvioUbicacion() {
    _gpsTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    setState(() => _enviandoUbicacion = false);
  }

  Future<void> actualizarEstado(String estado) async {
    setState(() => procesando = true);
    final resultado = await TecnicoService.actualizarEstado(
      asignacionId: widget.asignacion['asignacion_id'],
      estado: estado,
    );
    setState(() => procesando = false);

    if (resultado['success']) {
      if (estado == 'en_camino') await _iniciarEnvioUbicacion();
      if (estado == 'en_servicio') _detenerEnvioUbicacion();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Estado actualizado"),
          backgroundColor: Colors.green,
        ),
      );
      widget.onActualizar();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void finalizarServicio() {
    bool enviando = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text("Finalizar servicio"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: montoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Monto cobrado (Bs.)",
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: observacionesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Observaciones",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El cliente seleccionará el método de pago desde su app.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: enviando
                  ? null
                  : () async {
                      if (montoController.text.trim().isEmpty) return;
                      setStateDialog(() => enviando = true);
                      final nav = Navigator.of(context);
                      final scaffold = ScaffoldMessenger.of(context);
                      final resultado = await TecnicoService.registrarPago(
                        asignacionId: widget.asignacion['asignacion_id'],
                        tallerId: widget.tallerId,
                        monto: double.parse(montoController.text.trim()),
                        observaciones: observacionesController.text.trim(),
                        metodoPago: metodoPago,
                      );
                      if (resultado['success']) {
                        nav.pop();
                        _detenerEnvioUbicacion();
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Text("Servicio finalizado"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        await Future.delayed(Duration(seconds: 2));
                        widget.onActualizar();
                        nav.pop();
                      } else {
                        setStateDialog(() => enviando = false);
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Text(resultado['message']),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1A237E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text("Confirmar", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'aceptada':
        return Colors.blue;
      case 'en_camino':
        return Colors.orange;
      case 'en_servicio':
        return Colors.purple;
      case 'completada':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.asignacion;
    final estado = a['estado'] ?? '';

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A237E),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Detalle del Servicio",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_enviandoUbicacion)
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Icon(Icons.gps_fixed, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 4),
                  Text(
                    "GPS",
                    style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),

      body: procesando
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // HEADER
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A237E),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Servicio #${a['asignacion_id']}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _colorEstado(estado).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            estado.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_enviandoUbicacion) ...[
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.gps_fixed,
                                color: Colors.greenAccent,
                                size: 14,
                              ),
                              SizedBox(width: 5),
                              Text(
                                "Enviando ubicación en tiempo real",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // MAPA CON RUTA (visible cuando está en camino)
                  if (estado == 'en_camino' || estado == 'en_servicio')
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
                                    "Ruta hacia el cliente",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Spacer(),
                                  // Leyenda
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.directions_car,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Tú",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Cliente",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
                                        _clienteUbicacion ??
                                        LatLng(-17.7833, -63.1821),
                                    initialZoom: 14,
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
                                    if (_tecnicoUbicacion != null &&
                                        _clienteUbicacion != null)
                                      PolylineLayer(
                                        polylines: [
                                          Polyline(
                                            points: [
                                              _tecnicoUbicacion!,
                                              _clienteUbicacion!,
                                            ],
                                            strokeWidth: 4,
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

                  if (estado == 'en_camino' || estado == 'en_servicio')
                    SizedBox(height: 15),

                  // BOTON ABRIR EN GOOGLE MAPS
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _abrirRutaEnMaps,
                        icon: Icon(Icons.directions, color: Colors.white),
                        label: Text(
                          "Abrir ruta en Google Maps",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 15),

                  // BOTON CHAT
                  if (estado == 'en_camino' || estado == 'en_servicio')
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                incidenteId: widget.asignacion['incidente_id'],
                                otroNombre:
                                    widget.asignacion['cliente_nombre'] ??
                                    'Cliente',
                                channel: _channel,
                              ),
                            ),
                          ),
                          icon: Icon(Icons.chat, color: Colors.white),
                          label: Text(
                            "Chat con el cliente",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: 15),

                  // INFO CLIENTE
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Información del cliente",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 15),
                        _iconRow(Icons.person, a['cliente_nombre'] ?? ''),
                        SizedBox(height: 8),
                        _iconRow(Icons.phone, a['cliente_telefono'] ?? ''),
                        SizedBox(height: 8),
                        _iconRow(
                          Icons.directions_car,
                          "${a['marca']} ${a['modelo']} - ${a['placa']}",
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 15),

                  // DESCRIPCION
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Descripción del problema",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          a['descripcion'] ?? '',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 25),

                  // BOTONES DE ESTADO
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        if (estado == 'aceptada')
                          _boton(
                            "Marcar En Camino",
                            Icons.directions_car,
                            Colors.orange,
                            () => actualizarEstado('en_camino'),
                          ),
                        if (estado == 'en_camino')
                          _boton(
                            "Marcar Atendiendo",
                            Icons.build,
                            Colors.blue,
                            () => actualizarEstado('en_servicio'),
                          ),
                        if (estado == 'en_servicio')
                          _boton(
                            "Finalizar y Registrar Pago",
                            Icons.check_circle,
                            Colors.green,
                            finalizarServicio,
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _card({required Widget child}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _iconRow(IconData icono, String texto) {
    return Row(
      children: [
        Icon(icono, color: Colors.grey, size: 18),
        SizedBox(width: 8),
        Expanded(child: Text(texto, style: TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _boton(String texto, IconData icono, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icono, color: Colors.white),
        label: Text(texto, style: TextStyle(color: Colors.white, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}
