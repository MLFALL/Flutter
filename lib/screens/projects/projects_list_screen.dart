import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/project_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_message.dart';
import '../../widgets/project/project_card.dart';
import '../../config/constants.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({Key? key}) : super(key: key);

  @override
  _ProjectsListScreenState createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  final ProjectController _projectController = Get.find<ProjectController>();
  final AuthController _authController = Get.find<AuthController>();

  final TextEditingController _searchController = TextEditingController();
  ProjectStatus? _selectedStatus;
  String _searchQuery = '';
  bool _isMyProjects = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    await _projectController.fetchProjects();
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<ProjectModel> _getFilteredProjects() {
    return _projectController.projects.where((project) {
      // Filter by search query
      final matchesQuery = _searchQuery.isEmpty ||
          project.title.toLowerCase().contains(_searchQuery) ||
          project.description.toLowerCase().contains(_searchQuery);

      // Filter by status
      final matchesStatus = _selectedStatus == null || project.status == _selectedStatus;

      // Filter by "My Projects"
      final matchesMyProjects = !_isMyProjects ||
          project.members.contains(_authController.currentUser?.id) ||
          project.createdBy == _authController.currentUser?.id;

      return matchesQuery && matchesStatus && matchesMyProjects;
    }).toList();
  }

  Future<void> _showFilterDialog() async {
    final currentStatus = _selectedStatus;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtrer les projets'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statut',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildStatusFilterChip(
                        null,
                        'Tous',
                        null,
                        setState,
                      ),
                      _buildStatusFilterChip(
                        ProjectStatus.pending,
                        'En attente',
                        AppConstants.statusColors[ProjectStatus.pending],
                        setState,
                      ),
                      _buildStatusFilterChip(
                        ProjectStatus.inProgress,
                        'En cours',
                        AppConstants.statusColors[ProjectStatus.inProgress],
                        setState,
                      ),
                      _buildStatusFilterChip(
                        ProjectStatus.completed,
                        'Terminé',
                        AppConstants.statusColors[ProjectStatus.completed],
                        setState,
                      ),
                      _buildStatusFilterChip(
                        ProjectStatus.cancelled,
                        'Annulé',
                        AppConstants.statusColors[ProjectStatus.cancelled],
                        setState,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Reset to original status
                    _selectedStatus = currentStatus;
                    Navigator.pop(context);
                  },
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Appliquer'),
                ),
              ],
            );
          },
        );
      },
    );

    // Update UI
    setState(() {});
  }

  Widget _buildStatusFilterChip(
      ProjectStatus? status,
      String label,
      Color? color,
      StateSetter setState,
      ) {
    return FilterChip(
      label: Text(label),
      selected: _selectedStatus == status,
      selectedColor: color != null ? color.withOpacity(0.2) : null,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildToggleBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProjects,
              child: Obx(() {
                if (_projectController.isLoading.value) {
                  return const LoadingIndicator();
                }

                if (_projectController.errorMessage.isNotEmpty) {
                  return ErrorMessage(
                    message: _projectController.errorMessage.value,
                    actionText: 'Réessayer', // Texte du bouton
                    onAction: _loadProjects, // Remplacez onRetry par onAction
                  );
                }

                final filteredProjects = _getFilteredProjects();

                if (filteredProjects.isEmpty) {
                  return EmptyState(
                    icon: Icons.folder_open,
                    title: 'Aucun projet trouvé',
                    description: 'Aucun projet ne correspond à vos critères de recherche',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProjects.length,
                  itemBuilder: (context, index) {
                    final project = filteredProjects[index];
                    return ProjectCard(
                      project: project,
                      onTap: () => Get.toNamed('/project-details', arguments: project),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.toNamed('/projects/create/new');  // Utiliser la route correcte
          if (result == true) {
            _loadProjects();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher des projets...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _handleSearch('');
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: _handleSearch,
      ),
    );
  }

  Widget _buildToggleBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              title: 'Tous les projets',
              isSelected: !_isMyProjects,
              onTap: () {
                setState(() {
                  _isMyProjects = false;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildToggleButton(
              title: 'Mes projets',
              isSelected: _isMyProjects,
              onTap: () {
                setState(() {
                  _isMyProjects = true;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}