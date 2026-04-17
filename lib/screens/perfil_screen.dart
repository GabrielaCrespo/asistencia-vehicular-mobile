import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../services/cliente_service.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController documentoController = TextEditingController();

  String email = "";
  int usuarioId = 0;
  bool editando = false;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarPerfil();
  }

  void cargarPerfil() async {
    final sesion = await SessionService.getSesion();
    usuarioId = sesion['usuario_id'] ?? 0;

    final resultado = await ClienteService.getPerfil(usuarioId);

    if (resultado['success']) {
      final user = resultado['data'];
      setState(() {
        nombreController.text = user.nombre;
        telefonoController.text = user.telefono;
        documentoController.text = user.documentoIdentidad;
        email = user.email;
        cargando = false;
      });
    } else {
      setState(() => cargando = false);
    }
  }

  void guardarCambios() async {
    if (nombreController.text.trim().isEmpty ||
        telefonoController.text.trim().isEmpty ||
        documentoController.text.trim().isEmpty) {
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

    final resultado = await ClienteService.updatePerfil(
      usuarioId: usuarioId,
      nombre: nombreController.text.trim(),
      telefono: telefonoController.text.trim(),
      documentoIdentidad: documentoController.text.trim(),
    );

    Navigator.pop(context);

    if (resultado['success']) {
      setState(() => editando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Perfil actualizado correctamente"),
          backgroundColor: Colors.green,
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

  void cerrarSesion() async {
    await SessionService.cerrarSesion();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
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
          "Mi Perfil",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              if (editando) {
                guardarCambios();
              } else {
                setState(() => editando = true);
              }
            },
            child: Text(
              editando ? "Guardar" : "Editar",
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      body: cargando
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [

                  // HEADER
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(Icons.person, size: 50, color: Colors.blue),
                        ),
                        SizedBox(height: 10),
                        Text(
                          nombreController.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          email,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // FORMULARIO
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            "Información personal",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),

                          SizedBox(height: 20),

                          // NOMBRE
                          TextField(
                            controller: nombreController,
                            enabled: editando,
                            decoration: InputDecoration(
                              labelText: "Nombre completo",
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: editando ? Colors.white : Colors.grey.shade50,
                            ),
                          ),

                          SizedBox(height: 15),

                          // EMAIL (no editable)
                          TextField(
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: "Correo electrónico",
                              hintText: email,
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),

                          SizedBox(height: 15),

                          // TELEFONO
                          TextField(
                            controller: telefonoController,
                            enabled: editando,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: "Teléfono",
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: editando ? Colors.white : Colors.grey.shade50,
                            ),
                          ),

                          SizedBox(height: 15),

                          // DOCUMENTO
                          TextField(
                            controller: documentoController,
                            enabled: editando,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Documento de identidad",
                              prefixIcon: Icon(Icons.badge),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: editando ? Colors.white : Colors.grey.shade50,
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // BOTON CERRAR SESION
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cerrarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 10),
                            Text(
                              "Cerrar sesión",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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