import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/navigation/dark_route.dart';
import '../../admin/presentation/admin_dashboard_page.dart';
import '../../auth/presentation/login_page.dart';
import '../../auth/presentation/primer_ingreso_page.dart';
import '../../incidencias/presentation/incidencias_soporte_page.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kNavyMid = Color(0xFF0F2347);
const _kBlue = Color(0xFF2563EB);
const _kBlueLight = Color(0xFF3B82F6);
const _kWhite = Colors.white;
const _kWhite70 = Color(0xB3FFFFFF);

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // Pantalla completa inmersiva
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _kNavy,
      ),
    );

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOut),
      ),
    );

    // Inicia animación y luego navega
    _ctrl.forward().then((_) => _navigate());
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    Widget nextPage;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        nextPage = const LoginPage();
      } else {
        final uid = session.user.id;
        final memb = await Supabase.instance.client
            .from('miembros_organizacion')
            .select('rol, estado')
            .eq('usuario_id', uid)
            .eq('estado', 'ACTIVO')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (memb == null) {
          nextPage = const PrimerIngresoPage();
        } else if (memb['rol'] == 'ADMIN') {
          nextPage = const AdminDashboardPage();
        } else {
          nextPage = const IncidenciasSoportePage();
        }
      }
    } catch (_) {
      nextPage = const LoginPage();
    }

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      darkRoute(page: nextPage),
    );
  }


  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bg = isDark ? _kNavy : Colors.white;
    final textPrimary = isDark ? _kWhite : const Color(0xFF111827);
    final textSecondary = isDark ? _kWhite70 : const Color(0xFF6B7280);
    final glowColor = isDark ? _kBlue.withAlpha(35) : _kBlue.withAlpha(15);
    final shadowColor = isDark ? _kBlue.withAlpha(80) : Colors.black.withAlpha(15);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── Círculos de brillo decorativos ─────────────────────
          Positioned(
            top: -size.height * 0.15,
            right: -size.width * 0.25,
            child: _GlowCircle(size: size.width * 0.75, color: glowColor),
          ),
          Positioned(
            bottom: -size.height * 0.12,
            left: -size.width * 0.2,
            child: _GlowCircle(size: size.width * 0.8, color: isDark ? _kBlue.withAlpha(28) : _kBlue.withAlpha(10)),
          ),
          Positioned(
            bottom: size.height * 0.08,
            right: -size.width * 0.1,
            child: _GlowCircle(size: size.width * 0.45, color: isDark ? _kBlueLight.withAlpha(20) : _kBlueLight.withAlpha(8)),
          ),

          // ── Contenido centrado ─────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo animado
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 130,
                          width: 130,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Nombre y subtítulo animados
                FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        Text(
                          'FixTrack',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Activos e incidencias,\nsiempre en marcha',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: textSecondary,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Indicador de carga en la parte baja ────────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textOpacity,
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _kBlueLight.withAlpha(180),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget auxiliar ───────────────────────────────────────────────────────────

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
