import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_toggle_button.dart';
import 'detalle_incidencia_admin_page.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);
const _kBlueLight = Color(0xFF60A5FA);

const _filtros = ['Todos', 'PENDIENTE', 'EN_ATENCION', 'SOLUCIONADA', 'CERRADA'];

class IncidenciasAdminPage extends StatefulWidget {
  const IncidenciasAdminPage({super.key});

  @override
  State<IncidenciasAdminPage> createState() => _IncidenciasAdminPageState();
}

class _IncidenciasAdminPageState extends State<IncidenciasAdminPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _incidencias = [];
  List<Map<String, dynamic>> _filtradas = [];
  bool _loading = true;
  String _filtroActivo = 'Todos';
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
      await _cargar();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargar() async {
    if (_orgId == null) return;
    setState(() => _loading = true);
    try {
      final data = await _supabase
          .from('incidencias')
          .select('id, codigo, titulo, descripcion, estado, prioridad, reportado_por, activos(nombre)')
          .eq('organizacion_id', _orgId!)
          .order('created_at', ascending: false);
      final list = List<Map<String, dynamic>>.from(data as List);
      final reporterIds = list.map((i) => i['reportado_por']).whereType<String>().toSet().toList();
      Map<String, String> perfilesMap = {};
      if (reporterIds.isNotEmpty) {
        try {
          final pData = await _supabase.from('perfiles').select('id, nombre, apellido').inFilter('id', reporterIds);
          for (final p in pData as List) {
            final n = '${p['nombre'] ?? ''} ${p['apellido'] ?? ''}'.trim();
            perfilesMap[p['id'] as String] = n.isNotEmpty ? n : 'Usuario';
          }
        } catch (_) {}
      }
      for (final inc in list) {
        final rId = inc['reportado_por'];
        if (rId != null && perfilesMap.containsKey(rId)) {
          inc['perfiles'] = {'nombre': perfilesMap[rId]};
        }
      }
      setState(() {
        _incidencias = list;
        _aplicarFiltro();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _aplicarFiltro() {
    if (_filtroActivo == 'Todos') {
      _filtradas = List.from(_incidencias);
    } else {
      _filtradas = _incidencias
          .where((i) => i['estado'] == _filtroActivo)
          .toList();
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _kNavy : Colors.grey[100]!;
    final cardColor = isDark ? const Color(0xFF162852) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    final chipBg = isDark ? const Color(0xFF0F2347) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? _kNavy : _kBlue,
        title: const Text(
          'Incidencias',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _cargar,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros en chips horizontales
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _filtros.length,
              itemBuilder: (ctx, i) {
                final filtro = _filtros[i];
                final isSelected = _filtroActivo == filtro;
                Color chipColor;
                if (filtro == 'Todos') {
                  chipColor = isDark ? _kBlueLight : _kBlue;
                } else {
                  chipColor = _estadoColor(filtro);
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      filtro == 'Todos' ? 'Todos' : filtro.replaceAll('_', ' '),
                      style: TextStyle(
                        color: isSelected ? Colors.white : textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: chipColor,
                    backgroundColor: chipBg,
                    side: BorderSide(
                        color: isSelected
                            ? chipColor
                            : (isDark ? Colors.white24 : Colors.black12)),
                    onSelected: (_) {
                      setState(() {
                        _filtroActivo = filtro;
                        _aplicarFiltro();
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Contador
          if (!_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filtradas.length} incidencia${_filtradas.length != 1 ? 's' : ''}',
                  style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),

          // Lista
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 64, color: textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              'No hay incidencias',
                              style: TextStyle(
                                  color: textSecondary, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtradas.length,
                          itemBuilder: (ctx, index) {
                            final inc = _filtradas[index];
                            final activo = inc['activos'] as Map?;
                            final perfil = inc['perfiles'] as Map?;
                            final estado = inc['estado'] as String?;
                            final estadoColor = _estadoColor(estado);
                            return Card(
                              color: cardColor,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: isDark ? 0 : 2,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DetalleIncidenciaAdminPage(
                                              incidencia: inc),
                                    ),
                                  ).then((_) => _cargar());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: estadoColor.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.report_problem_rounded,
                                          color: estadoColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              activo?['nombre'] as String? ??
                                                  'Sin equipo',
                                              style: TextStyle(
                                                color: isDark
                                                    ? _kBlueLight
                                                    : _kBlue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              inc['tipo_problema']
                                                      ?.toString() ??
                                                  '—',
                                              style: TextStyle(
                                                  color: textSecondary,
                                                  fontSize: 12),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                Icon(Icons.person_rounded,
                                                    size: 12,
                                                    color: textSecondary),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    perfil != null
                                                        ? '${perfil['nombre'] ?? ''} ${perfil['apellido'] ?? ''}'.trim().isEmpty
                                                            ? 'Desconocido'
                                                            : '${perfil['nombre'] ?? ''} ${perfil['apellido'] ?? ''}'.trim()
                                                        : 'Desconocido',
                                                    style: TextStyle(
                                                        color: textSecondary,
                                                        fontSize: 12),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              estadoColor.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: estadoColor
                                                  .withOpacity(0.4)),
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
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
