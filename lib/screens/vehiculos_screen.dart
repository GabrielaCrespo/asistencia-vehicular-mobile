import 'package:flutter/material.dart';
import 'agregar_vehiculo_screen.dart';

class VehiculosScreen extends StatefulWidget {
  @override
  _VehiculosScreenState createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {

  // Por ahora lista simulada, luego vendrá del backend
  List<Map<String, String>> vehiculos = [
    {
      "marca": "Toyota",
      "modelo": "Corolla",
      "placa": "ABC-123",
      "color": "Blanco",
      "anio": "2020",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mis Vehículos"),
        centerTitle: true,
      ),

      body: vehiculos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "No tienes vehículos registrados",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(15),
              itemCount: vehiculos.length,
              itemBuilder: (context, index) {
                final v = vehiculos[index];
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.directions_car, color: Colors.white),
                    ),
                    title: Text(
                      "${v['marca']} ${v['modelo']}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Placa: ${v['placa']}"),
                        Text("Color: ${v['color']}  |  Año: ${v['anio']}"),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          vehiculos.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),

      // Botón para agregar vehículo
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final nuevoVehiculo = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AgregarVehiculoScreen()),
          );
          // Si el usuario guardó un vehículo, lo agrega a la lista
          if (nuevoVehiculo != null) {
            setState(() {
              vehiculos.add(nuevoVehiculo);
            });
          }
        },
      ),
    );
  }
}