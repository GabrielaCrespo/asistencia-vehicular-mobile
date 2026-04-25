import 'package:flutter/material.dart';
import '../services/taller_service.dart';
import '../services/emergencia_service.dart';

class TalleresScreen extends StatefulWidget {
  final double latitud;
  final double longitud;
  final String tipoProblema;
  final int incidenteId;

  TalleresScreen({
    required this.latitud,
    required this.longitud,
    required this.tipoProblema,
    required this.incidenteId,
  });

  @override
  _TalleresScreenState createState() => _TalleresScreenState();
}

class _TalleresScreenState extends State<TalleresScreen> {
  List<Map<String, dynamic>> talleres = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarTalleres();
  }

  void cargarTalleres() async {
    final resultado = await TallerService.obtenerCandidatos(
      latitud: widget.latitud,
      longitud: widget.longitud,
      tipoProblema: widget.tipoProblema,
    );

    if (resultado['success']) {
      setState(() {
        talleres = List<Map<String, dynamic>>.from(resultado['talleres']);
        cargando = false;
      });
    } else {
      setState(() => cargando = false);
    }
  }

  void seleccionarTaller(Map<String, dynamic> taller) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Solicitar servicio"),
        content: Text("¿Deseas solicitar asistencia a ${taller['razon_social']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Solicitud enviada a ${taller['razon_social']}"),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text("Confirmar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
          "Talleres Disponibles",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: cargando
          ? Center(child: CircularProgressIndicator())
          : talleres.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_mall_directory,
                          size: 80, color: Colors.grey),
                      SizedBox(height: 15),
                      Text(
                        "No hay talleres disponibles",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Intenta más tarde",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
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
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.store, color: Colors.red, size: 30),
                          ),
                          SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Talleres Cercanos",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                "${talleres.length} talleres encontrados",
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 15),

                    // LISTA
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: talleres.length,
                        itemBuilder: (context, index) {
                          final taller = talleres[index];
                          return GestureDetector(
                            onTap: () => seleccionarTaller(taller),
                            child: Container(
                              margin: EdgeInsets.only(bottom: 15),
                              padding: EdgeInsets.all(15),
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
                              child: Row(
                                children: [

                                  // ICONO
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.store, color: Colors.blue, size: 28),
                                  ),

                                  SizedBox(width: 15),

                                  // INFO
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          taller['razon_social'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          taller['direccion'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                size: 14, color: Colors.red),
                                            SizedBox(width: 4),
                                            Text(
                                              "${taller['distancia_km']} km",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(width: 15),
                                            Icon(Icons.access_time,
                                                size: 14, color: Colors.orange),
                                            SizedBox(width: 4),
                                            Text(
                                              "${taller['tiempo_minutos']} min",
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // FLECHA
                                  Icon(Icons.arrow_forward_ios,
                                      size: 16, color: Colors.grey),
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