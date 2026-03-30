# Notova — *Toma nota de tu futuro*

> Gestor de tareas y productividad gamificado para Android, construido en Flutter.

---

## Descripción

**Notova** combina una interfaz neo-brutalista con un motor de gamificación ligero. Los usuarios ganan Experiencia (XP), suben de nivel y mantienen rachas diarias completando sus tareas — sin la complejidad de un RPG completo.

**Público objetivo:** Estudiantes, freelancers y opositores (16–35 años).

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Frontend | Flutter (Dart), MVVM + Provider |
| Auth & Base de datos | Firebase Auth + Cloud Firestore |
| Calendario | Google Calendar API v3 (OAuth 2.0) |
| Microservicio de exportación | Python / FastAPI — [arocaalex.pythonanywhere.com](https://arocaalex.pythonanywhere.com) |
| Persistencia local | SharedPreferences / SQLite (sesión offline) |

---

## Arquitectura

```
lib/
├── main.dart                  # Entry point, MultiProvider, SplashScreen
├── models/                    # Modelos de datos puros
│   ├── calendar_event.dart
│   └── calendar_info.dart
├── pages/                     # Vista (UI-only, sin lógica de negocio)
│   ├── splash_screen.dart
│   ├── auth_screen.dart
│   ├── main_screen.dart       # Shell con BottomNavigationBar
│   ├── home_screen.dart
│   ├── task_screen.dart
│   ├── calendar_screen.dart
│   └── profile_screen.dart
├── viewmodel/                 # Estado reactivo (ChangeNotifier)
│   ├── auth_viewmodel.dart
│   ├── task_viewmodel.dart
│   ├── calendar_viewmodel.dart
│   ├── home_viewmodel.dart
│   └── profile_viewmodel.dart
└── repositories/              # Acceso a datos externos (Firebase, APIs)
    ├── auth_repository.dart
    ├── task_repository.dart
    ├── calendar_repository.dart
    ├── home_repository.dart
    └── profile_repository.dart
```

Patrón **MVVM**: las `pages` solo consumen estado del `ViewModel`. Toda llamada a Firebase o a APIs externas pasa por los `repositories`.

---

## Funcionalidades (v0.1.3)

### Autenticación
- Registro e inicio de sesión con email/contraseña
- Sign-in con Google (OAuth 2.0 via `google_sign_in` v7)
- Sesión persistente gestionada por Firebase Auth

### Gestión de Tareas (Quests)
- Crear tareas con título, fecha/hora y prioridad (Alta / Media / Baja)
- Pestañas filtrables: Todas · Alta Prioridad · Completadas
- Al completar una tarea se otorga XP en tiempo real (Firestore)

### Motor de Gamificación
| Nivel | Nombre | XP requerida |
|---|---|---|
| 1 | Novato | 0 – 150 |
| 2 | Aspirante | 151 – 500 |
| 3 | Táctico | 501 – 1.200 |
| 4 | Ninja | 1.201 – 2.500 |
| 5 | Maestro | 2.501 – 4.500 |
| 6 | Leyenda | 4.501 – 7.500 |
| 7 | SuperNotova | +7.500 |

- **Day Streak**: se incrementa al completar al menos una tarea diaria (o visitar la sección de tareas si no hay ninguna pendiente)

### Calendario
- Vista mensual con navegación entre meses
- **Sincronización bidireccional** con Google Calendar (calendarios propios)
- **Solo lectura** para calendarios de terceros / Google Classroom
- Badge `Read-only` en calendarios y eventos ajenos
- Crear eventos desde la app (solo en calendarios propios, FAB)
- Eliminar eventos con swipe (solo en calendarios propios)

### Perfil
- Nombre, nivel, XP actual/requerida y racha mostrados en tiempo real (StreamBuilder)
- Historial de logros y badges

---

## Paleta de colores

| Token | Hex | Uso |
|---|---|---|
| Background | `#120E1A` | Fondo principal |
| Card | `#1E1A29` | Tarjetas y contenedores |
| Primary | `#7B2CBF` | Botones, selección activa |
| Accent | `#8A2BE2` | Highlights secundarios |
| Cyan | `#00E5FF` | Badges XP, indicadores |
| Text accent | `#DEB7FF` | Links, texto destacado |

---

## Primeros pasos

### Requisitos
- Flutter SDK `^3.11.1`
- Dart SDK `^3.11.1`
- Cuenta de Firebase con proyecto configurado
- Proyecto en Google Cloud con **Google Calendar API** habilitada

### Instalación

```bash
git clone https://github.com/<tu-usuario>/notova.git
cd notova
flutter pub get
```

### Configuración de Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Activa **Authentication** (Email/Contraseña + Google)
3. Crea una base de datos **Cloud Firestore**
4. Descarga `google-services.json` → `android/app/`
5. El archivo `lib/firebase_options.dart` se genera con `flutterfire configure`

### Configuración de Google Calendar API

1. En [Google Cloud Console](https://console.cloud.google.com), habilita **Google Calendar API**
2. Crea credenciales OAuth 2.0 para Android
3. Registra el SHA-1 del keystore en Firebase Console

### Ejecutar

```bash
flutter run
```

---

## Variables de entorno

El archivo `.env` (no incluido en el repositorio) puede contener claves adicionales para el microservicio de exportación:

```
PYTHON_API_BASE_URL=https://arocaalex.pythonanywhere.com
```

---

## Roadmap

- [ ] Motor de gamificación completo (XP al completar, animación de level-up, SFX)
- [ ] Sincronización completa con Google Classroom (solo lectura)
- [ ] Exportación de historial a `.csv` / `.txt` vía microservicio Python
- [ ] Persistencia offline con SQLite
- [ ] Notificaciones push (Firebase Cloud Messaging)

---

## Versión

`v0.1.3` — Integración Google Calendar + arquitectura MVVM completa.

---

## Licencia

Proyecto académico — uso educativo.
