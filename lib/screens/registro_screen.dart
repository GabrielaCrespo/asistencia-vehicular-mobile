import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/cliente_service.dart';

class RegistroScreen extends StatefulWidget {
  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmarPasswordController = TextEditingController();
  final TextEditingController documentoController = TextEditingController();

  void registrar() async {
  String nombre = nombreController.text.trim();
  String apellido = apellidoController.text.trim();
  String email = emailController.text.trim();
  String telefono = telefonoController.text.trim();
  String password = passwordController.text.trim();
  String confirmar = confirmarPasswordController.text.trim();

  if (nombre.isEmpty || apellido.isEmpty || email.isEmpty ||
      telefono.isEmpty || password.isEmpty || confirmar.isEmpty ||
      documentoController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Completa todos los campos")),
    );
    return;
  }

  if (password != confirmar) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Las contraseñas no coinciden")),
    );
    return;
  }

  // Mostrar loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(child: CircularProgressIndicator()),
  );

  final resultado = await ClienteService.registrar(
    nombre: "$nombre $apellido",
    email: email,
    telefono: telefono,
    password: password,
    documentoIdentidad: "",
  );

  Navigator.pop(context);

  if (resultado['success']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Cuenta creada exitosamente"),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
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

              SizedBox(height: 60),

              Icon(Icons.person_add, size: 70, color: Colors.white),

              SizedBox(height: 10),

              Text(
                "Crear cuenta",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 30),

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
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: "Nombre",
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),

                    SizedBox(height: 15),

                    TextField(
                      controller: apellidoController,
                      decoration: InputDecoration(
                        labelText: "Apellido",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    SizedBox(height: 15),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),

                    SizedBox(height: 15),

                    TextField(
                      controller: telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Teléfono",
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
SizedBox(height: 15),

TextField(
  controller: documentoController,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(
    labelText: "Documento de identidad",
    prefixIcon: Icon(Icons.badge),
    border: OutlineInputBorder(),
  ),
),
                    SizedBox(height: 15),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),

                    SizedBox(height: 15),

                    TextField(
                      controller: confirmarPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Confirmar contraseña",
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),

                    SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: registrar,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text("Registrarse"),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("¿Ya tienes cuenta? Inicia sesión"),
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