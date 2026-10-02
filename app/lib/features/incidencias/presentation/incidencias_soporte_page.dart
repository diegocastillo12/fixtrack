import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../../equipos/presentation/escaner_page.dart';
import '../../equipos/presentation/detalle_equipo_page.dart';
import '../../auth/presentation/login_page.dart';
import '../../../core/navigation/dark_route.dart';
import 'nueva_incidencia_page.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kNavyLight = Color(0xFF162852);
const _kBlue = Color(0xFF2563EB);
const _kBlueLight = Color(0xFF60A5FA);

class IncidenciasSoportePage extends StatefulWidget {
  const IncidenciasSoportePage({super.key});

  @override
  State<IncidenciasSoportePage> createState() => _IncidenciasSoportePageState();
}

class _IncidenciasSoportePageState extends State<IncidenciasSoportePage> {
  final _supabase = Supabase.instance.client;
  int _currentTab = 0;
  List<Map<String, dynamic>> _incidencias = [];
  bool _loading = true;
  String? _uid;
  String? _orgId;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    _uid = _supabase.auth.currentUser?.id;
    if (_uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final miembro = await _supabase
          .from('miembros_organizacion')
          .select('organizacion_id')
          .eq('usuario_id', _uid!)
          .eq('estado', 'ACTIVO')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      _orgId = miembro?['organizacion_id'] as String?;
      await _cargarIncidencias();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarIncidencias() async {
    if (_uid == null) return;
    setState(() => _loading = true);
    try {
      final data = await _supabase
          .from('incidencias')
          .select('id, codigo, titulo, descripcion, estado, prioridad, activos(nombre)')
          .eq('reportado_por', _uid!)
          .order('created_at', ascending: false);
      setState(() {
        _incidencias = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar tu sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirm == true) {
      await _supabase.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        darkRoute(page: const LoginPage()),
        (_) => false,
      );
    }
  }

  Future<void> _abrirEscaner() async {
    final codigo = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const EscanerPage()),
    );
    if (codigo != null && mounted) {
      // Buscar el activo con ese código de barras
      final data = await _supabase
          .from('activos')
          .select('id, nombre, codigo_barras, numero_serie, estado, ambientes(nombre), tipos_activo(nombre)')
          .eq('codigo_barras', codigo)
          .maybeSingle();
      if (data != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalleEquipoPage(activo: data),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró un equipo con ese código')),
        );
      }
    }
  }

  Color _estadoColor(String? estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.amber;
      case 'EN_ATENCION':
        return const Color(0xFF2563EB);
      case 'SOLUCIONADA':
        return Colors.green;
      case 'CERRADA':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _kNavy : Colors.grey[100]!;
    final cardColor = isDark ? _kNavyLight : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? _kNavy : _kBlue,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.build_circle_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'FixTrack',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ],
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _currentTab == 0 ? _buildMisIncidencias(
        isDark, bgColor, cardColor, textPrimary, textSecondary,
      ) : _buildEscanearTab(isDark, textPrimary, textSecondary),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NuevaIncidenciaPage()),
                );
                if (result == true) _cargarIncidencias();
              },
              backgroundColor: _kBlue,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          if (index == 1) {
            _abrirEscaner();
          } else {
            setState(() => _currentTab = index);
          }
        },
        backgroundColor: isDark ? _kNavyLight : Colors.white,
        selectedItemColor: _kBlue,
        unselectedItemColor: textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Mis incidencias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Escanear',
          ),
        ],
      ),
    );
  }

  Widget _buildMisIncidencias(
    bool isDark,
    Color bgColor,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_incidencias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: textSecondary),
            const SizedBox(height: 16),
            Text('No tienes incidencias registradas',
                style: TextStyle(color: textSecondary, fontSize: 15)),
            const SizedBox(height: 8),
            Text('Presiona + para crear una',
                style: TextStyle(color: textSecondary, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargarIncidencias,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _incidencias.length,
        itemBuilder: (context, index) {
          final inc = _incidencias[index];
          final activo = inc['activos'] as Map?;
          final estado = inc['estado'] as String?;
          final estadoColor = _estadoColor(estado);
          return Card(
            color: cardColor,
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: isDark ? 0 : 2,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.report_problem_rounded,
                        color: estadoColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inc['codigo']?.toString() ?? '—',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activo?['nombre'] as String? ?? 'Sin equipo',
                          style: TextStyle(
                              color: isDark ? _kBlueLight : _kBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          inc['descripcion']?.toString() ?? '—',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          );
        },
      ),
    );
  }

  Widget _buildEscanearTab(
      bool isDark, Color textPrimary, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner_rounded,
              size: 80, color: isDark ? _kBlueLight : _kBlue),
          const SizedBox(height: 20),
          Text('Escanear equipo',
              style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            'Toca el botón para escanear\nel código de barras del equipo',
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _abrirEscaner,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Abrir escáner',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
