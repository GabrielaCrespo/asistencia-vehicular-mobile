import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../services/stripe_service.dart';

class PagoScreen extends StatefulWidget {
  final int pagoId;
  final double monto;
  final int incidenteId;

  const PagoScreen({
    super.key,
    required this.pagoId,
    required this.monto,
    required this.incidenteId,
  });

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  bool _procesando = false;
  String? _error;

  Future<void> _pagarConStripe() async {
    setState(() { _procesando = true; _error = null; });
    try {
      await StripeService.initStripe();
      await StripeService.pagarConStripe(widget.pagoId);
      if (!mounted) return;
      _mostrarExito('Pago con tarjeta realizado correctamente');
    } on StripeException catch (e) {
      if (!mounted) return;
      if (e.error.code != FailureCode.Canceled) {
        setState(() => _error = e.error.localizedMessage ?? 'Error al procesar el pago');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _pagarEfectivo(String metodo) async {
    setState(() { _procesando = true; _error = null; });
    try {
      await StripeService.confirmarPagoEfectivo(widget.pagoId, metodo);
      if (!mounted) return;
      final labels = {'efectivo': 'Efectivo', 'qr': 'QR', 'transferencia': 'Transferencia'};
      _mostrarExito('Pago con ${labels[metodo]} registrado correctamente');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _mostrarExito(String mensaje) {
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje)),
        ]),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _mostrarModalQR() async {
    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QRModal(monto: widget.monto, pagoId: widget.pagoId),
    );
    if (confirmar == true && mounted) {
      await _pagarEfectivo('qr');
    }
  }

  Future<void> _mostrarModalEfectivo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.payments_outlined, color: Colors.green.shade700),
          ),
          const SizedBox(width: 12),
          const Text('Pago en efectivo', style: TextStyle(fontSize: 17)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Entrega el monto directamente al técnico al finalizar el servicio.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildDialogRow(Colors.green, Icons.attach_money,
                'Monto a pagar', 'Bs ${widget.monto.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildDialogRow(Colors.blue, Icons.receipt_long,
                'Referencia', 'INC-${widget.incidenteId}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El técnico registrará el pago al finalizar el servicio.',
                    style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      await _pagarEfectivo('efectivo');
    }
  }

  Future<void> _mostrarModalTransferencia() async {
    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransferenciaModal(
        monto: widget.monto,
        pagoId: widget.pagoId,
        incidenteId: widget.incidenteId,
      ),
    );
    if (confirmar == true && mounted) {
      await _pagarEfectivo('transferencia');
    }
  }

  Widget _buildDialogRow(Color color, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
      ]),
    );
  }

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
        title: const Text('Registrar pago',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _procesando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con gradiente
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.lock, color: Colors.white.withValues(alpha: 0.7), size: 13),
                        const SizedBox(width: 4),
                        Text('Pago seguro',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                      ]),
                      const SizedBox(height: 10),
                      const Text('Total a pagar',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(
                        'Bs ${widget.monto.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Incidente #${widget.incidenteId}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 28),

                  const Text('Elige un método de pago',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('Selecciona cómo deseas realizar tu pago',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 16),

                  // Error
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Stripe (real)
                  _MetodoCard(
                    icon: Icons.credit_card,
                    titulo: 'Tarjeta de crédito / débito',
                    subtitulo: 'Pago seguro con Stripe',
                    color: const Color(0xFF635BFF),
                    badge: 'Recomendado',
                    onTap: _pagarConStripe,
                  ),
                  const SizedBox(height: 12),

                  // Efectivo
                  _MetodoCard(
                    icon: Icons.payments_outlined,
                    titulo: 'Efectivo',
                    subtitulo: 'Pago directo al técnico',
                    color: Colors.green,
                    onTap: _mostrarModalEfectivo,
                  ),
                  const SizedBox(height: 12),

                  // QR
                  _MetodoCard(
                    icon: Icons.qr_code_2,
                    titulo: 'Pago QR',
                    subtitulo: 'Escanea y transfiere al instante',
                    color: Colors.orange,
                    onTap: _mostrarModalQR,
                  ),
                  const SizedBox(height: 12),

                  // Transferencia
                  _MetodoCard(
                    icon: Icons.account_balance,
                    titulo: 'Transferencia bancaria',
                    subtitulo: 'Depósito o transferencia directa',
                    color: Colors.blue,
                    onTap: _mostrarModalTransferencia,
                  ),

                  const SizedBox(height: 32),

                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.security, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text('Tus datos están protegidos',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  ]),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}

class _MetodoCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _MetodoCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge!,
                        style: TextStyle(
                            fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
              const SizedBox(height: 3),
              Text(subtitulo,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ]),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
        ]),
      ),
    );
  }
}

// ─── Modal QR ────────────────────────────────────────────────────────────────

class _QRModal extends StatelessWidget {
  final double monto;
  final int pagoId;

  const _QRModal({required this.monto, required this.pagoId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.qr_code_2, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            const Text('Pago por código QR',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),

          // QR simulado
          Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.qr_code_2, size: 130, color: Colors.black87),
              const SizedBox(height: 6),
              Text('Ref: AV-$pagoId',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
          const SizedBox(height: 20),

          // Datos del destinatario
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Column(children: [
              _ModalInfoRow('Titular', 'Asistencia Vehicular S.A.'),
              const Divider(height: 16),
              _ModalInfoRow('Banco', 'Banco Nacional de Bolivia'),
              const Divider(height: 16),
              _ModalInfoRow('Monto', 'Bs ${monto.toStringAsFixed(2)}'),
              const Divider(height: 16),
              _ModalInfoRow('Concepto', 'Pago incidente AV-$pagoId'),
            ]),
          ),
          const SizedBox(height: 14),

          Text(
            'Escanea el código QR con tu app bancaria y completa el pago.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya realicé el pago',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

// ─── Modal Transferencia ──────────────────────────────────────────────────────

class _TransferenciaModal extends StatelessWidget {
  final double monto;
  final int pagoId;
  final int incidenteId;

  static const _numeroCuenta = '1-1234567-8-90';

  const _TransferenciaModal({
    required this.monto,
    required this.pagoId,
    required this.incidenteId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.account_balance, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            const Text('Transferencia bancaria',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),

          // Datos bancarios
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(children: [
              _ModalInfoRow('Titular', 'Asistencia Vehicular S.A.'),
              const Divider(height: 16),
              _ModalInfoRow('Banco', 'Banco Mercantil Santa Cruz'),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('N° de cuenta',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const Text(_numeroCuenta,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ]),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: _numeroCuenta));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Número copiado al portapapeles'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.copy, size: 16, color: Colors.blue),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              _ModalInfoRow('Tipo de cuenta', 'Cuenta Corriente'),
              const Divider(height: 16),
              _ModalInfoRow('Monto exacto', 'Bs ${monto.toStringAsFixed(2)}'),
              const Divider(height: 16),
              _ModalInfoRow('Concepto / Ref.', 'INC-$incidenteId'),
            ]),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: Colors.amber.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Incluye el concepto de referencia para identificar tu pago correctamente.',
                  style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya realicé la transferencia',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _ModalInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ModalInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }
}
