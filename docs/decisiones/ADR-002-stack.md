# ADR-002 – Selección del stack tecnológico

## Estado
Aceptado

## Contexto
Para el desarrollo de FixTrack se evaluaron diferentes tecnologías móviles considerando la experiencia del equipo, soporte de capacidades requeridas, madurez del ecosistema, rendimiento, viabilidad sin macOS, curva de aprendizaje y mantenibilidad.

## Alternativas consideradas
- Flutter
- React Native
- Kotlin Multiplatform
- Desarrollo nativo

La evaluación detallada se encuentra en el archivo:

`docs/decisiones/evaluacion_stacks.csv`

## Prueba de humo
Como parte de la evaluación se seleccionaron Flutter y React Native como finalistas.

Se utilizó el acceso a la cámara como capacidad crítica para realizar una prueba de humo en ambas tecnologías.

En los dos casos fue posible acceder correctamente a la cámara desde un emulador Android, demostrando que ambas alternativas son técnicamente viables para esta funcionalidad.

## Decisión
Se selecciona **Flutter** como stack principal para el desarrollo de FixTrack.

Flutter obtuvo la mayor puntuación en la matriz de evaluación y permite mantener una única base de código para la aplicación móvil.

## Consecuencias

### Positivas
- Una sola base de código.
- Ecosistema amplio de paquetes.
- Desarrollo Android viable desde Windows.
- Facilidad de mantenimiento para el proyecto.
- Compatibilidad con las capacidades móviles requeridas.

### Negativas
- Dependencia del ecosistema Flutter y Dart.
- Algunas capacidades específicas podrían requerir integración con código nativo.

## Plan de salida
Si durante el desarrollo Flutter presenta una limitación que impida implementar alguna capacidad crítica, se evaluará primero el uso de integración con código nativo mediante los mecanismos proporcionados por Flutter.

Si la limitación afecta significativamente la viabilidad o mantenimiento de la aplicación, **React Native se mantiene como alternativa de migración**, debido a que también superó satisfactoriamente la prueba de humo realizada.

## Resultado
Flutter queda seleccionado como stack tecnológico principal de FixTrack, sustentado por la evaluación comparativa y las pruebas prácticas realizadas.