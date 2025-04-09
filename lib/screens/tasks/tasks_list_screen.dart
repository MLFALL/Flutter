// screens/tasks/tasks_list_screen.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/task_model.dart';
import '../../widgets/task/task_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../config/constants.dart';

class TasksListScreen extends StatefulWidget {
  final String? projectId;

  const TasksListScreen({Key? key, this.projectId}) : super(key: key);

  @override
  _TasksListScreenState createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  final TaskController _taskController = Get.find<TaskController>();
  final AuthController _authController = Get.find<AuthController>();

  final TextEditingController _searchController = TextEditingController();
  TaskPriority? _selectedPriority;
  TaskStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Charger les tâches au démarrage
    if (widget.projectId != null) {
      _taskController.setCurrentProject(widget.projectId!);
    } else {
      // Pas de projet => on charge toutes les tâches (à adapter selon ton besoin)
      _taskController.fetchTasks(); // assure-toi que currentProjectId est vide    }
  }}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedPriority = null;
      _selectedStatus = null;
    });
  }

    List<TaskModel> _filterTasks(List<TaskModel> tasks) {
      return tasks.where((task) {
        final searchText = _searchController.text.toLowerCase();

        final matchesSearch = searchText.isEmpty ||
            task.title.toLowerCase().contains(searchText) ||
            task.description.toLowerCase().contains(searchText);

        final matchesPriority = _selectedPriority == null ||
            task.priority == _selectedPriority;

        final matchesStatus = _selectedStatus == null ||
            task.status == _selectedStatus;

        return matchesSearch && matchesPriority && matchesStatus;
      }).toList();
    }

    void _showFilterDialog(BuildContext context) {
      TaskPriority? tempPriority = _selectedPriority;
      TaskStatus? tempStatus = _selectedStatus;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Filtrer les tâches'),
            content: StatefulBuilder(
              builder: (context, setDialogState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Priorité', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: TaskPriority.values.map((priority) {
                          return ChoiceChip(
                            label: Text(priority.toString().split('.').last),
                            selected: tempPriority == priority,
                            onSelected: (selected) {
                              setDialogState(() {
                                tempPriority = selected ? priority : null;
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),
                      Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: TaskStatus.values.map((status) {
                          return ChoiceChip(
                            label: Text(status.toString().split('.').last),
                            selected: tempStatus == status,
                            onSelected: (selected) {
                              setDialogState(() {
                                tempStatus = selected ? status : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedPriority = tempPriority;
                    _selectedStatus = tempStatus;
                  });
                  Navigator.pop(context);
                },
                child: Text('Appliquer'),
              ),
            ],
          );
        },
      );
    }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectId != null ? 'Tâches du projet' : 'Mes tâches'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher des tâches...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Chips pour les filtres actifs
          if (_selectedPriority != null || _selectedStatus != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  if (_selectedPriority != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text('Priorité: ${_selectedPriority.toString().split('.').last}'),
                        onDeleted: () {
                          setState(() {
                            _selectedPriority = null;
                          });
                        },
                      ),
                    ),

                  if (_selectedStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text('Statut: ${_selectedStatus.toString().split('.').last}'),
                        onDeleted: () {
                          setState(() {
                            _selectedStatus = null;
                          });
                        },
                      ),
                    ),

                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text('Effacer les filtres'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: Obx(() {
              if (_taskController.isLoading.value) {
                return const LoadingIndicator();
              }

              final List<TaskModel> filteredTasks = _filterTasks(_taskController.filteredTasks);


              if (filteredTasks.isEmpty) {
                return EmptyState(
                    icon: Icons.task_alt,
                    title: 'Aucune tâche trouvée',
                    description: 'Aucune tâche ne correspond à vos critères de recherche.'
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TaskCard(
                      task: task,
                      onTap: () {
                        Get.toNamed('/task-details', arguments: task);
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: widget.projectId != null ? FloatingActionButton(
        onPressed: () {
          Get.toNamed('/projects/${widget.projectId}/tasks/create');
        },
        child: Icon(Icons.add),
      ) : null,
    );
  }


}
