import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/project_controller.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../widgets/project/project_status_badge.dart';
import '../../widgets/project/project_progress_chart.dart';
import '../../widgets/task/task_card.dart';
import '../../widgets/user/user_avatar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final String projectId;
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
  const ProjectDetailsScreen({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProjectController projectController = Get.find<ProjectController>();
    final TaskController taskController = Get.find<TaskController>();
    final AuthController authController = Get.find<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du projet'),
        actions: [
          Obx(() {
            final project = projectController.getProjectById(projectId);
            final currentUserId = authController.currentUser?.id;

            // Only show edit button if user is project owner or admin
            if (project != null &&
                (project.createdBy == currentUserId ||
                    authController.currentUser?.role == UserRole.admin)) {
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // Navigate to edit project screen
                  Get.toNamed(
                    AppRoutes.createProject,
                    arguments: project,
                  );
                },
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        final project = projectController.getProjectById(projectId);

        if (projectController.isLoading.value) {
          return const LoadingIndicator();
        }

        if (project == null) {
          return const Center(
            child: Text('Projet non trouvé'),
          );
        }

        return DefaultTabController(
          length: 3,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: _buildProjectHeader(context, project),
                ),
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        tabs: const [
                          Tab(text: 'Aperçu'),
                          Tab(text: 'Tâches'),
                          Tab(text: 'Fichiers'),
                        ],
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: theme.colorScheme.onSurface,
                        indicatorColor: theme.colorScheme.primary,
                      ),
                    ),
                    pinned: true,
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                _buildOverviewTab(context, project, taskController),
                _buildTasksTab(context, project, taskController),
                _buildFilesTab(context, project),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Create new task for this project
          Get.toNamed(
            AppRoutes.createTask,
            arguments: {'projectId': projectId},
          );
        },
        child: const Icon(Icons.add_task),
      ),
    );
  }

  Widget _buildProjectHeader(BuildContext context, ProjectModel project) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ProjectStatusBadge(
                status: _getStatusLabel(project.status), // Convertit le statut en chaîne
              )            ],
          ),
          const SizedBox(height: 8),
          Text(
            project.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Du ${_formatDate(project.startDate)} au ${_formatDate(project.endDate)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Membres (${project.members?.length ?? 0})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Open dialog to add members
                },
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: project.members != null && project.members!.isNotEmpty
                ? ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: project.members!.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: UserAvatar(
                    user: project.members![index],
                    size: 40,
                    showStatus: true,
                  ),
                );
              },
            )
                : Text(
              'Aucun membre pour le moment',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
      BuildContext context,
      ProjectModel project,
      TaskController taskController,
      ) {
    final theme = Theme.of(context);

    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progression du projet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ProjectProgressChart(
                      project: project,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Statistiques',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      final projectTasks = taskController.getTasksByProjectId(project.id);

                      // Count tasks by status
                      final int totalTasks = projectTasks.length;
                      final int completedTasks = projectTasks
                          .where((task) => task.completionPercentage >= 1.0)
                          .length;
                      final int inProgressTasks = projectTasks
                          .where((task) => task.completionPercentage > 0 && task.completionPercentage < 1.0)
                          .length;
                      final int pendingTasks = projectTasks
                          .where((task) => task.completionPercentage == 0)
                          .length;

                      return Column(
                        children: [
                          _buildStatItem(
                            context,
                            'Tâches totales',
                            totalTasks.toString(),
                            Icons.assignment_outlined,
                          ),
                          _buildStatItem(
                            context,
                            'Tâches terminées',
                            completedTasks.toString(),
                            Icons.check_circle_outline,
                            AppConstants.statusCompletedColor,
                          ),
                          _buildStatItem(
                            context,
                            'Tâches en cours',
                            inProgressTasks.toString(),
                            Icons.pending_actions_outlined,
                            AppConstants.statusInProgressColor,
                          ),
                          _buildStatItem(
                            context,
                            'Tâches en attente',
                            pendingTasks.toString(),
                            Icons.hourglass_empty_outlined,
                            AppConstants.statusPendingColor,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTasksTab(
      BuildContext context,
      ProjectModel project,
      TaskController taskController,
      ) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: Obx(() {
                final projectTasks = taskController.getTasksByProjectId(project.id);

                if (taskController.isLoading.value) {
                  return const SliverToBoxAdapter(
                    child: LoadingIndicator(),
                  );
                }

                if (projectTasks.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.task_outlined,
                      title: 'Aucune tâche pour ce projet',
                      actionText: 'Créer une tâche',
                      onAction: () {
                        Get.toNamed(
                          AppRoutes.createTask,
                          arguments: {'projectId': project.id},
                        );
                      },
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return TaskCard(
                        task: projectTasks[index],
                        onTap: () => Get.toNamed(
                          AppRoutes.taskDetails,
                          arguments: projectTasks[index].id,
                        ),
                      );
                    },
                    childCount: projectTasks.length,
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilesTab(BuildContext context, ProjectModel project) {
    // Implement files tab
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: EmptyState(
                  icon: Icons.insert_drive_file_outlined,
                  title: 'Aucun fichier pour ce projet',
                  actionText: 'Ajouter un fichier',
                  onAction: () {
                    // Navigate to add file
                    Get.toNamed(
                      AppRoutes.fileList,
                      arguments: {'projectId': project.id},
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      String label,
      String value,
      IconData icon, [
        Color? color,
      ]) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? theme.colorScheme.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color ?? theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }

}