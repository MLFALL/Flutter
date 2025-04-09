import 'package:get/get.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import 'auth_controller.dart';

class AdminController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxList<ProjectModel> allProjects = <ProjectModel>[].obs;
  final RxList<TaskModel> tasks = <TaskModel>[].obs; // Ajout de la liste des tâches
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Dashboard statistics
  final RxInt activeUsersCount = 0.obs;
  final RxInt inactiveUsersCount = 0.obs;
  final RxInt pendingProjectsCount = 0.obs;
  final RxInt inProgressProjectsCount = 0.obs;
  final RxInt completedProjectsCount = 0.obs;
  final RxInt canceledProjectsCount = 0.obs;
  final RxDouble averageProjectCompletionRate = 0.0.obs;
  final RxList<Map<String, dynamic>> recentActivities = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    checkAdminAccess();
  }

  Future<void> checkAdminAccess() async {
    if (!await _authController.checkIfAdmin()) {
      errorMessage.value = 'Access denied: Admin privileges required';
      Get.back(); // Navigate back if not admin
    } else {
      loadAdminDashboard();
    }
  }

  Future<void> loadAdminDashboard() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Load all necessary data for admin dashboard
      await Future.wait([
        fetchAllUsers(),
        fetchAllProjects(),
        calculateStatistics(),
        fetchRecentActivities(),
      ]);
    } catch (e) {
      errorMessage.value = 'Failed to load dashboard: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> fetchRecentActivities() async {
    try {
      // Simuler des activités récentes
      recentActivities.addAll([
        {'type': 'project_created', 'description': 'Nouveau projet créé'},
        {'type': 'user_joined', 'description': 'Un utilisateur a rejoint'},
        {'type': 'task_completed', 'description': 'Tâche terminée'},
        {'type': 'project_completed', 'description': 'Projet terminé'},
      ]);
    } catch (e) {
      errorMessage.value = 'Failed to load recent activities: ${e.toString()}';
    }
  }

  Future<void> fetchAllUsers() async {
    try {
      List<UserModel> fetchedUsers = await _firebaseService.getAllUsers();
      users.value = fetchedUsers;

      // Calculate user status counts
      activeUsersCount.value = users.where((u) => u.isActive).length;
      inactiveUsersCount.value = users.where((u) => !u.isActive).length;
    } catch (e) {
      errorMessage.value = 'Failed to load users: ${e.toString()}';
    }
  }

  Future<void> fetchAllProjects() async {
    try {
      List<ProjectModel> fetchedProjects = await _firebaseService.getAllProjects();
      allProjects.value = fetchedProjects;

      // Calculate project status counts
      pendingProjectsCount.value = allProjects.where((p) => p.status == 'En attente').length;
      inProgressProjectsCount.value = allProjects.where((p) => p.status == 'En cours').length;
      completedProjectsCount.value = allProjects.where((p) => p.status == 'Terminé').length;
      canceledProjectsCount.value = allProjects.where((p) => p.status == 'Annulé').length;
    } catch (e) {
      errorMessage.value = 'Failed to load projects: ${e.toString()}';
    }
  }

  Future<void> calculateStatistics() async {
    try {
      // Average project completion
      if (allProjects.isNotEmpty) {
        double totalCompletion = allProjects.fold(0.0, (sum, project) {
          // Convert project status to completion percentage
          switch (project.status) {
            case 'En attente': return sum + 0.0;
            case 'En cours': return sum + 50.0;
            case 'Terminé': return sum + 100.0;
            case 'Annulé': return sum + 0.0;
            default: return sum;
          }
        });

        averageProjectCompletionRate.value = totalCompletion / allProjects.length;
      }

      // Additional analytics through analytics service
      await _analyticsService.recordDashboardVisit(_authController.currentUser!.id);
    } catch (e) {
      errorMessage.value = 'Failed to calculate statistics: ${e.toString()}';
    }
  }

  Future<void> toggleUserActiveStatus(String userId, bool isActive) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _firebaseService.updateUserActiveStatus(userId, isActive);

      // Refresh users list
      await fetchAllUsers();
    } catch (e) {
      errorMessage.value = 'Failed to update user status: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _firebaseService.updateUserRole(userId, role);

      // Refresh users list
      await fetchAllUsers();
    } catch (e) {
      errorMessage.value = 'Failed to update user role: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Get team performance data
  Map<String, double> getTeamPerformanceData() {
    Map<String, double> teamPerformance = {};

    // Group completed projects by team and calculate completion rate
    for (ProjectModel project in allProjects) {
      if (project.status == 'Terminé') {
        for (UserModel member in project.teamMembers) {
          if (teamPerformance.containsKey(member.fullName)) {
            teamPerformance[member.fullName] = teamPerformance[member.fullName]! + 1;
          } else {
            teamPerformance[member.fullName] = 1;
          }
        }
      }
    }

    // Convert counts to percentages
    int totalCompleted = completedProjectsCount.value;
    if (totalCompleted > 0) {
      teamPerformance.forEach((key, value) {
        teamPerformance[key] = (value / totalCompleted) * 100;
      });
    }

    return teamPerformance;
  }

  // Get project status distribution for charts
  List<Map<String, dynamic>> getProjectStatusDistribution() {
    return [
      {'status': 'En attente', 'count': pendingProjectsCount.value},
      {'status': 'En cours', 'count': inProgressProjectsCount.value},
      {'status': 'Terminé', 'count': completedProjectsCount.value},
      {'status': 'Annulé', 'count': canceledProjectsCount.value},
    ];
  }

  // Get user status distribution for charts
  List<Map<String, dynamic>> getUserStatusDistribution() {
    return [
      {'status': 'Actif', 'count': activeUsersCount.value},
      {'status': 'Inactif', 'count': inactiveUsersCount.value},
    ];
  }

  // Get projects created over time for trend analysis
  List<Map<String, dynamic>> getProjectsCreationTimeline() {
    Map<String, int> monthlyProjects = {};

    for (ProjectModel project in allProjects) {
      String monthYear = '${project.createdAt.month}-${project.createdAt.year}';
      if (monthlyProjects.containsKey(monthYear)) {
        monthlyProjects[monthYear] = monthlyProjects[monthYear]! + 1;
      } else {
        monthlyProjects[monthYear] = 1;
      }
    }

    List<Map<String, dynamic>> result = [];
    monthlyProjects.forEach((key, value) {
      result.add({
        'month': key,
        'count': value,
      });
    });

    // Sort by date
    result.sort((a, b) {
      List<String> aParts = a['month'].split('-');
      List<String> bParts = b['month'].split('-');
      int aYear = int.parse(aParts[1]);
      int bYear = int.parse(bParts[1]);
      if (aYear != bYear) return aYear.compareTo(bYear);
      return int.parse(aParts[0]).compareTo(int.parse(bParts[0]));
    });

    return result;
  }

  // Export dashboard data (for reports, etc.)
  Map<String, dynamic> exportDashboardData() {
    return {
      'timestamp': DateTime.now().toString(),
      'users': {
        'total': users.length,
        'active': activeUsersCount.value,
        'inactive': inactiveUsersCount.value,
      },
      'projects': {
        'total': allProjects.length,
        'pending': pendingProjectsCount.value,
        'inProgress': inProgressProjectsCount.value,
        'completed': completedProjectsCount.value,
        'canceled': canceledProjectsCount.value,
        'averageCompletion': averageProjectCompletionRate.value,
      },
      'teamPerformance': getTeamPerformanceData(),
      'timeline': getProjectsCreationTimeline(),
    };
  }

  // Getter pour les projets en cours
  List<ProjectModel> get activeProjects {
    return allProjects.where((p) => p.status == 'En cours').toList();
  }

// Getter pour les projets terminés
  List<ProjectModel> get completedProjects {
    return allProjects.where((p) => p.status == 'Terminé').toList();
  }

// Getter pour les projets en attente
  List<ProjectModel> get pendingProjects {
    return allProjects.where((p) => p.status == 'En attente').toList();
  }

  // Getter pour les utilisateurs actifs
  List<UserModel> get activeUsers {
    return users.where((u) => u.isActive).toList();
  }

// Getter pour les utilisateurs inactifs
  List<UserModel> get inactiveUsers {
    return users.where((u) => !u.isActive).toList();
  }

  // Getter pour les tâches "Todo"
  List<TaskModel> get todoTasks {
    return tasks.where((task) => task.status == 'Todo').toList();
  }

// Getter pour les tâches "En cours"
  List<TaskModel> get inProgressTasks {
    return tasks.where((task) => task.status == 'En cours').toList();
  }

// Getter pour les tâches "Terminées"
  List<TaskModel> get completedTasks {
    return tasks.where((task) => task.status == 'Terminé').toList();
  }
  // Getter pour le nombre total de tâches
  int get totalTasks {
    return tasks.length;
  }
  // Getter pour le nombre total de projets
  int get totalProjects {
    return allProjects.length;
  }
// Getter pour le nombre total d'utilisateurs
  int get totalUsers {
    return users.length;
  }


// Getter pour le taux de complétion global des projets
  double get completionRate {
    if (allProjects.isEmpty) {
      return 0.0; // Retourne 0 si aucune tâche n'existe
    }

    double totalCompletion = allProjects.fold(0.0, (sum, project) {
      // Calcule la somme des pourcentages en fonction du statut du projet
      switch (project.status) {
        case 'En attente': // Projet non commencé
          return sum + 0.0;
        case 'En cours':  // Projet en cours
          return sum + 50.0; // Moitié complété
        case 'Terminé':   // Projet terminé
          return sum + 100.0;
        case 'Annulé':    // Projet annulé
          return sum + 0.0;
        default:
          return sum; // En cas de statut inconnu
      }
    });

    // Calcule la moyenne du taux de complétion
    return totalCompletion / allProjects.length;
  }


}