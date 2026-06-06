import 'package:flutter/material.dart';
import '../services/emergencia_service.dart';
import '../services/session_service.dart';
import '../services/stripe_service.dart';
import 'seguimiento_screen.dart';
import 'calificacion_screen.dart';
import 'pago_screen.dart';

class HistorialScreen extends StatefulWidget {
  @override
  _HistorialScreenState createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Map<String, dynamic>> emergencias = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarHistorial();
  }

  void cargarHistorial() async {
    final sesion = await SessionService.getSesion();
    final usuarioId = sesion['usuario_id'] ?? 0;
    final token = sesion['token'] as String? ?? '';

    final resultado = await EmergenciaService.listar(usuarioId, token: token);
    if (resultado['success']) {
      setState(() {
        emergencias = List<Map<String, dynamic>>.from(resultado['emergencias']);
        cargando = false;
      });
    } else {
      setState(() => cargando = false);
    }
  }

  Color getColorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return Colors.blue;
      case 'atendido':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData getIconoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.access_time;
      case 'en_proceso':
        return Icons.build;
      case 'atendido':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String getTextoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
        return 'En Proceso';
      case 'atendido':
        return 'Atendido';
      default:
        return 'Desconocido';
    }
  }

  String formatearFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return fecha;
    }
  }

  bool _esServicioFinalizado(String estado) {
    const finalizados = {'atendido', 'cerrada', 'completado', 'finalizado'};
    return finalizados.contains(estado);
  }

  Future<void> _abrirPago(int incidenteId) async {
    final pago = await StripeService.getPagoIncidente(incidenteId);
    if (!mounted) return;

    if (pago == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró un pago pendiente para este servicio')),
      );
      return;
    }

    if (pago['estado'] == 'completado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este servicio ya fue pagado'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    final pagado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PagoScreen(
          pagoId: pago['pago_id'] as int,
          monto: (pago['monto_total'] as num).toDouble(),
          incidenteId: incidenteId,
        ),
      ),
    );

    if (pagado == true) cargarHistorial();
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
          "Historial",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue),
            onPressed: () {
              setState(() => cargando = true);
              cargarHistorial();
            },
          ),
        ],
      ),

      body: cargando
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [

                // HEADER
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.history, color: Colors.blue, size: 30),
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Mis Emergencias",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "${emergencias.length} registro(s)",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 15),

                // LISTA O EMPTY STATE
                Expanded(
                  child: emergencias.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.history,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              SizedBox(height: 15),
                              Text(
                                "Sin historial",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Aún no tienes emergencias registradas",
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          itemCount: emergencias.length,
                          itemBuilder: (context, index) {
                            final e = emergencias[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SeguimientoScreen(
                                      incidenteId: e['incidente_id'],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 15),
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // ICONO ESTADO
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: getColorEstado(e['estado']).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            getIconoEstado(e['estado']),
                                            color: getColorEstado(e['estado']),
                                            size: 28,
                                          ),
                                        ),

                                        SizedBox(width: 15),

                                        // INFO
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    "Emergencia #${e['incidente_id']}",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: getColorEstado(e['estado']).withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      getTextoEstado(e['estado']),
                                                      style: TextStyle(
                                                        color: getColorEstado(e['estado']),
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                "${e['marca'] ?? ''} ${e['modelo'] ?? ''} - ${e['placa'] ?? ''}",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today,
                                                      size: 12, color: Colors.grey),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    formatearFecha(e['fecha_creacion'].toString()),
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

                                        Icon(Icons.arrow_forward_ios,
                                            size: 16, color: Colors.grey),
                                      ],
                                    ),

                                    // BOTONES (solo servicios finalizados)
                                    if (_esServicioFinalizado(e['estado'])) ...[
                                      SizedBox(height: 12),
                                      Divider(height: 1, color: Colors.grey.shade200),
                                      SizedBox(height: 12),
                                      Row(children: [
                                        // Pagar
                                        Expanded(
                                          child: SizedBox(
                                            height: 38,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _abrirPago(e['incidente_id'] as int),
                                              icon: Icon(Icons.payment, size: 16),
                                              label: Text('Pagar',
                                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFF1A237E),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10)),
                                                elevation: 0,
                                                padding: EdgeInsets.symmetric(horizontal: 8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        // Valorar
                                        Expanded(
                                          child: SizedBox(
                                            height: 38,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => CalificacionScreen(
                                                      incidenteId: e['incidente_id'],
                                                      tallerNombre: e['taller_nombre'] as String?,
                                                      tipoProblema: e['tipo_problema'] as String?,
                                                      fechaCreacion: e['fecha_creacion']?.toString(),
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: Icon(Icons.star_border_rounded, size: 16),
                                              label: Text('Valorar',
                                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFF5cbdb9),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10)),
                                                elevation: 0,
                                                padding: EdgeInsets.symmetric(horizontal: 8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ]),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}