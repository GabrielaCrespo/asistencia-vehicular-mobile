import 'package:flutter/material.dart';
import '../services/tecnico_service.dart';
import '../services/session_service.dart';
import 'login_tecnico_screen.dart';
import 'tecnico_asignacion_screen.dart';

class TecnicoHomeScreen extends StatefulWidget {
  final int tecnicoId;
  final String nombre;
  final int tallerId;
  final String tallerNombre;

  TecnicoHomeScreen({
    required this.tecnicoId,
    required this.nombre,
    required this.tallerId,
    required this.tallerNombre,
  });

  @override
  _TecnicoHomeScreenState createState() => _TecnicoHomeScreenState();
}

class _TecnicoHomeScreenState extends State<TecnicoHomeScreen> {
  Map<String, dynamic>? asignacion;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarAsignacion();
  }

  void cargarAsignacion() async {
    final resultado = await TecnicoService.getAsignacion(widget.tecnicoId);
    setState(() {
      asignacion = resultado['asignacion'];
      cargando = false;
    });
  }

  void cerrarSesion() async {
    await SessionService.cerrarSesion();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginTecnicoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A237E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Portal Técnico",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: cerrarSesion,
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // HEADER
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: BoxDecoration(
                color: Color(0xFF1A237E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.engineering, color: Colors.white),
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hola, ${widget.nombre.split(' ')[0]} 👋",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.tallerNombre,
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // ASIGNACION ACTIVA
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Asignación actual",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: 10),

            cargando
                ? Center(child: CircularProgressIndicator())
                : asignacion == null
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
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
                            children: [
                              Icon(Icons.inbox, size: 50, color: Colors.grey),
                              SizedBox(height: 10),
                              Text(
                                "Sin asignaciones activas",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                "Espera que el taller te asigne un servicio",
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TecnicoAsignacionScreen(
                                  asignacion: asignacion!,
                                  tallerId: widget.tallerId,
                                  onActualizar: cargarAsignacion,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Servicio #${asignacion!['asignacion_id']}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        asignacion!['estado'].toString().toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Text(
                                  asignacion!['descripcion'] ?? '',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.person, size: 14, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      asignacion!['cliente_nombre'] ?? '',
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(Icons.directions_car, size: 14, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      "${asignacion!['marca']} ${asignacion!['modelo']} - ${asignacion!['placa']}",
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TecnicoAsignacionScreen(
                                            asignacion: asignacion!,
                                            tallerId: widget.tallerId,
                                            onActualizar: cargarAsignacion,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF1A237E),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      "Ver detalle",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

            SizedBox(height: 20),

            // BOTON ACTUALIZAR
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => cargando = true);
                    cargarAsignacion();
                  },
                  icon: Icon(Icons.refresh),
                  label: Text("Actualizar"),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}