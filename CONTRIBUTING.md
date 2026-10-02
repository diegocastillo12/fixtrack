# Convenciones del equipo – FixTrack

## Ramas

El proyecto utilizará las siguientes ramas:

- `main`: rama principal y protegida. Solo se integrarán cambios mediante Pull Request aprobado.
- `develop`: rama de integración del equipo.
- `feature/<US-xx>-descripcion`: desarrollo de nuevas funcionalidades.
- `fix/<descripcion>`: corrección de errores.
- `chore/<descripcion>`: tareas de configuración o mantenimiento.

## Commits

Se utilizará la convención Conventional Commits:

`<tipo>(<alcance>): <descripción> [US-xx]`

Tipos permitidos:

- `feat`: nueva funcionalidad.
- `fix`: corrección de errores.
- `docs`: documentación.
- `style`: cambios de formato.
- `refactor`: refactorización.
- `test`: pruebas.
- `chore`: configuración o mantenimiento.

Ejemplo:

`feat(incidencias): agregar registro de incidencias [US-05]`

## Pull Requests

Todo Pull Request deberá:

- Estar relacionado con una historia de usuario o tarea.
- Tener la integración continua en verde.
- Ser revisado por un integrante diferente al autor.
- Cumplir con la Definition of Done.
- No contener credenciales, tokens ni archivos sensibles.

## Revisión

Debido a que el equipo está conformado por dos integrantes, los cambios realizados por un integrante serán revisados por el otro antes de integrarse a la rama correspondiente.