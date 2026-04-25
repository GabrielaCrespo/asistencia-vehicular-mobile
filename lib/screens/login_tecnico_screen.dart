import 'package:flutter/material.dart';
import '../services/tecnico_service.dart';
import '../services/session_service.dart';
import 'tecnico_home_screen.dart';

class LoginTecnicoScreen extends StatefulWidget {
  @override
  _LoginTecnicoScreenState createState() => _LoginTecnicoScreenState();
}

class _LoginTecnicoScreenState extends State<LoginTecnicoScreen> {
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

    final resultado = await TecnicoService.login(
      email: email,
      password: password,
    );

    Navigator.pop(context);

    if (resultado['success']) {
      final data = resultado['data'];
      await SessionService.guardarSesion(
        usuarioId: data['tecnico_id'],
        nombre: data['nombre'],
        email: email,
        token: data['access_token'],
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TecnicoHomeScreen(
            tecnicoId: data['tecnico_id'],
            nombre: data['nombre'],
            tallerId: data['taller_id'],
            tallerNombre: data['taller_nombre'],
          ),
        ),
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
            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [

              SizedBox(height: 80),

              Icon(Icons.engineering, size: 80, color: Colors.white),

              SizedBox(height: 10),

              Text(
                "Portal Técnico",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 5),

              Text(
                "Inicia sesión para ver tus asignaciones",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),

              SizedBox(height: 40),

              Container(
                padding: EdgeInsets.all(25),
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    TextField(
                      controller: passwordController,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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

                    SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1A237E),
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Iniciar sesión",
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

              SizedBox(height: 30),

            ],
          ),
        ),
      ),
    );
  }
}