import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_toggle_button.dart';
import 'agregar_equipo_page.dart';
import 'detalle_equipo_page.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);
const _kBlueLight = Color(0xFF60A5FA);

class EquiposAdminPage extends StatefulWidget {
  const EquiposAdminPage({super.key});

  @override
  State<EquiposAdminPage> createState() => _EquiposAdminPageState();
}

class _EquiposAdminPageState extends State<EquiposAdminPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _equipos = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _loading = true;
  String _busqueda = '';
  String? _orgId;

  @override
  void initState() {
    super.initState();
    _initOrg();
  }

  Future<void> _initOrg() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final miembro = await _supabase
          .from('miembros_organizacion')
          .select('organizacion_id')
          .eq('usuario_id', uid)
          .eq('estado', 'ACTIVO')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      _orgId = miembro?['organizacion_id'] as String?;
      await _cargarEquipos();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarEquipos() async {
    if (_orgId == null) return;
    setState(() => _loading = true);
    try {
      final data = await _supabase
          .from('activos')
          .select('id, nombre, codigo_barras, numero_serie, estado, ambientes(nombre), tipos_activo(nombre)')
          .eq('organizacion_id', _orgId!)
          .order('nombre');
      setState(() {
        _equipos = List<Map<String, dynamic>>.from(data as List);
        _aplicarFiltro();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar equipos: $e')),
        );
      }
    }
  }

  void _aplicarFiltro() {
    if (_busqueda.isEmpty) {
      _filtrados = List.from(_equipos);
    } else {
      _filtrados = _equipos.where((e) {
        final nombre = (e['nombre'] ?? '').toString().toLowerCase();
        return nombre.contains(_busqueda.toLowerCase());
      }).toList();
    }
  }

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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? _kNavy : _kBlue,
        title: const Text(
          'Inventario de Equipos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _cargarEquipos,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) {
                setState(() {
                  _busqueda = v;
                  _aplicarFiltro();
                });
              },
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar equipo por nombre...',
                hintStyle: TextStyle(color: textSecondary),
                prefixIcon: Icon(Icons.search_rounded, color: isDark ? _kBlueLight : _kBlue),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Contador
          if (!_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filtrados.length} equipo${_filtrados.length != 1 ? 's' : ''} registrado${_filtrados.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          // Lista
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.devices_rounded, size: 64, color: textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              _busqueda.isEmpty ? 'No hay equipos registrados' : 'Sin resultados',
                              style: TextStyle(color: textSecondary, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtrados.length,
                        itemBuilder: (context, index) {
                          final equipo = _filtrados[index];
                          final ambiente = equipo['ambientes'] as Map?;
                          final tipo = equipo['tipos_activo'] as Map?;
                          final estado = equipo['estado'] as String?;
                          return _EquipoCard(
                            equipo: equipo,
                            ambiente: ambiente?['nombre'] as String? ?? '—',
                            tipo: tipo?['nombre'] as String? ?? '—',
                            estado: estado,
                            estadoColor: _estadoColor(estado),
                            cardColor: cardColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetalleEquipoPage(activo: equipo),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgregarEquipoPage()),
          );
          if (result == true) _cargarEquipos();
        },
        backgroundColor: _kBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nuevo equipo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _EquipoCard extends StatelessWidget {
  final Map<String, dynamic> equipo;
  final String ambiente;
  final String tipo;
  final String? estado;
  final Color estadoColor;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onTap;

  const _EquipoCard({
    required this.equipo,
    required this.ambiente,
    required this.tipo,
    required this.estado,
    required this.estadoColor,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: isDark ? 0 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D1B3E) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.devices_rounded,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipo['nombre'] ?? '—',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.qr_code_rounded,
                      label: equipo['codigo_barras']?.toString() ?? '—',
                      textColor: textSecondary,
                    ),
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      label: ambiente,
                      textColor: textSecondary,
                    ),
                    _InfoRow(
                      icon: Icons.category_rounded,
                      label: tipo,
                      textColor: textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: estadoColor.withOpacity(0.4)),
                ),
                child: Text(
                  estado?.replaceAll('_', '\n') ?? '—',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: estadoColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;

  const _InfoRow({required this.icon, required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: textColor, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
