import 'package:flutter/material.dart';
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
      // El usuario canceló el sheet — no es un error grave
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
                  // Monto
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(children: [
                      const Text('Total a pagar',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        'Bs ${widget.monto.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E)),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 24),
                  const Text('Elige un método de pago',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

                  // Stripe
                  _MetodoCard(
                    icon: Icons.credit_card,
                    titulo: 'Tarjeta de crédito / débito',
                    subtitulo: 'Pago seguro con Stripe',
                    color: const Color(0xFF635BFF),
                    onTap: _pagarConStripe,
                  ),
                  const SizedBox(height: 12),

                  // Efectivo
                  _MetodoCard(
                    icon: Icons.payments_outlined,
                    titulo: 'Efectivo',
                    subtitulo: 'Confirmar pago en mano',
                    color: Colors.green,
                    onTap: () => _pagarEfectivo('efectivo'),
                  ),
                  const SizedBox(height: 12),

                  // QR
                  _MetodoCard(
                    icon: Icons.qr_code_2,
                    titulo: 'Pago QR',
                    subtitulo: 'Transferencia por código QR',
                    color: Colors.orange,
                    onTap: () => _pagarEfectivo('qr'),
                  ),
                  const SizedBox(height: 12),

                  // Transferencia
                  _MetodoCard(
                    icon: Icons.account_balance,
                    titulo: 'Transferencia bancaria',
                    subtitulo: 'Depósito o transferencia',
                    color: Colors.blue,
                    onTap: () => _pagarEfectivo('transferencia'),
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Modo test: usa tarjeta 4242 4242 4242 4242',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ),
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

  const _MetodoCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
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
                offset: const Offset(0, 2))
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
              Text(titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
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
