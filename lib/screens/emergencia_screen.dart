import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/evidencia_service.dart';
import 'package:flutter/material.dart';
import '../services/emergencia_service.dart';
import '../services/vehiculo_service.dart';
import '../services/session_service.dart';
import '../services/ubicacion_service.dart';
import '../services/audio_service.dart';
import 'talleres_screen.dart';

class EmergenciaScreen extends StatefulWidget {
  @override
  _EmergenciaScreenState createState() => _EmergenciaScreenState();
}

class _EmergenciaScreenState extends State<EmergenciaScreen> {
  final TextEditingController descripcionController = TextEditingController();

  String ubicacion = "Santa Cruz - Bolivia";
  double latitud = -17.7833;
  double longitud = -63.1821;
  String imagen = "";
  XFile? imagenSeleccionada;
  bool audioGrabado = false;
  bool grabando = false;
  String? rutaAudio;
  String tipoProblema = "";
  int? vehiculoSeleccionadoId;
  String vehiculoSeleccionadoNombre = "";
  bool cargando = true;
  int usuarioId = 0;

  List<Map<String, dynamic>> vehiculos = [];

  List<String> tiposProblema = [
    "Batería",
    "Llanta",
    "Motor",
    "Choque",
    "Otros",
  ];

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  void cargarDatos() async {
    final sesion = await SessionService.getSesion();
    usuarioId = sesion['usuario_id'] ?? 0;

    final resultado = await VehiculoService.listar(usuarioId);
    if (resultado['success']) {
      setState(() {
        vehiculos = List<Map<String, dynamic>>.from(resultado['vehiculos']);
        cargando = false;
      });
    } else {
      setState(() => cargando = false);
    }
  }

  void seleccionarImagen() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Seleccionar imagen",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: Text("Galería"),
              onTap: () async {
                Navigator.pop(context);
                final resultado = await EvidenciaService.seleccionarDeGaleria();
                if (resultado['success']) {
                  setState(() {
                    imagenSeleccionada = XFile(resultado['path']);
                    imagen = resultado['path'];
                  });
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt, color: Colors.green),
              ),
              title: Text("Cámara"),
              onTap: () async {
                Navigator.pop(context);
                final resultado = await EvidenciaService.tomarFoto();
                if (resultado['success']) {
                  setState(() {
                    imagenSeleccionada = XFile(resultado['path']);
                    imagen = resultado['path'];
                  });
                }
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void grabarAudio() async {
    if (!grabando) {
      final resultado = await AudioService.iniciarGrabacion();
      if (resultado['success']) {
        setState(() {
          grabando = true;
          audioGrabado = false;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(resultado['message'])));
      }
    } else {
      final resultado = await AudioService.detenerGrabacion();
      if (resultado['success']) {
        setState(() {
          grabando = false;
          audioGrabado = true;
          rutaAudio = resultado['path'];
        });
      }
    }
  }

  void enviarEmergencia() async {
    if (vehiculoSeleccionadoId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Selecciona un vehículo")));
      return;
    }

    if (tipoProblema.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Selecciona el tipo de problema")));
      return;
    }

    if (descripcionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Describe el problema")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    // Subir imagen si hay una seleccionada
    String? imagenPath;
    if (imagenSeleccionada != null) {
      final resultadoImagen = await EvidenciaService.subirImagen(
        imagenSeleccionada!,
      );
      if (resultadoImagen['success']) {
        imagenPath = resultadoImagen['imagen_path'];
      }
    }

    // Subir audio si hay uno grabado
   // Subir audio si hay uno grabado
String? audioPath;
print("=== DEBUG AUDIO ===");
print("rutaAudio: $rutaAudio");
if (rutaAudio != null && rutaAudio!.isNotEmpty) {
  print("Intentando subir audio...");
  final resultadoAudio = await EvidenciaService.subirAudio(rutaAudio!);
  print("Resultado audio: $resultadoAudio");
  if (resultadoAudio['success']) {
    audioPath = resultadoAudio['audio_path'];
    print("Audio path: $audioPath");
  }
} else {
  print("rutaAudio es null o vacío");
}
    final resultado = await EmergenciaService.registrar(
      usuarioId: usuarioId,
      vehiculoId: vehiculoSeleccionadoId!,
      descripcion: descripcionController.text.trim(),
      latitud: latitud,
      longitud: longitud,
      tipoProblema: tipoProblema,
      imagenPath: imagenPath,
      audioPath: audioPath, // 👈 línea nueva
    );

    Navigator.pop(context);

    if (resultado['success']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TalleresScreen(
            latitud: latitud,
            longitud: longitud,
            tipoProblema: tipoProblema,
            incidenteId: resultado['data']['incidente_id'],
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
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Registrar Emergencia",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: cargando
          ? Center(child: CircularProgressIndicator())
          : vehiculos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, size: 80, color: Colors.grey),
                  SizedBox(height: 15),
                  Text(
                    "No tienes vehículos registrados",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Registra un vehículo para continuar",
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Ir a Mis Vehículos"),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.warning_rounded,
                            color: Colors.red,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nueva Emergencia",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "Completa la información del incidente",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // VEHICULO
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Vehículo afectado",
                      style: TextStyle(
                        fontSize: 15,
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
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          hint: Text("Selecciona tu vehículo"),
                          value: vehiculoSeleccionadoId,
                          items: vehiculos.map((v) {
                            return DropdownMenuItem<int>(
                              value: v['vehiculo_id'],
                              child: Text(
                                "${v['marca']} ${v['modelo']} - ${v['placa']}",
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              vehiculoSeleccionadoId = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // TIPO PROBLEMA
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Tipo de problema",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: tiposProblema.map((tipo) {
                        bool seleccionado = tipoProblema == tipo;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              tipoProblema = tipo;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: seleccionado
                                  ? Color(0xFFE53935)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Text(
                              tipo,
                              style: TextStyle(
                                color: seleccionado
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  SizedBox(height: 20),

                  // DESCRIPCION
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Descripción del problema",
                      style: TextStyle(
                        fontSize: 15,
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
                      child: TextField(
                        controller: descripcionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              "Ej: Mi auto no enciende, la batería parece descargada...",
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.all(15),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // EVIDENCIAS
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Evidencias",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: seleccionarImagen,
                            child: Container(
                              height: 120,
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
                              child: imagenSeleccionada == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt,
                                          size: 35,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Agregar foto",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: kIsWeb
                                          ? Icon(
                                              Icons.check_circle,
                                              size: 35,
                                              color: Colors.green,
                                            )
                                          : Image.file(
                                              File(imagenSeleccionada!.path),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ),
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: GestureDetector(
                            onTap: grabarAudio,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: grabando
                                    ? Colors.red.shade50
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    grabando
                                        ? Icons.stop_circle
                                        : audioGrabado
                                        ? Icons.check_circle
                                        : Icons.mic,
                                    size: 35,
                                    color: grabando
                                        ? Colors.red
                                        : audioGrabado
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    grabando
                                        ? "Toca para detener"
                                        : audioGrabado
                                        ? "Audio grabado"
                                        : "Grabar audio",
                                    style: TextStyle(
                                      color: grabando
                                          ? Colors.red
                                          : audioGrabado
                                          ? Colors.green
                                          : Colors.grey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // UBICACION
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Ubicación",
                      style: TextStyle(
                        fontSize: 15,
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
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.location_on, color: Colors.red),
                        ),
                        title: Text(
                          "Ubicación actual",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(ubicacion),
                        trailing: Icon(Icons.my_location, color: Colors.blue),
                        onTap: () async {
                          final resultado =
                              await UbicacionService.obtenerUbicacion();
                          if (resultado['success']) {
                            setState(() {
                              latitud = resultado['latitud'];
                              longitud = resultado['longitud'];
                              ubicacion =
                                  "Lat: ${latitud.toStringAsFixed(4)}, Lng: ${longitud.toStringAsFixed(4)}";
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "No se pudo obtener la ubicación",
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // BOTON ENVIAR
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: enviarEmergencia,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE53935),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              "Enviar Emergencia",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
