// screens/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/user/user_avatar.dart';
import '../../widgets/user/user_role_badge.dart';

class ManageUsersScreen  extends StatelessWidget {
  final UserController _userController = Get.find<UserController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Utilisateurs'),
      ),
      body: Obx(() {
        if (_userController.isLoading.value) {
          return LoadingIndicator();
        }

        if (_userController.users.isEmpty) {
          return EmptyState(
            title: 'Aucun utilisateur trouvé',
            description: 'Aucun utilisateur trouvé',
            icon: Icons.people_outline,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _userController.users.length,
          itemBuilder: (context, index) {
            final user = _userController.users[index];
            return _buildUserCard(context, user);
          },
        );
      }),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            UserAvatar(
              user: user, // Pass the whole user object
              size: 50,
              showStatus: true,  // Show status indicator if needed
              showBorder: true,  // Show a border around the avatar if needed
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.fullName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      UserRoleBadge(role: user.role),
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.isActive ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            color: user.isActive ? Colors.green.shade800 : Colors.red.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                CustomButton(
                  text: user.isActive ? 'Désactiver' : 'Activer',
                  onPressed: () => _userController.toggleUserStatus(user.id),
                  color: user.isActive ? Colors.red : Colors.green,
                  size: ButtonSize.small,
                ),
                SizedBox(height: 8),
                CustomButton(
                  text: 'Changer Rôle',
                  onPressed: () => _showRoleChangeDialog(context, user),
                  color: Colors.blue,
                  size: ButtonSize.small,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleChangeDialog(BuildContext context, UserModel user) {
    final selectedRole = Rx<UserRole>(user.role);

    Get.dialog(
      AlertDialog(
        title: Text('Changer le rôle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            return Obx(() {
              return RadioListTile<UserRole>(
                title: Text(roleToString(role)),
                value: role,
                groupValue: selectedRole.value,
                onChanged: (value) {
                  selectedRole.value = value!;
                },
              );
            });
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _userController.changeUserRole(user.id, selectedRole.value);
              Get.back();
            },
            child: Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  String roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.projectManager:
        return 'Chef de Projet';
      case UserRole.teamMember:
        return 'Membre d\'équipe';
      default:
        return 'Invité';
    }
  }
}