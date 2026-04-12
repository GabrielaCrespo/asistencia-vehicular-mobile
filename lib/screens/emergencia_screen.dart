import 'package:flutter/material.dart';

class EmergenciaScreen extends StatefulWidget {
  @override
  _EmergenciaScreenState createState() => _EmergenciaScreenState();
}

class _EmergenciaScreenState extends State<EmergenciaScreen> {

  final TextEditingController descripcionController = TextEditingController();

  String ubicacion = "Santa Cruz - Bolivia";
  String imagen = "";
  bool audioGrabado = false;

  void seleccionarImagen() {
    setState(() {
      imagen = "imagen_cargada";
    });
  }

  void grabarAudio() {
    setState(() {
      audioGrabado = !audioGrabado;
    });
  }

  void enviarEmergencia() {
    String descripcion = descripcionController.text.trim();

    if (descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Describe el problema")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Emergencia enviada correctamente"),
        backgroundColor: Colors.green,
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
          "Registrar Emergencia",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: Icon(Icons.warning_rounded, color: Colors.red, size: 30),
                  ),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Nueva Emergencia",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "Completa la información del incidente",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // DESCRIPCION
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Descripción del problema",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: 10),

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
                child: TextField(
                  controller: descripcionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Ej: Mi auto no enciende, la batería parece descargada...",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.all(15),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // EVIDENCIAS
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Evidencias",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: 10),

            // IMAGEN Y AUDIO
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [

                  // IMAGEN
                  Expanded(
                    child: GestureDetector(
                      onTap: seleccionarImagen,
                      child: Container(
                        height: 120,
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              imagen.isEmpty ? Icons.camera_alt : Icons.check_circle,
                              size: 35,
                              color: imagen.isEmpty ? Colors.grey : Colors.green,
                            ),
                            SizedBox(height: 8),
                            Text(
                              imagen.isEmpty ? "Agregar foto" : "Foto cargada",
                              style: TextStyle(
                                color: imagen.isEmpty ? Colors.grey : Colors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 15),

                  // AUDIO
                  Expanded(
                    child: GestureDetector(
                      onTap: grabarAudio,
                      child: Container(
                        height: 120,
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              audioGrabado ? Icons.check_circle : Icons.mic,
                              size: 35,
                              color: audioGrabado ? Colors.green : Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              audioGrabado ? "Audio grabado" : "Grabar audio",
                              style: TextStyle(
                                color: audioGrabado ? Colors.green : Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),

            SizedBox(height: 20),

            // UBICACION
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Ubicación",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: 10),

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
                    "Ubicación actual",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(ubicacion),
                  trailing: Icon(Icons.my_location, color: Colors.grey),
                ),
              ),
            ),

            SizedBox(height: 30),

            // BOTON ENVIAR
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: enviarEmergencia,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE53935),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "Enviar Emergencia",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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