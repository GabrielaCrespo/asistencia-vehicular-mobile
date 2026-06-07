import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/session_service.dart';

class ChatScreen extends StatefulWidget {
  final int incidenteId;
  final String otroNombre;
  final WebSocketChannel? channel;

  ChatScreen({
    required this.incidenteId,
    required this.otroNombre,
    this.channel,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _mensajes = [];
  bool _cargando = true;
  int _usuarioId = 0;
  String _token = '';

  @override
  void initState() {
    super.initState();
    _cargarSesionYMensajes();
    _escucharWebSocket();
  }

  void _cargarSesionYMensajes() async {
    final sesion = await SessionService.getSesion();
    _usuarioId = sesion['usuario_id'] ?? 0;
    _token = sesion['token'] ?? '';
    await _cargarMensajes();
  }

  Future<void> _cargarMensajes() async {
    try {
      final response = await http.get(
        Uri.parse('https://asistencia-vehicular-backend.onrender.com/api/chat/${widget.incidenteId}/mensajes'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _mensajes = List<Map<String, dynamic>>.from(data['mensajes']);
          _cargando = false;
        });
        _scrollAlFinal();
      }
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  void _escucharWebSocket() {
    widget.channel?.stream.listen((mensaje) {
      try {
        final data = jsonDecode(mensaje);
        if (data['tipo'] == 'chat_mensaje' &&
            data['incidente_id'] == widget.incidenteId) {
          setState(() {
            _mensajes.add(Map<String, dynamic>.from(data));
          });
          _scrollAlFinal();
        }
      } catch (e) {}
    });
  }

  void _scrollAlFinal() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _enviarMensaje() {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    // Agregar mensaje localmente
    setState(() {
      _mensajes.add({
        'usuario_id': _usuarioId,
        'mensaje': texto,
        'fecha_creacion': DateTime.now().toIso8601String(),
        'remitente_nombre': 'Tú',
        'rol': 'cliente',
      });
    });

    // Enviar por WebSocket
    widget.channel?.sink.add(jsonEncode({
      'tipo': 'chat_mensaje',
      'incidente_id': widget.incidenteId,
      'mensaje': texto,
    }));

    _mensajeController.clear();
    _scrollAlFinal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 18,
            child: Icon(Icons.person, color: Colors.blue.shade700, size: 20),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.otroNombre,
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              Text("En línea", style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ]),
      ),
      body: Column(
        children: [
          // MENSAJES
          Expanded(
            child: _cargando
                ? Center(child: CircularProgressIndicator())
                : _mensajes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade400),
                            SizedBox(height: 10),
                            Text("No hay mensajes aún",
                                style: TextStyle(color: Colors.grey, fontSize: 14)),
                            Text("Envía un mensaje al técnico",
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        itemCount: _mensajes.length,
                        itemBuilder: (context, index) {
                          final msg = _mensajes[index];
                          final esMio = msg['usuario_id'] == _usuarioId;
                          return _buildMensaje(msg, esMio);
                        },
                      ),
          ),

          // INPUT
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _mensajeController,
                  decoration: InputDecoration(
                    hintText: "Escribe un mensaje...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onSubmitted: (_) => _enviarMensaje(),
                ),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTap: _enviarMensaje,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildMensaje(Map<String, dynamic> msg, bool esMio) {
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!esMio)
              Padding(
                padding: EdgeInsets.only(left: 5, bottom: 3),
                child: Text(
                  msg['remitente_nombre'] ?? 'Técnico',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: esMio ? Colors.blue.shade700 : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: esMio ? Radius.circular(18) : Radius.circular(4),
                  bottomRight: esMio ? Radius.circular(4) : Radius.circular(18),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
              ),
              child: Text(
                msg['mensaje'] ?? '',
                style: TextStyle(
                  color: esMio ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 3, left: 5, right: 5),
              child: Text(
                _formatearFecha(msg['fecha_creacion']),
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return '';
    try {
      final dt = DateTime.parse(fecha).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}