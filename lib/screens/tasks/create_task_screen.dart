// screens/tasks/create_task_screen.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/project_controller.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/user/user_avatar.dart';
import '../../config/constants.dart';
import '../../utils/validators.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({Key? key}) : super(key: key);

  @override
  _CreateTaskScreenState createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TaskController _taskController = Get.find<TaskController>();
  final AuthController _authController = Get.find<AuthController>();
  final UserController _userController = Get.find<UserController>();
  final ProjectController _projectController = Get.find<ProjectController>();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final RxString _projectId = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxList<String> _selectedAssignees = <String>[].obs;
  final Rx<DateTime> _dueDate = DateTime.now().add(Duration(days: 7)).obs;
  final Rx<TaskPriority> _priority = TaskPriority.medium.obs;

  @override
  void initState() {
    super.initState();

    // Si un ID de projet est passé en argument, le définir
    if (Get.arguments != null && Get.arguments is String) {
      _projectId.value = Get.arguments;

      // Charger les membres du projet
      _projectController.getProjectMembers(_projectId.value);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null && picked != _dueDate.value) {
      _dueDate.value = picked;
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_projectId.value.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner un projet',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Valider qu'au moins un assigné est sélectionné
    if (_selectedAssignees.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez assigner la tâche à au moins un membre',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    _isLoading.value = true;

    // Créez directement un objet TaskModel avec les valeurs appropriées
    final taskModel = TaskModel(
      id: '', // Générer ou assigner un ID si nécessaire
      projectId: _projectId.value,
      title: _titleController.text,
      description: _descriptionController.text,
      createdBy: _authController.currentUser?.id ?? '',
      assignedTo: _selectedAssignees,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(), // L'heure actuelle comme date de mise à jour
      dueDate: _dueDate.value,
      priority: _priority.value,
      status: TaskStatus.todo, // Par défaut, la tâche est "todo"
      completionPercentage: 0.0, // Par défaut, la tâche n'est pas terminée
      comments: [], // Liste vide de commentaires (ou vous pouvez la remplir si nécessaire)
    );


    try {
      await _taskController.createTask(taskModel);
      _isLoading.value = false;

      Get.back();
      Get.snackbar(
        'Succès',
        'La tâche a été créée avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue lors de la création de la tâche: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer une tâche'),
      ),
      body: Obx(() => _isLoading.value
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélection du projet (si pas défini)
              if (_projectId.value.isEmpty)
                _buildProjectSelection(),

              // Titre de la tâche
              CustomTextField(
                controller: _titleController,
                labelText: 'Titre de la tâche',
                hintText: 'Entrez un titre concis et clair',
                validator: (value) => Validators.validateRequired(value, 'Le titre'),
              ),
              SizedBox(height: 16),

              // Description de la tâche
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description',
                hintText: 'Décrivez la tâche en détail',
                maxLines: 5,
                validator: (value) => Validators.validateRequired(value, 'La description'),
              ),
              SizedBox(height: 16),

              // Priorité
              Text(
                'Priorité',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildPrioritySelection(),
              SizedBox(height: 16),

              // Date d'échéance
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date d\'échéance',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDueDate(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today),
                                SizedBox(width: 8),
                                Obx(() => Text(
                                  DateFormat('dd/MM/yyyy').format(_dueDate.value),
                                )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Assignation aux membres
              Text(
                'Assigner à',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildMemberSelection(),
              SizedBox(height: 24),

              // Bouton de création
              Center(
                child: CustomButton(
                  text: 'Créer la tâche',
                  onPressed: _createTask,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildProjectSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Projet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Obx(() {
          final projects = _projectController.userProjects;

          if (projects.isEmpty) {
            return Text('Aucun projet disponible. Créez un projet d\'abord.');
          }

          return DropdownButtonFormField<String>(
            value: _projectId.value.isNotEmpty ? _projectId.value : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Sélectionnez un projet',
            ),
            items: projects.map((project) {
              return DropdownMenuItem<String>(
                value: project.id,
                child: Text(project.title),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _projectId.value = value;
                _selectedAssignees.clear();
                _projectController.getProjectMembers(value);
              }
            },
          );
        }),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPrioritySelection() {
    return Container(
      width: double.infinity,
      child: SegmentedButton<TaskPriority>(
        segments: TaskPriority.values.map((priority) {
          String label;
          IconData icon;

          switch (priority) {
            case TaskPriority.low:
              label = 'Basse';
              icon = Icons.arrow_downward;
              break;
            case TaskPriority.medium:
              label = 'Moyenne';
              icon = Icons.remove;
              break;
            case TaskPriority.high:
              label = 'Haute';
              icon = Icons.arrow_upward;
              break;
            case TaskPriority.urgent:
              label = 'Urgente';
              icon = Icons.priority_high;
              break;
          }

          return ButtonSegment<TaskPriority>(
            value: priority,
            label: Text(label),
            icon: Icon(icon),
          );
        }).toList(),
        selected: {_priority.value},
        onSelectionChanged: (value) {
          if (value.isNotEmpty) {
            _priority.value = value.first;
          }
        },
      ),
    );
  }

  Widget _buildMemberSelection() {
    return Obx(() {
      final members = _projectController.projectMembers;

      if (_projectController.selectedProject.value == null) {
        return Text('Sélectionnez un projet pour voir les membres');
      }

      if (_projectController.isLoadingMembers.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (members.isEmpty) {
        return Text('Aucun membre dans ce projet');
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Membres sélectionnés (chips)
          if (_selectedAssignees.isNotEmpty)
            ...members.map((member) => Chip(label: Text(member.fullName))).toList(),

          SizedBox(height: 8),

          // Liste des membres disponibles
          Text(
            _selectedAssignees.isEmpty
                ? 'Sélectionnez au moins un membre'
                : 'Ajouter d\'autres membres',
            style: TextStyle(
              color: _selectedAssignees.isEmpty ? Colors.red : Colors.grey,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),

          // Liste des membres à sélectionner
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final user = members[index];
              final isSelected = _selectedAssignees.contains(user.id);

              return ListTile(
                leading: UserAvatar(user: user),
                title: Text(user.fullName),
                subtitle: Text(user.email),
                trailing: Checkbox(
                  value: isSelected,
                  onChanged: (selected) {
                    if (selected!) {
                      _selectedAssignees.add(user.id);
                    } else {
                      _selectedAssignees.remove(user.id);
                    }
                  },
                ),
                onTap: () {
                  if (isSelected) {
                    _selectedAssignees.remove(user.id);
                  } else {
                    _selectedAssignees.add(user.id);
                  }
                },
              );
            },
          ),
        ],
      );
    });
  }
}