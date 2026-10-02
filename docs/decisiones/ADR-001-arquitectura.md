# ADR-001 – Arquitectura de la aplicación

## Estado
Aceptado

## Contexto
FixTrack requiere una estructura que permita separar la interfaz de usuario, la lógica de presentación, las reglas principales del negocio y el acceso a datos. Además, la arquitectura debe facilitar las pruebas unitarias y el mantenimiento del proyecto sin introducir una complejidad excesiva.

## Alternativas consideradas

### MVC
Permite una organización sencilla, pero puede generar mayor acoplamiento entre la interfaz y la lógica cuando la aplicación crece.

### MVVM + Repository
Separa la interfaz, la lógica de presentación y el acceso a datos mediante ViewModels y repositorios.

### Clean Architecture completa
Ofrece una separación muy estricta de responsabilidades, pero agrega mayor cantidad de capas, interfaces y complejidad para el alcance actual del proyecto.

## Decisión
Se adopta una arquitectura **MVVM + Repository con una capa de dominio ligera**.

La aplicación se organiza por funcionalidades y cada funcionalidad contiene las capas:

- `presentation`
- `domain`
- `data`

La capa `presentation` contiene las pantallas y ViewModels.

La capa `domain` contiene las entidades, contratos de repositorio y reglas principales del negocio.

La capa `data` contiene DTO, mappers e implementaciones concretas de los repositorios.

## Regla de dependencias
La capa `domain` debe permanecer independiente de Flutter, componentes de interfaz gráfica, APIs externas y mecanismos específicos de almacenamiento.

La capa `presentation` puede depender de `domain`.

La capa `data` puede depender de `domain` para implementar sus contratos y transformar los datos hacia entidades del dominio.

## Consecuencias

### Positivas
- Separación clara de responsabilidades.
- Mayor facilidad para realizar pruebas unitarias.
- Menor acoplamiento entre interfaz y acceso a datos.
- Mejor mantenibilidad del proyecto.
- Permite evolucionar la aplicación por funcionalidades.

### Negativas
- Requiere una mayor cantidad de archivos que una estructura básica.
- El equipo debe respetar las reglas de dependencia definidas.

## Resultado
La arquitectura seleccionada ofrece un equilibrio entre organización, facilidad de pruebas y mantenibilidad, siendo adecuada para el alcance del proyecto FixTrack.