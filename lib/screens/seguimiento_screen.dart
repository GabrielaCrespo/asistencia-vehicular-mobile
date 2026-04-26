import 'package:flutter/material.dart';
import '../services/emergencia_service.dart';

class SeguimientoScreen extends StatefulWidget {
  final int incidenteId;

  SeguimientoScreen({required this.incidenteId});

  @override
  _SeguimientoScreenState createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  Map<String, dynamic>? incidente;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDetalle();
  }

  void cargarDetalle() async {
    final resultado = await EmergenciaService.obtenerDetalle(
      widget.incidenteId,
    );
    if (resultado['success']) {
      setState(() {
        incidente = resultado['incidente'];
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
      case 'asignada':
        return Colors.blue;
      case 'en_camino':
        return Colors.blue;
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

                          // PASO 1
                          _buildPaso(
                            "Solicitud enviada",
                            "Tu emergencia fue registrada",
                            true,
                            Icons.check_circle,
                            Colors.green,
                          ),

                          // PASO 2
                          _buildPaso(
                            "Taller asignado",
                            incidente!['taller_nombre'] != null
                                ? "Taller asignado"
                                : "Buscando el taller más cercano",
                            incidente!['taller_nombre'] != null,
                            incidente!['taller_nombre'] != null
                                ? Icons.check_circle
                                : Icons.access_time,
                            incidente!['taller_nombre'] != null
                                ? Colors.green
                                : Colors.orange,
                          ),

                          // PASO 3
                          _buildPaso(
                            "En camino",
                            incidente!['estado'] == 'en_camino' ||
                                    incidente!['estado'] == 'en_servicio' ||
                                    incidente!['estado'] == 'atendido' ||
                                    incidente!['estado'] == 'cerrada'
                                ? "El técnico está en camino"
                                : "Esperando confirmación",
                            incidente!['estado'] == 'en_camino' ||
                                incidente!['estado'] == 'en_servicio' ||
                                incidente!['estado'] == 'atendido' ||
                                incidente!['estado'] == 'cerrada',
                            incidente!['estado'] == 'en_camino' ||
                                    incidente!['estado'] == 'en_servicio' ||
                                    incidente!['estado'] == 'atendido' ||
                                    incidente!['estado'] == 'cerrada'
                                ? Icons.check_circle
                                : Icons.access_time,
                            incidente!['estado'] == 'en_camino' ||
                                    incidente!['estado'] == 'en_servicio' ||
                                    incidente!['estado'] == 'atendido' ||
                                    incidente!['estado'] == 'cerrada'
                                ? Colors.green
                                : Colors.grey,
                          ),

                          // PASO 4
                          _buildPaso(
                            "Servicio completado",
                            incidente!['estado'] == 'atendido' ||
                                    incidente!['estado'] == 'cerrada'
                                ? "Tu vehículo fue atendido"
                                : "Pendiente",
                            incidente!['estado'] == 'atendido' ||
                                incidente!['estado'] == 'cerrada',
                            incidente!['estado'] == 'atendido' ||
                                    incidente!['estado'] == 'cerrada'
                                ? Icons.check_circle
                                : Icons.access_time,
                            incidente!['estado'] == 'atendido' ||
                                    incidente!['estado'] == 'cerrada'
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

                  SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildPaso(
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
