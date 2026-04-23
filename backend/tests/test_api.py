"""
Tests de la API REST de Notova.

Ejecutar con:  pytest tests/ -v
"""

import json
import pytest
from unittest.mock import patch, MagicMock

# ── Mocks de Firebase (se aplican ANTES de importar la app) ────────────

# Mock de firebase_admin para que no necesite serviceAccountKey.json real
mock_cred = MagicMock()
mock_firestore_client = MagicMock()


def _mock_verify_id_token(token, **kwargs):
    """Simula la verificación de tokens Firebase."""
    if token == "token_valido":
        return {"uid": "test_user_123"}
    raise Exception("Token inválido")


# Creamos un mock de documento Firestore
def _make_mock_doc(doc_id, data, exists=True):
    doc = MagicMock()
    doc.id = doc_id
    doc.exists = exists
    doc.to_dict.return_value = data if exists else None
    return doc


# Patcheamos Firebase antes de importar la app
with patch("firebase_admin.credentials.Certificate", return_value=mock_cred), \
     patch("firebase_admin.initialize_app"), \
     patch("firebase_admin.firestore.client", return_value=mock_firestore_client):
    from api import app


# ═══════════════════════════════════════════════════════════════════════
#  Fixtures
# ═══════════════════════════════════════════════════════════════════════

@pytest.fixture
def client():
    """Cliente de test de Flask."""
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


@pytest.fixture
def auth_headers():
    """Headers con token válido."""
    return {"Authorization": "Bearer token_valido", "Content-Type": "application/json"}


@pytest.fixture
def no_auth_headers():
    """Headers sin token."""
    return {"Content-Type": "application/json"}


TAREA_EJEMPLO = {
    "title": "Estudiar Flutter",
    "subtitle": "Repasar widgets",
    "priority": "HIGH",
    "xpReward": 50,
    "isCompleted": False,
    "createdAt": None,
    "completedAt": None,
    "dueDate": None,
}


# ═══════════════════════════════════════════════════════════════════════
#  Tests — Health Check
# ═══════════════════════════════════════════════════════════════════════

class TestHealthCheck:
    def test_home_returns_ok(self, client):
        """GET / devuelve status ok."""
        resp = client.get("/")
        assert resp.status_code == 200
        data = resp.get_json()
        assert data["status"] == "ok"
        assert "docs" in data


# ═══════════════════════════════════════════════════════════════════════
#  Tests — Autenticación 
# ═══════════════════════════════════════════════════════════════════════

class TestAuth:
    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_sin_token_devuelve_401(self, mock_auth, client, no_auth_headers):
        """Petición sin token Authorization devuelve 401."""
        resp = client.get("/tareas", headers=no_auth_headers)
        assert resp.status_code == 401
        assert "Token no proporcionado" in resp.get_json()["error"]

    @patch("api.auth.verify_id_token", side_effect=Exception("Token inválido"))
    def test_token_invalido_devuelve_401(self, mock_auth, client):
        """Token inválido devuelve 401."""
        headers = {"Authorization": "Bearer token_falso", "Content-Type": "application/json"}
        resp = client.get("/tareas", headers=headers)
        assert resp.status_code == 401
        assert "inválido" in resp.get_json()["error"]

    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_token_valido_permite_acceso(self, mock_auth, client, auth_headers):
        """Token válido permite acceder al recurso protegido."""
        # Mock Firestore para que devuelva una lista vacía
        mock_ref = MagicMock()
        mock_ref.stream.return_value = []
        mock_firestore_client.collection.return_value.document.return_value.collection.return_value = mock_ref

        resp = client.get("/tareas", headers=auth_headers)
        assert resp.status_code == 200


# ═══════════════════════════════════════════════════════════════════════
#  Tests — CRUD de Tareas 
# ═══════════════════════════════════════════════════════════════════════

class TestListarTareas:
    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_listar_tareas_vacio(self, mock_auth, client, auth_headers):
        """GET /tareas devuelve lista vacía cuando no hay tareas."""
        mock_ref = MagicMock()
        mock_ref.stream.return_value = []
        mock_firestore_client.collection.return_value.document.return_value.collection.return_value = mock_ref

        resp = client.get("/tareas", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.get_json()
        assert data["tareas"] == []
        assert data["total"] == 0

    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_listar_tareas_con_datos(self, mock_auth, client, auth_headers):
        """GET /tareas devuelve las tareas del usuario."""
        mock_doc = _make_mock_doc("task_1", TAREA_EJEMPLO.copy())
        mock_ref = MagicMock()
        mock_ref.stream.return_value = [mock_doc]
        mock_firestore_client.collection.return_value.document.return_value.collection.return_value = mock_ref

        resp = client.get("/tareas", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.get_json()
        assert data["total"] == 1
        assert data["tareas"][0]["id"] == "task_1"

    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_filtrar_por_completada(self, mock_auth, client, auth_headers):
        """GET /tareas?completada=true filtra correctamente."""
        mock_ref = MagicMock()
        mock_where = MagicMock()
        mock_where.stream.return_value = []
        mock_ref.where.return_value = mock_where
        mock_firestore_client.collection.return_value.document.return_value.collection.return_value = mock_ref

        resp = client.get("/tareas?completada=true", headers=auth_headers)
        assert resp.status_code == 200
        mock_ref.where.assert_called_once_with("isCompleted", "==", True)


class TestObtenerTarea:
    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_tarea_existente(self, mock_auth, client, auth_headers):
        """GET /tareas/<id> devuelve la tarea si existe."""
        mock_doc = _make_mock_doc("task_1", TAREA_EJEMPLO.copy())
        mock_firestore_client.collection.return_value.document.return_value \
            .collection.return_value.document.return_value.get.return_value = mock_doc

        resp = client.get("/tareas/task_1", headers=auth_headers)
        assert resp.status_code == 200
        assert resp.get_json()["id"] == "task_1"

    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_tarea_no_encontrada(self, mock_auth, client, auth_headers):
        """GET /tareas/<id> devuelve 404 si no existe."""
        mock_doc = _make_mock_doc("fake_id", None, exists=False)
        mock_firestore_client.collection.return_value.document.return_value \
            .collection.return_value.document.return_value.get.return_value = mock_doc

        resp = client.get("/tareas/fake_id", headers=auth_headers)
        assert resp.status_code == 404


class TestCrearTarea:
    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_crear_tarea_exitosa(self, mock_auth, client, auth_headers):
        """POST /tareas crea una tarea y devuelve 201."""
        mock_doc_ref = MagicMock()
        mock_doc_ref.id = "nueva_task_id"
        mock_firestore_client.collection.return_value.document.return_value \
            .collection.return_value.add.return_value = (None, mock_doc_ref)

        resp = client.post("/tareas", headers=auth_headers,
                           data=json.dumps({"titulo": "Test task", "prioridad": "HIGH"}))
        assert resp.status_code == 201
        data = resp.get_json()
        assert data["tarea"]["id"] == "nueva_task_id"
        assert data["tarea"]["title"] == "Test task"

    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_crear_tarea_sin_titulo_devuelve_400(self, mock_auth, client, auth_headers):
        """POST /tareas sin título devuelve 400."""
        resp = client.post("/tareas", headers=auth_headers,
                           data=json.dumps({"subtitulo": "sin titulo"}))
        assert resp.status_code == 400
        assert "titulo" in resp.get_json()["error"].lower()

    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_crear_tarea_prioridad_invalida(self, mock_auth, client, auth_headers):
        """POST /tareas con prioridad inválida devuelve 400."""
        resp = client.post("/tareas", headers=auth_headers,
                           data=json.dumps({"titulo": "Test", "prioridad": "ULTRA"}))
        assert resp.status_code == 400
        assert "Prioridad" in resp.get_json()["error"]

    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_crear_tarea_sin_json_devuelve_400(self, mock_auth, client, auth_headers):
        """POST /tareas sin body JSON devuelve 400."""
        resp = client.post("/tareas", headers={"Authorization": "Bearer token_valido"})
        assert resp.status_code == 400


class TestActualizarTarea:
    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_actualizar_tarea_exitosa(self, mock_auth, client, auth_headers):
        """PUT /tareas/<id> actualiza correctamente."""
        mock_doc = _make_mock_doc("task_1", TAREA_EJEMPLO.copy())
        mock_doc_ref = MagicMock()
        mock_doc_ref.get.return_value = mock_doc
        mock_firestore_client.collection.return_value.document.return_value \
            .collection.return_value.document.return_value = mock_doc_ref

        resp = client.put("/tareas/task_1", headers=auth_headers,
                          data=json.dumps({"titulo": "Actualizada", "prioridad": "LOW"}))
        assert resp.status_code == 200
        mock_doc_ref.update.assert_called_once()

    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_actualizar_tarea_no_encontrada(self, mock_auth, client, auth_headers):
        """PUT /tareas/<id> devuelve 404 si no existe."""
        mock_doc = _make_mock_doc("fake_id", None, exists=False)
        mock_doc_ref = MagicMock()
        mock_doc_ref.get.return_value = mock_doc
        mock_firestore_client.collection.return_value.document.return_value \
            .collection.return_value.document.return_value = mock_doc_ref

        resp = client.put("/tareas/fake_id", headers=auth_headers,
                          data=json.dumps({"titulo": "X"}))
        assert resp.status_code == 404


class TestEliminarTarea:
    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_eliminar_tarea_exitosa(self, mock_auth, client, auth_headers):
        """DELETE /tareas/<id> elimina y devuelve 200."""
        mock_doc = _make_mock_doc("task_1", TAREA_EJEMPLO.copy())
        mock_doc_ref = MagicMock()
        mock_doc_ref.get.return_value = mock_doc
        mock_firestore_client.collection.return_value.document.return_value \
            .collection.return_value.document.return_value = mock_doc_ref

        resp = client.delete("/tareas/task_1", headers=auth_headers)
        assert resp.status_code == 200
        mock_doc_ref.delete.assert_called_once()

    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_eliminar_tarea_no_encontrada(self, mock_auth, client, auth_headers):
        """DELETE /tareas/<id> devuelve 404 si no existe."""
        mock_doc = _make_mock_doc("fake_id", None, exists=False)
        mock_doc_ref = MagicMock()
        mock_doc_ref.get.return_value = mock_doc
        mock_firestore_client.collection.return_value.document.return_value \
            .collection.return_value.document.return_value = mock_doc_ref

        resp = client.delete("/tareas/fake_id", headers=auth_headers)
        assert resp.status_code == 404


# ═══════════════════════════════════════════════════════════════════════
#  Tests — Exportación
# ═══════════════════════════════════════════════════════════════════════

class TestExportarTxt:
    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_exportar_txt_exitoso(self, mock_auth, client, auth_headers):
        """POST /exportar/txt genera un archivo de texto."""
        payload = {
            "tareas": [
                {"titulo": "Tarea 1", "prioridad": "HIGH", "completada": True, "xpReward": 50},
                {"titulo": "Tarea 2", "prioridad": "LOW", "completada": False, "xpReward": 25},
            ]
        }
        resp = client.post("/exportar/txt", headers=auth_headers, data=json.dumps(payload))
        assert resp.status_code == 200
        assert "text/plain" in resp.content_type
        contenido = resp.data.decode("utf-8")
        assert "NOTOVA" in contenido
        assert "COMPLETADA" in contenido
        assert "PENDIENTE" in contenido

    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_exportar_txt_sin_tareas_devuelve_400(self, mock_auth, client, auth_headers):
        """POST /exportar/txt sin campo tareas devuelve 400."""
        resp = client.post("/exportar/txt", headers=auth_headers, data=json.dumps({}))
        assert resp.status_code == 400


class TestExportarCsv:
    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_exportar_csv_exitoso(self, mock_auth, client, auth_headers):
        """POST /exportar/csv genera un archivo CSV con cabeceras."""
        payload = {
            "tareas": [
                {"titulo": "Tarea 1", "prioridad": "HIGH", "completada": True, "xpReward": 50},
            ]
        }
        resp = client.post("/exportar/csv", headers=auth_headers, data=json.dumps(payload))
        assert resp.status_code == 200
        assert "text/csv" in resp.content_type
        contenido = resp.data.decode("utf-8")
        assert "Titulo" in contenido
        assert "Tarea 1" in contenido

    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_exportar_csv_sin_tareas_devuelve_400(self, mock_auth, client, auth_headers):
        """POST /exportar/csv sin campo tareas devuelve 400."""
        resp = client.post("/exportar/csv", headers=auth_headers, data=json.dumps({}))
        assert resp.status_code == 400


# ═══════════════════════════════════════════════════════════════════════
#  Tests — Validación de entrada 
# ═══════════════════════════════════════════════════════════════════════

class TestValidacion:
    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_xp_negativo_devuelve_400(self, mock_auth, client, auth_headers):
        """POST /tareas con xpReward negativo devuelve 400."""
        resp = client.post("/tareas", headers=auth_headers,
                           data=json.dumps({"titulo": "Test", "xpReward": -10}))
        assert resp.status_code == 400
        assert "xpReward" in resp.get_json()["error"]

    @patch("api.auth.verify_id_token", side_effect=_mock_verify_id_token)
    def test_titulo_vacio_devuelve_400(self, mock_auth, client, auth_headers):
        """POST /tareas con título vacío devuelve 400."""
        resp = client.post("/tareas", headers=auth_headers,
                           data=json.dumps({"titulo": "   "}))
        assert resp.status_code == 400

    def test_metodo_no_permitido(self, client):
        """PATCH /tareas devuelve 405."""
        resp = client.patch("/tareas")
        assert resp.status_code == 405
