import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_toggle_button.dart';
import 'agregar_ambiente_page.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);

class AmbientesPage extends StatefulWidget {
  const AmbientesPage({super.key});

  @override
  State<AmbientesPage> createState() => _AmbientesPageState();
}

class _AmbientesPageState extends State<AmbientesPage> {
  List<Map<String, dynamic>> _ambientes = [];
  bool _loading = true;
  String? _error;
  String? _orgId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser!.id;

      final miembro = await client
          .from('miembros_organizacion')
          .select('organizacion_id')
          .eq('usuario_id', userId)
          .eq('estado', 'ACTIVO')
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      _orgId = miembro['organizacion_id'] as String;

      // Obtenemos las áreas de la organización primero
      final areas = await client
          .from('areas')
          .select('id')
          .eq('organizacion_id', _orgId!);

      final areaIds = (areas as List).map((a) => a['id'] as String).toList();

      if (areaIds.isEmpty) {
        if (mounted) setState(() => _ambientes = []);
        return;
      }

      // Luego buscamos ambientes que pertenezcan a esas áreas
      final data = await client
          .from('ambientes')
          .select('id, nombre, descripcion, area_id, areas(nombre)')
          .inFilter('area_id', areaIds)
          .order('nombre');

      if (mounted) {
        setState(() => _ambientes = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _eliminar(String id) async {
    try {
      await Supabase.instance.client.from('ambientes').delete().eq('id', id);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _kNavy : Colors.grey[100]!;
    final cardColor = isDark ? const Color(0xFF162852) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? _kNavy : _kBlue,
        foregroundColor: Colors.white,
        title: const Text('Ambientes'),
        actions: const [ThemeToggleButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo ambiente'),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgregarAmbientePage()),
          );
          if (result == true) _loadData();
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _loadData, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : _ambientes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.door_sliding_rounded,
                              size: 64, color: subColor),
                          const SizedBox(height: 16),
                          Text('No hay ambientes registrados',
                              style: TextStyle(color: subColor, fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _ambientes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final amb = _ambientes[i];
                          final areaNombre =
                              (amb['areas'] as Map?)?.containsKey('nombre') ==
                                      true
                                  ? amb['areas']['nombre'] as String?
                                  : null;
                          final descripcion = amb['descripcion'] as String?;

                          return Card(
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _kBlue.withOpacity(0.15),
                                child: Icon(Icons.door_sliding_rounded,
                                    color: _kBlue),
                              ),
                              title: Text(amb['nombre'] ?? '',
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (areaNombre != null)
                                    Text('Área: $areaNombre',
                                        style: TextStyle(color: subColor)),
                                  if (descripcion != null && descripcion.isNotEmpty)
                                    Text(descripcion,
                                        style: TextStyle(
                                            color: subColor, fontSize: 12)),
                                ],
                              ),
                              isThreeLine: areaNombre != null && descripcion != null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Eliminar ambiente'),
                                    content: const Text(
                                        '¿Estás seguro de eliminar este ambiente?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancelar')),
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _eliminar(amb['id']);
                                          },
                                          child: const Text('Eliminar',
                                              style: TextStyle(
                                                  color: Colors.red))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
