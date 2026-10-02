import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_toggle_button.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);
const _kBlueLight = Color(0xFF60A5FA);

class DetalleIncidenciaAdminPage extends StatefulWidget {
  final Map<String, dynamic> incidencia;

  const DetalleIncidenciaAdminPage({super.key, required this.incidencia});

  @override
  State<DetalleIncidenciaAdminPage> createState() =>
      _DetalleIncidenciaAdminPageState();
}

class _DetalleIncidenciaAdminPageState
    extends State<DetalleIncidenciaAdminPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _historial = [];
  List<Map<String, dynamic>> _proveedores = [];
  bool _loadingHistorial = true;
  bool _actualizando = false;
  late String _estadoActual;
  late String _incidenciaId;
  String? _orgId;

  @override
  void initState() {
    super.initState();
    _estadoActual = widget.incidencia['estado'] as String? ?? 'PENDIENTE';
    _incidenciaId = widget.incidencia['id']?.toString() ?? '';
    _initData();
  }

  Future<void> _initData() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid != null) {
      final miembro = await _supabase
          .from('miembros_organizacion')
          .select('organizacion_id')
          .eq('usuario_id', uid)
          .eq('estado', 'ACTIVO')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      _orgId = miembro?['organizacion_id'] as String?;
      if (_orgId != null) {
        final provData = await _supabase
            .from('proveedores')
            .select('id, razon_social')
            .eq('organizacion_id', _orgId!)
            .order('razon_social');
        _proveedores = List<Map<String, dynamic>>.from(provData as List);
      }
    }
    await _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _loadingHistorial = true);
    try {
      final data = await _supabase
          .from('historial_incidencia')
          .select('id, estado, descripcion, created_at, perfiles(nombre, apellido)')
          .eq('incidencia_id', _incidenciaId)
          .order('created_at');
      setState(() {
        _historial = List<Map<String, dynamic>>.from(data as List);
        _loadingHistorial = false;
      });
    } catch (e) {
      setState(() => _loadingHistorial = false);
    }
  }

  Future<void> _cambiarEstado(String nuevoEstado, {String? descripcion}) async {
    setState(() => _actualizando = true);
    try {
      await _supabase
          .from('incidencias')
          .update({'estado': nuevoEstado})
          .eq('id', _incidenciaId);
      await _supabase.from('historial_incidencia').insert({
        'incidencia_id': _incidenciaId,
        'estado': nuevoEstado,
        'descripcion': descripcion ?? 'Estado actualizado a $nuevoEstado',
        'usuario_id': _supabase.auth.currentUser?.id,
      });
      setState(() => _estadoActual = nuevoEstado);
      await _cargarHistorial();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a $nuevoEstado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _actualizando = false);
    }
  }

  Future<void> _enviarAProveedor() async {
    String? proveedorSeleccionado;
    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx2, setDialogState) => AlertDialog(
            backgroundColor:
                isDark ? const Color(0xFF162852) : Colors.white,
            title: Text(
              'Seleccionar proveedor',
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87),
            ),
            content: DropdownButtonFormField<String>(
              value: proveedorSeleccionado,
              decoration: InputDecoration(
                labelText: 'Proveedor',
                labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54),
                border: const OutlineInputBorder(),
              ),
              dropdownColor: isDark ? const Color(0xFF162852) : Colors.white,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87),
              items: _proveedores
                  .map((p) => DropdownMenuItem(
                        value: p['id'].toString(),
                        child: Text(p['razon_social'] ?? p['nombre'] ?? ''),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setDialogState(() => proveedorSeleccionado = v),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: proveedorSeleccionado == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _supabase
                            .from('incidencias')
                            .update({'proveedor_id': proveedorSeleccionado})
                            .eq('id', _incidenciaId);
                        await _cambiarEstado('EN_ATENCION',
                            descripcion:
                                'Enviada a proveedor para atención');
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _estadoColor(String? estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.amber;
      case 'EN_ATENCION':
        return _kBlue;
      case 'SOLUCIONADA':
        return Colors.green;
      case 'CERRADA':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _estadoIcon(String? estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Icons.hourglass_empty_rounded;
      case 'EN_ATENCION':
        return Icons.build_rounded;
      case 'SOLUCIONADA':
        return Icons.check_circle_rounded;
      case 'CERRADA':
        return Icons.lock_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _kNavy : Colors.grey[100]!;
    final cardColor = isDark ? const Color(0xFF162852) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    final activo = widget.incidencia['activos'] as Map?;
    final perfil = widget.incidencia['perfiles'] as Map?;
    final estadoColor = _estadoColor(_estadoActual);
    final codigo = widget.incidencia['codigo']?.toString() ?? '—';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? _kNavy : _kBlue,
        title: Text(
          codigo,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [ThemeToggleButton()],
      ),
      body: _actualizando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: código y estado
                  Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: isDark ? 0 : 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      codigo,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      activo?['nombre'] as String? ??
                                          'Sin equipo',
                                      style: TextStyle(
                                        color:
                                            isDark ? _kBlueLight : _kBlue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: estadoColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: estadoColor.withOpacity(0.4)),
                                ),
                                child: Text(
                                  _estadoActual.replaceAll('_', ' '),
                                  style: TextStyle(
                                    color: estadoColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.person_rounded,
                                  size: 14, color: textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                () {
                                  if (perfil == null) return 'Reportado por: Desconocido';
                                  final fullName = '${perfil['nombre'] ?? ''} ${perfil['apellido'] ?? ''}'.trim();
                                  final finalName = fullName.isNotEmpty ? fullName : (perfil['nombre_completo'] as String? ?? 'Desconocido');
                                  return 'Reportado por: $finalName';
                                }(),
                                style: TextStyle(
                                    color: textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Descripción del problema
                  _SectionHeader(title: 'Descripción', textColor: textPrimary),
                  const SizedBox(height: 10),
                  Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: isDark ? 0 : 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: isDark ? _kBlueLight : _kBlue,
                                  size: 16),
                              const SizedBox(width: 8),
                              Text(
                                widget.incidencia['tipo_problema']
                                        ?.toString() ??
                                    '—',
                                style: TextStyle(
                                  color: isDark ? _kBlueLight : _kBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.incidencia['descripcion']?.toString() ??
                                '—',
                            style: TextStyle(
                                color: textSecondary, fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Timeline de historial
                  _SectionHeader(
                      title: 'Historial de cambios', textColor: textPrimary),
                  const SizedBox(height: 10),
                  _loadingHistorial
                      ? const Center(child: CircularProgressIndicator())
                      : _historial.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Sin historial aún',
                                style: TextStyle(
                                    color: textSecondary, fontSize: 14),
                              ),
                            )
                          : ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: _historial.length,
                              itemBuilder: (ctx, i) {
                                final h = _historial[i];
                                final isLast = i == _historial.length - 1;
                                final hEstado =
                                    h['estado'] as String? ?? '—';
                                final hColor = _estadoColor(hEstado);
                                final hPerfil = h['perfiles'] as Map?;
                                final fecha =
                                    h['created_at']?.toString() ?? '—';
                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Línea del timeline
                                      SizedBox(
                                        width: 32,
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: hColor.withOpacity(0.15),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: hColor, width: 2),
                                              ),
                                              child: Icon(
                                                _estadoIcon(hEstado),
                                                color: hColor,
                                                size: 16,
                                              ),
                                            ),
                                            if (!isLast)
                                              Expanded(
                                                child: Container(
                                                  width: 2,
                                                  color: isDark
                                                      ? Colors.white12
                                                      : Colors.black12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              bottom: isLast ? 0 : 16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                hEstado.replaceAll('_', ' '),
                                                style: TextStyle(
                                                  color: hColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                h['descripcion']
                                                        ?.toString() ??
                                                    '',
                                                style: TextStyle(
                                                    color: textSecondary,
                                                    fontSize: 12),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                fecha.length > 10
                                                    ? fecha.substring(0, 10)
                                                    : fecha,
                                                style: TextStyle(
                                                    color: textSecondary,
                                                    fontSize: 11),
                                              ),
                                              if (hPerfil != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${hPerfil['nombre'] ?? ''} ${hPerfil['apellido'] ?? ''}'.trim().isNotEmpty
                                                      ? '${hPerfil['nombre'] ?? ''} ${hPerfil['apellido'] ?? ''}'.trim()
                                                      : (hPerfil['nombre_completo']?.toString() ?? ''),
                                                  style: TextStyle(
                                                      color: textSecondary,
                                                      fontSize: 11),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  const SizedBox(height: 16),

                  // Botones de acción
                  _SectionHeader(
                      title: 'Acciones', textColor: textPrimary),
                  const SizedBox(height: 12),

                  if (_estadoActual == 'PENDIENTE' ||
                      _estadoActual == 'EN_ATENCION')
                    _ActionButton(
                      icon: Icons.store_rounded,
                      label: 'Enviar al proveedor',
                      color: Colors.orange,
                      onPressed: _enviarAProveedor,
                    ),
                  if (_estadoActual == 'EN_ATENCION')
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _ActionButton(
                        icon: Icons.check_circle_rounded,
                        label: 'Marcar como solucionada',
                        color: Colors.green,
                        onPressed: () => _cambiarEstado('SOLUCIONADA',
                            descripcion: 'Incidencia marcada como solucionada'),
                      ),
                    ),
                  if (_estadoActual == 'SOLUCIONADA')
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _ActionButton(
                        icon: Icons.lock_rounded,
                        label: 'Cerrar incidencia',
                        color: Colors.grey,
                        onPressed: () => _cambiarEstado('CERRADA',
                            descripcion: 'Incidencia cerrada'),
                      ),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color textColor;
  const _SectionHeader({required this.title, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon),
        label: Text(label,
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
