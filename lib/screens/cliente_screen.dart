import 'package:flutter/material.dart';
import 'emergencia_screen.dart';
import 'vehiculos_screen.dart';
import '../services/session_service.dart';
import 'login_screen.dart';
import 'perfil_screen.dart';

class ClienteScreen extends StatefulWidget {
  @override
  _ClienteScreenState createState() => _ClienteScreenState();
}

class _ClienteScreenState extends State<ClienteScreen> {
  String nombre = "";
  String email = "";
int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
    cargarSesion();
  }

  void cargarSesion() async {
    final sesion = await SessionService.getSesion();
    setState(() {
      nombre = sesion['nombre'] ?? "Cliente";
      email = sesion['email'] ?? "";
    });
  }

  void cerrarSesion() async {
    await SessionService.cerrarSesion();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }
void _onTabTapped(int index) {
  if (index == 2) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PerfilScreen()),
    );
  } else {
    setState(() => _selectedIndex = index);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Inicio",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.grey),
            onPressed: cerrarSesion,
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // HEADER
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hola, ${nombre.split(' ')[0]} 👋",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        "Santa Cruz - Bolivia",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 25),

            // BOTON EMERGENCIA
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "¿Necesitas ayuda?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: 15),

            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EmergenciaScreen()),
                  );
                },
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFE53935).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_rounded, color: Colors.white, size: 40),
                      SizedBox(height: 8),
                      Text(
                        "EMERGENCIA",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 25),

            // ESTADO SOLICITUD
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Estado actual",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: 10),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(18),
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
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.inbox, color: Colors.grey),
                    ),
                    SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sin solicitudes activas",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "Presiona emergencia para solicitar ayuda",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 25),

            // ACCESOS RAPIDOS
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Accesos rápidos",
                style: TextStyle(
                  fontSize: 16,
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.directions_car, color: Colors.blue),
                  ),
                  title: Text(
                    "Mis Vehículos",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text("Gestiona tus vehículos registrados"),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => VehiculosScreen()),
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: 30),

          ],
        ),
      ),

    bottomNavigationBar: BottomNavigationBar(
  backgroundColor: Colors.white,
  selectedItemColor: Colors.black87,
  unselectedItemColor: Colors.grey,
  elevation: 10,
  currentIndex: _selectedIndex,
  onTap: _onTabTapped,
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