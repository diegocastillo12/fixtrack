import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/navigation/dark_route.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../../incidencias/presentation/incidencias_soporte_page.dart';

const _kBlue   = Color(0xFF2563EB);
const _kBlueBg = Color(0xFFEFF6FF);
const _kBlueLight = Color(0xFF60A5FA);
const _kGrey   = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);
const _kRed    = Color(0xFFEF4444);

class UnirseOrganizacionPage extends StatefulWidget {
  final String? initialCodigo;
  const UnirseOrganizacionPage({super.key, this.initialCodigo});

  @override
  State<UnirseOrganizacionPage> createState() => _UnirseOrganizacionPageState();
}

class _UnirseOrganizacionPageState extends State<UnirseOrganizacionPage> {
  final _formKey    = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();

  bool    _isLoading = false;
  String? _error;

  Map<String, dynamic>? _invitacionDetectada;
  bool _buscando = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialCodigo != null) {
      _codigoCtrl.text = widget.initialCodigo!;
    }
    _buscarInvitacionPorCorreo();
  }

  Future<void> _buscarInvitacionPorCorreo() async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) {
      if (mounted) setState(() => _buscando = false);
      return;
    }

    try {
      final inv = await Supabase.instance.client
          .from('invitaciones')
          .select('id, codigo, rol, organizacion_id, organizaciones(nombre)')
          .eq('email', email.trim().toLowerCase())
          .eq('estado', 'PENDIENTE')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted && inv != null) {
        setState(() {
          _invitacionDetectada = inv;
          if (_codigoCtrl.text.isEmpty && inv['codigo'] != null) {
            _codigoCtrl.text = inv['codigo'].toString();
          }
          _buscando = false;
        });
      } else {
        if (mounted) setState(() => _buscando = false);
      }
    } catch (_) {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _unirse() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _error = null; });

    try {
      await Supabase.instance.client.rpc('unirse_organizacion', params: {
        'p_codigo': _codigoCtrl.text.trim().toUpperCase(),
      });

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        darkRoute(page: const IncidenciasSoportePage()),
        (_) => false,
      );
    } on PostgrestException catch (e) {
      String mensaje = 'Código inválido o expirado.';
      if (e.message.contains('Ya eres miembro')) {
        mensaje = 'Ya eres miembro de esta organización.';
      }
      setState(() { _isLoading = false; _error = mensaje; });
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Error al conectar. Intenta de nuevo.'; });
      debugPrint('[FixTrack] unirse_organizacion error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B3E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);

    final orgNombre = _invitacionDetectada?['organizaciones']?['nombre'] as String? ?? 'tu organización';

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
          'Unirse a una organización',
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
              const SizedBox(height: 8),

              // Ilustración con logo ORGANIZACION.png
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: _kBlueBg,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Image.asset('assets/images/organizacion.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 20),

              // ── Campanita / Banner de Invitación Detectada por Correo ──
              if (_invitacionDetectada != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF102552) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBlue.withOpacity(0.5), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '¡Invitación encontrada para tu correo!',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                                Text(
                                  'Fuiste invitado a unirte a "$orgNombre"',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Código: ', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
                          Text(
                            _invitacionDetectada!['codigo']?.toString() ?? '',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kBlue, letterSpacing: 2),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: _kBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            icon: const Icon(Icons.paste_rounded, size: 16),
                            label: const Text('Auto-rellenar'),
                            onPressed: () {
                              setState(() {
                                _codigoCtrl.text = _invitacionDetectada!['codigo']?.toString() ?? '';
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Título y descripción
              const Text(
                'Código de invitación',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Ingresa el código proporcionado por el administrador para unirte a su equipo.',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : _kGrey),
              ),
              const SizedBox(height: 16),

              // Campo de texto del código
              TextFormField(
                controller: _codigoCtrl,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _unirse(),
                maxLength: 12,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                ],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'ABC-12345',
                  hintStyle: TextStyle(
                    fontSize: 20,
                    color: isDark ? Colors.white54 : const Color(0xFFD1D5DB),
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                  ),
                  counterText: '',
                  filled:    true,
                  fillColor: isDark ? const Color(0xFF162852) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF263B6E) : _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF263B6E) : _kBorder, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _kBlue, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _kRed),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _kRed, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el código';
                  if (v.trim().length < 6) return 'El código tiene al menos 6 caracteres';
                  return null;
                },
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: _kRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: const TextStyle(color: _kRed, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Botón Unirme
              ElevatedButton(
                onPressed: _isLoading ? null : _unirse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Unirme ahora',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
