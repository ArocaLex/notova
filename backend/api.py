"""
Notova REST API — Backend del proyecto intermodular.

Framework: Flask + Flasgger (Swagger/OpenAPI)
Auth:      Firebase Admin SDK (verificación de ID tokens)
DB:        Cloud Firestore (lectura/escritura de tareas)
Despliegue: PythonAnywhere (arocaalex.pythonanywhere.com)


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

# RA3.c — CORS: permite peticiones desde cualquier origen (app móvil)
CORS(app, resources={r"/*": {"origins": "*"}})

# RA3.g — Swagger/OpenAPI con Flasgger
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
#  Middleware de autenticación (RA3.d)
# ═══════════════════════════════════════════════════════════════════════

def require_auth(f):
    """Verifica el Firebase ID Token del header Authorization."""
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
#  Gestión global de errores (RA3.e)
# ═══════════════════════════════════════════════════════════════════════

@app.errorhandler(400)
def bad_request(e):
    return jsonify({"error": "Petición incorrecta", "detalle": str(e)}), 400

@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Recurso no encontrado"}), 404

@app.errorhandler(405)
def method_not_allowed(e):
    return jsonify({"error": "Método HTTP no permitido"}), 405

@app.errorhandler(500)
def server_error(e):
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
#  CRUD de Tareas  (RA3.a — GET, POST, PUT, DELETE)
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

    # RA3.e — Validación de datos de entrada
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
#  Punto de entrada (desarrollo local)
# ═══════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    app.run(debug=True)
