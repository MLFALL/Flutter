import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

/// Service pour générer des statistiques et analyses
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère les statistiques générales pour le tableau de bord admin
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      // Compter les projets par statut
      Map<String, int> projectStatusCounts = {};
      for (var status in ProjectStatus.values) {
        String statusStr = status.toString().split('.').last;
        QuerySnapshot projectSnap = await _firestore
            .collection('projects')
            .where('status', isEqualTo: statusStr)
            .get();
        projectStatusCounts[statusStr] = projectSnap.size;
      }

      // Compter les utilisateurs par status
      Map<String, int> userStatusCounts = {};
      for (var status in UserStatus.values) {
        String statusStr = status.toString().split('.').last;
        QuerySnapshot userSnap = await _firestore
            .collection('users')
            .where('status', isEqualTo: statusStr)
            .get();
        userStatusCounts[statusStr] = userSnap.size;
      }

      // Calculer le taux de complétion moyen des projets
      QuerySnapshot projectsSnap = await _firestore.collection('projects').get();
      double avgCompletion = 0;
      if (projectsSnap.size > 0) {
        double totalCompletion = 0;
        for (var doc in projectsSnap.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          totalCompletion += data['completionPercentage'] ?? 0;
        }
        avgCompletion = totalCompletion / projectsSnap.size;
      }

      // Récupérer les projets récemment terminés
      QuerySnapshot completedProjectsSnap = await _firestore
          .collection('projects')
          .where('status', isEqualTo: ProjectStatus.completed.toString().split('.').last)
          .orderBy('updatedAt', descending: true)
          .limit(5)
          .get();

      List<Map<String, dynamic>> recentlyCompletedProjects = completedProjectsSnap.docs
          .map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'],
          'completedAt': data['updatedAt'],
        };
      })
          .toList();

      // Assembler les statistiques
      return {
        'projectStatusCounts': projectStatusCounts,
        'userStatusCounts': userStatusCounts,
        'averageProjectCompletion': avgCompletion,
        'recentlyCompletedProjects': recentlyCompletedProjects,
        'totalProjects': projectsSnap.size,
        'totalUsers': await _firestore.collection('users').count().get().then((value) => value.count),
        'totalTasks': await _firestore.collection('tasks').count().get().then((value) => value.count),
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
      return {};
    }
  }

  /// Calcule les performances d'une équipe (pour un projet spécifique)
  Future<Map<String, dynamic>> getTeamPerformance(String projectId) async {
    try {
      // Récupérer toutes les tâches du projet
      QuerySnapshot tasksSnap = await _firestore
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .get();

      Map<String, dynamic> memberPerformance = {};
      int totalTasks = tasksSnap.size;
      int completedTasks = 0;
      int overdueTasks = 0;

      for (var doc in tasksSnap.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        bool isCompleted = data['status'] == TaskStatus.completed.toString().split('.').last;
        if (isCompleted) {
          completedTasks++;
        }

        // Vérifier si la tâche est en retard
        DateTime dueDate = (data['dueDate'] as Timestamp).toDate();
        if (dueDate.isBefore(DateTime.now()) && !isCompleted) {
          overdueTasks++;
        }

        // Calculer les statistiques par membre
        List<String> assignedTo = List<String>.from(data['assignedTo'] ?? []);
        for (String userId in assignedTo) {
          if (!memberPerformance.containsKey(userId)) {
            memberPerformance[userId] = {
              'totalAssigned': 0,
              'completed': 0,
              'overdue': 0,
            };
          }

          memberPerformance[userId]['totalAssigned']++;
          if (isCompleted) {
            memberPerformance[userId]['completed']++;
          }
          if (dueDate.isBefore(DateTime.now()) && !isCompleted) {
            memberPerformance[userId]['overdue']++;
          }
        }
      }

      // Calculer les pourcentages pour chaque membre
      for (String userId in memberPerformance.keys) {
        int totalAssigned = memberPerformance[userId]['totalAssigned'];
        int completed = memberPerformance[userId]['completed'];

        memberPerformance[userId]['completionRate'] =
        totalAssigned > 0 ? (completed / totalAssigned * 100) : 0;

        // Récupérer les informations sur l'utilisateur
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          memberPerformance[userId]['name'] = userData['fullName'];
        }
      }

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'overdueTasks': overdueTasks,
        'completionRate': totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0,
        'memberPerformance': memberPerformance,
      };
    } catch (e) {
      print('Erreur lors de la récupération des performances: $e');
      return {};
    }
  }

  /// Récupère les statistiques de progression d'un projet
  Future<Map<String, dynamic>> getProjectProgressStats(String projectId) async {
    try {
      // Récupérer le projet
      DocumentSnapshot projectDoc = await _firestore.collection('projects').doc(projectId).get();
      if (!projectDoc.exists) {
        throw Exception("Le projet n'existe pas");
      }

      ProjectModel project = ProjectModel.fromFirestore(projectDoc);

      // Récupérer toutes les tâches du projet
      QuerySnapshot tasksSnap = await _firestore
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .get();

      int totalTasks = tasksSnap.size;

      // Compter les tâches par statut
      Map<String, int> taskStatusCounts = {};
      for (var status in TaskStatus.values) {
        taskStatusCounts[status.toString().split('.').last] = 0;
      }

      for (var doc in tasksSnap.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String status = data['status'] ?? TaskStatus.todo.toString().split('.').last;
        taskStatusCounts[status] = (taskStatusCounts[status] ?? 0) + 1;
      }

      // Calculer les statistiques d'avancement
      double timeProgress = project.timeProgressPercentage;
      double taskProgress = 0;
      if (totalTasks > 0) {
        int completedTasks = taskStatusCounts[TaskStatus.completed.toString().split('.').last] ?? 0;
        taskProgress = (completedTasks / totalTasks) * 100;
      }

      return {
        'projectId': projectId,
        'projectTitle': project.title,
        'startDate': project.startDate,
        'endDate': project.endDate,
        'daysRemaining': project.daysRemaining,
        'isOverdue': project.isOverdue,
        'status': project.status.toString().split('.').last,
        'priority': project.priority.toString().split('.').last,
        'timeProgress': timeProgress,
        'taskProgress': taskProgress,
        'completionPercentage': project.completionPercentage,
        'taskStatusCounts': taskStatusCounts,
        'totalTasks': totalTasks,
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques du projet: $e');
      return {};
    }
  }

  /// Récupère les données pour un graphique d'activité
  Future<List<Map<String, dynamic>>> getActivityChartData(String projectId) async {
    try {
      // Récupérer les tâches complétées au cours des 30 derniers jours
      DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      QuerySnapshot tasksSnap = await _firestore
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .where('status', isEqualTo: TaskStatus.completed.toString().split('.').last)
          .where('updatedAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('updatedAt')
          .get();

      // Organiser les données par jour
      Map<String, int> dailyCompletions = {};

      for (var doc in tasksSnap.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime completedAt = (data['updatedAt'] as Timestamp).toDate();
        String dateKey = '${completedAt.year}-${completedAt.month.toString().padLeft(2, '0')}-${completedAt.day.toString().padLeft(2, '0')}';

        dailyCompletions[dateKey] = (dailyCompletions[dateKey] ?? 0) + 1;
      }

      // Convertir en liste pour le graphique
      List<Map<String, dynamic>> chartData = [];

      for (int i = 0; i < 30; i++) {
        DateTime date = DateTime.now().subtract(Duration(days: 29 - i));
        String dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        chartData.add({
          'date': dateKey,
          'completedTasks': dailyCompletions[dateKey] ?? 0,
        });
      }

      return chartData;
    } catch (e) {
      print('Erreur lors de la récupération des données du graphique: $e');
      return [];
    }
  }
  // Définir la méthode recordDashboardVisit
  Future<void> recordDashboardVisit(String userId) async {
    try {
      await _firestore.collection('dashboardVisits').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error recording dashboard visit: $e');
    }
  }
}