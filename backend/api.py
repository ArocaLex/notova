"""
Notova REST API — Backend del proyecto intermodular.

Framework: Flask + Flasgger (Swagger/OpenAPI)
Auth:      Firebase Admin SDK (verificación de ID tokens)
DB:        Cloud Firestore (lectura/escritura de tareas)
Despliegue: PythonAnywhere (arocaalex.pythonanywhere.com)

Este servicio expone endpoints para:

- CRUD de tareas bajo `/tareas`.
- Exportación de tareas a TXT y CSV bajo `/exportar/*`.

Autenticación:

- Los endpoints protegidos requieren el header `Authorization: Bearer <token>`,
  donde `<token>` es un Firebase ID Token emitido por Firebase Auth.
"""

import csv
import io
import functools
from datetime import datetime, timezone

from flask import Flask, request, jsonify, Response, g
from flask_cors import CORS
from flasgger import Swagger
import firebase_admin
from firebase_admin import credentials, auth, firestore

# ═══════════════════════════════════════════════════════════════════════
#  Configuración de la aplicación
# ═══════════════════════════════════════════════════════════════════════

app = Flask(__name__)

CORS(app, resources={r"/*": {"origins": "*"}})

swagger_template = {
    "info": {
        "title": "Notova API",
        "description": "API RESTful del proyecto Notova — gestión de tareas gamificada.",
        "version": "1.0.0",
    },
    "host": "arocaalex.pythonanywhere.com",
    "basePath": "/",
    "schemes": ["https"],
    "securityDefinitions": {
        "Bearer": {
            "type": "apiKey",
            "name": "Authorization",
            "in": "header",
            "description": "Firebase ID Token. Formato: Bearer <token>",
        }
    },
    "security": [{"Bearer": []}],
}

swagger = Swagger(app, template=swagger_template)

# ═══════════════════════════════════════════════════════════════════════
#  Firebase Admin SDK — inicialización
# ═══════════════════════════════════════════════════════════════════════

import os
_base_dir = os.path.dirname(os.path.abspath(__file__))
cred = credentials.Certificate(os.path.join(_base_dir, "serviceAccountKey.json"))
firebase_admin.initialize_app(cred)
db = firestore.client()


# ═══════════════════════════════════════════════════════════════════════
#  Middleware de autenticación 
# ═══════════════════════════════════════════════════════════════════════

def require_auth(f):
    """Protege un endpoint verificando el Firebase ID Token.

    Lee el header `Authorization` con formato `Bearer <token>`. Si el token es
    válido, guarda el UID verificado en `flask.g.uid` para que las funciones de
    endpoint puedan resolver el árbol Firestore `/users/{uid}`.
    """
    @functools.wraps(f)
    def decorated(*args, **kwargs):
        header = request.headers.get("Authorization", "")
        if not header.startswith("Bearer "):
            return jsonify({"error": "Token no proporcionado"}), 401
        token = header.split("Bearer ", 1)[1]
        try:
            decoded = auth.verify_id_token(token)
            g.uid = decoded["uid"]
        except Exception:
            return jsonify({"error": "Token inválido o expirado"}), 401
        return f(*args, **kwargs)
    return decorated


# ═══════════════════════════════════════════════════════════════════════
#  Gestión global de errores 
# ═══════════════════════════════════════════════════════════════════════

@app.errorhandler(400)
def bad_request(e):
    """Manejador global para errores 400 (validación / entrada inválida)."""
    return jsonify({"error": "Petición incorrecta", "detalle": str(e)}), 400

@app.errorhandler(404)
def not_found(e):
    """Manejador global para errores 404 (ruta o recurso inexistente)."""
    return jsonify({"error": "Recurso no encontrado"}), 404

@app.errorhandler(405)
def method_not_allowed(e):
    """Manejador global para errores 405 (método HTTP no permitido)."""
    return jsonify({"error": "Método HTTP no permitido"}), 405

@app.errorhandler(500)
def server_error(e):
    """Manejador global para errores 500 (excepción no controlada)."""
    return jsonify({"error": "Error interno del servidor"}), 500


# ═══════════════════════════════════════════════════════════════════════
#  Health check
# ═══════════════════════════════════════════════════════════════════════

@app.route("/")
def home():
    """
    Health check — comprueba que la API está activa.
    ---
    tags:
      - General
    responses:
      200:
        description: API operativa
        schema:
          type: object
          properties:
            status:
              type: string
            mensaje:
              type: string
            docs:
              type: string
    """
    return jsonify({
        "status": "ok",
        "mensaje": "API de Notova funcionando",
        "docs": "/apidocs",
    })


# ═══════════════════════════════════════════════════════════════════════
#  CRUD de Tareas  
# ═══════════════════════════════════════════════════════════════════════

def _tasks_ref():
    """Referencia a la subcolección de tareas del usuario autenticado."""
    return db.collection("users").document(g.uid).collection("tasks")


@app.route("/tareas", methods=["GET"])
@require_auth
def listar_tareas():
    """
    Obtener todas las tareas del usuario autenticado.
    ---
    tags:
      - Tareas
    security:
      - Bearer: []
    parameters:
      - name: completada
        in: query
        type: string
        required: false
        description: Filtrar por estado — "true" o "false"
    responses:
      200:
        description: Lista de tareas
        schema:
          type: object
          properties:
            tareas:
              type: array
              items:
                type: object
            total:
              type: integer
      401:
        description: No autorizado
    """
    ref = _tasks_ref()

    completada = request.args.get("completada")
    if completada is not None:
        ref = ref.where("isCompleted", "==", completada.lower() == "true")

    docs = ref.stream()
    tareas = []
    for doc in docs:
        data = doc.to_dict()
        data["id"] = doc.id
        # Convertir Timestamps de Firestore a ISO strings
        for campo in ("createdAt", "completedAt", "dueDate"):
            if data.get(campo) and hasattr(data[campo], "isoformat"):
                data[campo] = data[campo].isoformat()
        tareas.append(data)

    return jsonify({"tareas": tareas, "total": len(tareas)})


@app.route("/tareas/<tarea_id>", methods=["GET"])
@require_auth
def obtener_tarea(tarea_id):
    """
    Obtener una tarea por su ID.
    ---
    tags:
      - Tareas
    security:
      - Bearer: []
    parameters:
      - name: tarea_id
        in: path
        type: string
        required: true
    responses:
      200:
        description: Tarea encontrada
      404:
        description: Tarea no encontrada
    """
    doc = _tasks_ref().document(tarea_id).get()
    if not doc.exists:
        return jsonify({"error": "Tarea no encontrada"}), 404

    data = doc.to_dict()
    data["id"] = doc.id
    for campo in ("createdAt", "completedAt", "dueDate"):
        if data.get(campo) and hasattr(data[campo], "isoformat"):
            data[campo] = data[campo].isoformat()
    return jsonify(data)


@app.route("/tareas", methods=["POST"])
@require_auth
def crear_tarea():
    """
    Crear una nueva tarea.
    ---
    tags:
      - Tareas
    security:
      - Bearer: []
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - titulo
          properties:
            titulo:
              type: string
              description: Nombre de la tarea (obligatorio)
            subtitulo:
              type: string
              description: Notas o descripción
            prioridad:
              type: string
              enum: [HIGH, MED, LOW]
              description: Nivel de prioridad
            xpReward:
              type: integer
              description: Puntos de experiencia al completar
    responses:
      201:
        description: Tarea creada correctamente
      400:
        description: Datos de entrada inválidos
    """
    datos = request.get_json(silent=True)

    # — Validación de datos de entrada
    if not datos:
        return jsonify({"error": "El cuerpo de la petición debe ser JSON válido"}), 400

    titulo = datos.get("titulo", "").strip()
    if not titulo:
        return jsonify({"error": "El campo 'titulo' es obligatorio y no puede estar vacío"}), 400

    prioridad = datos.get("prioridad", "MED").upper()
    if prioridad not in ("HIGH", "MED", "LOW"):
        return jsonify({"error": "Prioridad debe ser HIGH, MED o LOW"}), 400

    xp = datos.get("xpReward", 25)
    if not isinstance(xp, int) or xp < 0:
        return jsonify({"error": "xpReward debe ser un entero positivo"}), 400

    nueva_tarea = {
        "title": titulo,
        "subtitle": datos.get("subtitulo", ""),
        "priority": prioridad,
        "xpReward": xp,
        "isCompleted": False,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "completedAt": None,
        "dueDate": None,
    }

    _, doc_ref = _tasks_ref().add(nueva_tarea)
    nueva_tarea["id"] = doc_ref.id
    nueva_tarea["createdAt"] = datetime.now(timezone.utc).isoformat()

    return jsonify({"mensaje": "Tarea creada", "tarea": nueva_tarea}), 201


@app.route("/tareas/<tarea_id>", methods=["PUT"])
@require_auth
def actualizar_tarea(tarea_id):
    """
    Actualizar una tarea existente.
    ---
    tags:
      - Tareas
    security:
      - Bearer: []
    parameters:
      - name: tarea_id
        in: path
        type: string
        required: true
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            titulo:
              type: string
            subtitulo:
              type: string
            prioridad:
              type: string
              enum: [HIGH, MED, LOW]
            completada:
              type: boolean
    responses:
      200:
        description: Tarea actualizada
      400:
        description: Datos inválidos
      404:
        description: Tarea no encontrada
    """
    doc_ref = _tasks_ref().document(tarea_id)
    if not doc_ref.get().exists:
        return jsonify({"error": "Tarea no encontrada"}), 404

    datos = request.get_json(silent=True)
    if not datos:
        return jsonify({"error": "No se proporcionaron datos JSON"}), 400

    campos = {}

    if "titulo" in datos:
        titulo = datos["titulo"].strip()
        if not titulo:
            return jsonify({"error": "El título no puede estar vacío"}), 400
        campos["title"] = titulo

    if "subtitulo" in datos:
        campos["subtitle"] = datos["subtitulo"]

    if "prioridad" in datos:
        prioridad = datos["prioridad"].upper()
        if prioridad not in ("HIGH", "MED", "LOW"):
            return jsonify({"error": "Prioridad debe ser HIGH, MED o LOW"}), 400
        campos["priority"] = prioridad

    if "completada" in datos:
        campos["isCompleted"] = bool(datos["completada"])
        if datos["completada"]:
            campos["completedAt"] = firestore.SERVER_TIMESTAMP

    if not campos:
        return jsonify({"error": "No se proporcionó ningún campo válido para actualizar"}), 400

    doc_ref.update(campos)
    return jsonify({"mensaje": "Tarea actualizada", "campos_modificados": list(campos.keys())})


@app.route("/tareas/<tarea_id>", methods=["DELETE"])
@require_auth
def eliminar_tarea(tarea_id):
    """
    Eliminar una tarea.
    ---
    tags:
      - Tareas
    security:
      - Bearer: []
    parameters:
      - name: tarea_id
        in: path
        type: string
        required: true
    responses:
      200:
        description: Tarea eliminada
      404:
        description: Tarea no encontrada
    """
    doc_ref = _tasks_ref().document(tarea_id)
    if not doc_ref.get().exists:
        return jsonify({"error": "Tarea no encontrada"}), 404

    doc_ref.delete()
    return jsonify({"mensaje": "Tarea eliminada"})


# ═══════════════════════════════════════════════════════════════════════
#  Exportación  (POST — generación de ficheros)
# ═══════════════════════════════════════════════════════════════════════

@app.route("/exportar/txt", methods=["POST"])
@require_auth
def exportar_txt():
    """
    Exportar lista de tareas a formato TXT.
    ---
    tags:
      - Exportación
    security:
      - Bearer: []
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - tareas
          properties:
            tareas:
              type: array
              items:
                type: object
                properties:
                  titulo:
                    type: string
                  prioridad:
                    type: string
                  completada:
                    type: boolean
                  xpReward:
                    type: integer
    responses:
      200:
        description: Archivo TXT generado correctamente
      400:
        description: Datos inválidos
    """
    datos = request.get_json(silent=True)
    if not datos or "tareas" not in datos:
        return jsonify({"error": "Se requiere el campo 'tareas' como array"}), 400

    tareas = datos["tareas"]
    if not isinstance(tareas, list):
        return jsonify({"error": "'tareas' debe ser un array"}), 400

    contenido = "MIS TAREAS — NOTOVA\n"
    contenido += "=" * 35 + "\n"
    contenido += f"Exportado: {datetime.now(timezone.utc).strftime('%d/%m/%Y %H:%M')} UTC\n"
    contenido += f"Total: {len(tareas)} tareas\n\n"

    for t in tareas:
        estado = "COMPLETADA" if t.get("completada") else "PENDIENTE"
        titulo = t.get("titulo", "Sin título")
        prioridad = t.get("prioridad", "MED")
        xp = t.get("xpReward", 0)
        contenido += f"[{estado}] {titulo} (Prioridad: {prioridad} | XP: {xp})\n"

    return Response(
        contenido,
        mimetype="text/plain",
        headers={"Content-Disposition": "attachment;filename=notova_tareas.txt"},
    )


@app.route("/exportar/csv", methods=["POST"])
@require_auth
def exportar_csv():
    """
    Exportar lista de tareas a formato CSV.
    ---
    tags:
      - Exportación
    security:
      - Bearer: []
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - tareas
          properties:
            tareas:
              type: array
              items:
                type: object
                properties:
                  titulo:
                    type: string
                  prioridad:
                    type: string
                  completada:
                    type: boolean
                  xpReward:
                    type: integer
    responses:
      200:
        description: Archivo CSV generado correctamente
      400:
        description: Datos inválidos
    """
    datos = request.get_json(silent=True)
    if not datos or "tareas" not in datos:
        return jsonify({"error": "Se requiere el campo 'tareas' como array"}), 400

    tareas = datos["tareas"]
    if not isinstance(tareas, list):
        return jsonify({"error": "'tareas' debe ser un array"}), 400

    salida = io.StringIO()
    writer = csv.writer(salida)
    writer.writerow(["Titulo", "Prioridad", "XP", "Completada"])

    for t in tareas:
        writer.writerow([
            t.get("titulo", ""),
            t.get("prioridad", ""),
            t.get("xpReward", 0),
            "Sí" if t.get("completada") else "No",
        ])

    return Response(
        salida.getvalue(),
        mimetype="text/csv",
        headers={"Content-Disposition": "attachment;filename=notova_tareas.csv"},
    )


# ═══════════════════════════════════════════════════════════════════════
#  Páginas legales (requeridas por Google OAuth)
# ═══════════════════════════════════════════════════════════════════════

_HTML_HEAD = """<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{title} — Notova</title>
  <style>
    *{{box-sizing:border-box;margin:0;padding:0}}
    body{{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;
          background:#0f0b17;color:#e0d9f0;line-height:1.7;padding:40px 20px}}
    .wrap{{max-width:760px;margin:0 auto}}
    h1{{font-size:2rem;color:#deb7ff;margin-bottom:8px}}
    h2{{font-size:1.15rem;color:#b892f5;margin:32px 0 10px}}
    p,li{{font-size:.97rem;color:#c4b8d8;margin-bottom:10px}}
    ul{{padding-left:20px}}
    a{{color:#7b2cbf;text-decoration:none}}
    a:hover{{text-decoration:underline}}
    .badge{{display:inline-block;background:#1e1a29;border:1px solid #3a2d55;
             border-radius:8px;padding:4px 12px;font-size:.8rem;color:#9b7fd4;margin-bottom:24px}}
    footer{{margin-top:48px;font-size:.82rem;color:#5a4f6e;border-top:1px solid #2a2040;padding-top:16px}}
  </style>
</head>
<body><div class="wrap">"""

_HTML_FOOT = """<footer>© 2026 Notova · <a href="/privacy">Política de Privacidad</a> · <a href="/terms">Condiciones del Servicio</a></footer>
</div></body></html>"""


@app.route("/privacy")
def privacy():
    """Política de Privacidad de Notova (requerida por Google OAuth)."""
    from flask import make_response
    html = _HTML_HEAD.format(title="Política de Privacidad") + """
  <h1>Política de Privacidad</h1>
  <span class="badge">Última actualización: mayo 2026</span>

  <p>Notova («la App») es una aplicación de productividad gamificada desarrollada por Alejandro Aroca.
  Esta política explica qué datos recogemos, cómo los usamos y cómo puedes controlarlos.</p>

  <h2>1. Datos que recogemos</h2>
  <ul>
    <li><strong>Cuenta de usuario:</strong> nombre, dirección de correo electrónico y foto de perfil
        proporcionados mediante Firebase Authentication (correo/contraseña o Google Sign-In).</li>
    <li><strong>Datos de uso:</strong> tareas creadas, puntos de experiencia (XP), rachas diarias e insignias.</li>
    <li><strong>Google Calendar (opcional):</strong> si conectas tu cuenta de Google Calendar, la App
        accede a la lista de calendarios y eventos para mostrarlos dentro de la App.
        Este acceso es opcional y puede revocarse en cualquier momento.</li>
    <li><strong>Avatar:</strong> imagen que el usuario sube voluntariamente, almacenada en Firebase Storage.</li>
  </ul>

  <h2>2. Cómo usamos tus datos</h2>
  <ul>
    <li>Para mostrar y sincronizar tus tareas, nivel y estadísticas de gamificación.</li>
    <li>Para mostrar tus eventos de Google Calendar dentro de la pantalla de Calendario de la App.</li>
    <li>Para generar exportaciones (CSV/TXT) de tu historial de tareas a petición tuya.</li>
  </ul>
  <p>No usamos tus datos para publicidad ni los compartimos con terceros con fines comerciales.</p>

  <h2>3. Datos de Google Calendar</h2>
  <p>El acceso a Google Calendar se realiza mediante OAuth 2.0 con el scope
  <code>https://www.googleapis.com/auth/calendar</code>. Los datos obtenidos:</p>
  <ul>
    <li>Se usan exclusivamente para mostrar eventos en la App y permitir crear o eliminar eventos
        en calendarios propios del usuario.</li>
    <li>No se almacenan en nuestros servidores de forma permanente; se cachean localmente
        en el dispositivo del usuario.</li>
    <li>No se comparten con ningún tercero.</li>
  </ul>
  <p>Puedes revocar el acceso en cualquier momento desde
  <a href="https://myaccount.google.com/permissions" target="_blank">Permisos de tu cuenta Google</a>
  o desde la pantalla de Perfil de la App.</p>

  <h2>4. Almacenamiento y seguridad</h2>
  <p>Los datos se almacenan en Firebase (Google Cloud). Aplicamos medidas de seguridad estándar
  de la industria, incluyendo autenticación de tokens y reglas de seguridad en Firestore que
  garantizan que cada usuario solo puede acceder a sus propios datos.</p>

  <h2>5. Retención de datos</h2>
  <p>Conservamos tus datos mientras tu cuenta esté activa. Puedes solicitar la eliminación
  completa de tu cuenta y datos desde la sección de Ajustes de la App o escribiéndonos a
  <a href="mailto:arocaalex2112@gmail.com">arocaalex2112@gmail.com</a>.</p>

  <h2>6. Menores de edad</h2>
  <p>La App no está dirigida a menores de 13 años. No recogemos conscientemente datos de menores.</p>

  <h2>7. Cambios en esta política</h2>
  <p>Notificaremos cambios relevantes mediante la App o por correo electrónico.
  El uso continuado de la App tras los cambios implica la aceptación de la nueva política.</p>

  <h2>8. Contacto</h2>
  <p>Para cualquier consulta sobre privacidad: <a href="mailto:arocaalex2112@gmail.com">arocaalex2112@gmail.com</a></p>
""" + _HTML_FOOT
    return make_response(html, 200, {"Content-Type": "text/html; charset=utf-8"})


@app.route("/terms")
def terms():
    """Condiciones del Servicio de Notova."""
    from flask import make_response
    html = _HTML_HEAD.format(title="Condiciones del Servicio") + """
  <h1>Condiciones del Servicio</h1>
  <span class="badge">Última actualización: mayo 2026</span>

  <p>Al usar Notova («la App») aceptas las presentes Condiciones del Servicio.
  Si no estás de acuerdo, no uses la App.</p>

  <h2>1. Descripción del servicio</h2>
  <p>Notova es una aplicación de productividad gamificada que permite gestionar tareas,
  ganar puntos de experiencia y sincronizar eventos con Google Calendar.</p>

  <h2>2. Cuenta de usuario</h2>
  <ul>
    <li>Debes proporcionar información veraz al registrarte.</li>
    <li>Eres responsable de mantener la seguridad de tu cuenta y contraseña.</li>
    <li>Notova se reserva el derecho a suspender cuentas que infrinjan estas condiciones.</li>
  </ul>

  <h2>3. Uso aceptable</h2>
  <p>Queda prohibido:</p>
  <ul>
    <li>Usar la App para actividades ilegales o fraudulentas.</li>
    <li>Intentar acceder a datos de otros usuarios.</li>
    <li>Realizar ingeniería inversa o redistribuir el código de la App sin autorización.</li>
  </ul>

  <h2>4. Integración con Google Calendar</h2>
  <p>La conexión con Google Calendar es opcional. Al conectarla, autorizas a Notova a
  leer y escribir eventos en tu nombre según los permisos que otorgues. Puedes desconectarla
  en cualquier momento desde la App o desde tu cuenta de Google.</p>

  <h2>5. Propiedad intelectual</h2>
  <p>El nombre, logo y código de Notova son propiedad de Alejandro Aroca.
  El contenido que tú creas (tareas, eventos) es tuyo.</p>

  <h2>6. Limitación de responsabilidad</h2>
  <p>La App se proporciona «tal cual». No garantizamos disponibilidad continua ni
  ausencia de errores. No somos responsables de pérdidas de datos derivadas de fallos técnicos.</p>

  <h2>7. Modificaciones</h2>
  <p>Podemos actualizar estas condiciones. Los cambios relevantes se notificarán en la App.
  El uso continuado implica aceptación.</p>

  <h2>8. Contacto</h2>
  <p><a href="mailto:arocaalex2112@gmail.com">arocaalex2112@gmail.com</a></p>
""" + _HTML_FOOT
    return make_response(html, 200, {"Content-Type": "text/html; charset=utf-8"})


# ═══════════════════════════════════════════════════════════════════════
#  Punto de entrada (desarrollo local)
# ═══════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    app.run(debug=True)
