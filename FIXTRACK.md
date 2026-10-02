# FixTrack — Documentación del Proyecto

> **Sistema móvil universitario para gestión de activos e incidencias tecnológicas**

---

## 🎯 Visión

FixTrack es una aplicación móvil Flutter diseñada para instituciones que necesitan gestionar sus activos tecnológicos (PCs, laptops, proyectores, etc.) y registrar incidencias cuando fallan. Pensada inicialmente para universidades, con arquitectura que permite escalar a cualquier organización.

---

## 🏗️ Arquitectura

**Feature-First + Clean Architecture simplificada + MVVM**

```
lib/
│
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
│
├── core/
│   ├── config/
│   ├── constants/
│   ├── errors/
│   ├── network/        → Supabase / Dio
│   ├── auth/           → sesión Google
│   ├── storage/        → fotografías (Supabase Storage)
│   ├── permissions/    → permisos y roles
│   ├── navigation/     → dark_route, router helpers
│   ├── services/       → servicios compartidos
│   └── utils/
│
└── features/
    ├── auth/
    ├── organizations/
    ├── members/
    ├── locations/        → sedes, áreas, ambientes
    ├── inventory/        → activos, tipos de activo
    ├── barcode_scanner/
    ├── incidents/
    ├── providers/
    ├── notifications/
    └── profile/
```

### Capas por feature

```
features/incidents/
│
├── data/
│   ├── datasources/          → SupabaseIncidentsDatasource
│   ├── dto/                  → IncidentDto
│   ├── mappers/              → IncidentMapper
│   └── repositories/         → IncidentRepositoryImpl
│
├── domain/
│   ├── entities/             → Incident
│   ├── repositories/         → IncidentRepository (interface)
│   └── usecases/
│       ├── create_incident.dart
│       ├── get_incidents.dart
│       ├── assign_provider.dart
│       └── close_incident.dart
│
└── presentation/
    ├── pages/                → CreateIncidentPage, IncidentDetailPage
    ├── widgets/              → IncidentCard
    └── viewmodels/           → IncidentsViewModel
```

### Flujo estricto (nunca saltarse capas)

```
UI (Page)
  ↓
ViewModel
  ↓
UseCase
  ↓
Repository (interface)
  ↓
RepositoryImpl
  ↓
DataSource
  ↓
Supabase
```

> ⚠️ **Regla de oro:** Nunca llamar a Supabase directamente desde un Page o ViewModel. Siempre a través del UseCase → Repository → DataSource.

---

## 📱 Flujo de la aplicación

### Primer ingreso
```
Splash → Google OAuth → ¡Bienvenido! → [Crear organización] o [Unirme con código]
```

### Rol y acceso
- El usuario **no elige su rol** — el Administrador lo asigna.
- Roles: `ADMIN` | `SOPORTE`

### Registro de incidencia (encargado de soporte)
```
Escanear código de barras
  ↓
FixTrack identifica: nombre, modelo, serie, ubicación
  ↓
Encargado registra incidencia + fotos
  ↓
Administrador recibe la incidencia
  ↓
Admin asigna proveedor → Edge Function → Email (Brevo/Resend)
  ↓
Seguimiento hasta cierre
```

---

## 🛠️ Stack tecnológico

| Capa | Tecnología |
|---|---|
| **Frontend** | Flutter + Dart |
| **Arquitectura** | Feature-First + Clean Architecture + MVVM |
| **Backend** | Supabase |
| **Auth** | Google OAuth (solo Google, sin email/password) |
| **Base de datos** | PostgreSQL (Supabase) |
| **Fotos** | Supabase Storage |
| **Lógica segura** | Supabase Edge Functions |
| **Correo** | Brevo o Resend (gratuito, sin Firebase) |
| **Estado** | ViewModels (ChangeNotifier) |

---

## 🗄️ Módulos de la base de datos

| Tabla | Descripción |
|---|---|
| `perfiles` | Datos adicionales del usuario auth |
| `organizaciones` | Empresa, universidad, institución |
| `miembros_organizacion` | Relación usuario ↔ organización + rol |
| `sedes` | Campus, sucursales |
| `areas` | Departamentos dentro de una sede |
| `ambientes` | Laboratorio, salón, oficina |
| `tipos_activo` | PC, laptop, proyector, etc. |
| `proveedores` | Empresas de soporte/reparación |
| `activos` | Equipos registrados (con código de barras) |
| `incidencias` | Fallas reportadas |
| `fotos_incidencia` | Rutas de fotos en Storage |
| `historial_incidencia` | Trazabilidad de cambios de estado |
| `comentarios_incidencia` | Comunicación interna |
| `invitaciones` | Códigos para unirse a organización |
| `notificaciones` | Alertas en la app |
| `envios_email` | Registro de correos enviados |

---

## 🔐 Seguridad (pendiente implementar)

- **RLS (Row Level Security)** en todas las tablas de Supabase
- Política base: un usuario solo ve datos de su organización
- El rol `ADMIN` puede gestionar; el rol `SOPORTE` solo puede leer/crear incidencias
- Triggers de `updated_at` en todas las tablas que lo tienen

---

## 🎨 Diseño UI

- **Paleta principal:** Azul marino `#0D1B3E` (fondo), Azul `#2563EB` (acento)
- **Estilo:** Dark theme con glassmorphism
- **Fuente de verdad del color:** Logo FixTrack (F + llave azul sobre fondo navy)

---

## 📋 Estado actual del proyecto (Sprint)

- [x] Pantalla splash con animación
- [x] Login (Google OAuth configurado en Supabase)
- [x] Registro de usuario
- [x] Pantalla "Primer Ingreso" (Crear empresa / Unirme)
- [x] Pantalla de incidencias (base)
- [x] Cerrar sesión
- [ ] Crear organización
- [ ] Unirse con código de invitación
- [ ] Gestión de activos
- [ ] Escáner de código de barras
- [ ] Registro de incidencias con fotos
- [ ] Asignación a proveedores + email
- [ ] Panel de administración

---

## 🗂️ Estructura de archivos actuales

```
app/lib/
├── main.dart
├── core/
│   ├── errors/
│   │   ├── dio_failure_mapper.dart
│   │   └── failure.dart
│   ├── navigation/
│   │   └── dark_route.dart
│   └── network/
│       └── dio_client.dart
└── features/
    ├── auth/
    │   └── presentation/
    │       ├── login_page.dart
    │       ├── register_page.dart
    │       ├── splash_page.dart
    │       └── primer_ingreso_page.dart
    └── incidencias/
        ├── data/
        │   ├── incidencia_dto.dart
        │   ├── incidencia_mapper.dart
        │   └── incidencia_repository_impl.dart
        ├── domain/
        │   ├── incidencia.dart
        │   ├── incidencia_repository.dart
        │   └── incidencia_validator.dart
        └── presentation/
            ├── incidencias_page.dart
            └── incidencias_view_model.dart
```
