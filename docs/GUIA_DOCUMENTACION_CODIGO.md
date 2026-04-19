# Guía de documentación de código — Notova

Esta guía define el estándar de documentación que se aplica en todo el proyecto, basada en las recomendaciones de Effective Dart.

## Objetivo

- Hacer que cada clase y método público sea entendible sin leer su implementación completa.
- Mantener comentarios breves, orientados a intención y comportamiento.
- Estandarizar el estilo para que cualquier módulo (`models`, `repositories`, `viewmodel`, `pages`, `backend`) siga el mismo formato.

## Reglas obligatorias

- **Dart/Flutter**: usar `///` para documentación de clases, métodos públicos, getters y factories públicas.
- **Python (backend)**: usar *docstrings* (`"""..."""`) en módulos y funciones, especialmente en endpoints y middlewares.
- Comenzar con una primera oración breve que resuma la responsabilidad.
- Incluir una línea en blanco antes de ampliar detalles.
- Referenciar símbolos con corchetes: `[UserModel]`, `[AuthRepository]`, `[errorMessage]`.
- Explicar parámetros y retorno dentro del texto natural, sin etiquetas `@param` o `@return`.
- Describir efectos importantes (side effects), errores esperados y valores de retorno especiales (`null`, `false`, etc.).

## Qué NO documentar a mano

- **Archivos generados**: no editar ni documentar manualmente `*.g.dart` (por ejemplo Drift). Se regeneran y sobrescriben.

## Estilo empleado

- Escribir en frases completas, con mayúscula inicial y punto final.
- Preferir verbos en tercera persona para métodos: "Retorna...", "Actualiza...", "Construye...".
- Evitar comentarios redundantes ("asigna valor a x").
- Documentar el "por qué" y el "qué"; evitar repetir el "cómo" evidente en código.

## Cobertura mínima por capa

- **Modelos (`lib/models`)**: clase, factories, getters derivados y conversiones (`toJson`, `fromJson`).
- **Repositorios (`lib/repositories`)**: clase, métodos públicos, contratos de error y dependencia externa (Firebase/API).
- **ViewModels (`lib/viewmodel`)**: clase, estado expuesto y operaciones de negocio que consumen las vistas.
- **Pages (`lib/pages`)**: comentario corto de propósito de pantalla y comportamiento relevante de UI.
- **Base de datos (`lib/database`)**: tablas y propósito de cada entidad persistida.
- **Backend (`backend/`)**: docstring de módulo, endpoints con contrato (payload, respuesta, errores) y middlewares (auth).

## Plantillas rápidas

```dart
/// Describe la responsabilidad principal de esta clase.
///
/// Añade el contexto funcional necesario para entender cuándo usarla.
class ExampleClass {}
```

```dart
/// Ejecuta la operación principal con [input].
///
/// Retorna `true` cuando la operación finaliza correctamente y `false` si
/// ocurre una condición recuperable.
Future<bool> doWork(String input) async {}
```

```dart
/// Obtiene la representación serializable para persistencia local.
Map<String, dynamic> toJson() => {};
```

```python
def endpoint():
    """Resume el endpoint en una frase.

    Describe autenticación requerida, formato de entrada y respuesta, y los
    errores esperados (códigos HTTP).
    """
    ...
```
