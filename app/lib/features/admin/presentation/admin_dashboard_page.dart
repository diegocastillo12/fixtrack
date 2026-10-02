import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/navigation/dark_route.dart';
import '../../../core/theme/theme_toggle_button.dart';
import 'sedes_page.dart';
import 'areas_page.dart';
import 'ambientes_page.dart';
import 'organizacion_page.dart';
import '../../equipos/presentation/equipos_admin_page.dart';
import 'personal_page.dart';
import 'proveedores_page.dart';
import '../../incidencias/presentation/incidencias_admin_page.dart';
import '../../auth/presentation/login_page.dart';

const _kNavy     = Color(0xFF0D1B3E);
const _kNavyMid  = Color(0xFF0F2347);
const _kBlue     = Color(0xFF2563EB);

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  String _orgNombre = 'Mi organización';
  String _userNombre = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      String nombre = Supabase.instance.client.auth.currentUser?.userMetadata?['nombre'] ??
                      Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ??
                      Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? '';
      try {
        final perfil = await Supabase.instance.client
            .from('perfiles')
            .select()
            .eq('id', uid)
            .maybeSingle();
        if (perfil != null) {
          nombre = perfil['nombre_completo'] ?? perfil['nombre'] ?? nombre;
        }
      } catch (_) {}

      // Cargar nombre de la organización activa
      final membresia = await Supabase.instance.client
          .from('miembros_organizacion')
          .select('organizaciones(nombre)')
          .eq('usuario_id', uid)
          .eq('estado', 'ACTIVO')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _userNombre = nombre;
          if (membresia != null && membresia['organizaciones'] != null) {
            _orgNombre = membresia['organizaciones']['nombre'] ?? 'Mi organización';
          }
        });
      }
    } catch (e) {
      debugPrint('AdminDashboard error: $e');
    }
  }

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded,           label: 'Inicio'),
    _NavItem(icon: Icons.devices_rounded,        label: 'Inventario'),
    _NavItem(icon: Icons.report_problem_rounded, label: 'Incidencias'),
    _NavItem(icon: Icons.apartment_rounded,      label: 'Organización'),
    _NavItem(icon: Icons.local_shipping_rounded, label: 'Proveedores'),
    _NavItem(icon: Icons.people_rounded,         label: 'Personal'),
    _NavItem(icon: Icons.settings_rounded,       label: 'Ajustes'),
  ];

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0: return _HomeContent(orgNombre: _orgNombre, userNombre: _userNombre, onNav: (i) => setState(() => _selectedIndex = i));
      case 1: return const EquiposAdminPage();
      case 2: return const IncidenciasAdminPage();
      case 3: return const OrganizacionPage();
      case 4: return const ProveedoresPage();
      case 5: return const PersonalPage();
      case 6: return _AjustesContent(orgNombre: _orgNombre);
      default: return const SizedBox();
    }
  }

  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      darkRoute(page: const LoginPage()), (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _kNavy : Colors.white;
    final sidebarBg = isDark ? _kNavyMid : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: bg,
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────────
          Container(
            width: 72,
            color: sidebarBg,
            child: Column(
              children: [
                const SizedBox(height: 50),
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/logo.png', height: 36, width: 36),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _navItems.length,
                    itemBuilder: (ctx, i) {
                      final selected = _selectedIndex == i;
                      return Tooltip(
                        message: _navItems[i].label,
                        child: InkWell(
                          onTap: () => setState(() => _selectedIndex = i),
                          child: Container(
                            height: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: selected ? _kBlue.withAlpha(30) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: selected ? Border.all(color: _kBlue.withAlpha(80), width: 1) : null,
                            ),
                            child: Icon(
                              _navItems[i].icon,
                              color: selected ? _kBlue : (isDark ? Colors.white38 : Colors.grey.shade400),
                              size: 22,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Notificaciones
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.notifications_none_rounded,
                        color: isDark ? Colors.white38 : Colors.grey.shade400),
                  ),
                ),
                // Perfil / logout
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: IconButton(
                    onPressed: _cerrarSesion,
                    icon: Icon(Icons.logout_rounded,
                        color: isDark ? Colors.white38 : Colors.grey.shade400),
                    tooltip: 'Cerrar sesión',
                  ),
                ),
              ],
            ),
          ),

          // ── Main content ────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: MediaQuery.of(context).padding.top + 56,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    left: 20, right: 8,
                  ),
                  color: sidebarBg,
                  child: Row(
                    children: [
                      // Org info
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _orgNombre,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Administrador',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const ThemeToggleButton(),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                // Page content
                Expanded(child: _buildPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ── Home inicial del admin ──────────────────────────────────────────────────

class _HomeContent extends StatelessWidget {
  final String orgNombre;
  final String userNombre;
  final ValueChanged<int> onNav;
  const _HomeContent({required this.orgNombre, required this.userNombre, required this.onNav});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSec = isDark ? Colors.white60 : Colors.grey.shade600;

    final accesos = [
      _Acceso(icon: Icons.devices_rounded,        label: 'Inventario',   color: _kBlue,                 index: 1),
      _Acceso(icon: Icons.report_problem_rounded, label: 'Incidencias',  color: const Color(0xFFDC2626), index: 2),
      _Acceso(icon: Icons.apartment_rounded,      label: 'Organización', color: const Color(0xFF7C3AED), index: 3),
      _Acceso(icon: Icons.local_shipping_rounded, label: 'Proveedores',  color: const Color(0xFF0891B2), index: 4),
      _Acceso(icon: Icons.people_rounded,         label: 'Personal',     color: const Color(0xFF059669), index: 5),
      _Acceso(icon: Icons.settings_rounded,       label: 'Ajustes',      color: const Color(0xFF6B7280), index: 6),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¡Hola, ${userNombre.isNotEmpty ? userNombre.split(' ').first : "Administrador"}!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary)),
          const SizedBox(height: 4),
          Text('Panel de administración · $orgNombre',
              style: TextStyle(fontSize: 13, color: textSec)),
          const SizedBox(height: 24),

          // Acceso rápido
          Text('Acceso rápido', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: accesos.map((a) => _AccesoCard(
              icon: a.icon, label: a.label, color: a.color,
              onTap: () => onNav(a.index),
            )).toList(),
          ),

          const SizedBox(height: 24),

          // Incidencias recientes
          Row(
            children: [
              Text('Incidencias recientes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).push(darkRoute(page: const IncidenciasAdminPage())),
                child: const Text('Ver todas', style: TextStyle(color: _kBlue, fontSize: 13)),
              ),
            ],
          ),
          const _IncidenciasResumen(),
        ],
      ),
    );
  }
}

class _Acceso {
  final IconData icon;
  final String label;
  final Color color;
  final int index;
  const _Acceso({required this.icon, required this.label, required this.color, required this.index});
}

class _AccesoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AccesoCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162852) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF263B6E) : const Color(0xFFE5E7EB)),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              )),
          ],
        ),
      ),
    );
  }
}

class _IncidenciasResumen extends StatefulWidget {
  const _IncidenciasResumen();
  @override
  State<_IncidenciasResumen> createState() => _IncidenciasResumenState();
}

class _IncidenciasResumenState extends State<_IncidenciasResumen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await Supabase.instance.client
          .from('incidencias')
          .select('codigo, descripcion, estado, activos(nombre)')
          .order('created_at', ascending: false)
          .limit(4);
      if (mounted) setState(() { _items = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'PENDIENTE': return const Color(0xFFD97706);
      case 'EN_ATENCION': return _kBlue;
      case 'SOLUCIONADA': return const Color(0xFF059669);
      case 'CERRADA': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _kBlue)));
    if (_items.isEmpty) return Padding(
      padding: const EdgeInsets.all(20),
      child: Text('Sin incidencias recientes', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
    );

    return Column(
      children: _items.map((inc) {
        final estado = inc['estado'] ?? 'PENDIENTE';
        final color = _estadoColor(estado);
        final activo = (inc['activos'] as Map?)?['nombre'] ?? 'Equipo';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF162852) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF263B6E) : const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(inc['codigo'] ?? '', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  )),
                  Text(inc['descripcion'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827))),
                  Text(activo, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withAlpha(60)),
                ),
                child: Text(estado.replaceAll('_', ' '), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Ajustes content ─────────────────────────────────────────────────────────

class _AjustesContent extends StatelessWidget {
  final String orgNombre;
  const _AjustesContent({required this.orgNombre});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final bg2 = isDark ? const Color(0xFF162852) : Colors.white;
    final border = isDark ? const Color(0xFF263B6E) : const Color(0xFFE5E7EB);
    final user = Supabase.instance.client.auth.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ajustes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary)),
          const SizedBox(height: 20),
          // Perfil
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _kBlue,
                child: Text((user?.email ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(orgNombre, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                Text(user?.email ?? '', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _kBlue.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                  child: const Text('ADMIN', style: TextStyle(fontSize: 10, color: _kBlue, fontWeight: FontWeight.w700)),
                ),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          // Tema
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: _kBlue),
              title: Text('Tema', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
              subtitle: Text(isDark ? 'Oscuro' : 'Claro', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
              trailing: const ThemeToggleButton(),
            ),
          ),
        ],
      ),
    );
  }
}
