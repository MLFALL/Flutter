import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/project_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_indicator.dart';

import '../../utils/validators.dart';

class CreateProjectScreen extends StatefulWidget {
  final ProjectModel? projectToEdit;

  const CreateProjectScreen({Key? key, this.projectToEdit}) : super(key: key);

  @override
  _CreateProjectScreenState createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final ProjectController _projectController = Get.find<ProjectController>();
  final UserController _userController = Get.find<UserController>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  ProjectPriority _selectedPriority = ProjectPriority.medium;
  final List<UserModel> _selectedMembers = [];

  bool get isEditing => widget.projectToEdit != null;

  @override
  void initState() {
    super.initState();

    // Utiliser un post frame pour attendre que GetX soit prêt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userController = Get.find<UserController>();
      final currentUser = userController.authController.currentUser;

      if (_shouldRedirect(currentUser?.role)) {
        Get.offAllNamed('/home');
      } else {
        _loadUsers();

        if (isEditing) {
          _loadProjectData();
        } else {
          _startDate = DateTime.now();
          _endDate = DateTime.now().add(const Duration(days: 30));
          _updateDateControllers();
        }
      }
    });
  }


// Détermine si l'utilisateur doit être redirigé en fonction de son rôle
  bool _shouldRedirect(UserRole? role) {
    return role != UserRole.admin; // Compare directement l'énumération UserRole
  }




  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _loadProjectData() {
    final project = widget.projectToEdit!;

    _titleController.text = project.title;
    _descriptionController.text = project.description;
    _startDate = project.startDate;
    _endDate = project.endDate;
    _selectedPriority = project.priority;

    _updateDateControllers();

    // Load project members
    for (var memberId in project.members) {
      // Utilisez Obx pour écouter la valeur de getUserById
      _userController.getUserById(memberId.id).listen((user) {
        if (user != null && !_selectedMembers.contains(user)) {
          setState(() {
            _selectedMembers.add(user);
          });
        }
      });
    }
  }

  void _updateDateControllers() {
    if (_startDate != null) {
      _startDateController.text = DateFormat('dd/MM/yyyy').format(_startDate!);
    }

    if (_endDate != null) {
      _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate!);
    }
  }

  Future<void> _loadUsers() async {
    await _userController.getAllUsers();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now().add(const Duration(days: 1)));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isStartDate ? DateTime.now().subtract(const Duration(days: 365)) : _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          _startDateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);

          // Update end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(pickedDate)) {
            _endDate = pickedDate.add(const Duration(days: 7));
            _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate!);
          }
        } else {
          _endDate = pickedDate;
          _endDateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
        }
      });
    }
  }

  void _saveProject() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMembers.isEmpty) {
        Get.snackbar(
          'Erreur',
          'Veuillez sélectionner au moins un membre pour le projet',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final project = ProjectModel(
        id: isEditing ? widget.projectToEdit!.id : '',
        title: _titleController.text,
        description: _descriptionController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        priority: _selectedPriority,
        status: isEditing ? widget.projectToEdit!.status : ProjectStatus.pending,
        createdBy: isEditing ? widget.projectToEdit!.createdBy : _userController.currentUserId!,
        createdAt: isEditing ? widget.projectToEdit!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        members: _selectedMembers,
        completionPercentage: isEditing ? widget.projectToEdit!.completionPercentage : 0,
      );

      if (isEditing) {
        await _projectController.updateProject(project);
      } else {
        await _projectController.createProject(project);
      }

      if (!_projectController.isLoading.value && _projectController.errorMessage.isEmpty) {
        Get.back(result: true);
        Get.snackbar(
          'Succès',
          isEditing ? 'Projet mis à jour avec succès' : 'Projet créé avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le projet' : 'Créer un projet'),
      ),
      body: Obx(() {
        if (_projectController.isLoading.value || _userController.isLoading.value) {
          return const LoadingIndicator();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _titleController,
                  labelText: 'Titre du projet',
                  hintText: 'Entrez le titre du projet',
                  prefixIcon: Icons.title,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le titre du projet est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  hintText: 'Entrez la description du projet',
                  prefixIcon: Icons.description,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La description du projet est requise';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, true),
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: _startDateController,
                            labelText: 'Date de début',
                            hintText: 'Sélectionner',
                            prefixIcon: Icons.calendar_today,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requis';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, false),
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: _endDateController,
                            labelText: 'Date de fin',
                            hintText: 'Sélectionner',
                            prefixIcon: Icons.calendar_today,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requis';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPrioritySelector(),
                const SizedBox(height: 24),
                _buildMembersSelector(),
                const SizedBox(height: 32),
                CustomButton(
                  text: isEditing ? 'Mettre à jour le projet' : 'Créer le projet',
                  onPressed: _saveProject,
                  isLoading: _projectController.isLoading.value,
                  fullWidth: true,
                ),
                const SizedBox(height: 16),
                if (_projectController.errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.withOpacity(0.1),
                    child: Text(
                      _projectController.errorMessage.value,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priorité',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildPriorityOption(ProjectPriority.low, 'Basse', Colors.green),
              const Divider(height: 1),
              _buildPriorityOption(ProjectPriority.medium, 'Moyenne', Colors.orange),
              const Divider(height: 1),
              _buildPriorityOption(ProjectPriority.high, 'Haute', Colors.red),
              const Divider(height: 1),
              _buildPriorityOption(ProjectPriority.urgent, 'Urgente', Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityOption(ProjectPriority priority, String label, Color color) {
    return RadioListTile<ProjectPriority>(
      title: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      value: priority,
      groupValue: _selectedPriority,
      onChanged: (ProjectPriority? value) {
        if (value != null) {
          setState(() {
            _selectedPriority = value;
          });
        }
      },
      dense: true,
    );
  }

  Widget _buildMembersSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Membres du projet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: _showMemberSelectionDialog,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedMembers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Aucun membre ajouté',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedMembers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _selectedMembers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (user.photoUrl?.isNotEmpty ?? false)
                        ? NetworkImage(user.photoUrl!) as ImageProvider
                        : const AssetImage('assets/images/placeholder_avatar.png'),
                  ),
                  title: Text(user.fullName),
                  subtitle: Text(user.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedMembers.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showMemberSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter des membres'),
          content: SizedBox(
            width: double.maxFinite,
            child: Obx(() {
              final allUsers = _userController.users;

              // Filter out already selected members
              final availableUsers = allUsers.where(
                      (user) => !_selectedMembers.any((selectedUser) => selectedUser.id == user.id)
              ).toList();

              if (availableUsers.isEmpty) {
                return const Center(
                  child: Text('Tous les utilisateurs ont déjà été ajoutés au projet'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: availableUsers.length,
                itemBuilder: (context, index) {
                  final user = availableUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (user.photoUrl?.isNotEmpty ?? false)
                          ? NetworkImage(user.photoUrl!) as ImageProvider
                          : const AssetImage('assets/images/placeholder_avatar.png'),
                    ),
                    title: Text(user.fullName),
                    subtitle: Text(user.email),
                    onTap: () {
                      setState(() {
                        _selectedMembers.add(user);
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}