import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_toggle_button.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);

class AgregarProveedorPage extends StatefulWidget {
  const AgregarProveedorPage({super.key});

  @override
  State<AgregarProveedorPage> createState() => _AgregarProveedorPageState();
}

class _AgregarProveedorPageState extends State<AgregarProveedorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _contactoNombreCtrl = TextEditingController();
  final _contactoEmailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _contactoNombreCtrl.dispose();
    _contactoEmailCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
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

      await client.from('proveedores').insert({
        'razon_social': _nombreCtrl.text.trim(),
        'contacto_nombre': _contactoNombreCtrl.text.trim().isEmpty
            ? null
            : _contactoNombreCtrl.text.trim(),
        'email': _contactoEmailCtrl.text.trim().isEmpty
            ? null
            : _contactoEmailCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim().isEmpty
            ? null
            : _telefonoCtrl.text.trim(),
        'organizacion_id': orgId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proveedor creado correctamente')),
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

    InputDecoration _field(String label) => InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
          border: const OutlineInputBorder(),
        );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? _kNavy : _kBlue,
        foregroundColor: Colors.white,
        title: const Text('Nuevo proveedor'),
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
                  TextFormField(
                    controller: _nombreCtrl,
                    style: TextStyle(color: textColor),
                    decoration: _field('Nombre empresa *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactoNombreCtrl,
                    style: TextStyle(color: textColor),
                    decoration: _field('Nombre contacto'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactoEmailCtrl,
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _field('Email contacto'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      return emailRegex.hasMatch(v.trim())
                          ? null
                          : 'Email inválido';
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telefonoCtrl,
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.phone,
                    decoration: _field('Teléfono'),
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
                        : const Text('Guardar proveedor',
                            style: TextStyle(fontSize: 16)),
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
