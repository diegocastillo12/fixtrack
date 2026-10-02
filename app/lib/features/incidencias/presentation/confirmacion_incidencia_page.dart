import 'package:flutter/material.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);
const _kBlueLight = Color(0xFF60A5FA);

class ConfirmacionIncidenciaPage extends StatefulWidget {
  final String codigo;

  const ConfirmacionIncidenciaPage({super.key, required this.codigo});

  @override
  State<ConfirmacionIncidenciaPage> createState() =>
      _ConfirmacionIncidenciaPageState();
}

class _ConfirmacionIncidenciaPageState
    extends State<ConfirmacionIncidenciaPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _kNavy : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    final codigoCardColor =
        isDark ? const Color(0xFF162852) : const Color(0xFFEFF6FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono de check animado
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 80,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Título
                Text(
                  '¡Incidencia registrada!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                // Mensaje
                Text(
                  'La incidencia ha sido enviada al administrador. Se notificará por correo electrónico.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                // Código de incidencia
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: codigoCardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isDark
                            ? _kBlueLight.withOpacity(0.3)
                            : _kBlue.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Código de seguimiento',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.codigo,
                        style: TextStyle(
                          color: isDark ? _kBlueLight : _kBlue,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Botón Volver al inicio
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: isDark ? _kBlueLight : _kBlue),
                      foregroundColor: isDark ? _kBlueLight : _kBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Volver al inicio',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
