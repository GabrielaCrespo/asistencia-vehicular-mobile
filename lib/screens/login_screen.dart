import 'package:flutter/material.dart';
import 'cliente_screen.dart';
import 'taller_screen.dart';
import 'admin_screen.dart';
import 'registro_screen.dart';  
import '../services/cliente_service.dart';
import '../services/session_service.dart';
import 'login_tecnico_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
bool _passwordVisible = false;
void login() async {
  String email = emailController.text.trim();
  String password = passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Completa todos los campos")),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(child: CircularProgressIndicator()),
  );

  final resultado = await ClienteService.login(
    email: email,
    password: password,
  );

  Navigator.pop(context);

  if (resultado['success']) {
    // Guardar sesión
    final data = resultado['data'];
    await SessionService.guardarSesion(
      usuarioId: data['user']['usuario_id'],
      nombre: data['user']['nombre'],
      email: data['user']['email'],
      token: data['access_token'],
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ClienteScreen()),
    );
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
  obscureText: _passwordVisible ? false : true,
  decoration: InputDecoration(
    labelText: "Contraseña",
    prefixIcon: Icon(Icons.lock),
    suffixIcon: IconButton(
      icon: Icon(
        _passwordVisible ? Icons.visibility : Icons.visibility_off,
        color: Colors.grey,
      ),
      onPressed: () {
        setState(() {
          _passwordVisible = !_passwordVisible;
        });
      },
    ),
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
TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginTecnicoScreen()),
    );
  },
  child: Text(
    "¿Eres técnico? Ingresa aquí",
    style: TextStyle(color: Colors.blue.shade700),
  ),
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
 