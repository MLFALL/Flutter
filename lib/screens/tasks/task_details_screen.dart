// screens/tasks/task_details_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/task_model.dart';
import '../../models/comment_model.dart';
import '../../models/user_model.dart';
import '../../widgets/task/task_priority_badge.dart';
import '../../widgets/task/task_progress_indicator.dart';
import '../../widgets/user/user_avatar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../config/constants.dart';

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({Key? key}) : super(key: key);

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final TaskController _taskController = Get.find<TaskController>();
  final AuthController _authController = Get.find<AuthController>();
  final UserController _userController = Get.find<UserController>();

  late TaskModel task;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RxBool _isUpdatingProgress = false.obs;
  final RxDouble _currentProgress = 0.0.obs;

  @override
  void initState() {
    super.initState();
    task = Get.arguments as TaskModel;
    _currentProgress.value = task.completionPercentage;

    // Charger les informations à jour concernant la tâche
    _taskController.getTaskDetails(task.id);

    // Charger les commentaires de la tâche
    _taskController.getTaskComments(task.id);

    // Charger les utilisateurs assignés à la tâche
    if (task.assignedTo.isNotEmpty) {
      for (String userId in task.assignedTo) {
        _userController.getUserById(userId);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final comment = CommentModel(
      id: '',
      taskId: task.id,
      userId: _authController.currentUser!.id,
      message: _authController.currentUser!.fullName,
      createdAt: DateTime.now(),
    );

    await _taskController.addComment(comment.taskId, comment.message);
    _commentController.clear();

    // Faire défiler vers le bas pour voir le nouveau commentaire
    Future.delayed(Duration(milliseconds: 300), _scrollToBottom);
  }

  Future<void> _updateTaskStatus(TaskStatus newStatus) async {
    await _taskController.updateTaskStatus(task.id, newStatus);
    Get.snackbar(
      'Statut mis à jour',
      'Le statut de la tâche a été mis à jour.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _updateTaskProgress() async {
    _isUpdatingProgress.value = true;
    await _taskController.updateTaskProgress(task.id, _currentProgress.value);
    _isUpdatingProgress.value = false;
    Get.snackbar(
      'Progression mise à jour',
      'La progression de la tâche a été mise à jour à ${(_currentProgress.value * 100).toInt()}%.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la tâche'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Get.toNamed('/edit-task', arguments: task);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (_taskController.isLoading.value) {
          return const LoadingIndicator();
        }

        // Utiliser les données à jour de la tâche si disponibles
        final updatedTask = _taskController.selectedTask.value ?? task;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de la tâche
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    updatedTask.title,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TaskPriorityBadge(priority: updatedTask.priority),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              updatedTask.description,
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Échéance: ${DateFormat('dd/MM/yyyy').format(updatedTask.dueDate)}',
                                  style: TextStyle(
                                    color: updatedTask.dueDate.isBefore(DateTime.now()) &&
                                        updatedTask.status != TaskStatus.completed
                                        ? Colors.red
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Statut de la tâche
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statut',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            DropdownButtonFormField<TaskStatus>(
                              value: updatedTask.status,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: TaskStatus.values.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status.toString().split('.').last),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  _updateTaskStatus(newValue);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Progression de la tâche
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progression',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('${(_currentProgress.value * 100).toInt()}%'),
                              ],
                            ),
                            SizedBox(height: 8),
                            TaskProgressIndicator(progress: _currentProgress.value),
                            SizedBox(height: 8),
                            Slider(
                              value: _currentProgress.value,
                              min: 0.0,
                              max: 1.0,
                              divisions: 20,
                              onChanged: (value) {
                                _currentProgress.value = value;
                              },
                            ),
                            Center(
                              child: Obx(() => ElevatedButton(
                                onPressed: _isUpdatingProgress.value
                                    ? null
                                    : _updateTaskProgress,
                                child: _isUpdatingProgress.value
                                    ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : Text('Mettre à jour la progression'),
                              )),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Membres assignés
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Membres assignés',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Obx(() {
                              if (_userController.isLoading.value) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (updatedTask.assignedTo.isEmpty) {
                                return Text('Aucun membre assigné');
                              }

                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: updatedTask.assignedTo.map((userId) {
                                  final user = _userController.users.firstWhereOrNull(
                                        (u) => u.id == userId,
                                  );

                                  return user != null
                                      ? Chip(
                                    avatar: UserAvatar(
                                      user: user,
                                      size: 16,
                                    ),
                                    label: Text(user.fullName),
                                  )
                                      : SizedBox.shrink();
                                }).toList(),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Commentaires
                    Text(
                      'Discussion',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),

                    Obx(() {
                      final comments = _taskController.taskComments;

                      if (_taskController.isLoadingComments.value) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text('Aucun commentaire pour le moment'),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          final isCurrentUser = comment.userId == _authController.currentUser?.id;

                          return Align(
                            alignment: isCurrentUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Theme.of(context).primaryColor.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _authController.getUserFullName(comment.userId),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        DateFormat('dd/MM HH:mm').format(comment.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(comment.message),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Zone de saisie de commentaire
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, -1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Écrire un commentaire...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        maxLines: null,
                      ),
                    ),
                    SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: _addComment,
                      child: Icon(Icons.send),
                      mini: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        title: Text('Supprimer la tâche'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette tâche ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _taskController.deleteTask(task.id);
              Get.back();
              Get.snackbar(
                'Tâche supprimée',
                'La tâche a été supprimée avec succès.',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}