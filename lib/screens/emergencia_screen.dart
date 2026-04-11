import 'package:flutter/material.dart';

class EmergenciaScreen extends StatefulWidget {
  @override
  _EmergenciaScreenState createState() => _EmergenciaScreenState();
}

class _EmergenciaScreenState extends State<EmergenciaScreen> {

  final TextEditingController descripcionController = TextEditingController();

  String ubicacion = "Santa Cruz - Bolivia";
  String imagen = "";

  void seleccionarImagen() {
    setState(() {
      imagen = "imagen_cargada";
    });
  }

  void enviarEmergencia() {
    String descripcion = descripcionController.text;

    if (descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Describe el problema")),
      );
      return;
    }

    print("Descripción: $descripcion");
    print("Ubicación: $ubicacion");
    print("Imagen: $imagen");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Emergencia enviada")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registrar Emergencia"),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [

            //  DESCRIPCIÓN
            TextField(
              controller: descripcionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Describe el problema",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            //  IMAGEN
            GestureDetector(
              onTap: seleccionarImagen,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: imagen.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40),
                          Text("Agregar imagen"),
                        ],
                      )
                    : Center(child: Text("Imagen cargada ✔")),
              ),
            ),

            SizedBox(height: 20),

            //  UBICACIÓN
            ListTile(
              leading: Icon(Icons.location_on, color: Colors.red),
              title: Text("Ubicación"),
              subtitle: Text(ubicacion),
            ),

            SizedBox(height: 30),

            //  BOTÓN ENVIAR
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: enviarEmergencia,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text("Enviar Emergencia"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}