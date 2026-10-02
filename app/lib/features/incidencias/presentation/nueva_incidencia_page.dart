import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_toggle_button.dart';
import 'confirmacion_incidencia_page.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);
const _kBlueLight = Color(0xFF60A5FA);

const _tiposProblema = [
  'No enciende',
  'Pantalla dañada',
  'Teclado roto',
  'Red/Internet',
  'Recalentamiento',
  'Ruido extraño',
  'Otro',
];

class NuevaIncidenciaPage extends StatefulWidget {
  final String? activoId;
  final String? activoNombre;

  const NuevaIncidenciaPage({super.key, this.activoId, this.activoNombre});

  @override
  State<NuevaIncidenciaPage> createState() => _NuevaIncidenciaPageState();
}

class _NuevaIncidenciaPageState extends State<NuevaIncidenciaPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _descripcionCtrl = TextEditingController();
  final _picker = ImagePicker();

  String? _activoId;
  String? _activoNombre;
  String? _tipoProblema;
  String? _orgId;
  String? _uid;
  bool _guardando = false;
  bool _loadingActivos = false;

  List<Map<String, dynamic>> _activos = [];
  List<String> _fotos = [];

  @override
  void initState() {
    super.initState();
    _activoId = widget.activoId;
    _activoNombre = widget.activoNombre;
    _initUser();
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _initUser() async {
    _uid = _supabase.auth.currentUser?.id;
    if (_uid == null) return;
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
    } catch (_) {}

    if (widget.activoId == null && _orgId != null) {
      await _cargarActivos();
    }
  }

  Future<void> _cargarActivos() async {
    setState(() => _loadingActivos = true);
    final data = await _supabase
        .from('activos')
        .select('id, nombre')
        .eq('organizacion_id', _orgId!)
        .order('nombre');
    setState(() {
      _activos = List<Map<String, dynamic>>.from(data as List);
      _loadingActivos = false;
    });
  }

  Future<void> _agregarFoto(ImageSource source) async {
    if (_fotos.length >= 3) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() => _fotos.add(picked.path));
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_activoId == null && _activos.isNotEmpty && widget.activoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un equipo')),
      );
      return;
    }
    if (_tipoProblema == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el tipo de problema')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final result = await _supabase
          .from('incidencias')
          .insert({
            'activo_id': _activoId,
            'titulo': _tipoProblema,
            'descripcion': _descripcionCtrl.text.trim(),
            'estado': 'EN_ATENCION',
            'prioridad': 'MEDIA',
            'organizacion_id': _orgId,
            'reportado_por': _uid,
          })
          .select('codigo')
          .single();

      final codigo = result['codigo']?.toString() ?? 'INC-????';

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmacionIncidenciaPage(codigo: codigo),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar: $e')),
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

    InputDecoration inputDeco(String label, {IconData? icon}) => InputDecoration(
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
            borderSide: BorderSide(
                color: isDark ? _kBlueLight : _kBlue, width: 2),
          ),
        );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? _kNavy : _kBlue,
        title: const Text(
          'Nueva incidencia',
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [ThemeToggleButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de equipo (solo si no se pasó)
              if (widget.activoId == null) ...[
                Text('Equipo afectado',
                    style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 12),
                _loadingActivos
                    ? const Center(child: CircularProgressIndicator())
                    : _activos.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange[400]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No hay equipos registrados en la organización. Se registrará la incidencia sin equipo.',
                                    style: TextStyle(color: textSecondary, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: _activoId,
                            decoration: inputDeco('Seleccionar equipo',
                                icon: Icons.devices_rounded),
                            dropdownColor: cardColor,
                            style: TextStyle(color: textPrimary),
                            items: _activos
                                .map((a) => DropdownMenuItem(
                                      value: a['id'].toString(),
                                      child: Text(a['nombre'] ?? ''),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() => _activoId = v);
                              _activoNombre = _activos
                                  .firstWhere((a) => a['id'].toString() == v,
                                      orElse: () => {})['nombre']
                                  ?.toString();
                            },
                            validator: (v) =>
                                v == null && _activos.isNotEmpty ? 'Campo requerido' : null,
                          ),
                const SizedBox(height: 20),
              ],

              // Equipo seleccionado (si se pasó)
              if (widget.activoId != null) ...[
                Text('Equipo afectado',
                    style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.devices_rounded,
                          color: isDark ? _kBlueLight : _kBlue),
                      const SizedBox(width: 12),
                      Text(
                        widget.activoNombre ?? '—',
                        style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Tipo de problema
              Text('Tipo de problema',
                  style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _tipoProblema,
                decoration: inputDeco('Seleccionar tipo',
                    icon: Icons.warning_amber_rounded),
                dropdownColor: cardColor,
                style: TextStyle(color: textPrimary),
                items: _tiposProblema
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _tipoProblema = v),
                validator: (v) => v == null ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),

              // Descripción
              Text('Descripción',
                  style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionCtrl,
                style: TextStyle(color: textPrimary),
                maxLines: 3,
                decoration: inputDeco('Describe el problema detalladamente...',
                    icon: Icons.description_rounded),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'La descripción es requerida'
                    : null,
              ),
              const SizedBox(height: 20),

              // Fotos
              Text('Fotos (opcional, máx. 3)',
                  style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _FotoButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Cámara',
                    color: isDark ? _kBlueLight : _kBlue,
                    isDark: isDark,
                    enabled: _fotos.length < 3,
                    onTap: () => _agregarFoto(ImageSource.camera),
                  ),
                  const SizedBox(width: 10),
                  _FotoButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galería',
                    color: isDark ? _kBlueLight : _kBlue,
                    isDark: isDark,
                    enabled: _fotos.length < 3,
                    onTap: () => _agregarFoto(ImageSource.gallery),
                  ),
                ],
              ),
              if (_fotos.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _fotos.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              _fotos[i],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: cardColor,
                                child: Icon(Icons.image_rounded,
                                    color: textSecondary),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _fotos.removeAt(i)),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _guardando ? 'Enviando...' : 'Registrar incidencia',
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

class _FotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool enabled;
  final VoidCallback onTap;

  const _FotoButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: enabled ? color : Colors.grey),
        foregroundColor: enabled ? color : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
