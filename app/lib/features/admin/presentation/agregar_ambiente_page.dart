import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_toggle_button.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);

class AgregarAmbientePage extends StatefulWidget {
  final String? initialAreaId;
  const AgregarAmbientePage({super.key, this.initialAreaId});

  @override
  State<AgregarAmbientePage> createState() => _AgregarAmbientePageState();
}

class _AgregarAmbientePageState extends State<AgregarAmbientePage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  bool _loading = false;
  bool _loadingAreas = true;
  String? _error;
  String? _selectedAreaId;
  List<Map<String, dynamic>> _areas = [];

  @override
  void initState() {
    super.initState();
    _selectedAreaId = widget.initialAreaId;
    _loadAreas();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
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
          .from('areas')
          .select('id, nombre')
          .eq('organizacion_id', orgId)
          .order('nombre');

      if (mounted) {
        setState(() {
          _areas = List<Map<String, dynamic>>.from(data);
          if (_selectedAreaId == null && _areas.isNotEmpty) {
            _selectedAreaId = _areas.first['id'] as String;
          }
          _loadingAreas = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingAreas = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAreaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un área')),
      );
      return;
    }
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

      await client.from('ambientes').insert({
        'nombre': _nombreCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim().isEmpty
            ? null
            : _descripcionCtrl.text.trim(),
        'area_id': _selectedAreaId,
        'organizacion_id': orgId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ambiente creado correctamente')),
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

    InputDecoration fieldDecoration(String label, IconData icon) => InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _kBlue),
          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
          border: const OutlineInputBorder(),
        );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? _kNavy : _kBlue,
        foregroundColor: Colors.white,
        title: const Text('Nuevo ambiente'),
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

                  // Selector de Área
                  if (_loadingAreas)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  else if (_areas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text('Primero debes registrar al menos un área.',
                          style: TextStyle(color: Colors.orange.shade700)),
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      value: _selectedAreaId,
                      dropdownColor: cardColor,
                      style: TextStyle(color: textColor),
                      decoration: fieldDecoration('Área a la que pertenece *', Icons.grid_view_rounded),
                      items: _areas.map((a) {
                        return DropdownMenuItem<String>(
                          value: a['id'] as String,
                          child: Text(a['nombre'] as String),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedAreaId = val),
                      validator: (val) => val == null ? 'Selecciona un área' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _nombreCtrl,
                    style: TextStyle(color: textColor),
                    decoration: fieldDecoration('Nombre del ambiente (ej. Lab 01, Oficina 102) *', Icons.door_sliding_rounded),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcionCtrl,
                    style: TextStyle(color: textColor),
                    maxLines: 2,
                    decoration: fieldDecoration('Descripción (opcional)', Icons.description_outlined),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading || _areas.isEmpty ? null : _guardar,
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
                        : const Text('Guardar ambiente',
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
