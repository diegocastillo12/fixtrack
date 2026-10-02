import 'package:flutter/material.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../../incidencias/presentation/nueva_incidencia_page.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);
const _kBlueLight = Color(0xFF60A5FA);

class DetalleEquipoPage extends StatelessWidget {
  final Map<String, dynamic> activo;

  const DetalleEquipoPage({super.key, required this.activo});

  Color _estadoColor(String? estado) {
    switch (estado) {
      case 'OPERATIVO':
        return Colors.green;
      case 'NO_OPERATIVO':
        return Colors.red;
      case 'EN_MANTENIMIENTO':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _kNavy : Colors.grey[100]!;
    final cardColor = isDark ? const Color(0xFF162852) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    final ambiente = activo['ambientes'] as Map?;
    final tipo = activo['tipos_activo'] as Map?;
    final estado = activo['estado'] as String?;
    final estadoColor = _estadoColor(estado);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? _kNavy : _kBlue,
        title: const Text(
          'Detalle del equipo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [ThemeToggleButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: isDark ? 0 : 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark
                            ? _kNavy
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.devices_rounded,
                        color: isDark ? _kBlueLight : _kBlue,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activo['nombre'] ?? '—',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: estadoColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: estadoColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              estado ?? '—',
                              style: TextStyle(
                                color: estadoColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Información del equipo',
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Card de información
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: isDark ? 0 : 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.qr_code_rounded,
                      label: 'Código de barras',
                      value: activo['codigo_barras']?.toString() ?? '—',
                      iconColor: isDark ? _kBlueLight : _kBlue,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    _Divider(color: isDark ? Colors.white12 : Colors.black12),
                    _InfoTile(
                      icon: Icons.tag_rounded,
                      label: 'Número de serie',
                      value: activo['numero_serie']?.toString() ?? '—',
                      iconColor: isDark ? _kBlueLight : _kBlue,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    _Divider(color: isDark ? Colors.white12 : Colors.black12),
                    _InfoTile(
                      icon: Icons.location_on_rounded,
                      label: 'Ubicación / Ambiente',
                      value: ambiente?['nombre'] as String? ?? '—',
                      iconColor: isDark ? _kBlueLight : _kBlue,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    _Divider(color: isDark ? Colors.white12 : Colors.black12),
                    _InfoTile(
                      icon: Icons.category_rounded,
                      label: 'Tipo de activo',
                      value: tipo?['nombre'] as String? ?? '—',
                      iconColor: isDark ? _kBlueLight : _kBlue,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    _Divider(color: isDark ? Colors.white12 : Colors.black12),
                    _InfoTile(
                      icon: Icons.circle_rounded,
                      label: 'Estado',
                      value: estado ?? '—',
                      iconColor: estadoColor,
                      valueColor: estadoColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botón registrar incidencia
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NuevaIncidenciaPage(
                        activoId: activo['id']?.toString(),
                        activoNombre: activo['nombre']?.toString(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
                icon: const Icon(Icons.report_problem_rounded, size: 22),
                label: const Text(
                  'Registrar incidencia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.textPrimary,
    required this.textSecondary,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: color, indent: 50, endIndent: 16);
  }
}
