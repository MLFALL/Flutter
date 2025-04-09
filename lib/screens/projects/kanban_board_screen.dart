import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/project_controller.dart';
import '../../controllers/task_controller.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../widgets/task/task_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../widgets/charts/project_status_chart.dart';


class KanbanBoardScreen extends StatelessWidget {
  const KanbanBoardScreen({Key? key}) : super(key: key);

  // Méthode pour afficher un dialogue de filtre
  void _showFilterDialog(BuildContext context, ProjectController projectController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter Projects'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Exemple de champ de filtrage
              TextField(
                decoration: InputDecoration(
                  labelText: 'Filter by Status',
                ),
              ),
              // Vous pouvez ajouter d'autres champs ici si nécessaire
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Appliquer le filtre ici
                Navigator.of(context).pop();
              },
              child: Text('Apply'),
            ),
          ],
        );
      },
    );
  }
  // Méthode pour obtenir la couleur de progression
  Color _getProgressColor(double progress) {
    if (progress < 0.5) {
      return Colors.red; // Progression < 50% -> Rouge
    } else {
      return Colors.green; // Progression >= 50% -> Vert
    }
  }
  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.pending:
        return AppConstants.statusPendingColor;
      case ProjectStatus.inProgress:
        return AppConstants.statusInProgressColor;
      case ProjectStatus.completed:
        return AppConstants.statusCompletedColor;
      case ProjectStatus.cancelled:
        return AppConstants.statusCancelledColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.pending:
        return 'En attente';
      case ProjectStatus.inProgress:
        return 'En cours';
      case ProjectStatus.completed:
        return 'Terminé';
      case ProjectStatus.cancelled:
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }
  @override
  Widget build(BuildContext context) {
    final ProjectController projectController = Get.find<ProjectController>();
    final TaskController taskController = Get.find<TaskController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau Kanban'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
              _showFilterDialog(context, projectController);
            },
          ),
        ],
      ),
      body: Obx(() {
        if (projectController.isLoading.value ||
            taskController.isLoading.value) {
          return const LoadingIndicator();
        }

        // Get filtered projects
        final filteredProjects = projectController.filteredProjects.isNotEmpty
            ? projectController.filteredProjects
            : projectController.projects;

        if (filteredProjects.isEmpty) {
          return EmptyState(
            title: 'Aucun projet à afficher', // Ajoutez ce paramètre ici
            icon: Icons.dashboard_outlined,
            description: 'Aucun projet n\'est disponible dans cette section.',
            actionText: 'Créer un projet',
            onAction: () => Get.toNamed(AppRoutes.createProject),
          );
        }


        return DefaultTabController(
          length: ProjectStatus.values.length,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabs: ProjectStatus.values.map((status) {
                  final count = filteredProjects
                      .where((p) => p.status == status)
                      .length;

                  return Tab(
                    child: Row(
                      children: [
                        Text(_getStatusLabel(status)),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                labelColor: Theme
                    .of(context)
                    .colorScheme
                    .primary,
                unselectedLabelColor: Theme
                    .of(context)
                    .colorScheme
                    .onSurface,
                indicatorColor: Theme
                    .of(context)
                    .colorScheme
                    .primary,
              ),
              Expanded(
                child: TabBarView(
                  children: ProjectStatus.values.map((status) {
                    final projectsWithStatus = filteredProjects
                        .where((p) => p.status == status)
                        .toList();

                    if (projectsWithStatus.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun projet ${_getStatusLabel(status)
                              .toLowerCase()}',
                          style: Theme
                              .of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: projectsWithStatus.length,
                      itemBuilder: (context, index) {
                        final project = projectsWithStatus[index];
                        return _buildProjectItem(
                            context, project, taskController);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProjectItem(BuildContext context,
      ProjectModel project,
      TaskController taskController,) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project header
          ListTile(
            title: Text(
              project.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Progression: ${(project.calculateProgress() * 100)
                  .toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                Get.toNamed(
                  AppRoutes.projectDetails,
                  arguments: project.id,
                );
              },
            ),
          ),
          // Progress indicator
          LinearProgressIndicator(
            value: project.calculateProgress(),
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(project.calculateProgress())),
          ),
          // Project tasks
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Obx(() {
              final projectTasks = taskController.getTasksByProjectId(
                  project.id);

              if (projectTasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Aucune tâche pour ce projet',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                );
              }

              // Show up to 3 tasks
              final tasksToShow = projectTasks.take(3).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...tasksToShow.map((task) =>
                      TaskCard(
                        task: task,
                        onTap: () =>
                            Get.toNamed(
                              AppRoutes.taskDetails,
                              arguments: task.id,
                            ),
                      )),
                  if (projectTasks.length > 3)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextButton(
                        onPressed: () {
                          Get.toNamed(
                            AppRoutes.projectDetails,
                            arguments: project.id,
                          );
                        },
                        child: Text(
                          'Voir ${projectTasks.length -
                              3} tâches supplémentaires',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
