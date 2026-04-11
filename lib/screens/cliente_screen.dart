import 'package:flutter/material.dart';
import 'emergencia_screen.dart';

class ClienteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cliente"),
        centerTitle: true,
      ),

      body: Column(
        children: [

          SizedBox(height: 20),

          // 👤 BIENVENIDA
          Text(
            "Bienvenido",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 20),

          //  BOTON EMERGENCIA
          GestureDetector(
           onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EmergenciaScreen(),
    ),
  );
},
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "EMERGENCIA",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 30),

          //  ESTADO
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  "Estado de tu solicitud",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text("Sin solicitudes activas"),
              ],
            ),
          ),

          SizedBox(height: 20),

          //  UBICACION (SIMULADA)
          ListTile(
            leading: Icon(Icons.location_on, color: Colors.red),
            title: Text("Ubicación"),
            subtitle: Text("Santa Cruz - Bolivia"),
          ),

        ],
      ),

      // MENU ABAJO
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Inicio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Historial",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}
