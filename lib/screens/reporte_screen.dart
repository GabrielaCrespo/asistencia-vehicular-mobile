import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/session_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';

class ReporteScreen extends StatefulWidget {
  final int tallerId;
  ReporteScreen({required this.tallerId});

  @override
  _ReporteScreenState createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen>
    with SingleTickerProviderStateMixin {
  final String baseUrl =
    'https://asistencia-vehicular-backend.onrender.com/api/reportes/tecnico';
  String _token = '';
  int _tallerIdTecnico = 0;
  bool _exportando = false;
  String _tipoReporteVoz = 'historial-servicios';

  // Pestañas
  late TabController _tabController;

  // ── REPORTE ESTÁTICO ──────────────────────────────────
  String _tipoReporte = 'emergencias';
  String _fechaDesde = '';
  String _fechaHasta = '';
  bool _cargandoEstatico = false;
  List<Map<String, dynamic>> _filas = [];
  Map<String, dynamic> _resumen = {};
  String? _errorEstatico;

  final List<Map<String, dynamic>> _tiposReporte = [
    {
      'tipo': 'emergencias',
      'titulo': 'Emergencias Atendidas',
      'icono': Icons.warning_amber_rounded,
      'color': Color(0xFFEF4444),
    },
    {
      'tipo': 'historial-servicios',
      'titulo': 'Historial de Servicios',
      'icono': Icons.build_rounded,
      'color': Color(0xFF3B82F6),
    },
    {
      'tipo': 'calificaciones',
      'titulo': 'Calificaciones Recibidas',
      'icono': Icons.star_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'tipo': 'kpis',
      'titulo': 'KPIs Operacionales',
      'icono': Icons.bar_chart_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'tipo': 'incidentes-tipo',
      'titulo': 'Incidentes por Tipo',
      'icono': Icons.pie_chart_rounded,
      'color': Color(0xFF06B6D4),
    },
  ];

  // ── REPORTE POR VOZ ───────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _grabando = false;
  bool _procesandoVoz = false;
  String _textoConsulta = '';
  List<Map<String, dynamic>> _filasVoz = [];
  Map<String, dynamic> _resumenVoz = {};
  String? _mensajeConfirmacion;
  String? _errorVoz;
  final TextEditingController _consultaController = TextEditingController();

  final List<String> _ejemplos = [
    'Muéstrame las emergencias del último mes',
    'Genera un reporte de calificaciones de esta semana',
    'Muéstrame los KPIs de mi taller',
    'Incidentes de batería del último mes',
    'Reporte de servicios completados este año',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarSesion();
    _inicializarVoz();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _consultaController.dispose();
    super.dispose();
  }

  // ── FIX BUG 3: esperar que el token esté listo antes de llamar _cargarReporte ──
  void _cargarSesion() async {
    final sesion = await SessionService.getSesion();
    final token = sesion['token'] ?? '';
    final tallerId = widget.tallerId;

    setState(() {
      _token = token;
      _tallerIdTecnico = tallerId;
    });

    print('=== DEBUG: tallerId=$tallerId, token=$token');

    // Solo cargar si el token no está vacío
    if (token.isNotEmpty) {
      _cargarReporte();
    } else {
      setState(() {
        _errorEstatico = 'Sesión no válida. Vuelve a iniciar sesión.';
      });
    }
  }

  void _inicializarVoz() async {
    final available = await _speech.initialize(
      onError: (e) => setState(() => _grabando = false),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening')
          setState(() => _grabando = false);
      },
    );
    setState(() => _speechAvailable = available);
  }

  // ── REPORTE ESTÁTICO ──────────────────────────────────
  // ── FIX BUG 1: el taller_id viene del token JWT en el backend (SaaS),
  //    pero igual lo mandamos como param por si el endpoint lo acepta.
  //    Además manejamos mejor los errores con el status code real. ──
  void _cargarReporte() async {
    if (_token.isEmpty) return;
    setState(() {
      _cargandoEstatico = true;
      _errorEstatico = null;
      _filas = [];
      _resumen = {};
    });

    try {
      final params = <String, String>{};
      // Solo agregamos taller_id si el backend lo acepta como query param
      if (_tallerIdTecnico > 0) {
        params['taller_id'] = _tallerIdTecnico.toString();
      }
      if (_fechaDesde.isNotEmpty) params['fecha_desde'] = _fechaDesde;
      if (_fechaHasta.isNotEmpty) params['fecha_hasta'] = _fechaHasta;

      final uri = Uri.parse(
        '$baseUrl/$_tipoReporte',
      ).replace(queryParameters: params);

      print('=== DEBUG GET: $uri');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $_token'},
      );

      print('=== DEBUG status: ${response.statusCode}');
      print('=== DEBUG body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // El backend puede devolver datos en diferentes claves según el reporte
        final rawFilas = List<Map<String, dynamic>>.from(
          data['datos'] ??
              data['por_taller'] ??
              data['servicios'] ??
              data['calificaciones'] ??
              data['kpis'] ??
              data['incidentes'] ??
              [],
        );
        setState(() {
          _filas = rawFilas;
          _resumen = Map<String, dynamic>.from(data['resumen'] ?? {});
          _cargandoEstatico = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorEstatico = 'Sesión expirada. Vuelve a iniciar sesión.';
          _cargandoEstatico = false;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _errorEstatico = 'No tienes permiso para ver este reporte.';
          _cargandoEstatico = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorEstatico = 'Reporte no encontrado.';
          _cargandoEstatico = false;
        });
      } else {
        // Intentamos leer el mensaje de error del backend
        String mensajeError = 'Error al cargar el reporte';
        try {
          final errData = jsonDecode(response.body);
          mensajeError =
              errData['detail'] ?? errData['message'] ?? mensajeError;
        } catch (_) {}
        setState(() {
          _errorEstatico = mensajeError;
          _cargandoEstatico = false;
        });
      }
    } catch (e) {
      print('=== DEBUG error: $e');
      setState(() {
        _errorEstatico = 'Error de conexión. Verifica tu internet.';
        _cargandoEstatico = false;
      });
    }
  }

  // ── REPORTE POR VOZ ───────────────────────────────────
  void _toggleGrabacion() async {
    if (!_speechAvailable) return;
    if (_grabando) {
      await _speech.stop();
      setState(() => _grabando = false);
    } else {
      setState(() {
        _grabando = true;
        _errorVoz = null;
      });
      await _speech.listen(
        onResult: (result) {
          setState(() => _textoConsulta = result.recognizedWords);
          _consultaController.text = result.recognizedWords;
          if (result.finalResult) {
            setState(() => _grabando = false);
            _enviarConsulta();
          }
        },
        localeId: 'es_ES',
      );
    }
  }

  // ── FIX BUG 2: el endpoint /voz espera 'consulta' o 'texto' + taller_id correcto.
  //    Mandamos ambos por compatibilidad y logueamos la respuesta completa. ──
  void _enviarConsulta() async {
    final texto = _consultaController.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _procesandoVoz = true;
      _errorVoz = null;
      _filasVoz = [];
      _resumenVoz = {};
      _mensajeConfirmacion = null;
    });

    try {
      final body = {
        'texto': texto, // campo original
        'consulta': texto, // algunos backends usan 'consulta'
        'taller_id': _tallerIdTecnico,
      };

      print('=== DEBUG VOZ POST body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/voz'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('=== DEBUG VOZ status: ${response.statusCode}');
      print('=== DEBUG VOZ body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // El backend puede devolver resultado directo o anidado en 'resultado'
        final r = data['resultado'] ?? data;

        final rawFilas = List<Map<String, dynamic>>.from(
          r['datos'] ??
              r['por_taller'] ??
              r['servicios'] ??
              r['calificaciones'] ??
              r['kpis'] ??
              r['incidentes'] ??
              [],
        );

        setState(() {
          _filasVoz = rawFilas;
          _resumenVoz = Map<String, dynamic>.from(r['resumen'] ?? {});
          // Mensaje de confirmación: puede venir en distintas claves
          _mensajeConfirmacion =
              data['mensaje_confirmacion'] ??
              data['mensaje'] ??
              data['message'] ??
              'Reporte generado correctamente';
          _tipoReporteVoz = data['tipo_reporte'] ?? 'historial-servicios';
          _procesandoVoz = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorVoz = 'Sesión expirada. Vuelve a iniciar sesión.';
          _procesandoVoz = false;
        });
      } else if (response.statusCode == 422) {
        // Error de validación — el backend rechaza el body
        String detalle = 'Consulta no válida';
        try {
          final errData = jsonDecode(response.body);
          // FastAPI devuelve errores 422 con estructura {"detail": [...]}
          final detail = errData['detail'];
          if (detail is List && detail.isNotEmpty) {
            detalle = detail.map((e) => e['msg'] ?? e.toString()).join(', ');
          } else if (detail is String) {
            detalle = detail;
          }
        } catch (_) {}
        setState(() {
          _errorVoz = detalle;
          _procesandoVoz = false;
        });
      } else {
        String mensajeError = 'No se pudo interpretar la consulta';
        try {
          final errData = jsonDecode(response.body);
          mensajeError =
              errData['detail'] ?? errData['message'] ?? mensajeError;
        } catch (_) {}
        setState(() {
          _errorVoz = mensajeError;
          _procesandoVoz = false;
        });
      }
    } catch (e) {
      print('=== DEBUG VOZ error: $e');
      setState(() {
        _errorVoz = 'Error de conexión. Verifica tu internet.';
        _procesandoVoz = false;
      });
    }
  }

  // ── EXPORTAR ──────────────────────────────────────────
  void _exportar(String formato, {bool esVoz = false}) async {
    final tipo = esVoz ? _tipoReporteVoz : _tipoReporte;
    setState(() => _exportando = true);

    try {
      final params = <String, String>{'tipo': tipo, 'formato': formato};
      if (_fechaDesde.isNotEmpty) params['fecha_desde'] = _fechaDesde;
      if (_fechaHasta.isNotEmpty) params['fecha_hasta'] = _fechaHasta;

      final uri = Uri.parse(
        '$baseUrl/exportar',
      ).replace(queryParameters: params);
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        // Guardar archivo en descargas del dispositivo
        final ext = formato == 'excel' ? 'xlsx' : formato;
        final nombreArchivo =
            'reporte_${tipo}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        // Usar path_provider para guardar
        final dir = await _getDownloadDir();
        final file = File('$dir/$nombreArchivo');
        await file.writeAsBytes(response.bodyBytes);

        setState(() => _exportando = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Guardado: $nombreArchivo'),
              backgroundColor: Color(0xFF15803d),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        setState(() => _exportando = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al exportar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _exportando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String> _getDownloadDir() async {
    try {
      // path_provider — funciona en Android 10+
      final dir = await getExternalStorageDirectory();
      if (dir != null) {
        // Subir niveles hasta llegar a /Downloads
        final parts = dir.path.split('/');
        final androidIdx = parts.indexOf('Android');
        if (androidIdx > 0) {
          return '${parts.sublist(0, androidIdx).join('/')}/Download';
        }
        return dir.path;
      }
    } catch (_) {}
    return '/sdcard/Download';
  }

  Widget _buildBotonExportar({bool esVoz = false}) {
    final tienedatos = esVoz ? _filasVoz.isNotEmpty : _filas.isNotEmpty;
    if (!tienedatos) return SizedBox.shrink();
    return PopupMenuButton<String>(
      onSelected: (fmt) => _exportar(fmt, esVoz: esVoz),
      enabled: !_exportando,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(
                Icons.picture_as_pdf_rounded,
                color: Color(0xFFdc2626),
                size: 18,
              ),
              SizedBox(width: 8),
              Text('Exportar PDF'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'excel',
          child: Row(
            children: [
              Icon(
                Icons.table_chart_rounded,
                color: Color(0xFF15803d),
                size: 18,
              ),
              SizedBox(width: 8),
              Text('Exportar Excel'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              Icon(
                Icons.description_rounded,
                color: Color(0xFF2563eb),
                size: 18,
              ),
              SizedBox(width: 8),
              Text('Exportar CSV'),
            ],
          ),
        ),
      ],
      child: _exportando
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFF0f766e),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Exportar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFF5cbdb9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mis Reportes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Reportes'),
            Tab(icon: Icon(Icons.mic_rounded), text: 'Por Voz'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTabEstatico(), _buildTabVoz()],
      ),
    );
  }

  // ── TAB REPORTE ESTÁTICO ──────────────────────────────
  Widget _buildTabEstatico() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de reporte',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tiposReporte.length,
              separatorBuilder: (_, __) => SizedBox(width: 10),
              itemBuilder: (context, i) {
                final t = _tiposReporte[i];
                final activo = _tipoReporte == t['tipo'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _tipoReporte = t['tipo'];
                    });
                    _cargarReporte();
                  },
                  child: Container(
                    width: 120,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: activo
                          ? (t['color'] as Color).withOpacity(0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: activo
                            ? t['color'] as Color
                            : Colors.grey.shade200,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          t['icono'] as IconData,
                          color: t['color'] as Color,
                          size: 28,
                        ),
                        SizedBox(height: 6),
                        Text(
                          t['titulo'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: activo
                                ? t['color'] as Color
                                : Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 16),

          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtros',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildCampoFecha(
                        'Desde',
                        _fechaDesde,
                        (v) => setState(() => _fechaDesde = v),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildCampoFecha(
                        'Hasta',
                        _fechaHasta,
                        (v) => setState(() => _fechaHasta = v),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _cargandoEstatico ? null : _cargarReporte,
                        icon: Icon(Icons.search_rounded, size: 18),
                        label: Text(
                          _cargandoEstatico
                              ? 'Generando...'
                              : 'Generar reporte',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5cbdb9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    _buildBotonExportar(esVoz: false),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          if (_cargandoEstatico)
            Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(color: Color(0xFF5cbdb9)),
              ),
            )
          else if (_errorEstatico != null)
            _buildError(_errorEstatico!)
          else if (_filas.isEmpty)
            _buildVacio()
          else ...[
            if (_resumen.isNotEmpty) _buildResumen(_resumen),
            SizedBox(height: 12),
            _buildTabla(_filas),
          ],
        ],
      ),
    );
  }

  Widget _buildCampoFecha(
    String label,
    String valor,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final fecha = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2024),
              lastDate: DateTime.now(),
            );
            if (fecha != null)
              onChanged(
                '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
              );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
                SizedBox(width: 6),
                Text(
                  valor.isEmpty ? 'Seleccionar' : valor,
                  style: TextStyle(
                    fontSize: 12,
                    color: valor.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── TAB VOZ ───────────────────────────────────────────
  Widget _buildTabVoz() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _toggleGrabacion,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _grabando ? Colors.red : Color(0xFF5cbdb9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_grabando ? Colors.red : Color(0xFF5cbdb9))
                              .withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: _grabando ? 5 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _grabando ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _grabando
                      ? 'Escuchando... habla ahora'
                      : _procesandoVoz
                      ? 'Procesando...'
                      : 'Presiona para hablar',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 16),

                TextField(
                  controller: _consultaController,
                  onChanged: (v) => _textoConsulta = v,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Ej: Muéstrame las emergencias del último mes',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF5cbdb9)),
                    ),
                    contentPadding: EdgeInsets.all(12),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.send_rounded, color: Color(0xFF5cbdb9)),
                      onPressed: _procesandoVoz ? null : _enviarConsulta,
                    ),
                  ),
                ),

                SizedBox(height: 14),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Prueba con estos ejemplos:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ejemplos
                      .map(
                        (e) => GestureDetector(
                          onTap: () {
                            _consultaController.text = e;
                            _textoConsulta = e;
                            _enviarConsulta();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFf0fdfc),
                              border: Border.all(color: Color(0xFF99f6e4)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              e,
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF0f766e),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          if (_procesandoVoz)
            Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(color: Color(0xFF5cbdb9)),
              ),
            )
          else if (_errorVoz != null)
            _buildError(_errorVoz!)
          else if (_mensajeConfirmacion != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFFe0f2fe),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF0369a1),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _mensajeConfirmacion!,
                      style: TextStyle(color: Color(0xFF0369a1), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_buildBotonExportar(esVoz: true)],
            ),
            SizedBox(height: 8),
            if (_resumenVoz.isNotEmpty) _buildResumen(_resumenVoz),
            SizedBox(height: 12),
            if (_filasVoz.isNotEmpty) _buildTabla(_filasVoz),
            if (_filasVoz.isEmpty) _buildVacio(),
          ],
        ],
      ),
    );
  }

  // ── WIDGETS COMUNES ───────────────────────────────────
  Widget _buildResumen(Map<String, dynamic> resumen) {
    final items = resumen.entries.where((e) => e.value is! Map).toList();
    if (items.isEmpty) return SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: items.map((e) {
          final val = e.value;
          String valStr = val.toString();
          Color valColor = Colors.black87;
          if (e.key.contains('ingreso') || e.key.contains('monto')) {
            valStr =
                'Bs. ${double.tryParse(val.toString())?.toStringAsFixed(2) ?? val}';
            valColor = Color(0xFF15803d);
          } else if (e.key.contains('pct')) {
            valStr =
                '${double.tryParse(val.toString())?.toStringAsFixed(1) ?? val}%';
            valColor = Color(0xFF2563eb);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valStr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: valColor,
                ),
              ),
              Text(
                e.key.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabla(List<Map<String, dynamic>> filas) {
    if (filas.isEmpty) return _buildVacio();
    final columnas = filas.first.keys.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Text(
                  '${filas.length} registro(s)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              dataRowMaxHeight: 50,
              columnSpacing: 16,
              columns: columnas
                  .map(
                    (c) => DataColumn(
                      label: Text(
                        c.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              rows: filas
                  .take(20)
                  .map(
                    (fila) => DataRow(
                      cells: columnas.map((c) {
                        final val = fila[c]?.toString() ?? '—';
                        return DataCell(
                          Text(
                            val.length > 15
                                ? '${val.substring(0, 15)}...'
                                : val,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (filas.length > 20)
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Mostrando 20 de ${filas.length} registros',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(String msg) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFfef2f2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFfecaca)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Color(0xFFdc2626)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(color: Color(0xFFdc2626), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVacio() {
    return Container(
      padding: EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 50, color: Colors.grey.shade300),
          SizedBox(height: 10),
          Text(
            'Sin datos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          Text(
            'Ajusta los filtros y genera el reporte',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
