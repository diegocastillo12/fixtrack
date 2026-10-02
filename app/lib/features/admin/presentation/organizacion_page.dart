import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sedes_page.dart';
import 'areas_page.dart';
import 'ambientes_page.dart';
import 'agregar_sede_page.dart';
import 'agregar_area_page.dart';
import 'agregar_ambiente_page.dart';
import '../../equipos/presentation/agregar_equipo_page.dart';
import '../../../core/theme/theme_toggle_button.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);
const _kBlueLight = Color(0xFF60A5FA);

class OrganizacionPage extends StatefulWidget {
  const OrganizacionPage({super.key});

  @override
  State<OrganizacionPage> createState() => _OrganizacionPageState();
}

class _OrganizacionPageState extends State<OrganizacionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Estado del flujo jerárquico (Drill-Down)
  String? _orgId;
  bool _loading = true;
  String? _error;

  // Datos para el árbol
  List<Map<String, dynamic>> _sedes = [];
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _ambientes = [];
  List<Map<String, dynamic>> _equipos = [];

  // Conteos
  Map<String, int> _areasPorSede = {};
  Map<String, int> _ambientesPorArea = {};
  Map<String, int> _equiposPorAmbiente = {};

  // Nivel seleccionado en la jerarquía
  Map<String, dynamic>? _selectedSede;
  Map<String, dynamic>? _selectedArea;
  Map<String, dynamic>? _selectedAmbiente;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarTodo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodo() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final miembro = await client
          .from('miembros_organizacion')
          .select('organizacion_id')
          .eq('usuario_id', userId)
          .eq('estado', 'ACTIVO')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (miembro == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      _orgId = miembro['organizacion_id'] as String;

      // Cargar Sedes, Áreas, Ambientes y Activos de esta organización en paralelo
      final results = await Future.wait([
        client.from('sedes').select('id, nombre, direccion, estado').eq('organizacion_id', _orgId!).order('nombre'),
        client.from('areas').select('id, nombre, descripcion, sede_id').eq('organizacion_id', _orgId!).order('nombre'),
        client.from('ambientes').select('id, nombre, descripcion, area_id').eq('organizacion_id', _orgId!).order('nombre'),
        client.from('activos').select('id, nombre, codigo_barras, numero_serie, estado, ambiente_id').eq('organizacion_id', _orgId!).order('nombre'),
      ]);

      final sedesData = List<Map<String, dynamic>>.from(results[0]);
      final areasData = List<Map<String, dynamic>>.from(results[1]);
      final ambData = List<Map<String, dynamic>>.from(results[2]);
      final actData = List<Map<String, dynamic>>.from(results[3]);

      // Calcular conteos
      final Map<String, int> aPorS = {};
      for (final a in areasData) {
        final sId = a['sede_id'] as String?;
        if (sId != null) {
          aPorS[sId] = (aPorS[sId] ?? 0) + 1;
        }
      }

      final Map<String, int> ambPorA = {};
      for (final amb in ambData) {
        final aId = amb['area_id'] as String?;
        if (aId != null) {
          ambPorA[aId] = (ambPorA[aId] ?? 0) + 1;
        }
      }

      final Map<String, int> eqPorAmb = {};
      for (final eq in actData) {
        final ambId = eq['ambiente_id'] as String?;
        if (ambId != null) {
          eqPorAmb[ambId] = (eqPorAmb[ambId] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _sedes = sedesData;
          _areas = areasData;
          _ambientes = ambData;
          _equipos = actData;
          _areasPorSede = aPorS;
          _ambientesPorArea = ambPorA;
          _equiposPorAmbiente = eqPorAmb;

          // Mantener selecciones activas sincronizadas si los datos cambiaron
          if (_selectedSede != null) {
            _selectedSede = _sedes.cast<Map<String, dynamic>?>().firstWhere(
                  (s) => s?['id'] == _selectedSede!['id'],
                  orElse: () => null,
                );
          }
          if (_selectedArea != null) {
            _selectedArea = _areas.cast<Map<String, dynamic>?>().firstWhere(
                  (a) => a?['id'] == _selectedArea!['id'],
                  orElse: () => null,
                );
          }
          if (_selectedAmbiente != null) {
            _selectedAmbiente = _ambientes.cast<Map<String, dynamic>?>().firstWhere(
                  (amb) => amb?['id'] == _selectedAmbiente!['id'],
                  orElse: () => null,
                );
          }

          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _kNavy : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? _kNavy : _kBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Estructura Organizacional', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar datos',
            onPressed: _cargarTodo,
          ),
          const ThemeToggleButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.account_tree_rounded, size: 20), text: 'Jerarquía'),
            Tab(icon: Icon(Icons.business_rounded, size: 20), text: 'Sedes'),
            Tab(icon: Icon(Icons.grid_view_rounded, size: 20), text: 'Áreas'),
            Tab(icon: Icon(Icons.door_sliding_rounded, size: 20), text: 'Ambientes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Explorador Jerárquico (Drill-Down Sede ➔ Área ➔ Ambiente ➔ Equipos)
          _buildJerarquiaView(isDark, textPrimary),

          // 2. Vista Plana: Sedes
          const SedesPage(),

          // 3. Vista Plana: Áreas
          const AreasPage(),

          // 4. Vista Plana: Ambientes
          const AmbientesPage(),
        ],
      ),
    );
  }

  // ── Vista Jerárquica Drill-Down ─────────────────────────────────────────────
  Widget _buildJerarquiaView(bool isDark, Color textPrimary) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kBlue));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error: $_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarTodo,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ── Breadcrumb de navegación interactivo ──
        _buildBreadcrumb(isDark),

        // ── Contenido según el nivel seleccionado ──
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildCurrentLevelContent(isDark, textPrimary),
          ),
        ),
      ],
    );
  }

  // ── Breadcrumb interactivo ──────────────────────────────────────────────────
  Widget _buildBreadcrumb(bool isDark) {
    final cardBg = isDark ? const Color(0xFF162852) : Colors.white;
    final borderColor = isDark ? const Color(0xFF263B6E) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Root: Sedes
            InkWell(
              onTap: () {
                setState(() {
                  _selectedSede = null;
                  _selectedArea = null;
                  _selectedAmbiente = null;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.business_rounded, size: 16, color: _selectedSede == null ? _kBlue : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Sedes (${_sedes.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedSede == null ? FontWeight.w700 : FontWeight.w500,
                        color: _selectedSede == null ? _kBlue : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sede seleccionada
            if (_selectedSede != null) ...[
              const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedArea = null;
                    _selectedAmbiente = null;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.grid_view_rounded, size: 16, color: _selectedArea == null ? _kBlue : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _selectedSede!['nombre'] ?? 'Sede',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedArea == null ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedArea == null ? _kBlue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Área seleccionada
            if (_selectedArea != null) ...[
              const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedAmbiente = null;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.door_sliding_rounded, size: 16, color: _selectedAmbiente == null ? _kBlue : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _selectedArea!['nombre'] ?? 'Área',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedAmbiente == null ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedAmbiente == null ? _kBlue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Ambiente seleccionado
            if (_selectedAmbiente != null) ...[
              const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.devices_rounded, size: 16, color: _kBlue),
                    const SizedBox(width: 4),
                    Text(
                      _selectedAmbiente!['nombre'] ?? 'Ambiente',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Selector de Nivel Actual ────────────────────────────────────────────────
  Widget _buildCurrentLevelContent(bool isDark, Color textPrimary) {
    if (_selectedAmbiente != null) {
      return _buildEquiposLevel(isDark, textPrimary);
    }
    if (_selectedArea != null) {
      return _buildAmbientesLevel(isDark, textPrimary);
    }
    if (_selectedSede != null) {
      return _buildAreasLevel(isDark, textPrimary);
    }
    return _buildSedesLevel(isDark, textPrimary);
  }

  // ── NIVEL 1: SEDES ──────────────────────────────────────────────────────────
  Widget _buildSedesLevel(bool isDark, Color textPrimary) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kBlue,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('Nueva Sede', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AgregarSedePage()));
          if (res == true) _cargarTodo();
        },
      ),
      body: _sedes.isEmpty
          ? _buildEmptyState(
              icon: Icons.business_rounded,
              titulo: 'No hay sedes registradas',
              subtitulo: 'Crea tu primera sede para empezar a organizar tus áreas y ambientes.',
              botonTexto: 'Crear primera Sede',
              onBoton: () async {
                final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AgregarSedePage()));
                if (res == true) _cargarTodo();
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: _sedes.length,
              itemBuilder: (ctx, i) {
                final s = _sedes[i];
                final sId = s['id'] as String;
                final areasCount = _areasPorSede[sId] ?? 0;

                return _HierarchyCard(
                  key: ValueKey('sede_$sId'),
                  icon: Icons.business_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  title: s['nombre'] ?? 'Sin nombre',
                  subtitle: s['direccion'] != null && s['direccion'].toString().isNotEmpty
                      ? s['direccion'].toString()
                      : 'Sin dirección especificada',
                  badgeText: '$areasCount ${areasCount == 1 ? "área" : "áreas"}',
                  badgeColor: const Color(0xFF7C3AED),
                  onTap: () {
                    setState(() {
                      _selectedSede = s;
                      _selectedArea = null;
                      _selectedAmbiente = null;
                    });
                  },
                );
              },
            ),
    );
  }

  // ── NIVEL 2: ÁREAS DE LA SEDE ───────────────────────────────────────────────
  Widget _buildAreasLevel(bool isDark, Color textPrimary) {
    final sId = _selectedSede!['id'] as String;
    final areasDeSede = _areas.where((a) => a['sede_id'] == sId).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Nueva Área en ${_selectedSede!['nombre']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AgregarAreaPage(initialSedeId: sId)),
          );
          if (res == true) _cargarTodo();
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de contexto
          _buildContextBanner(
            icon: Icons.business_rounded,
            title: 'Sede: ${_selectedSede!['nombre']}',
            subtitle: 'Selecciona un área para ver sus ambientes o añade una nueva.',
            onBack: () => setState(() => _selectedSede = null),
          ),

          Expanded(
            child: areasDeSede.isEmpty
                ? _buildEmptyState(
                    icon: Icons.grid_view_rounded,
                    titulo: 'No hay áreas en ${_selectedSede!['nombre']}',
                    subtitulo: 'Agrega departamentos como Informática, Administración o Biblioteca.',
                    botonTexto: 'Agregar Área a esta Sede',
                    onBoton: () async {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AgregarAreaPage(initialSedeId: sId)),
                      );
                      if (res == true) _cargarTodo();
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: areasDeSede.length,
                    itemBuilder: (ctx, i) {
                      final a = areasDeSede[i];
                      final aId = a['id'] as String;
                      final ambCount = _ambientesPorArea[aId] ?? 0;

                      return _HierarchyCard(
                        key: ValueKey('area_$aId'),
                        icon: Icons.grid_view_rounded,
                        iconColor: const Color(0xFF059669),
                        title: a['nombre'] ?? 'Sin nombre',
                        subtitle: a['descripcion'] != null && a['descripcion'].toString().isNotEmpty
                            ? a['descripcion'].toString()
                            : 'Sin descripción',
                        badgeText: '$ambCount ${ambCount == 1 ? "ambiente" : "ambientes"}',
                        badgeColor: const Color(0xFF059669),
                        onTap: () {
                          setState(() {
                            _selectedArea = a;
                            _selectedAmbiente = null;
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── NIVEL 3: AMBIENTES DEL ÁREA ─────────────────────────────────────────────
  Widget _buildAmbientesLevel(bool isDark, Color textPrimary) {
    final aId = _selectedArea!['id'] as String;
    final ambDeArea = _ambientes.where((amb) => amb['area_id'] == aId).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD97706),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Nuevo Ambiente en ${_selectedArea!['nombre']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AgregarAmbientePage(initialAreaId: aId)),
          );
          if (res == true) _cargarTodo();
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de contexto
          _buildContextBanner(
            icon: Icons.grid_view_rounded,
            title: 'Área: ${_selectedArea!['nombre']} · ${_selectedSede!['nombre']}',
            subtitle: 'Selecciona un ambiente para ver sus equipos instalados.',
            onBack: () => setState(() => _selectedArea = null),
          ),

          Expanded(
            child: ambDeArea.isEmpty
                ? _buildEmptyState(
                    icon: Icons.door_sliding_rounded,
                    titulo: 'No hay ambientes en ${_selectedArea!['nombre']}',
                    subtitulo: 'Crea salas, laboratorios u oficinas para ubicar tus activos.',
                    botonTexto: 'Agregar Ambiente a esta Área',
                    onBoton: () async {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AgregarAmbientePage(initialAreaId: aId)),
                      );
                      if (res == true) _cargarTodo();
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: ambDeArea.length,
                    itemBuilder: (ctx, i) {
                      final amb = ambDeArea[i];
                      final ambId = amb['id'] as String;
                      final eqCount = _equiposPorAmbiente[ambId] ?? 0;
                      final desc = amb['descripcion'] != null && amb['descripcion'].toString().isNotEmpty
                          ? amb['descripcion'].toString()
                          : 'Ambiente de trabajo';

                      return _HierarchyCard(
                        key: ValueKey('amb_$ambId'),
                        icon: Icons.door_sliding_rounded,
                        iconColor: const Color(0xFFD97706),
                        title: amb['nombre'] ?? 'Sin nombre',
                        subtitle: desc,
                        badgeText: '$eqCount ${eqCount == 1 ? "equipo" : "equipos"}',
                        badgeColor: const Color(0xFFD97706),
                        onTap: () {
                          setState(() {
                            _selectedAmbiente = amb;
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── NIVEL 4: EQUIPOS DEL AMBIENTE ───────────────────────────────────────────
  Widget _buildEquiposLevel(bool isDark, Color textPrimary) {
    final ambId = _selectedAmbiente!['id'] as String;
    final equiposDeAmb = _equipos.where((eq) => eq['ambiente_id'] == ambId).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Agregar Equipo a ${_selectedAmbiente!['nombre']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AgregarEquipoPage(initialAmbienteId: ambId)),
          );
          if (res == true) _cargarTodo();
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de contexto
          _buildContextBanner(
            icon: Icons.door_sliding_rounded,
            title: 'Ambiente: ${_selectedAmbiente!['nombre']}',
            subtitle: 'Ubicado en ${_selectedArea!['nombre']} · ${_selectedSede!['nombre']}',
            onBack: () => setState(() => _selectedAmbiente = null),
          ),

          Expanded(
            child: equiposDeAmb.isEmpty
                ? _buildEmptyState(
                    icon: Icons.devices_rounded,
                    titulo: 'No hay equipos en este ambiente',
                    subtitulo: 'Registra computadoras, monitores, proyectores o impresoras aquí.',
                    botonTexto: 'Agregar Primer Equipo',
                    onBoton: () async {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AgregarEquipoPage(initialAmbienteId: ambId)),
                      );
                      if (res == true) _cargarTodo();
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: equiposDeAmb.length,
                    itemBuilder: (ctx, i) {
                      final eq = equiposDeAmb[i];
                      final estado = eq['estado']?.toString() ?? 'OPERATIVO';

                      Color badgeColor = Colors.green;
                      if (estado == 'MANTENIMIENTO') badgeColor = Colors.orange;
                      if (estado == 'DE_BAJA') badgeColor = Colors.red;

                      return Card(
                        elevation: isDark ? 0 : 2,
                        color: isDark ? const Color(0xFF162852) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _kBlue.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.devices_rounded, color: _kBlue, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      eq['nombre'] ?? 'Sin nombre',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'S/N: ${eq['numero_serie'] ?? '—'} · Código: ${eq['codigo_barras'] ?? '—'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: badgeColor.withOpacity(0.4)),
                                ),
                                child: Text(
                                  estado,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Context Banner ──────────────────────────────────────────────────────────
  Widget _buildContextBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onBack,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101F42) : const Color(0xFFEEF2F6),
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF263B6E) : const Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Volver al nivel superior',
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required String botonTexto,
    required VoidCallback onBoton,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: _kBlue),
            ),
            const SizedBox(height: 20),
            Text(titulo, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text(subtitulo, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onBoton,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(botonTexto, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de la Jerarquía ─────────────────────────────────────────────────
class _HierarchyCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final VoidCallback onTap;

  const _HierarchyCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 0 : 2,
      color: isDark ? const Color(0xFF162852) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
