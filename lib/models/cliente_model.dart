class ClienteModel {
  final int usuarioId;
  final String nombre;
  final String email;
  final String telefono;
  final String documentoIdentidad;
  final String estado;

  ClienteModel({
    required this.usuarioId,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.documentoIdentidad,
    required this.estado,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      usuarioId: json['usuario_id'],
      nombre: json['nombre'],
      email: json['email'],
      telefono: json['telefono'] ?? '',
      documentoIdentidad: json['documento_identidad'] ?? '',
      estado: json['estado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'documento_identidad': documentoIdentidad,
    };
  }
}