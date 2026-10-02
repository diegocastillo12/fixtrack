import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/navigation/dark_route.dart';
import '../../auth/presentation/login_page.dart';
import '../data/incidencia_repository_impl.dart';
import 'incidencias_view_model.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);

class IncidenciasPage extends StatefulWidget {
  const IncidenciasPage({super.key});

  @override
  State<IncidenciasPage> createState() => _IncidenciasPageState();
}

class _IncidenciasPageState extends State<IncidenciasPage> {
  late final IncidenciasViewModel viewModel;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    viewModel = IncidenciasViewModel(IncidenciaRepositoryImpl());
    viewModel.addListener(_actualizar);
    viewModel.cargarIncidencias();
  }

  void _actualizar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    viewModel.removeListener(_actualizar);
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162852),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Se cerrará tu sesión actual.',
          style: TextStyle(color: Color(0x99FFFFFF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0x99FFFFFF))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _kBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _signingOut = true);

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Aunque falle, navegamos al login
    }

    if (!mounted) return;

    await Navigator.of(context).pushAndRemoveUntil(
      darkRoute(page: const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavy,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2347),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                height: 30,
                width: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'FixTrack',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          if (_signingOut)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: _cerrarSesion,
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
            ),
        ],
      ),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    switch (viewModel.estado) {
      case IncidenciasEstado.inicial:
      case IncidenciasEstado.cargando:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _kBlue),
              SizedBox(height: 16),
              Text('Cargando incidencias...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        );

      case IncidenciasEstado.exito:
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: viewModel.incidencias.length,
          itemBuilder: (context, index) {
            final incidencia = viewModel.incidencias[index];
            return Card(
              color: const Color(0xFF162852),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _kBlue,
                  child: Text(
                    '${incidencia.id}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  incidencia.titulo,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${incidencia.descripcion}\nEstado: ${incidencia.estado}',
                  style: const TextStyle(color: Color(0x99FFFFFF)),
                ),
                isThreeLine: true,
              ),
            );
          },
        );

      case IncidenciasEstado.vacio:
        return const Center(
          child: Text(
            'No existen incidencias registradas.',
            style: TextStyle(color: Colors.white70),
          ),
        );

      case IncidenciasEstado.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                viewModel.mensajeError,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _kBlue),
                onPressed: viewModel.cargarIncidencias,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
    }
  }
}