import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/task_model.dart';
import 'api_client.dart';

/// Gestiona la exportación del historial de tareas.
class ExportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiClient _api;

  ExportRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  String? get userId => _auth.currentUser?.uid;

  /// Recupera todas las tareas del usuario.
  Future<List<TaskModel>> _fetchAll() async {
    if (userId == null) return [];
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  }

  /// Convierte las tareas para la API.
  List<Map<String, dynamic>> _prepareForApi(List<TaskModel> tasks) {
    return tasks
        .map(
          (t) => {
            'titulo': t.title,
            'prioridad': t.priority,
            'completada': t.isCompleted,
            'xpReward': t.xpReward,
          },
        )
        .toList();
  }

  /// Exporta usando la API de PythonAnywhere.
  Future<String?> _exportViaApi(String format) async {
    try {
      final tasks = await _fetchAll();
      final response = await _api.post(
        '/exportar/$format',
        body: {'tareas': _prepareForApi(tasks)},
      );

      if (response.isOk) {
        return response.body;
      }
      return null;
    } catch (e) {
      debugPrint('[Export] Error en llamada API: $e');
      return null;
    }
  }

  /// Genera un CSV localmente.
  Future<String> _exportCsvLocal() async {
    final tasks = await _fetchAll();
    final rows = <List<dynamic>>[
      [
        'Título',
        'Notas',
        'Prioridad',
        'XP',
        'Completada',
        'FechaLímite',
        'CreadaEn',
        'CompletadaEn',
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

  /// Genera un TXT localmente.
  Future<String> _exportTxtLocal() async {
    final tasks = await _fetchAll();
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
        '    Creada: ${t.createdAt != null ? _formatDate(t.createdAt!) : '-'}',
      );
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

  /// Genera el archivo y lo comparte.
  Future<String> shareExport(String format) async {
    String path;

    final apiContent = await _exportViaApi(format);

    if (apiContent != null) {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = format == 'csv'
          ? 'notova_export.csv'
          : 'notova_export.txt';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(apiContent);
      path = file.path;
    } else {
      path = format == 'csv'
          ? await _exportCsvLocal()
          : await _exportTxtLocal();
    }

    final mimeType = format == 'csv' ? 'text/csv' : 'text/plain';
    final finalName = format == 'csv'
        ? 'notova_export.csv'
        : 'notova_export.txt';

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: mimeType, name: finalName)],
        subject: 'Historial de Notova',
        text: 'Mi historial de tareas de Notova.',
      ),
    );
    return path;
  }

  /// Formatea la fecha.
  String _formatDate(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}  ${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
}
