import 'package:flutter/material.dart';
import 'cliente_screen.dart';
import 'taller_screen.dart';
import 'admin_screen.dart';
import 'registro_screen.dart';  

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

void login() {
  String email = emailController.text.trim();
  String password = passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Completa todos los campos")),
    );
    return;
  }

  // Por ahora simulado, luego llamará al backend
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ClienteScreen()),
  );
}
    

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.lightBlue],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [

            SizedBox(height: 80),

            Icon(Icons.car_repair, size: 80, color: Colors.white),

            SizedBox(height: 10),

            Text(
              "Asistencia Vehicular",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 40),

            Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [

                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Correo",
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),

                  SizedBox(height: 20),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),

                  SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: login,
                    child: Text("Iniciar sesión"),
                  ),

                  TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegistroScreen()),
    );
  },
  child: Text("¿No tienes cuenta? Regístrate"),
),
                ],
              ),
            )
          ],
        ),
      ),
    ),
  );
}
}
 