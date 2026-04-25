import 'package:flutter/material.dart';
import '../services/tecnico_service.dart';

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
  _TecnicoAsignacionScreenState createState() => _TecnicoAsignacionScreenState();
}

class _TecnicoAsignacionScreenState extends State<TecnicoAsignacionScreen> {
  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController montoController = TextEditingController();
  String metodoPago = "efectivo";
  bool procesando = false;

  Future<void> actualizarEstado(String estado) async {
    setState(() => procesando = true);

    final resultado = await TecnicoService.actualizarEstado(
      asignacionId: widget.asignacion['asignacion_id'],
      estado: estado,
    );

    setState(() => procesando = false);

    if (resultado['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Estado actualizado correctamente"),
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Finalizar servicio"),
        content: Column(
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
                labelText: "Observaciones del servicio",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: metodoPago,
              decoration: InputDecoration(
                labelText: "Método de pago",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: [
                DropdownMenuItem(value: "efectivo", child: Text("Efectivo")),
                DropdownMenuItem(value: "transferencia", child: Text("Transferencia")),
                DropdownMenuItem(value: "qr", child: Text("QR")),
              ],
              onChanged: (value) => setState(() => metodoPago = value!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (montoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Ingresa el monto cobrado")),
                );
                return;
              }
              Navigator.pop(context);
              setState(() => procesando = true);

              final resultado = await TecnicoService.registrarPago(
                asignacionId: widget.asignacion['asignacion_id'],
                tallerId: widget.tallerId,
                monto: double.parse(montoController.text.trim()),
                observaciones: observacionesController.text.trim(),
                metodoPago: metodoPago,
              );

              setState(() => procesando = false);

              if (resultado['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Servicio finalizado correctamente"),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.asignacion;

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
      ),

      body: procesando
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [

                  // HEADER ESTADO
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
                        SizedBox(height: 5),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            a['estado'].toString().toUpperCase(),
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // INFO CLIENTE
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
                            "Información del cliente",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 15),
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.grey, size: 18),
                              SizedBox(width: 8),
                              Text(a['cliente_nombre'] ?? ''),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.phone, color: Colors.grey, size: 18),
                              SizedBox(width: 8),
                              Text(a['cliente_telefono'] ?? ''),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.directions_car, color: Colors.grey, size: 18),
                              SizedBox(width: 8),
                              Text("${a['marca']} ${a['modelo']} - ${a['placa']}"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 15),

                  // DESCRIPCION
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
                  ),

                  SizedBox(height: 15),

                  // UBICACION
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
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.location_on, color: Colors.red),
                        ),
                        title: Text(
                          "Ubicación del cliente",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "Lat: ${a['latitud']}, Lng: ${a['longitud']}",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 25),

                  // BOTONES DE ESTADO
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [

                        if (a['estado'] == 'aceptada')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => actualizarEstado('en_camino'),
                              icon: Icon(Icons.directions_car, color: Colors.white),
                              label: Text(
                                "Marcar En Camino",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),

                        if (a['estado'] == 'en_camino')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => actualizarEstado('en_servicio'),
                              icon: Icon(Icons.build, color: Colors.white),
                              label: Text(
                                "Marcar Atendiendo",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),

                        if (a['estado'] == 'en_servicio')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: finalizarServicio,
                              icon: Icon(Icons.check_circle, color: Colors.white),
                              label: Text(
                                "Finalizar y Registrar Pago",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
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
}