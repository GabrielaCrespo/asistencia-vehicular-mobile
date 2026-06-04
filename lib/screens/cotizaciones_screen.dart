import 'package:flutter/material.dart';
import '../services/cotizacion_service.dart';
import '../services/session_service.dart';

class CotizacionesScreen extends StatefulWidget {
  final int incidenteId;
  const CotizacionesScreen({super.key, required this.incidenteId});

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  List<Map<String, dynamic>> cotizaciones = [];
  bool cargando = true;
  bool seleccionando = false;
  int? usuarioId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final sesion = await SessionService.getSesion();
    usuarioId = sesion['usuario_id'] as int?;

    final resultado =
        await CotizacionService.listarPorIncidente(widget.incidenteId);
    if (mounted) {
      setState(() {
        cargando = false;
        if (resultado['success'] == true) {
          cotizaciones = List<Map<String, dynamic>>.from(
              resultado['cotizaciones'] ?? []);
        }
      });
    }
  }

  Future<void> _seleccionar(Map<String, dynamic> cotizacion) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar selección',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas aceptar la propuesta de:',
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            _infoRow(Icons.store, cotizacion['taller_nombre'] ?? ''),
            _infoRow(Icons.attach_money,
                'Bs ${(cotizacion['costo_estimado'] as num).toStringAsFixed(2)}'),
            _infoRow(Icons.access_time,
                '${cotizacion['tiempo_estimado']} horas estimadas'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Las demás cotizaciones quedarán como "No seleccionadas" y se generará la asignación automáticamente.',
                    style: TextStyle(
                        fontSize: 11, color: Colors.amber.shade800),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Aceptar propuesta',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmado != true || usuarioId == null) return;

    setState(() => seleccionando = true);

    final resultado = await CotizacionService.seleccionar(
      cotizacionId: cotizacion['cotizacion_id'] as int,
      usuarioId: usuarioId!,
    );

    setState(() => seleccionando = false);

    if (!mounted) return;

    if (resultado['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
                child: Text(resultado['message'] ??
                    'Cotización aceptada correctamente')),
          ]),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      // Recargar para mostrar estados actualizados
      await _cargarDatos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    resultado['message'] ?? 'Error al seleccionar cotización')),
          ]),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _infoRow(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
            child: Text(texto,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'aceptada':
        return Colors.green;
      case 'no_seleccionada':
        return Colors.grey;
      case 'rechazada':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'aceptada':
        return 'Aceptada';
      case 'no_seleccionada':
        return 'No seleccionada';
      case 'rechazada':
        return 'Rechazada';
      default:
        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hayAceptada =
        cotizaciones.any((c) => c['estado'] == 'aceptada');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cotizaciones',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: () {
              setState(() => cargando = true);
              _cargarDatos();
            },
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : cotizaciones.isEmpty
              ? _buildEmpty()
              : Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _cargarDatos,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Banner informativo
                          _buildBanner(hayAceptada),
                          const SizedBox(height: 16),

                          // Tarjetas de cotizaciones
                          ...cotizaciones.map((c) => _buildCard(c, hayAceptada)),
                        ],
                      ),
                    ),
                    if (seleccionando)
                      Container(
                        color: Colors.black26,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Sin cotizaciones aún',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(
            'Los talleres están preparando sus propuestas.\nVuelve a revisar en unos minutos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => cargando = true);
              _cargarDatos();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(bool hayAceptada) {
    if (hayAceptada) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(children: [
          Icon(Icons.check_circle, color: Colors.green.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ya seleccionaste una cotización. El taller asignado comenzará a atenderte.',
              style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(children: [
        Icon(Icons.info_outline, color: Colors.blue.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Compara las propuestas de los talleres y elige la más conveniente. '
            'Se ordenan de menor a mayor costo.',
            style: TextStyle(
                color: Colors.blue.shade800, fontSize: 13),
          ),
        ),
      ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> c, bool hayAceptada) {
    final estado = c['estado'] as String? ?? 'pendiente';
    final esPendiente = estado == 'pendiente';
    final esAceptada = estado == 'aceptada';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: esAceptada
            ? Border.all(color: Colors.green, width: 2)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header taller
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: esAceptada
                  ? Colors.green.shade50
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(Icons.store,
                      color: esAceptada ? Colors.green : Colors.blue,
                      size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    c['taller_nombre'] ?? 'Taller',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87),
                  ),
                ),
                // Badge de estado
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _colorEstado(estado).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _labelEstado(estado),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _colorEstado(estado)),
                  ),
                ),
              ],
            ),
          ),

          // Calificación
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              ...List.generate(
                5,
                (i) => Icon(
                  Icons.star,
                  size: 14,
                  color: i < ((c['calificacion_promedio'] as num?)?.round() ?? 0)
                      ? Colors.amber
                      : Colors.grey.shade300,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                ((c['calificacion_promedio'] as num?) ?? 0).toStringAsFixed(1),
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ),

          // Costo y tiempo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(
                child: _buildMetrica(
                  Icons.attach_money,
                  'Costo estimado',
                  'Bs ${(c['costo_estimado'] as num).toStringAsFixed(2)}',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetrica(
                  Icons.access_time,
                  'Tiempo estimado',
                  '${c['tiempo_estimado']} horas',
                  Colors.purple,
                ),
              ),
            ]),
          ),

          // Observaciones
          if (c['observaciones'] != null &&
              (c['observaciones'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Observaciones',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .4)),
                  const SizedBox(height: 4),
                  Text(
                    c['observaciones'],
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),

          // Botón seleccionar
          if (esPendiente && !hayAceptada)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: seleccionando ? null : () => _seleccionar(c),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Seleccionar esta propuesta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMetrica(
      IconData icon, String label, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .4)),
          ]),
          const SizedBox(height: 4),
          Text(valor,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ],
      ),
    );
  }
}
