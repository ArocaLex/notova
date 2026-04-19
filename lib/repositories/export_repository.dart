import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/task_model.dart';
import 'api_client.dart';

/// Gestiona la exportación del historial de tareas a CSV o TXT.
///
/// Flujo principal (online):
///   1. Recoge las tareas del usuario.
///   2. Las envía al microservicio REST en PythonAnywhere vía [ApiClient]
///      (RA3.c — llamada HTTP a otra API). El servidor procesa los datos
///      y genera el fichero.
///   3. Se guarda la respuesta en local y se abre el menú de compartir.
///
/// Fallback (offline): genera el fichero íntegramente en el dispositivo
/// cuando la API no está disponible.
///
class ExportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiClient _api;

  ExportRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  String? get _uid => _auth.currentUser?.uid;

  /// Recupera todas las tareas del usuario desde Firestore ordenadas por
  /// fecha de creación ascendente.
  Future<List<TaskModel>> _fetchAllTasks() async {
    if (_uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('tasks')
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  }

  /// Convierte las tareas a la estructura JSON que espera la API Python.
  List<Map<String, dynamic>> _tasksToApiPayload(List<TaskModel> tasks) {
    return tasks
        .map((t) => {
              'titulo': t.title,
              'prioridad': t.priority,
              'completada': t.isCompleted,
              'xpReward': t.xpReward,
            })
        .toList();
  }

  /// Exporta las tareas llamando al endpoint POST /exportar/{format}
  /// del microservicio Python vía [ApiClient]. El token se inyecta
  /// automáticamente. Devuelve el contenido del fichero generado
  /// por el servidor, o `null` si la API no está disponible.
  Future<String?> _exportViaApi(String format) async {
    try {
      final tasks = await _fetchAllTasks();
      final response = await _api.post(
        '/exportar/$format',
        body: {'tareas': _tasksToApiPayload(tasks)},
      );

      if (response.isOk) {
        debugPrint('[Export] API response OK ($format) — '
            '${response.body.length} bytes');
        return response.body;
      }

      debugPrint('[Export] API error ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('[Export] API call failed (offline?): $e');
      return null;
    }
  }

  /// Genera un fichero CSV en el dispositivo con todas las tareas del usuario.
  ///
  /// Se usa como fallback cuando la API REST no está disponible.
  Future<String> _exportToCsvLocal() async {
    final tasks = await _fetchAllTasks();
    final rows = <List<dynamic>>[
      [
        'Título',
        'Notas',
        'Prioridad',
        'XP',
        'Completada',
        'FechaLímite',
        'CreadaEn',
        'CompletadaEn'
      ],
    ];

    for (final t in tasks) {
      rows.add([
        t.title,
        t.subtitle,
        t.priority,
        t.xpReward,
        t.isCompleted ? 'Sí' : 'No',
        t.dueDate != null ? _formatDate(t.dueDate!) : '',
        t.createdAt != null ? _formatDate(t.createdAt!) : '',
        t.completedAt != null ? _formatDate(t.completedAt!) : '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/notova_export.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  /// Genera un fichero TXT en el dispositivo con todas las tareas del usuario.
  ///
  /// Se usa como fallback cuando la API REST no está disponible.
  Future<String> _exportToTxtLocal() async {
    final tasks = await _fetchAllTasks();
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('  NOTOVA — Historial de Quests');
    buffer.writeln('  Exportado: ${_formatDate(DateTime.now())}');
    buffer.writeln('═══════════════════════════════════\n');

    for (final t in tasks) {
      buffer.writeln('[${t.isCompleted ? '✓' : ' '}] ${t.title}');
      if (t.subtitle.isNotEmpty) buffer.writeln('    Notas: ${t.subtitle}');
      buffer.writeln('    Prioridad: ${t.priority}  |  XP: ${t.xpReward}');
      if (t.dueDate != null) {
        buffer.writeln('    Fecha límite: ${_formatDate(t.dueDate!)}');
      }
      buffer.writeln(
          '    Creada: ${t.createdAt != null ? _formatDate(t.createdAt!) : '-'}');
      if (t.completedAt != null) {
        buffer.writeln('    Completada: ${_formatDate(t.completedAt!)}');
      }
      buffer.writeln('───────────────────────────────────');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/notova_export.txt');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  /// Genera el fichero de exportación y abre el menú nativo de compartir.
  ///
  /// Flujo:
  ///   1. Intenta generar el fichero a través de la API REST (microservicio
  ///      Python desplegado en PythonAnywhere) vía [ApiClient].
  ///   2. Si la API no responde (offline o error), genera el fichero
  ///      localmente como fallback.
  ///   3. En ambos casos escribe el resultado en disco y lanza share_plus.
  Future<String> shareExport(String format) async {
    String path;

    final apiContent = await _exportViaApi(format);

    if (apiContent != null) {
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          format == 'csv' ? 'notova_export.csv' : 'notova_export.txt';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(apiContent);
      path = file.path;
      debugPrint('[Export] Fichero generado vía API REST ($format)');
    } else {
      path = format == 'csv'
          ? await _exportToCsvLocal()
          : await _exportToTxtLocal();
      debugPrint('[Export] Fichero generado localmente ($format) — '
          'API no disponible');
    }

    final mime = format == 'csv' ? 'text/csv' : 'text/plain';
    final fileName =
        format == 'csv' ? 'notova_export.csv' : 'notova_export.txt';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: mime, name: fileName)],
        subject: 'Historial de Notova',
        text: 'Mi historial de quests de Notova.',
      ),
    );
    return path;
  }

  /// Formatea [d] como `dd/mm/yyyy  hh:mm`.
  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
