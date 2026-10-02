import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/theme_toggle_button.dart';

import '../../../core/navigation/dark_route.dart';
import 'primer_ingreso_page.dart';

// Paleta (misma que login)
const _kNavy = Color(0xFF0D1B3E);
const _kNavyLight = Color(0xFF162852);
const _kBlue = Color(0xFF2563EB);
const _kBlueLight = Color(0xFF3B82F6);
const _kWhite = Colors.white;
const _kWhite60 = Color(0x99FFFFFF);
const _kWhite15 = Color(0x26FFFFFF);
const _kRed = Color(0xFFEF4444);
const _kGreen = Color(0xFF22C55E);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registrarse() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'nombre': _nameController.text.trim()},
      );

      if (!mounted) return;

      if (response.session != null) {
        Navigator.of(context).pushAndRemoveUntil(
          darkRoute(page: const PrimerIngresoPage()),
          (_) => false,
        );
        return;
      }

      setState(() {
        _isLoading = false;
        _successMessage = 'Cuenta creada. Revisa tu correo para confirmarla.';
      });
    } on AuthException catch (error) {
      // ignore: avoid_print
      print('[FixTrack] RegisterException: ${error.message}');
      _mostrarError(_mensajeDeAuth(error));
    } catch (e) {
      // ignore: avoid_print
      print('[FixTrack] Error inesperado en registro: $e');
      _mostrarError('No pudimos crear tu cuenta. Inténtalo de nuevo.');
    }
  }

  void _mostrarError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  String _mensajeDeAuth(AuthException error) {
    final msg = error.message.toLowerCase();
    if (msg.contains('already registered') || msg.contains('already been registered')) {
      return 'Ya existe una cuenta con este correo.';
    }
    if (msg.contains('password')) return 'La contraseña no cumple los requisitos.';
    return 'Error: ${error.message}';
  }

  String? _validarNombre(String? value) {
    if (value == null || value.trim().isEmpty) return 'Escribe tu nombre';
    return null;
  }

  String? _validarCorreo(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Escribe tu correo electrónico';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Escribe un correo válido';
    }
    return null;
  }

  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) return 'Escribe una contraseña';
    if (value.length < 6) return 'Debe tener al menos 6 caracteres';
    return null;
  }

  String? _validarConfirmacion(String? value) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != _passwordController.text) return 'Las contraseñas no coinciden';
    return null;
  }

  InputDecoration _field({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? _kWhite15 : Colors.white;
    final border = isDark ? _kWhite15 : const Color(0xFFE5E7EB);
    final iconCol = isDark ? _kWhite60 : const Color(0xFF9CA3AF);
    final labelCol = isDark ? _kWhite60 : const Color(0xFF6B7280);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelCol, fontSize: 13),
      prefixIcon: Icon(icon, color: iconCol, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kRed, width: 1.5),
      ),
      errorStyle: const TextStyle(color: _kRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? _kNavy : Colors.white;
    final textPrimary   = isDark ? _kWhite : const Color(0xFF111827);
    final textSecondary = isDark ? _kWhite60 : const Color(0xFF6B7280);
    final glowColor     = isDark ? _kBlue.withAlpha(40) : _kBlue.withAlpha(15);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Fondo decorativo
          Positioned(top: -80, right: -60, child: _GlowCircle(size: 260, color: glowColor)),
          Positioned(bottom: -100, left: -80, child: _GlowCircle(size: 300, color: glowColor)),

          // Contenido
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo + nombre
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 56,
                              width: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'FixTrack',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Crea tu cuenta',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tarjeta glass
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? _kNavyLight.withAlpha(200) : Colors.white.withAlpha(230),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark ? _kWhite15 : const Color(0xFFE5E7EB), 
                                width: 1
                              ),
                              boxShadow: isDark ? null : [
                                BoxShadow(
                                  color: Colors.black.withAlpha(10),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Registro',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Empieza a gestionar tus incidencias.',
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                                  const SizedBox(height: 16),

                                  // Nombre
                                  TextFormField(
                                    controller: _nameController,
                                    textCapitalization: TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.name],
                                    style: TextStyle(color: textPrimary),
                                    decoration: _field(
                                      label: 'Nombre completo',
                                      icon: Icons.person_outline_rounded,
                                    ),
                                    validator: _validarNombre,
                                  ),
                                  const SizedBox(height: 10),

                                  // Email
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    style: TextStyle(color: textPrimary),
                                    decoration: _field(
                                      label: 'Correo electrónico',
                                      icon: Icons.alternate_email_rounded,
                                    ),
                                    validator: _validarCorreo,
                                  ),
                                  const SizedBox(height: 10),

                                  // Contraseña
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_passwordVisible,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.newPassword],
                                    style: TextStyle(color: textPrimary),
                                    decoration: _field(
                                      label: 'Contraseña',
                                      icon: Icons.lock_outline_rounded,
                                      suffix: IconButton(
                                        onPressed: () => setState(
                                          () => _passwordVisible = !_passwordVisible,
                                        ),
                                        icon: Icon(
                                          _passwordVisible
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: textSecondary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    validator: _validarPassword,
                                  ),
                                  const SizedBox(height: 10),

                                  // Confirmar contraseña
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: !_confirmPasswordVisible,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [AutofillHints.newPassword],
                                    onFieldSubmitted: (_) => _registrarse(),
                                    style: TextStyle(color: textPrimary),
                                    decoration: _field(
                                      label: 'Confirmar contraseña',
                                      icon: Icons.lock_reset_outlined,
                                      suffix: IconButton(
                                        onPressed: () => setState(
                                          () => _confirmPasswordVisible =
                                              !_confirmPasswordVisible,
                                        ),
                                        icon: Icon(
                                          _confirmPasswordVisible
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: textSecondary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    validator: _validarConfirmacion,
                                  ),

                                  // Error
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 12),
                                    _Banner(message: _errorMessage!, isSuccess: false),
                                  ],

                                  // Éxito
                                  if (_successMessage != null) ...[
                                    const SizedBox(height: 12),
                                    _Banner(message: _successMessage!, isSuccess: true),
                                  ],

                                  const SizedBox(height: 16),

                                  // Botón crear cuenta
                                  SizedBox(
                                    height: 46,
                                    child: FilledButton(
                                      onPressed: _isLoading ? null : _registrarse,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _kBlue,
                                        disabledBackgroundColor: _kBlue.withAlpha(100),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: _kWhite,
                                              ),
                                            )
                                          : const Text(
                                              'Crear cuenta',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: _kWhite,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // Ya tengo cuenta
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => Navigator.of(context).pop(),
                                    child: const Text(
                                      '¿Ya tienes cuenta? Iniciar sesión',
                                      style: TextStyle(
                                        color: _kBlueLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        'FixTrack · Gestión de incidencias',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── Botón toggle tema arriba derecha (Flotando arriba) ─────────────────────
          const SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: 8, right: 8),
                child: ThemeToggleButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.isSuccess});
  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? _kGreen : _kRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
