import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../config/constants.dart';

class UserRoleBadge extends StatelessWidget {
  final UserRole role;
  final bool isSmall;

  const UserRoleBadge({
    Key? key,
    required this.role,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRoleColor(role),
          width: 1,
        ),
      ),
      child: Text(
        _getRoleLabel(role),
        style: TextStyle(
          color: _getRoleColor(role),
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppConstants.adminRoleColor;
      case UserRole.projectManager:
        return AppConstants.managerRoleColor;
      case UserRole.teamMember:
        return AppConstants.memberRoleColor;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.projectManager:
        return 'Chef de Projet';
      case UserRole.teamMember:
        return 'Membre';
      default:
        return 'Inconnu';
    }
  }
}