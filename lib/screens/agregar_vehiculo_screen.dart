import 'package:flutter/material.dart';
import '../services/vehiculo_service.dart';
import '../services/session_service.dart';

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

  void guardar() async {
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

    if (int.tryParse(anio) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("El año debe ser un número válido")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    final sesion = await SessionService.getSesion();
    final usuarioId = sesion['usuario_id'] ?? 0;

    final resultado = await VehiculoService.registrar(
      usuarioId: usuarioId,
      placa: placa,
      marca: marca,
      modelo: modelo,
      anio: int.parse(anio),
      color: color,
    );

    Navigator.pop(context);

    if (resultado['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vehículo registrado correctamente"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message']),
          backgroundColor: Colors.red,
        ),
      );
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
          "Agregar Vehículo",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
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
                    child: Icon(Icons.directions_car, color: Colors.blue, size: 30),
                  ),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Nuevo Vehículo",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "Completa los datos del vehículo",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

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
                  children: [

                    TextField(
                      controller: marcaController,
                      decoration: InputDecoration(
                        labelText: "Marca",
                        prefixIcon: Icon(Icons.branding_watermark),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    TextField(
                      controller: modeloController,
                      decoration: InputDecoration(
                        labelText: "Modelo",
                        prefixIcon: Icon(Icons.car_repair),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    TextField(
                      controller: placaController,
                      decoration: InputDecoration(
                        labelText: "Placa",
                        prefixIcon: Icon(Icons.credit_card),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    TextField(
                      controller: colorController,
                      decoration: InputDecoration(
                        labelText: "Color",
                        prefixIcon: Icon(Icons.color_lens),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    TextField(
                      controller: anioController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Año",
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Guardar Vehículo",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
}