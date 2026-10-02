# Definition of Done – FixTrack

Una funcionalidad se considera terminada cuando cumple los siguientes criterios:

| N.º | Criterio | Forma de verificación |
|---|---|---|
| 1 | El código de la funcionalidad se encuentra implementado completamente. | Revisión del código en el repositorio. |
| 2 | La funcionalidad respeta la arquitectura definida para el proyecto. | Verificación de la separación entre domain, data y presentation. |
| 3 | No existen errores de compilación. | Ejecución exitosa de `flutter build apk` o compilación equivalente. |
| 4 | El análisis estático no presenta errores críticos. | Ejecución de `flutter analyze`. |
| 5 | Las pruebas unitarias asociadas se ejecutan correctamente. | Ejecución de `flutter test`. |
| 6 | La lógica de dominio cuenta con una cobertura mínima del 70 %. | Revisión del reporte de cobertura generado por las pruebas. |
| 7 | No existen secretos, contraseñas o credenciales expuestas en el repositorio. | Revisión automática dentro del flujo de integración continua. |
| 8 | La funcionalidad contempla los estados Loading, Success, Empty y Error cuando corresponda. | Verificación funcional de la interfaz. |
| 9 | Los errores mostrados al usuario incluyen una opción de recuperación cuando sea necesaria. | Prueba funcional de estados de error y reintento. |
| 10 | Los nombres de archivos, clases y variables mantienen una convención uniforme. | Revisión del código y análisis estático. |
| 11 | Los cambios fueron integrados mediante Pull Request. | Verificación del historial de Pull Requests en GitHub. |
| 12 | El flujo de integración continua finaliza correctamente antes de integrar los cambios. | Comprobación del estado verde de GitHub Actions. |