import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_toggle_button.dart';
import 'agregar_sede_page.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);

class SedesPage extends StatefulWidget {
  const SedesPage({super.key});
  @override
  State<SedesPage> createState() => _SedesPageState();
}

class _SedesPageState extends State<SedesPage> {
  List<Map<String, dynamic>> _sedes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      final memb = await Supabase.instance.client
          .from('miembros_organizacion')
          .select('organizacion_id')
          .eq('usuario_id', uid)
          .eq('estado', 'ACTIVO')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (memb == null) return;
      final orgId = memb['organizacion_id'];
      final data = await Supabase.instance.client
          .from('sedes')
          .select('id, nombre, direccion, created_at')
          .eq('organizacion_id', orgId)
          .order('nombre');
      if (mounted) setState(() { _sedes = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _eliminar(String id) async {
    await Supabase.instance.client.from('sedes').delete().eq('id', id);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _kNavy : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kBlue,
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgregarSedePage()));
          _cargar();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva sede', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Sedes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary)),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: _kBlue)))
          else if (_sedes.isEmpty)
            Expanded(child: _EmptyState(
              icon: Icons.business_rounded,
              mensaje: 'No tienes sedes registradas.',
              accion: 'Agregar primera sede',
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgregarSedePage()));
                _cargar();
              },
            ))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                itemCount: _sedes.length,
                itemBuilder: (ctx, i) {
                  final s = _sedes[i];
                  return _SedeCard(
                    nombre: s['nombre'] ?? '',
                    direccion: s['direccion'] ?? '',
                    onEliminar: () => _eliminar(s['id']),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SedeCard extends StatelessWidget {
  final String nombre;
  final String direccion;
  final VoidCallback onEliminar;
  const _SedeCard({required this.nombre, required this.direccion, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162852) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF263B6E) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _kBlue.withAlpha(20), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.business_rounded, color: _kBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nombre, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF111827))),
              if (direccion.isNotEmpty) Text(direccion, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
            onPressed: onEliminar,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String mensaje;
  final String accion;
  final VoidCallback onTap;
  const _EmptyState({required this.icon, required this.mensaje, required this.accion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 56, color: isDark ? Colors.white24 : Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(mensaje, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 14)),
        const SizedBox(height: 12),
        TextButton(onPressed: onTap, child: Text(accion, style: const TextStyle(color: _kBlue, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
