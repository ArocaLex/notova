import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../repositories/task_repository.dart'; // Asegúrate de que el nombre del archivo coincida

class TasksViewModel extends ChangeNotifier {
  final TasksRepository _repository = TasksRepository();

  bool isLoading = false;
  String? errorMessage;

  // 1. EL TUBO EN TIEMPO REAL: Le pasamos el Stream directo a la vista
  Stream<QuerySnapshot> get pendingTasksStream => _repository.getPendingTasks();
  Stream<QuerySnapshot> get completedTasksStream => _repository.getCompletedTasks();

  // 2. CREAR TAREA
  Future<bool> createTask(
    String title,
    String subtitle,
    String priority,
    int xpReward,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners(); // Avisamos a la UI para que muestre (si quieres) un loader

    try {
      await _repository.addTask(
        title: title,
        subtitle: subtitle,
        priority: priority,
        xpReward: xpReward,
      );
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Error al crear la tarea: $e';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 3. COMPLETAR TAREA Y GANAR XP
  Future<void> toggleTaskCompletion(String taskId, int xpReward) async {
    try {
      // Llamamos al repositorio que hace el "Batch" (completa tarea + da XP)
      await _repository.completeTask(taskId, xpReward);

      // ¡OJO! No necesitamos notifyListeners() aquí.
      // Firestore detecta el cambio en la nube y hace que el StreamBuilder de la pantalla
      // se redibuje solo al instante, quitando la tarea de la lista.
    } catch (e) {
      errorMessage = 'Error al actualizar la tarea.';
      notifyListeners();
    }
  }
}
