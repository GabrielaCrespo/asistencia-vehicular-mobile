import 'package:flutter/material.dart';
import 'agregar_vehiculo_screen.dart';

class VehiculosScreen extends StatefulWidget {
  @override
  _VehiculosScreenState createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {

  List<Map<String, String>> vehiculos = [
    {
      "marca": "Toyota",
      "modelo": "Corolla",
      "placa": "ABC-123",
      "color": "Blanco",
      "anio": "2020",
    },
  ];

  void eliminarVehiculo(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Eliminar vehículo"),
        content: Text("¿Estás seguro que deseas eliminar este vehículo?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                vehiculos.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text("Eliminar", style: TextStyle(color: Colors.white)),
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
          "Mis Vehículos",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
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
                      "Mis Vehículos",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "${vehiculos.length} vehículo(s) registrado(s)",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // LISTA O EMPTY STATE
          Expanded(
            child: vehiculos.isEmpty
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
                            Icons.directions_car,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          "Sin vehículos registrados",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Agrega tu primer vehículo",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: vehiculos.length,
                    itemBuilder: (context, index) {
                      final v = vehiculos[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 15),
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
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Row(
                            children: [

                              // ICONO
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.directions_car, color: Colors.blue, size: 28),
                              ),

                              SizedBox(width: 15),

                              // INFO
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${v['marca']} ${v['modelo']}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.credit_card, size: 13, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          v['placa']!,
                                          style: TextStyle(color: Colors.grey, fontSize: 13),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(Icons.circle, size: 8, color: Colors.grey.shade300),
                                        SizedBox(width: 10),
                                        Icon(Icons.color_lens, size: 13, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          v['color']!,
                                          style: TextStyle(color: Colors.grey, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          "Año ${v['anio']}",
                                          style: TextStyle(color: Colors.grey, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // BOTON ELIMINAR
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                                onPressed: () => eliminarVehiculo(index),
                              ),

                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // BOTON AGREGAR
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text("Agregar", style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final nuevoVehiculo = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AgregarVehiculoScreen()),
          );
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