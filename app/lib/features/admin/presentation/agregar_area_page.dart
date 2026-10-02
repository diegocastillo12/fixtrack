import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_toggle_button.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);

class AgregarAreaPage extends StatefulWidget {
  final String? initialSedeId;
  const AgregarAreaPage({super.key, this.initialSedeId});

  @override
  State<AgregarAreaPage> createState() => _AgregarAreaPageState();
}

class _AgregarAreaPageState extends State<AgregarAreaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  bool _loading = false;
  bool _loadingSedes = true;
  String? _error;
  String? _selectedSedeId;
  List<Map<String, dynamic>> _sedes = [];

  @override
  void initState() {
    super.initState();
    _selectedSedeId = widget.initialSedeId;
    _loadSedes();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSedes() async {
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

      final orgId = miembro['organizacion_id'] as String;

      final data = await client
          .from('sedes')
          .select('id, nombre')
          .eq('organizacion_id', orgId)
          .order('nombre');

      if (mounted) {
        setState(() {
          _sedes = List<Map<String, dynamic>>.from(data);
          if (_selectedSedeId == null && _sedes.isNotEmpty) {
            _selectedSedeId = _sedes.first['id'] as String;
          }
          _loadingSedes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSedes = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
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

      final orgId = miembro['organizacion_id'] as String;

      await client.from('areas').insert({
        'nombre': _nombreCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim().isEmpty
            ? null
            : _descripcionCtrl.text.trim(),
        'organizacion_id': orgId,
        'sede_id': _selectedSedeId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Área creada correctamente')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _kNavy : Colors.grey[100]!;
    final cardColor = isDark ? const Color(0xFF162852) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? _kNavy : _kBlue,
        foregroundColor: Colors.white,
        title: const Text('Nueva área'),
        actions: const [ThemeToggleButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                    ),

                  // Selector de Sede
                  if (_loadingSedes)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  else if (_sedes.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedSedeId,
                      dropdownColor: cardColor,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Sede a la que pertenece *',
                        prefixIcon: const Icon(Icons.business_rounded, color: _kBlue),
                        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                        border: const OutlineInputBorder(),
                      ),
                      items: _sedes.map((s) {
                        return DropdownMenuItem<String>(
                          value: s['id'] as String,
                          child: Text(s['nombre'] as String),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedSedeId = val),
                      validator: (val) => val == null ? 'Selecciona una sede' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _nombreCtrl,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Nombre del área *',
                      prefixIcon: const Icon(Icons.grid_view_rounded, color: _kBlue),
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcionCtrl,
                    style: TextStyle(color: textColor),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Descripción (opcional)',
                      prefixIcon: const Icon(Icons.description_outlined, color: _kBlue),
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Guardar área',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
