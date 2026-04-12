import 'package:flutter/material.dart';

class AgregarVehiculoScreen extends StatefulWidget {
  @override
  _AgregarVehiculoScreenState createState() => _AgregarVehiculoScreenState();
}

class _AgregarVehiculoScreenState extends State<AgregarVehiculoScreen> {

  final TextEditingController marcaController = TextEditingController();
  final TextEditingController modeloController = TextEditingController();
  final TextEditingController placaController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController anioController = TextEditingController();

  void guardar() {
    String marca = marcaController.text.trim();
    String modelo = modeloController.text.trim();
    String placa = placaController.text.trim();
    String color = colorController.text.trim();
    String anio = anioController.text.trim();

    if (marca.isEmpty || modelo.isEmpty || placa.isEmpty ||
        color.isEmpty || anio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    // Devuelve el vehículo a la pantalla anterior
    Navigator.pop(context, {
      "marca": marca,
      "modelo": modelo,
      "placa": placa,
      "color": color,
      "anio": anio,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Agregar Vehículo"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [

            Icon(Icons.directions_car, size: 80, color: Colors.blue),

            SizedBox(height: 20),

            TextField(
              controller: marcaController,
              decoration: InputDecoration(
                labelText: "Marca",
                prefixIcon: Icon(Icons.branding_watermark),
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 15),

            TextField(
              controller: modeloController,
              decoration: InputDecoration(
                labelText: "Modelo",
                prefixIcon: Icon(Icons.car_repair),
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 15),

            TextField(
              controller: placaController,
              decoration: InputDecoration(
                labelText: "Placa",
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 15),

            TextField(
              controller: colorController,
              decoration: InputDecoration(
                labelText: "Color",
                prefixIcon: Icon(Icons.color_lens),
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 15),

            TextField(
              controller: anioController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Año",
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: guardar,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text("Guardar Vehículo"),
              ),
            ),

          ],
        ),
      ),
    );
  }
}