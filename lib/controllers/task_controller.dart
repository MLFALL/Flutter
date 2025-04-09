import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/task_model.dart';
import '../models/comment_model.dart';
import '../services/firebase_service.dart';
import 'auth_controller.dart';

class TaskController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<TaskModel> tasks = <TaskModel>[].obs;
  final RxList<TaskModel> filteredTasks = <TaskModel>[].obs;
  final Rx<TaskModel?> selectedTask = Rx<TaskModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;


  // Getter pour accéder à la tâche sélectionnée
  TaskModel? get currentTask => selectedTask.value;

  // Filters
  final RxString priorityFilter = 'All'.obs;
  final RxString assigneeFilter = ''.obs;
  final RxBool showOnlyMyTasks = false.obs;

  // Current project ID
  final RxString currentProjectId = ''.obs;

  void setCurrentProject(String projectId) {
    currentProjectId.value = projectId;
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    if (currentProjectId.value.isEmpty) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      List<TaskModel> fetchedTasks = await _firebaseService.getProjectTasks(currentProjectId.value);
      tasks.value = fetchedTasks;
      applyFilters();
    } catch (e) {
      errorMessage.value = 'Failed to load tasks: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    //List<TaskModel> result = List.from(tasks);
    var result = List<TaskModel>.from(tasks);

    // Apply priority filter
    if (priorityFilter.value != 'All') {
      result = result.where((task) => task.priority == priorityFilter.value).toList();
    }

    // Apply assignee filter
    if (assigneeFilter.value.isNotEmpty) {
      result = result.where((task) =>
          task.assignedTo.any((assignedUserId) => assignedUserId.toLowerCase().contains(assigneeFilter.value.toLowerCase()))
      ).toList();
    }

    // Show only my tasks if selected
    if (showOnlyMyTasks.value) {
      result = result.where((task) => task.assignedTo.contains(_authController.currentUser!.id)).toList();
    }

    filteredTasks.value = result;
  }

  void setPriorityFilter(String priority) {
    priorityFilter.value = priority;
    applyFilters();
  }

  void setAssigneeFilter(String assignee) {
    assigneeFilter.value = assignee;
    applyFilters();
  }

  void toggleShowOnlyMyTasks() {
    showOnlyMyTasks.value = !showOnlyMyTasks.value;
    applyFilters();
  }

  void clearFilters() {
    priorityFilter.value = 'All';
    assigneeFilter.value = '';
    showOnlyMyTasks.value = false;
    applyFilters();
  }

  Future<void> createTask(TaskModel task) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Crée une nouvelle instance de TaskModel avec le projectId mis à jour
      task = task.copyWith(projectId: currentProjectId.value);

      // Sauvegarder dans Firestore
      await _firebaseService.createTask(task);

      // Rafraîchir la liste des tâches
      await fetchTasks();
    } catch (e) {
      errorMessage.value = 'Failed to create task: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> updateTask(TaskModel task) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _firebaseService.updateTask(task);

      // Update selected task if it's the one being modified
      if (selectedTask.value?.id == task.id) {
        selectedTask.value = task; // Cela met à jour uniquement si nécessaire
      }

      // Refresh tasks list
      await fetchTasks();
    } catch (e) {
      errorMessage.value = 'Failed to update task: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Supprimer la tâche via FirebaseService
      await _firebaseService.deleteTask(taskId, currentProjectId.value);

      // Clear selected task if it's the one being deleted
      if (selectedTask.value?.id == taskId) {
        selectedTask.value = null;
      }

      // Refresh tasks list
      await fetchTasks();
    } catch (e) {
      errorMessage.value = 'Failed to delete task: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateTaskProgress(String taskId, double progress) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _firebaseService.updateTaskProgress(taskId, progress);

      // Refresh tasks list
      await fetchTasks();

      // Refresh selected task if it's the one being modified
      if (selectedTask.value?.id == taskId) {
        selectedTask.value = await _firebaseService.getTaskById(taskId);
      }
    } catch (e) {
      errorMessage.value = 'Failed to update progress: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  RxList<CommentModel> taskComments = <CommentModel>[].obs;
  Future<void> addComment(String taskId, String text) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Créer un nouveau commentaire sans userName et userPhotoUrl
      final comment = CommentModel(
        id: '',  // L'ID sera généré automatiquement par Firestore lors de l'ajout
        taskId: taskId,
        userId: _authController.currentUser!.id,
        message: text,  // Utiliser 'message' au lieu de 'text'
        createdAt: DateTime.now(),
      );

      await _firebaseService.addTaskComment(comment);

      // Refresh selected task if it's the one being modified
      if (selectedTask.value?.id == taskId) {
        selectedTask.value = await _firebaseService.getTaskById(taskId);
      }
    } catch (e) {
      errorMessage.value = 'Failed to add comment: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void selectTask(TaskModel task) {
    selectedTask.value = task;
  }

  void clearSelectedTask() {
    selectedTask.value = null;
  }

  List<TaskModel> getTasksByStatus(String status) {
    return tasks.where((task) => task.status == status).toList();
  }

  List<TaskModel> getTasksAssignedToCurrentUser() {
    final currentUserId = _authController.currentUser?.id;
    if (currentUserId == null) return [];

    // Vérifie si currentUserId est présent dans la liste des assignés
    return tasks.where((task) => task.assignedTo.contains(currentUserId)).toList();
  }

  Future<void> getTaskDetails(String taskId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Récupérer la tâche via FirebaseService en utilisant l'ID de la tâche
      TaskModel task = await _firebaseService.getTaskById(taskId);
      selectedTask.value = task;
    } catch (e) {
      errorMessage.value = 'Failed to load task details: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getTaskComments(String taskId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Récupérer les commentaires de la tâche via FirebaseService
      List<CommentModel> comments = await _firebaseService.getTaskComments(taskId);

      // Ajouter les commentaires à la tâche sélectionnée si elle est active
      if (selectedTask.value != null) {
        selectedTask.value = selectedTask.value!.copyWith(comments: comments);
      }

    } catch (e) {
      errorMessage.value = 'Failed to load task comments: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addTaskComment(CommentModel comment) async {
    await FirebaseFirestore.instance.collection('comments').add(comment.toFirestore());
  }

  // Méthode pour mettre à jour le statut de la tâche
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Récupérer la tâche existante
      TaskModel task = await _firebaseService.getTaskById(taskId);

      // Mettre à jour le statut de la tâche
      task = task.copyWith(status: newStatus);

      // Mettre à jour la tâche dans Firestore
      await _firebaseService.updateTask(task);

      // Mettre à jour la tâche sélectionnée si elle est modifiée
      if (selectedTask.value?.id == taskId) {
        selectedTask.value = task;
      }

      // Rafraîchir la liste des tâches
      await fetchTasks();
    } catch (e) {
      errorMessage.value = 'Failed to update task status: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  final RxBool isLoadingComments = false.obs;
  Future<void> loadComments(String taskId) async {
    try {
      isLoadingComments.value = true;  // Marquer que les commentaires sont en train de se charger

      // Récupère les commentaires de la tâche via ton service
      taskComments.value = await _firebaseService.getTaskComments(taskId);

    } catch (e) {
      // Gestion des erreurs, si nécessaire
    } finally {
      isLoadingComments.value = false;  // Marquer que le chargement est terminé
    }
  }

  List<TaskModel> getTasksByProjectId(String projectId) {
    return tasks.where((task) => task.projectId == projectId).toList();
  }


}