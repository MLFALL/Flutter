import 'package:get/get.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'auth_controller.dart';

class ProjectController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<ProjectModel> projects = <ProjectModel>[].obs;
  final RxList<ProjectModel> filteredProjects = <ProjectModel>[].obs;
  final Rx<ProjectModel?> selectedProject = Rx<ProjectModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<UserModel> projectMembers = <UserModel>[].obs; // Liste des membres du projet
  final RxBool isLoadingMembers = false.obs; // Indicateur de chargement pour les membres

  // Filters
  final RxString statusFilter = 'All'.obs;
  final Rx<DateTime?> dateFilter = Rx<DateTime?>(null);
  final RxString memberFilter = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProjects();
  }

  // Getter for user-specific projects
  List<ProjectModel> get userProjects {
    if (_authController.currentUser == null) {
      return [];
    }
    // Only return the projects that belong to the current user (if not an admin)
    if (_authController.currentUser!.role == 'admin') {
      return projects;
    } else {
      return projects.where((project) =>
          project.members.any((member) => member.id == _authController.currentUser!.id)
      ).toList();
    }
  }

  Future<void> fetchProjects() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Fetch different projects based on user role
      List<ProjectModel> fetchedProjects = [];

      if (await _authController.checkIfAdmin()) {
        // Admin sees all projects
        fetchedProjects = await _firebaseService.getAllProjects();
      } else {
        // Regular users see only their projects
        fetchedProjects = await _firebaseService.getUserProjects(_authController.currentUser!.id);
      }
      print('Fetched projects: $fetchedProjects');  // Vérifie si tu vois bien les projets récupérés

      projects.value = fetchedProjects;
      applyFilters(); // Apply any existing filters to the fetched projects
    } catch (e) {
      errorMessage.value = 'Failed to load projects: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }



  void applyFilters() {
    List<ProjectModel> result = List.from(projects);

    // Apply status filter
    if (statusFilter.value != 'All') {
      result = result.where((project) => project.status == statusFilter.value).toList();
    }

    // Apply date filter
    if (dateFilter.value != null) {
      final DateTime filterDate = dateFilter.value!;
      result = result.where((project) {
        final startDate = project.startDate;
        final endDate = project.endDate;
        return (startDate.isBefore(filterDate) || startDate.isAtSameMomentAs(filterDate)) &&
            (endDate.isAfter(filterDate) || endDate.isAtSameMomentAs(filterDate));
      }).toList();
    }

    // Apply member filter
    if (memberFilter.value.isNotEmpty) {
      result = result.where((project) =>
          project.members.any((member) =>
          member.fullName.toLowerCase().contains(memberFilter.value.toLowerCase()) ||
              member.email.toLowerCase().contains(memberFilter.value.toLowerCase())
          )
      ).toList();
    }

    filteredProjects.value = result;
  }

  void setStatusFilter(String status) {
    statusFilter.value = status;
    applyFilters();
  }

  void setDateFilter(DateTime? date) {
    dateFilter.value = date;
    applyFilters();
  }

  void setMemberFilter(String member) {
    memberFilter.value = member;
    applyFilters();
  }

  void clearFilters() {
    statusFilter.value = 'All';
    dateFilter.value = null;
    memberFilter.value = '';
    applyFilters();
  }

  Future<void> createProject(ProjectModel project) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Ensure creator is added as a member
      if (!project.members.any((member) => member.id == _authController.currentUser!.id)) {
        project.members.add(UserModel(
          id: _authController.currentUser!.id,
          email: _authController.currentUser!.email,
          fullName: _authController.currentUser!.fullName, // ✅ Nom correct
          role: _authController.currentUser!.role,
          photoUrl: _authController.currentUser!.photoUrl,
          isEmailVerified: _authController.currentUser!.isEmailVerified,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(), // ✅ Obligatoire dans ton modèle
        ));
      }

      // Save to Firestore
      await _firebaseService.createProject(project);

      // Refresh projects list
      await fetchProjects();
    } catch (e) {
      errorMessage.value = 'Failed to create project: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProject(ProjectModel project) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _firebaseService.updateProject(project);

      // Update selected project if it's the one being modified
      if (selectedProject.value?.id == project.id) {
        selectedProject.value = project;
      }

      // Refresh projects list
      await fetchProjects();
    } catch (e) {
      errorMessage.value = 'Failed to update project: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _firebaseService.deleteProject(projectId);

      // Clear selected project if it's the one being deleted
      if (selectedProject.value?.id == projectId) {
        selectedProject.value = null;
      }

      // Refresh projects list
      await fetchProjects();
    } catch (e) {
      errorMessage.value = 'Failed to delete project: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addMemberToProject(String projectId, String memberEmail) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _firebaseService.addMemberToProject(projectId, memberEmail);

      // Refresh projects list
      await fetchProjects();

      // Refresh selected project if it's the one being modified
      if (selectedProject.value?.id == projectId) {
        selectedProject.value = await _firebaseService.getProjectById(projectId);
      }
    } catch (e) {
      errorMessage.value = 'Failed to add member: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeMemberFromProject(String projectId, String memberId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _firebaseService.removeMemberFromProject(projectId, memberId);

      // Refresh projects list
      await fetchProjects();

      // Refresh selected project if it's the one being modified
      if (selectedProject.value?.id == projectId) {
        selectedProject.value = await _firebaseService.getProjectById(projectId);
      }
    } catch (e) {
      errorMessage.value = 'Failed to remove member: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProjectStatus(String projectId, String newStatus) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _firebaseService.updateProjectStatus(projectId, newStatus);

      // Refresh projects list
      await fetchProjects();

      // Refresh selected project if it's the one being modified
      if (selectedProject.value?.id == projectId) {
        selectedProject.value = await _firebaseService.getProjectById(projectId);
      }
    } catch (e) {
      errorMessage.value = 'Failed to update status: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void selectProject(ProjectModel project) {
    selectedProject.value = project;
  }

  void clearSelectedProject() {
    selectedProject.value = null;
  }

  // Get counts for statistics
  int getProjectCountByStatus(String status) {
    return projects.where((p) => p.status == status).length;
  }

  double getOverallCompletionRate() {
    if (projects.isEmpty) return 0.0;

    int completed = projects.where((p) => p.status == 'Terminé').length;
    return (completed / projects.length) * 100;
  }

  // Méthode pour récupérer les membres du projet
  Future<void> getProjectMembers(String projectId) async {
    try {
      isLoadingMembers.value = true;
      errorMessage.value = '';

      // Récupérer les membres du projet depuis Firebase ou ton service
      final members = await _firebaseService.getProjectMembers(projectId);

      // Mettre à jour la liste des membres
      projectMembers.value = members; // Liste de membres (UserModel)

      // Mettre à jour le projet sélectionné si nécessaire
      selectedProject.value = await _firebaseService.getProjectById(projectId);
      selectedProject.value!.members = members; // Met à jour les membres dans le projet

    } catch (e) {
      errorMessage.value = 'Échec du chargement des membres du projet : ${e.toString()}';
    } finally {
      isLoadingMembers.value = false;
    }
  }

  ProjectModel? getProjectById(String id) {
    try {
      return projects.firstWhere((project) => project.id == id);
    } catch (e) {
      return null;
    }
  }

}