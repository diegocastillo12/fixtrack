import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_toggle_button.dart';

const _kNavy = Color(0xFF0D1B3E);
const _kBlue = Color(0xFF2563EB);

class PersonalPage extends StatefulWidget {
  const PersonalPage({super.key});

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  List<Map<String, dynamic>> _miembros = [];
  bool _loading = true;
  String? _error;
  String? _orgId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

      _orgId = miembro['organizacion_id'] as String;

      // Consultamos miembros sin FK directa a perfiles para evitar PGRST200
      final data = await client
          .from('miembros_organizacion')
          .select('id, rol, estado, usuario_id, created_at')
          .eq('organizacion_id', _orgId!)
          .order('created_at');

      final list = List<Map<String, dynamic>>.from(data as List);
      final userIds = list.map((m) => m['usuario_id']).whereType<String>().toSet().toList();

      Map<String, Map<String, dynamic>> perfilesMap = {};
      if (userIds.isNotEmpty) {
        try {
          final pData = await client
              .from('perfiles')
              .select('id, nombre, apellido, email')
              .inFilter('id', userIds);
          for (final p in pData as List) {
            perfilesMap[p['id'] as String] = p;
          }
        } catch (_) {}
      }

      for (final m in list) {
        final uid = m['usuario_id'] as String?;
        if (uid != null && perfilesMap.containsKey(uid)) {
          final p = perfilesMap[uid]!;
          final nomCompleto = '${p['nombre'] ?? ''} ${p['apellido'] ?? ''}'.trim();
          m['perfiles'] = {
            'nombre': nomCompleto.isNotEmpty ? nomCompleto : (p['nombre'] ?? 'Usuario'),
            'email': p['email'] ?? '',
          };
        } else {
          m['perfiles'] = {
            'nombre': 'Usuario',
            'email': '',
          };
        }
      }

      if (mounted) {
        setState(() => _miembros = list);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _mostrarDialogoInvitacion() async {
    if (_orgId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InvitarDialog(orgId: _orgId!),
    );
  }

  Widget _rolChip(String rol) {
    final isAdmin = rol == 'ADMIN';
    return Chip(
      label: Text(rol,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: isAdmin ? _kBlue : Colors.green[700],
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _estadoChip(String estado) {
    final isActivo = estado == 'ACTIVO';
    return Chip(
      label: Text(estado,
          style: const TextStyle(color: Colors.white, fontSize: 11)),
      backgroundColor: isActivo ? Colors.green[600] : Colors.grey[600],
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _kNavy : Colors.grey[100]!;
    final cardColor = isDark ? const Color(0xFF162852) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? _kNavy : _kBlue,
        foregroundColor: Colors.white,
        title: const Text('Personal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Invitar usuario',
            onPressed: _mostrarDialogoInvitacion,
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _loadData, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : _miembros.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: subColor),
                          const SizedBox(height: 16),
                          Text('No hay miembros',
                              style: TextStyle(color: subColor, fontSize: 16)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: ElevatedButton.icon(
                            onPressed: _mostrarDialogoInvitacion,
                            icon: const Icon(Icons.person_add_outlined),
                            label: const Text('Invitar usuario con correo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kBlue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _miembros.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final m = _miembros[i];
                                final perfil = m['perfiles'] as Map?;
                                final nombre = perfil?['nombre'] as String? ?? 'Sin nombre';
                                final email = perfil?['email'] as String? ?? '';
                                final inicial = nombre.isNotEmpty
                                    ? nombre[0].toUpperCase()
                                    : '?';
                                final rol = m['rol'] as String? ?? '';
                                final estado = m['estado'] as String? ?? '';

                                return Card(
                                  color: cardColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              _kBlue.withOpacity(0.2),
                                          child: Text(inicial,
                                              style: const TextStyle(
                                                  color: _kBlue,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(nombre,
                                                  style: TextStyle(
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15)),
                                              if (email.isNotEmpty)
                                                Text(email,
                                                    style: TextStyle(
                                                        color: subColor,
                                                        fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            _rolChip(rol),
                                            const SizedBox(height: 4),
                                            _estadoChip(estado),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _InvitarDialog extends StatefulWidget {
  final String orgId;
  const _InvitarDialog({required this.orgId});

  @override
  State<_InvitarDialog> createState() => _InvitarDialogState();
}

class _InvitarDialogState extends State<_InvitarDialog> {
  final _emailCtrl = TextEditingController();
  String _selectedRol = 'SOPORTE';
  bool _generando = false;
  String? _codigoGenerado;
  String? _emailInvitado;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearInvitacion() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    setState(() { _generando = true; _error = null; });

    try {
      final client = Supabase.instance.client;
      final result = await client.rpc(
        'invitar_usuario',
        params: {
          'p_organizacion_id': widget.orgId,
          'p_rol': _selectedRol,
          if (email.isNotEmpty) 'p_email': email,
        },
      );

      String? codigo;
      String? invId;
      if (result is Map) {
        codigo = result['codigo']?.toString();
        invId = result['invitacion_id']?.toString();
      } else {
        codigo = result?.toString();
      }

      // Si tenemos invId y email, aseguramos que quede asociado en la BD
      if (invId != null && email.isNotEmpty) {
        try {
          await client.from('invitaciones').update({'email': email}).eq('id', invId);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _codigoGenerado = codigo ?? 'INV-????';
          _emailInvitado = email.isNotEmpty ? email : null;
          _generando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _generando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF162852) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return AlertDialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.mark_email_read_rounded, color: _kBlue),
          const SizedBox(width: 8),
          Text(
            _codigoGenerado == null ? 'Invitar usuario' : '¡Invitación lista!',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: _codigoGenerado == null
          ? SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ingresa el correo del usuario a invitar. Cuando ingrese a FixTrack, le aparecerá automáticamente la invitación con una campanita para unirse.',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico (opcional)',
                      hintText: 'ej. usuario@dominio.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: _kBlue),
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _selectedRol,
                    dropdownColor: cardColor,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Rol asignado',
                      prefixIcon: const Icon(Icons.badge_outlined, color: _kBlue),
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'SOPORTE', child: Text('Técnico / Soporte')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRol = val);
                    },
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _generando ? null : _crearInvitacion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _generando
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Generar código de invitación', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_emailInvitado != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Invitación enviada a $_emailInvitado.\nLe aparecerá una campanita para unirse directamente.',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.greenAccent : Colors.green.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Código de acceso único:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: _kBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBlue.withOpacity(0.4), width: 1.5),
                  ),
                  child: Text(
                    _codigoGenerado!,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: _kBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copiar código'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kBlue,
                    side: const BorderSide(color: _kBlue),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _codigoGenerado!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado al portapapeles')),
                    );
                  },
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_codigoGenerado == null ? 'Cancelar' : 'Cerrar', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        ),
      ],
    );
  }
}
