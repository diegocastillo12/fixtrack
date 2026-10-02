import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_toggle_button.dart';
import 'escaner_page.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);
const _kBlueLight = Color(0xFF60A5FA);

class AgregarEquipoPage extends StatefulWidget {
  final String? initialAmbienteId;
  const AgregarEquipoPage({super.key, this.initialAmbienteId});

  @override
  State<AgregarEquipoPage> createState() => _AgregarEquipoPageState();
}

class _AgregarEquipoPageState extends State<AgregarEquipoPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _numSerieCtrl = TextEditingController();
  final _codigoBarrasCtrl = TextEditingController();

  List<Map<String, dynamic>> _tipos = [];
  List<Map<String, dynamic>> _ambientes = [];
  List<Map<String, dynamic>> _proveedores = [];

  String? _tipoId;
  String? _ambienteId;
  String? _proveedorId;
  String? _orgId;
  bool _loading = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _ambienteId = widget.initialAmbienteId;
    _initData();
  }

  @override
  void dispose() {
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _numSerieCtrl.dispose();
    _codigoBarrasCtrl.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _loading = true);
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    final miembro = await _supabase
        .from('miembros_organizacion')
        .select('organizacion_id')
        .eq('usuario_id', uid)
        .eq('estado', 'ACTIVO')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    _orgId = miembro?['organizacion_id'] as String?;

    if (_orgId != null) {
      final results = await Future.wait([
        _supabase.from('tipos_activo').select('id, nombre').order('nombre'),
        _supabase
            .from('ambientes')
            .select('id, nombre')
            .eq('organizacion_id', _orgId!)
            .order('nombre'),
        _supabase
            .from('proveedores')
            .select('id, razon_social')
            .eq('organizacion_id', _orgId!)
            .order('razon_social'),
      ]);
      setState(() {
        _tipos = List<Map<String, dynamic>>.from(results[0] as List);
        _ambientes = List<Map<String, dynamic>>.from(results[1] as List);
        _proveedores = List<Map<String, dynamic>>.from(results[2] as List);
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _escanearCodigo() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const EscanerPage()),
    );
    if (result != null) {
      _codigoBarrasCtrl.text = result;
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un tipo de equipo')),
      );
      return;
    }
    if (_ambienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un ambiente/ubicación')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final nombre = '${_marcaCtrl.text.trim()} ${_modeloCtrl.text.trim()}';
      final data = {
        'nombre': nombre,
        'tipo_activo_id': _tipoId,
        'codigo_barras': _codigoBarrasCtrl.text.trim().isEmpty
            ? null
            : _codigoBarrasCtrl.text.trim(),
        'numero_serie': _numSerieCtrl.text.trim().isEmpty
            ? null
            : _numSerieCtrl.text.trim(),
        'ambiente_id': _ambienteId,
        'organizacion_id': _orgId,
        'estado': 'OPERATIVO',
      };
      if (_proveedorId != null) data['proveedor_id'] = _proveedorId;

      await _supabase.from('activos').insert(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipo registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _kNavy : Colors.grey[100]!;
    final cardColor = isDark ? const Color(0xFF162852) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark ? Colors.white24 : Colors.black12;
    final fillColor = isDark ? const Color(0xFF0F2347) : Colors.white;

    InputDecoration _inputDeco(String label, {IconData? icon}) => InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textSecondary),
          prefixIcon: icon != null
              ? Icon(icon, color: isDark ? _kBlueLight : _kBlue, size: 20)
              : null,
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDark ? _kBlueLight : _kBlue, width: 2),
          ),
        );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? _kNavy : _kBlue,
        title: const Text(
          'Nuevo equipo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [ThemeToggleButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: 'Información del equipo', textColor: textPrimary),
                    const SizedBox(height: 12),

                    // Tipo de equipo
                    DropdownButtonFormField<String>(
                      value: _tipoId,
                      decoration: _inputDeco('Tipo de equipo', icon: Icons.category_rounded),
                      dropdownColor: cardColor,
                      style: TextStyle(color: textPrimary),
                      items: _tipos
                          .map((t) => DropdownMenuItem(
                                value: t['id'].toString(),
                                child: Text(t['nombre'] ?? ''),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _tipoId = v),
                      validator: (v) => v == null ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 14),

                    // Marca
                    TextFormField(
                      controller: _marcaCtrl,
                      style: TextStyle(color: textPrimary),
                      decoration: _inputDeco('Marca', icon: Icons.business_rounded),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 14),

                    // Modelo
                    TextFormField(
                      controller: _modeloCtrl,
                      style: TextStyle(color: textPrimary),
                      decoration: _inputDeco('Modelo', icon: Icons.devices_rounded),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 14),

                    // Número de serie
                    TextFormField(
                      controller: _numSerieCtrl,
                      style: TextStyle(color: textPrimary),
                      decoration: _inputDeco('Número de serie', icon: Icons.tag_rounded),
                    ),
                    const SizedBox(height: 14),

                    // Código de barras con botón escanear
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codigoBarrasCtrl,
                            style: TextStyle(color: textPrimary),
                            decoration: _inputDeco('Código de barras', icon: Icons.qr_code_rounded),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: OutlinedButton.icon(
                            onPressed: _escanearCodigo,
                            icon: Icon(Icons.qr_code_scanner_rounded,
                                color: isDark ? _kBlueLight : _kBlue, size: 18),
                            label: Text(
                              'Escanear\ncódigo',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? _kBlueLight : _kBlue,
                                fontSize: 12,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: isDark ? _kBlueLight : _kBlue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    _SectionTitle(title: 'Ubicación', textColor: textPrimary),
                    const SizedBox(height: 12),

                    // Ambiente
                    DropdownButtonFormField<String>(
                      value: _ambienteId,
                      decoration: _inputDeco('Ubicación / Ambiente',
                          icon: Icons.location_on_rounded),
                      dropdownColor: cardColor,
                      style: TextStyle(color: textPrimary),
                      items: _ambientes
                          .map((a) => DropdownMenuItem(
                                value: a['id'].toString(),
                                child: Text(a['nombre'] ?? ''),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _ambienteId = v),
                      validator: (v) => v == null ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 22),

                    _SectionTitle(title: 'Proveedor (opcional)', textColor: textPrimary),
                    const SizedBox(height: 12),

                    // Proveedor
                    DropdownButtonFormField<String>(
                      value: _proveedorId,
                      decoration: _inputDeco('Proveedor', icon: Icons.store_rounded),
                      dropdownColor: cardColor,
                      style: TextStyle(color: textPrimary),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Ninguno')),
                        ..._proveedores.map((p) => DropdownMenuItem(
                              value: p['id'].toString(),
                              child: Text(p['razon_social'] ?? p['nombre'] ?? ''),
                            )),
                      ],
                      onChanged: (v) => setState(() => _proveedorId = v),
                    ),
                    const SizedBox(height: 32),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _guardando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _guardando ? 'Guardando...' : 'Guardar equipo',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color textColor;
  const _SectionTitle({required this.title, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
