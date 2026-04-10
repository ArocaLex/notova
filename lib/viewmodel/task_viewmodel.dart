import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../repositories/audio_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';

class TasksViewModel extends ChangeNotifier {
  late final TasksRepository _repository;
  late final UserRepository _userRepository;
  late final AudioRepository _audioRepository;

  TasksViewModel({
    TasksRepository? repository,
    UserRepository? userRepository,
    AudioRepository? audioRepository,
  })  : _repository = repository ?? TasksRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _audioRepository = audioRepository ?? AudioRepository();

  bool isLoading = false;
  String? errorMessage;

  // Streams tipados con TaskModel
  Stream<List<TaskModel>> get pendingTasksStream => _repository.getPendingTasks();
  Stream<List<TaskModel>> get completedTasksStream => _repository.getCompletedTasks();

  // Crear tarea con fecha de vencimiento opcional
  Future<bool> createTask(
    String title,
    String subtitle,
    String priority,
    int xpReward, {
    DateTime? dueDate,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.addTask(
        title: title,
        subtitle: subtitle,
        priority: priority,
        xpReward: xpReward,
        dueDate: dueDate,
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

  // Editar tarea existente
  Future<bool> updateTask(
    String taskId,
    String title,
    String subtitle,
    String priority,
    int xpReward, {
    DateTime? dueDate,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateTask(
        taskId: taskId,
        title: title,
        subtitle: subtitle,
        priority: priority,
        xpReward: xpReward,
        dueDate: dueDate,
      );
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Error al actualizar la tarea: $e';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Completar tarea: otorga XP, actualiza racha y dispara SFX.
  // Retorna true si hubo level-up.
  Future<bool> toggleTaskCompletion(String taskId, int xpReward) async {
    try {
      final didLevelUp = await _repository.completeTask(taskId, xpReward);
      await _userRepository.checkAndUpdateStreak();
      await _audioRepository.playTaskComplete();
      if (didLevelUp) await _audioRepository.playLevelUp();
      return didLevelUp;
    } catch (e) {
      errorMessage = 'Error al actualizar la tarea.';
      notifyListeners();
      return false;
    }
  }

  // Llamado al abrir la pantalla de Tasks (mantiene racha aunque no haya tareas)
  Future<void> checkStreakOnView() async {
    await _userRepository.checkAndUpdateStreak();
  }
}
