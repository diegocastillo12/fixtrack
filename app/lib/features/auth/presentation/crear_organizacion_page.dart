import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/navigation/dark_route.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../../admin/presentation/admin_dashboard_page.dart';

const _kBlue    = Color(0xFF2563EB);
const _kBlueBg  = Color(0xFFEFF6FF);
const _kGrey    = Color(0xFF6B7280);
const _kBorder  = Color(0xFFE5E7EB);
const _kRed     = Color(0xFFEF4444);

class CrearOrganizacionPage extends StatefulWidget {
  const CrearOrganizacionPage({super.key});

  @override
  State<CrearOrganizacionPage> createState() => _CrearOrganizacionPageState();
}

class _CrearOrganizacionPageState extends State<CrearOrganizacionPage> {
  final _formKey    = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _rucCtrl    = TextEditingController();

  String  _tipoInstitucion = 'Universidad';
  bool    _isLoading       = false;
  String? _error;
  File?   _logoImage;

  static const _tipos = [
    'Universidad',
    'Instituto',
    'Colegio',
    'Empresa',
    'Clínica',
    'Municipio',
    'Otro',
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _rucCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _logoImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _crear() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _error = null; });

    try {
      await Supabase.instance.client.rpc('crear_organizacion', params: {
        'p_nombre':   _nombreCtrl.text.trim(),
        'p_ruc':      _rucCtrl.text.trim().isEmpty ? null : _rucCtrl.text.trim(),
      });

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        darkRoute(page: const AdminDashboardPage()),
        (_) => false,
      );
    } catch (e) {
      setState(() { _isLoading = false; _error = 'No se pudo crear la organización.'; });
      // ignore: avoid_print
      print('[FixTrack] crear_organizacion error: $e');
    }
  }

  InputDecoration _field(String label, {String? hint}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? const Color(0xFF162852) : Colors.white;
    final border = isDark ? const Color(0xFF263B6E) : _kBorder;
    final hintCol = isDark ? Colors.white54 : const Color(0xFFD1D5DB);
    final labelCol = isDark ? Colors.white70 : _kGrey;

    return InputDecoration(
      labelText: label,
      hintText:  hint,
      labelStyle: TextStyle(color: labelCol, fontSize: 14),
      hintStyle:  TextStyle(color: hintCol),
      filled:     true,
      fillColor:  fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kRed, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B3E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Crear organización',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: ThemeToggleButton(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono ilustrativo
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _kBlueBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Image.asset('assets/images/empresa.png', color: _kBlue),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Configura tu institución',
                  style: TextStyle(fontSize: 14, color: _kGrey),
                ),
              ),
              const SizedBox(height: 32),

              // Nombre
              const _Label('Nombre de la organización'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: textPrimary),
                decoration: _field('', hint: 'Instituto Tecnológico ABC'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Escribe el nombre';
                  if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // RUC
              const _Label('RUC (opcional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _rucCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: textPrimary),
                decoration: _field('', hint: '20123456789'),
              ),
              const SizedBox(height: 20),

              // Tipo de institución
              const _Label('Tipo de institución'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _tipoInstitucion,
                onChanged: (v) => setState(() => _tipoInstitucion = v!),
                decoration: _field(''),
                style: TextStyle(color: textPrimary, fontSize: 15),
                dropdownColor: isDark ? const Color(0xFF162852) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                items: _tipos.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t),
                )).toList(),
              ),
              const SizedBox(height: 20),

              // Logo (opcional)
              const _Label('Logo (opcional)'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF162852) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF263B6E) : _kBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _kBlueBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _logoImage != null 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_logoImage!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.image_outlined, color: _kBlue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _seleccionarImagen,
                            child: const Text(
                              'Seleccionar imagen',
                              style: TextStyle(
                                color: _kBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _logoImage != null ? 'Imagen seleccionada' : 'PNG o JPG, máximo 2 MB',
                            style: TextStyle(color: isDark ? Colors.white54 : _kGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (_logoImage != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: isDark ? Colors.white54 : _kGrey,
                        onPressed: () => setState(() => _logoImage = null),
                      ),
                  ],
                ),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kRed.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: _kRed, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: const TextStyle(color: _kRed, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Botón
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _crear,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kBlue,
                    disabledBackgroundColor: _kBlue.withAlpha(100),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Crear organización',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF374151),
      ),
    );
  }
}
