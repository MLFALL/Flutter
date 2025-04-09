// screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/charts/project_status_chart.dart';
import '../../widgets/charts/team_performance_chart.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../config/constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminController _adminController = Get.find<AdminController>();
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await _adminController.loadAdminDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de bord administrateur'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: Obx(() {
        if (_adminController.isLoading.value) {
          return const LoadingIndicator();
        }

        return RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingHeader(),
                SizedBox(height: 24),
                _buildSummaryCards(),
                SizedBox(height: 24),
                _buildProjectStatusChart(),
                SizedBox(height: 24),
                _buildUserActivityChart(),
                SizedBox(height: 24),
                _buildTeamPerformanceChart(),
                SizedBox(height: 24),
                _buildRecentActivities(),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.toNamed('AppRoutes.manageUsers');
        },
        icon: Icon(Icons.people),
        label: Text('Gérer les utilisateurs'),
      ),
    );
  }

  Widget _buildGreetingHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                _authController.currentUser?.fullName.substring(0, 1) ?? 'A',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue, ${_authController.currentUser?.fullName ?? "Admin"}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Voici un aperçu de votre système',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildSummaryCard(
          title: 'Utilisateurs',
          value: _adminController.totalUsers.toString(),
          icon: Icons.people,
          color: Colors.blue,
          breakdown: [
            {'label': 'Actifs', 'value': _adminController.activeUsers.toString(), 'color': Colors.green},
            {'label': 'Inactifs', 'value': _adminController.inactiveUsers.toString(), 'color': Colors.red},
          ],
        ),
        _buildSummaryCard(
          title: 'Projets',
          value: _adminController.totalProjects.toString(),
          icon: Icons.folder,
          color: Colors.orange,
          breakdown: [
            {'label': 'En cours', 'value': _adminController.activeProjects.toString(), 'color': Colors.blue},
            {'label': 'Terminés', 'value': _adminController.completedProjects.toString(), 'color': Colors.green},
            {'label': 'En attente', 'value': _adminController.pendingProjects.toString(), 'color': Colors.grey},
          ],
        ),
        _buildSummaryCard(
          title: 'Tâches',
          value: _adminController.totalTasks.toString(),
          icon: Icons.task_alt,
          color: Colors.purple,
          breakdown: [
            {'label': 'À faire', 'value': _adminController.todoTasks.toString(), 'color': Colors.grey},
            {'label': 'En cours', 'value': _adminController.inProgressTasks.toString(), 'color': Colors.blue},
            {'label': 'Terminées', 'value': _adminController.completedTasks.toString(), 'color': Colors.green},
          ],
        ),
        _buildSummaryCard(
          title: 'Taux d\'achèvement',
          value: '${_adminController.completionRate.toStringAsFixed(1)}%',
          icon: Icons.pie_chart,
          color: Colors.green,
          showProgressBar: true,
          progress: _adminController.completionRate / 100,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    List<Map<String, dynamic>>? breakdown,
    bool showProgressBar = false,
    double progress = 0.0,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),

            if (showProgressBar)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),

            if (breakdown != null && breakdown.isNotEmpty)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(height: 8),
                    ...breakdown.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: item['color'],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                item['label'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            item['value'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectStatusChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statut des projets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ProjectStatusChart(
                pendingCount: _adminController.pendingProjectsCount.value,  // Utilisation du compteur réactif
                inProgressCount: _adminController.inProgressProjectsCount.value,
                completedCount: _adminController.completedProjectsCount.value,
                cancelledCount: _adminController.canceledProjectsCount.value,  // Utilisation du compteur réactif
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserActivityChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activité des utilisateurs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                // Remplacer par un graphique d'activité réel
                color: Colors.grey[200],
                child: Center(
                  child: Text('Graphique d\'activité des utilisateurs'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamPerformanceChart() {
    return Card(
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
                  'Performance des équipes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  items: ['7 derniers jours', '30 derniers jours', '3 derniers mois']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  value: '7 derniers jours',
                  onChanged: (value) {},
                ),
              ],
            ),
            SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: TeamPerformanceChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activités récentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _adminController.recentActivities.length,
              itemBuilder: (context, index) {
                final activity = _adminController.recentActivities[index];

                IconData activityIcon;
                Color activityColor;

                switch (activity['type']) {
                  case 'project_created':
                    activityIcon = Icons.create_new_folder;
                    activityColor = Colors.blue;
                    break;
                  case 'user_joined':
                    activityIcon = Icons.person_add;
                    activityColor = Colors.green;
                    break;
                  case 'task_completed':
                    activityIcon = Icons.task_alt;
                    activityColor = Colors.purple;
                    break;
                  case 'project_completed':
                    activityIcon = Icons.done_all;
                    activityColor = Colors.orange;
                    break;
                  default:
                    activityIcon = Icons.info;
                    activityColor = Colors.grey;
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: activityColor.withOpacity(0.2),
                    child: Icon(
                      activityIcon,
                      color: activityColor,
                    ),
                  ),
                  title: Text(activity['message']),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(activity['timestamp'].toDate()),
                  ),
                  trailing: activity['actionable'] == true
                      ? IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      // Navigation vers l'élément concerné
                    },
                  )
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}