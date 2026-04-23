# Notova — *Toma nota de tu futuro*

> Gestor de tareas y productividad gamificado construido en Flutter. Convierte tus tareas diarias en misiones, gana XP, sube de nivel y mantén rachas de actividad diaria.

**Público objetivo:** Estudiantes, freelancers y opositores (16–35 años) · Versión `0.3.1`

---

## Características

- **Autenticación completa** — Email/contraseña, Google Sign-In y recuperación de contraseña via Firebase Auth
- **Tareas (Quests)** — Crear, editar y completar tareas con prioridad Alta / Media / Baja, fecha límite y recompensa de XP
- **Sistema de XP y niveles** — 7 niveles progresivos con umbrales fijos de XP
- **Rachas diarias** — Se incrementa al completar una tarea, se mantiene si visitas sin pendientes, se resetea si pasa más de 1 día
- **Badges** — Desbloqueables por primera tarea completada, racha (3 y 7 días) y por nivel (3, 5 y 7)
- **Notificación de level-up** — Dialog celebratorio con el nuevo rango al subir de nivel
- **Efectos de sonido** — SFX al completar tarea y al subir de nivel (activable/desactivable)
- **Google Calendar** — Sincronización bidireccional con OAuth 2.0; calendarios de Classroom en modo solo lectura
- **Caché offline** — SQLite via Drift ORM; las tareas se cargan desde disco sin conexión
- **Exportar historial** — Genera CSV o TXT y lo envía a la API REST del backend
- **Editar perfil** — Cambiar nombre de usuario desde la pantalla de perfil
- **Onboarding** — Carousel de presentación que se muestra una única vez
- **Internacionalización** — Español / Inglés con más de 300 strings

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| UI | Flutter 3 · Material 3 · Google Fonts |
| Estado | Provider (ChangeNotifier) |
| Auth | Firebase Authentication |
| Base de datos remota | Cloud Firestore |
| Almacenamiento | Firebase Storage (avatares) |
| Caché local | SQLite · Drift ORM |
| Calendario | Google Calendar API v3 (googleapis) |
| Audio | audioplayers |
| Backend | Python · Flask · Flasgger (Swagger/OpenAPI) |
| Despliegue backend | PythonAnywhere |
| Tests | flutter_test · mocktail |

---

## Arquitectura — MVVM

```
lib/
├── models/          # Entidades de dominio (UserModel, TaskModel, ...)
├── repositories/    # Acceso a datos (Firebase, Google Calendar, SQLite, audio)
├── viewmodel/       # Lógica de negocio y estado de la UI (ChangeNotifier)
├── pages/           # Widgets de pantalla — solo código visual
├── database/        # Schema Drift y código generado (app_database.dart)
├── theme/           # Paleta de colores y constantes de diseño (AppColors)
└── l10n/            # Strings de internacionalización
```

**Flujo de datos:** `Page` → observa `ViewModel` → llama a `Repository` → Firebase / SQLite / API

## Guía de documentación de código

El estándar de documentación para Dart (`///`, estilo de comentarios y cobertura por capa) está en:

- `docs/GUIA_DOCUMENTACION_CODIGO.md`

### Generar y abrir DartDoc (con buscador funcional)

Para consultar la documentación de API con la barra de búsqueda activa:

1. Genera la documentación en `doc/api`.
2. Levanta un servidor HTTP local apuntando a esa carpeta.
3. Abre la URL local en el navegador.

```bash
flutter pub get
dart doc --output doc/api
python -m http.server 8080 --directory doc/api
```

Abre: `http://localhost:8080`

> Importante: no abras `doc/api/index.html` con doble clic (`file://...`), porque el buscador puede quedarse en "Loading search...". DartDoc necesita servirse por HTTP para cargar correctamente el índice de búsqueda.

---

## Estructura del proyecto

```
notova/
├── lib/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── task_model.dart
│   │   ├── calendar_event.dart
│   │   └── calendar_info.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── user_repository.dart
│   │   ├── task_repository.dart
│   │   ├── local_task_repository.dart  # Caché SQLite
│   │   ├── calendar_repository.dart
│   │   ├── notification_repository.dart
│   │   ├── audio_repository.dart
│   │   ├── export_repository.dart
│   │   └── api_client.dart
│   ├── viewmodel/
│   │   ├── auth_viewmodel.dart
│   │   ├── user_viewmodel.dart
│   │   ├── task_viewmodel.dart
│   │   └── calendar_viewmodel.dart
│   ├── pages/
│   │   ├── splash_screen.dart
│   │   ├── welcome_screen.dart       # Pantalla inicial (Login / Registro)
│   │   ├── onboarding_screen.dart
│   │   ├── auth_screen.dart
│   │   ├── main_screen.dart          # Shell con BottomNavigationBar
│   │   ├── home_screen.dart
│   │   ├── task_screen.dart
│   │   ├── calendar_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── all_tasks_screen.dart
│   │   └── all_events_screen.dart
│   ├── database/
│   │   ├── app_database.dart
│   │   └── app_database.g.dart       # generado por build_runner
│   ├── theme/
│   │   └── app_colors.dart           # Paleta de colores centralizada
│   └── l10n/
│       └── app_strings.dart
├── backend/
│   ├── api.py                        # Flask REST API
│   ├── wsgi.py                       # Punto de entrada WSGI
│   └── requirements.txt
├── assets/
│   ├── images/
│   └── audio/
│       ├── task_complete.mp3
│       └── level_up.mp3
└── test/
    └── unit/
        ├── user_model_test.dart
        ├── task_model_test.dart
        ├── task_viewmodel_test.dart
        └── auth_viewmodel_test.dart
```

---

## Configuración inicial

### Requisitos previos

- Flutter SDK ≥ 3.11 / Dart SDK ≥ 3.11
- Android Studio o VS Code con extensión Flutter
- Cuenta de Firebase y proyecto creado
- Cuenta de Google Cloud Platform con Google Calendar API habilitada
- Python 3.10+ (solo para ejecutar el backend localmente)

### 1. Clonar e instalar dependencias

```bash
git clone <url-del-repositorio>
cd notova
flutter pub get
```

### 2. Archivos de configuración (no incluidos en el repo)

Estos archivos contienen credenciales y deben obtenerse manualmente:

| Archivo | Origen |
|---|---|
| `android/app/google-services.json` | Firebase Console → Configuración del proyecto → Android |
| `ios/Runner/GoogleService-Info.plist` | Firebase Console → Configuración del proyecto → iOS |
| `lib/firebase_options.dart` | Generado con `flutterfire configure` |
| `android/key.properties` | Keystore propio para builds de release |
| `backend/serviceAccountKey.json` | Firebase Console → Configuración → Cuentas de servicio |

### 3. Generar código de Drift (ORM)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Ejecutar

```bash
flutter run
```

---

## Backend Flask

La API REST gestiona el acceso a Firestore desde servidor y genera los archivos de exportación.

**URL de producción:** `https://arocaalex.pythonanywhere.com`
**Documentación Swagger:** `https://arocaalex.pythonanywhere.com/apidocs`

### Ejecutar localmente

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
python api.py
```

### Endpoints

| Método | Ruta | Descripción | Auth |
|---|---|---|---|
| `GET` | `/` | Health check | No |
| `GET` | `/tareas` | Listar tareas (`?completada=true/false`) | Bearer |
| `GET` | `/tareas/{id}` | Obtener una tarea | Bearer |
| `POST` | `/tareas` | Crear tarea | Bearer |
| `PUT` | `/tareas/{id}` | Actualizar tarea | Bearer |
| `DELETE` | `/tareas/{id}` | Eliminar tarea | Bearer |
| `POST` | `/exportar/csv` | Exportar tareas a CSV | Bearer |
| `POST` | `/exportar/txt` | Exportar tareas a TXT | Bearer |

Los endpoints protegidos requieren el header:

```
Authorization: Bearer <Firebase ID Token>
```

---

## Tests

El proyecto tiene tests unitarios sin dependencias de Firebase ni de red.

```bash
flutter test test/unit/
```

| Archivo | Tests | Qué cubre |
|---|---|---|
| `user_model_test.dart` | - | Todos los umbrales XP→nivel, 7 rangos, `xpProgress`, `xpRemaining` |
| `task_model_test.dart` | - | `isOverdue` (4 casos), `formattedDueDate` (padding horas/minutos) |
| `task_viewmodel_test.dart` | - | `createTask`, `updateTask`, `toggleTaskCompletion` con y sin level-up |
| `auth_viewmodel_test.dart` | - | `signOut` verifica orden clearCache→signOut, `signInWithEmail`, `sendPasswordReset` |

---

## Sistema de niveles

| Nivel | Rango | XP mínima | XP máxima |
|---|---|---|---|
| 1 | Novato | 0 | 150 |
| 2 | Aspirante | 151 | 500 |
| 3 | Táctico | 501 | 1.200 |
| 4 | Ninja | 1.201 | 2.500 |
| 5 | Maestro | 2.501 | 4.500 |
| 6 | Leyenda | 4.501 | 7.500 |
| 7 | SuperNotova | 7.501 | — |

**XP por prioridad de tarea:** Alta = 250 XP · Media = 100 XP · Baja = 50 XP

---

## Paleta de colores

| Token | Hex | Uso |
|---|---|---|
| Background | `#120E1A` | Fondo principal |
| Card | `#1E1926` | Tarjetas y contenedores |
| Primary | `#7B2CBF` | Botones, selección activa |
| Accent | `#8A2BE2` | Highlights secundarios |
| Neon Cyan | `#00E5FF` | Indicadores, bordes de énfasis |
| Text accent | `#DEB7FF` | Links, texto destacado, badges XP |

---

## Variables de entorno

Crea `.env` en la raíz (ver `.env.example` como plantilla):

```env
API_BASE_URL=https://arocaalex.pythonanywhere.com
```

> `.env` y todos sus variantes están en `.gitignore` y nunca deben subirse al repositorio.

---

## Licencia

Proyecto académico — DAM Intermodular 2025/2026. Todos los derechos reservados.
