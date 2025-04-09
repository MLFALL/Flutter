import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/project_controller.dart';
import '../controllers/task_controller.dart';
import '../config/routes.dart';
import '../models/user_model.dart';
import '../widgets/project/project_card.dart';
import '../widgets/task/task_card.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/loading_indicator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final ProjectController projectController = Get.find<ProjectController>();
    final TaskController taskController = Get.find<TaskController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          Obx(() {
            final user = authController.currentUser;
            return IconButton(
              icon: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                  ? CircleAvatar(
                backgroundImage: NetworkImage(user.photoUrl!),
                radius: 14,
              )
                  : const CircleAvatar(
                child: Icon(Icons.person, size: 16),
                radius: 14,
              ),
              onPressed: () => Get.toNamed(AppRoutes.profile),
            );
          }),
        ],
      ),
      drawer: _buildDrawer(context, authController),
      body: Obx(() {
        final user = authController.currentUser;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        switch (user.role) {
          case UserRole.admin:
            return _buildAdminDashboard(context);
          case UserRole.projectManager:
            return _buildProjectManagerDashboard(context, projectController, taskController, theme, authController);
          case UserRole.teamMember:
          default:
            return _buildTeamMemberDashboard(context, projectController, taskController, theme, authController);
        }
      }),
      floatingActionButton: Obx(() {
        final user = authController.currentUser;
        if (user?.role == UserRole.teamMember) return SizedBox();
        return FloatingActionButton(
          onPressed: () => Get.toNamed(AppRoutes.createProject),
          child: const Icon(Icons.add),
        );
      }),
    );
  }

  Widget _buildAdminDashboard(BuildContext context) {
    return Center(
      child: Text(
        'Bienvenue dans l’espace administrateur',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }

  Widget _buildProjectManagerDashboard(
      BuildContext context,
      ProjectController projectController,
      TaskController taskController,
      ThemeData theme,
      AuthController authController,
      ) {
    return RefreshIndicator(
      onRefresh: () async {
        await projectController.fetchProjects();
        await taskController.fetchTasks();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Text(
              'Bonjour, ${authController.currentUser?.fullName ?? 'Utilisateur'}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            )),
            const SizedBox(height: 24),
            _buildSectionHeader(
              context,
              'Vos projets',
              onSeeAllPressed: () => Get.toNamed(AppRoutes.projectsList),
            ),
            const SizedBox(height: 8),
            Obx(() {
              // Affiche un indicateur de chargement si les projets sont en cours de récupération
              if (projectController.isLoading.value) {
                return const LoadingIndicator();
              }

              // Si la liste des projets est vide après récupération, affiche un message
              if (projectController.projects.isEmpty) {
                return EmptyState(
                  title: 'Aucun projet à afficher',
                  icon: Icons.folder_outlined,
                  actionText: 'Créer un projet',
                  onAction: () => Get.toNamed(AppRoutes.createProject),
                );
              }

              final recentProjects = projectController.projects.take(3).toList();

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentProjects.length,
                itemBuilder: (context, index) {
                  return ProjectCard(
                    project: recentProjects[index],
                    onTap: () => Get.toNamed(
                      AppRoutes.projectDetails,
                      arguments: recentProjects[index].id,
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberDashboard(
      BuildContext context,
      ProjectController projectController,
      TaskController taskController,
      ThemeData theme,
      AuthController authController,
      ) {
    return RefreshIndicator(
      onRefresh: () async {
        await projectController.fetchProjects();
        await taskController.fetchTasks();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Text(
              'Bonjour, ${authController.currentUser?.fullName ?? 'Utilisateur'}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            )),
            const SizedBox(height: 24),
            _buildSectionHeader(
              context,
              'Vos tâches',
              onSeeAllPressed: () => Get.toNamed(AppRoutes.tasksList),
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (taskController.isLoading.value) {
                return const LoadingIndicator();
              }

              final myTasks = taskController.getTasksAssignedToCurrentUser();

              if (myTasks.isEmpty) {
                return EmptyState(
                  title: 'Aucune tâche assignée',
                  icon: Icons.task_outlined,
                  actionText: 'Voir les projets',
                  onAction: () => Get.toNamed(AppRoutes.projectsList),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myTasks.length > 5 ? 5 : myTasks.length,
                itemBuilder: (context, index) {
                  return TaskCard(
                    task: myTasks[index],
                    onTap: () => Get.toNamed(
                      AppRoutes.taskDetails,
                      arguments: myTasks[index].id,
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context,
      String title, {
        required VoidCallback onSeeAllPressed,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        TextButton(
          onPressed: onSeeAllPressed,
          child: const Text('Voir tout'),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, AuthController authController) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Obx(() {
            final user = authController.currentUser;
            return UserAccountsDrawerHeader(
              accountName: Text(user?.fullName ?? 'Utilisateur'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage:
                user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                child: user?.photoUrl == null ? const Icon(Icons.person) : null,
              ),
            );
          }),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Tableau de bord'),
            onTap: () => Get.back(),
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Projets'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.projectsList);
            },
          ),
          ListTile(
            leading: const Icon(Icons.task_outlined),
            title: const Text('Tâches'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.tasksList);
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: const Text('Fichiers'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.fileList);
            },
          ),
          const Divider(),
          Obx(() => authController.currentUser?.role == UserRole.admin
              ? ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Administration'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.adminDashboard);
            },
          )
              : const SizedBox.shrink()),
          ListTile(
            leading: const Icon(Icons.person_outlined),
            title: const Text('Mon profil'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.profile);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Déconnexion'),
            onTap: () async {
              Get.back();
              await authController.logout();
              Get.offAllNamed(AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}
