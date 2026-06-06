import 'package:flutter/material.dart';
import '../services/calificacion_service.dart';

class CalificacionScreen extends StatefulWidget {
  final int incidenteId;
  final String? tallerNombre;
  final String? tipoProblema;
  final String? fechaCreacion;

  const CalificacionScreen({
    super.key,
    required this.incidenteId,
    this.tallerNombre,
    this.tipoProblema,
    this.fechaCreacion,
  });

  @override
  State<CalificacionScreen> createState() => _CalificacionScreenState();
}

class _CalificacionScreenState extends State<CalificacionScreen> {
  int _puntuacionTaller = 0;
  int _puntuacionServicio = 0;
  final TextEditingController _comentarioCtrl = TextEditingController();

  bool _cargando = true;
  bool _enviando = false;
  bool _enviado = false;
  bool _yaCalificado = false;
  Map<String, dynamic>? _calificacionExistente;

  static const Color _teal = Color(0xFF5cbdb9);

  @override
  void initState() {
    super.initState();
    _verificarCalificacion();
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificarCalificacion() async {
    final result =
        await CalificacionService.getCalificacion(widget.incidenteId);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (result['exists'] == true && result['calificacion'] != null) {
        _yaCalificado = true;
        _calificacionExistente = Map<String, dynamic>.from(result['calificacion']);
      }
    });
  }

  Future<void> _enviarCalificacion() async {
    if (_puntuacionTaller == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona una calificación para el taller'),
      ));
      return;
    }

    setState(() => _enviando = true);

    final result = await CalificacionService.registrar(
      incidenteId: widget.incidenteId,
      puntuacion: _puntuacionTaller,
      puntuacionServicio:
          _puntuacionServicio > 0 ? _puntuacionServicio : null,
      comentario: _comentarioCtrl.text.trim().isEmpty
          ? null
          : _comentarioCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (result['success'] == true) {
      setState(() => _enviado = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Error al enviar la valoración'),
        backgroundColor: Colors.red.shade600,
      ));
    }
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return '';
    try {
      final dt = DateTime.parse(fecha);
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (_) {
      return fecha;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────

  String _textoCalificacion(int v) {
    switch (v) {
      case 1: return 'Muy malo';
      case 2: return 'Malo';
      case 3: return 'Regular';
      case 4: return 'Bueno';
      case 5: return 'Excelente';
      default: return '';
    }
  }

  Color _colorCalificacion(int v) {
    if (v <= 2) return Colors.red.shade600;
    if (v == 3) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Valorar servicio',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  if (_yaCalificado) _buildCalificacionExistente(),
                  if (_enviado && !_yaCalificado) _buildExito(),
                  if (!_yaCalificado && !_enviado) ...[
                    _buildSelectorEstrellas(
                      titulo: 'Calificación del taller',
                      subtitulo: '¿Cómo calificarías la atención del taller?',
                      valor: _puntuacionTaller,
                      onChanged: (v) =>
                          setState(() => _puntuacionTaller = v),
                      requerido: true,
                    ),
                    const SizedBox(height: 16),
                    _buildSelectorEstrellas(
                      titulo: 'Calidad del servicio',
                      subtitulo:
                          '¿Cómo fue la calidad de la reparación? (opcional)',
                      valor: _puntuacionServicio,
                      onChanged: (v) =>
                          setState(() => _puntuacionServicio = v),
                      requerido: false,
                    ),
                    const SizedBox(height: 16),
                    _buildCampoComentario(),
                    const SizedBox(height: 24),
                    _buildBotonEnviar(),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.check_circle,
                  color: Colors.green.shade600, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Servicio completado',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Emergencia #${widget.incidenteId}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ]),
          if (widget.tallerNombre != null) ...[
            const Divider(height: 22),
            Row(children: [
              const Icon(Icons.store, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(widget.tallerNombre!,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600))),
            ]),
          ],
          if (widget.tipoProblema != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.build, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text(widget.tipoProblema!,
                  style: TextStyle(color: Colors.grey.shade700)),
            ]),
          ],
          if (widget.fechaCreacion != null &&
              widget.fechaCreacion!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today,
                  color: Colors.grey, size: 16),
              const SizedBox(width: 8),
              Text(_formatearFecha(widget.fechaCreacion),
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectorEstrellas({
    required String titulo,
    required String subtitulo,
    required int valor,
    required ValueChanged<int> onChanged,
    required bool requerido,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            if (requerido)
              const Text(' *',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Text(subtitulo,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final estrella = i + 1;
              return GestureDetector(
                onTap: () => onChanged(estrella),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    estrella <= valor
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 46,
                  ),
                ),
              );
            }),
          ),
          if (valor > 0) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                _textoCalificacion(valor),
                style: TextStyle(
                  color: _colorCalificacion(valor),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCampoComentario() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Comentario',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Opcional — cuéntanos tu experiencia',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: _comentarioCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: '¿Algo que quieras destacar o mejorar?',
              hintStyle: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: _teal, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonEnviar() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _enviando ? null : _enviarCalificacion,
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _enviando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: 10),
                  Text('Enviar valoración',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  Widget _buildExito() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 64),
          const SizedBox(height: 16),
          Text(
            '¡Gracias por tu valoración!',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu opinión nos ayuda a mejorar el servicio.',
            style: TextStyle(
                color: Colors.green.shade600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                5,
                (i) => Icon(
                      i < _puntuacionTaller
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    )),
          ),
        ],
      ),
    );
  }

  Widget _buildCalificacionExistente() {
    final cal = _calificacionExistente!;
    final puntuacion = (cal['puntuacion'] as num).toInt();
    final puntuacionServicio = cal['puntuacion_servicio'] != null
        ? (cal['puntuacion_servicio'] as num).toInt()
        : null;
    final comentario = cal['comentario'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.star, color: Colors.amber, size: 22),
            const SizedBox(width: 8),
            const Text('Tu valoración registrada',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 14),
          const Text('Calificación del taller:',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 6),
          Row(children: [
            ...List.generate(
                5,
                (i) => Icon(
                      i < puntuacion
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 28,
                    )),
            const SizedBox(width: 8),
            Text('$puntuacion/5',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade800,
                    fontSize: 15)),
          ]),
          if (puntuacionServicio != null) ...[
            const SizedBox(height: 12),
            const Text('Calidad del servicio:',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 6),
            Row(children: [
              ...List.generate(
                  5,
                  (i) => Icon(
                        i < puntuacionServicio
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.blue.shade300,
                        size: 24,
                      )),
              const SizedBox(width: 8),
              Text('$puntuacionServicio/5',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade700)),
            ]),
          ],
          if (comentario != null && comentario.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                '"$comentario"',
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Las valoraciones no pueden modificarse.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
