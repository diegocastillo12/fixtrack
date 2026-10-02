import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';

/// Botón toggle de tema claro/oscuro — reutilizable en cualquier pantalla.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.lightColor, this.darkColor});

  /// Color del ícono cuando el tema es OSCURO (fondo oscuro → ícono claro)
  final Color? darkColor;

  /// Color del ícono cuando el tema es CLARO (fondo claro → ícono oscuro)
  final Color? lightColor;

  @override
  Widget build(BuildContext context) {
    final ctrl  = ThemeController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = isDark
        ? (darkColor  ?? Colors.white.withAlpha(180))
        : (lightColor ?? const Color(0xFF374151));

    return IconButton(
      tooltip: isDark ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) =>
            RotationTransition(turns: anim, child: FadeTransition(opacity: anim, child: child)),
        child: Icon(
          isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          key: ValueKey(isDark),
          color: color,
          size: 22,
        ),
      ),
      onPressed: ctrl.toggle,
    );
  }
}
