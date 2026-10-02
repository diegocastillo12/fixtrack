import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/navigation/dark_route.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../../incidencias/presentation/incidencias_soporte_page.dart';
import 'crear_organizacion_page.dart';
import 'login_page.dart';
import 'unirse_organizacion_page.dart';

// Paleta
const _kNavy     = Color(0xFF0D1B3E);
const _kNavyCard = Color(0xFF162852);
const _kBlue     = Color(0xFF2563EB);
const _kBlueLight = Color(0xFF3B82F6);
const _kWhite    = Colors.white;
const _kWhite70  = Color(0xB3FFFFFF);

class PrimerIngresoPage extends StatefulWidget {
  const PrimerIngresoPage({super.key});

  @override
  State<PrimerIngresoPage> createState() => _PrimerIngresoPageState();
}

class _PrimerIngresoPageState extends State<PrimerIngresoPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>  _fadeIn;
  late final Animation<Offset>  _slideUp;

  Map<String, dynamic>? _invitacionPendiente;
  bool _unirseLoading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _buscarInvitacion();
  }

  Future<void> _buscarInvitacion() async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) return;
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
        setState(() => _invitacionPendiente = inv);
      }
    } catch (_) {}
  }

  Future<void> _aceptarInvitacionDirecta(String codigo) async {
    setState(() => _unirseLoading = true);
    try {
      await Supabase.instance.client.rpc('unirse_organizacion', params: {
        'p_codigo': codigo.trim().toUpperCase(),
      });
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        darkRoute(page: const IncidenciasSoportePage()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _unirseLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al unirse: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _salir() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      darkRoute(page: const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? _kNavy : Colors.white;
    final textPrimary   = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? _kWhite70    : const Color(0xFF6B7280);
    final glowColor     = isDark ? _kBlue.withAlpha(38) : _kBlue.withAlpha(15);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Fondo decorativo
          Positioned(
            top: -size.height * 0.12,
            right: -size.width * 0.2,
            child: _Glow(size: size.width * 0.7, color: glowColor),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            left: -size.width * 0.2,
            child: _Glow(size: size.width * 0.75, color: glowColor),
          ),

          // Contenido
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Botón Salir y Toggle arriba derecha ──────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 8, left: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ThemeToggleButton(),
                      TextButton.icon(
                        onPressed: _salir,
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? Colors.white.withAlpha(150) : const Color(0xFF6B7280),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: const Text('Salir', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),

                // ── Contenido principal ─────────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo + Bienvenido
                              Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: isDark ? [
                                        BoxShadow(
                                          color: _kBlue.withAlpha(70),
                                          blurRadius: 30,
                                          spreadRadius: 2,
                                        ),
                                      ] : null,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    '¡Bienvenido!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Para comenzar, selecciona\nuna opción:',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 36),

                              // ── Campanita / Banner de Invitación Pendiente ──────
                              if (_invitacionPendiente != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [const Color(0xFF1E3A8A), const Color(0xFF172554)]
                                          : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _kBlue.withOpacity(0.6), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _kBlue.withOpacity(0.2),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.notifications_active_rounded,
                                                color: Colors.amber, size: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '¡Tienes una invitación!',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Para unirte a "${_invitacionPendiente!['organizaciones']?['nombre'] ?? 'tu organización'}" (${_invitacionPendiente!['rol'] ?? 'SOPORTE'})',
                                                  style: TextStyle(fontSize: 13, color: textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF0D1B3E) : Colors.white,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                    color: isDark
                                                        ? const Color(0xFF263B6E)
                                                        : const Color(0xFFCBD5E1)),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Text('Código: ',
                                                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                                                  Text(
                                                    _invitacionPendiente!['codigo']?.toString() ?? '',
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 2,
                                                        color: _kBlue),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'Copiar código',
                                            icon: const Icon(Icons.copy_rounded, color: _kBlue),
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: _invitacionPendiente!['codigo']?.toString() ?? ''));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Código copiado al portapapeles')),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      ElevatedButton.icon(
                                        onPressed: _unirseLoading
                                            ? null
                                            : () => _aceptarInvitacionDirecta(
                                                _invitacionPendiente!['codigo'].toString()),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _kBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                        ),
                                        icon: _unirseLoading
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child: CircularProgressIndicator(
                                                    color: Colors.white, strokeWidth: 2))
                                            : const Icon(Icons.check_circle_rounded, size: 20),
                                        label: Text(
                                          _unirseLoading ? 'Uniéndote...' : 'Aceptar y unirme ahora',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Tarjeta: Crear empresa
                              _OpcionCard(
                                imagePath: 'assets/images/empresa.png',
                                titulo: 'Crear nueva empresa',
                                descripcion: 'Registra tu facultad, sede\no dependencia.',
                                color: _kBlue,
                                onTap: () => Navigator.of(context).push(
                                  darkRoute(page: const CrearOrganizacionPage()),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Tarjeta: Unirme
                              _OpcionCard(
                                imagePath: 'assets/images/unirme.png',
                                titulo: 'Unirme a una empresa',
                                descripcion: 'Ingresa el código de invitación\nque te proporcionaron.',
                                color: _kBlueLight,
                                onTap: () => Navigator.of(context).push(
                                  darkRoute(page: const UnirseOrganizacionPage()),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Más información
                              Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    showDialog<void>(
                                      context: context,
                                      builder: (_) => const _InfoDialog(),
                                    );
                                  },
                                  icon: const Icon(Icons.info_outline_rounded, size: 16, color: _kBlueLight),
                                  label: const Text(
                                    'Más información',
                                    style: TextStyle(color: _kBlueLight, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de opción ─────────────────────────────────────────────────────────

class _OpcionCard extends StatefulWidget {
  const _OpcionCard({
    required this.imagePath,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.onTap,
  });

  final String imagePath;
  final String titulo;
  final String descripcion;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_OpcionCard> createState() => _OpcionCardState();
}

class _OpcionCardState extends State<_OpcionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? _kNavyCard.withAlpha(220) : Colors.white.withAlpha(230);
    final textPrimary = isDark ? _kWhite : const Color(0xFF111827);
    final textSecondary = isDark ? _kWhite70 : const Color(0xFF6B7280);
    final borderColor = isDark ? widget.color.withAlpha(80) : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: isDark ? [
                  BoxShadow(color: widget.color.withAlpha(25), blurRadius: 20, offset: const Offset(0, 6)),
                ] : [
                  BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: widget.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: widget.color.withAlpha(60), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(widget.imagePath, color: widget.color, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                        const SizedBox(height: 4),
                        Text(widget.descripcion, style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: widget.color.withAlpha(40), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.arrow_forward_ios_rounded, color: widget.color, size: 14),
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

// ── Diálogo info ──────────────────────────────────────────────────────────────

class _InfoDialog extends StatelessWidget {
  const _InfoDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF162852) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('¿Cómo funciona?', style: TextStyle(color: isDark ? _kWhite : const Color(0xFF111827), fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoItem(icon: Icons.business_rounded, color: _kBlue,
              texto: 'Crear empresa: ideal si eres administrador y quieres registrar tu institución.'),
          const SizedBox(height: 12),
          _InfoItem(icon: Icons.group_add_rounded, color: _kBlueLight,
              texto: 'Unirme: úsalo si ya tienes un código de invitación de tu organización.'),
        ],
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.color, required this.texto});
  final IconData icon;
  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: TextStyle(color: isDark ? _kWhite70 : const Color(0xFF4B5563), fontSize: 13, height: 1.4))),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
