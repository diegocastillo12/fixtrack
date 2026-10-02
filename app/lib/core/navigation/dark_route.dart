import 'package:flutter/material.dart';

const _kNavy = Color(0xFF0D1B3E);

/// Ruta personalizada sin flash blanco — mantiene el fondo marino oscuro
/// durante toda la transición entre pantallas.
PageRouteBuilder<T> darkRoute<T>({required Widget page}) {
  return PageRouteBuilder<T>(
    barrierColor: _kNavy,
    opaque: true,
    pageBuilder: (_, _, _) => page,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}
