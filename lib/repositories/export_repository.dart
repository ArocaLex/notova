import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/task_model.dart';

/// Gestiona la exportación del historial de tareas a CSV o TXT.
///
/// Destinos posibles:
///   1. Archivo local en el directorio de documentos del dispositivo.
///   2. API REST en https://arocaalex.pythonanywhere.com/
class ExportRepository {
  static const _apiBase = 'https://arocaalex.pythonanywhere.com';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Obtiene el Firebase ID Token del usuario actual para autenticar
  /// las peticiones a la API REST (RA3.d).
  Future<String?> _getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  // ── Leer todas las tareas ────────────────────────────────────────────────

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

  // ── Exportar a CSV ───────────────────────────────────────────────────────

  Future<String> exportToCsv() async {
    final tasks = await _fetchAllTasks();
    final rows = <List<dynamic>>[
      ['Título', 'Notas', 'Prioridad', 'XP', 'Completada', 'FechaLímite', 'CreadaEn', 'CompletadaEn'],
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

  // ── Exportar a TXT ───────────────────────────────────────────────────────

  Future<String> exportToTxt() async {
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
      if (t.dueDate != null) buffer.writeln('    Fecha límite: ${_formatDate(t.dueDate!)}');
      buffer.writeln('    Creada: ${t.createdAt != null ? _formatDate(t.createdAt!) : '-'}');
      if (t.completedAt != null) buffer.writeln('    Completada: ${_formatDate(t.completedAt!)}');
      buffer.writeln('───────────────────────────────────');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/notova_export.txt');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  // ── Enviar a la API REST (autenticado con Firebase ID Token) ─────────────

  Future<bool> sendToApi(String format) async {
    try {
      final token = await _getIdToken();
      if (token == null) return false;

      final tasks = await _fetchAllTasks();
      final tareasJson = tasks.map((t) {
        return {
          'titulo': t.title,
          'prioridad': t.priority,
          'completada': t.isCompleted,
          'xpReward': t.xpReward,
        };
      }).toList();

      final uri = Uri.parse('$_apiBase/exportar/$format');
      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'tareas': tareasJson}),
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
