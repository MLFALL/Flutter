import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/user/user_role_badge.dart';
import '../../utils/validators.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final UserController _userController = Get.find<UserController>();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  XFile? _profileImage;
  bool _isEditingProfile = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final UserModel? user = _authController.currentUser;
    if (user != null) {
      _nameController.text = user.fullName;
      _emailController.text = user.email;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = image;
      });
    }
  }


  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      // Convertir XFile en File
      final file = _profileImage != null ? File(_profileImage!.path) : null;

      await _userController.updateUserProfile(
        _nameController.text,
        file, // Passer le fichier converti
      );
      setState(() {
        _isEditingProfile = false;
      });
    }
  }

  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      await _authController.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      if (!_authController.isLoading.value && _authController.errorMessage.isEmpty) {
        _resetPasswordFields();
        setState(() {
          _isChangingPassword = false;
        });
        Get.snackbar(
          'Succès',
          'Votre mot de passe a été modifié avec succès.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    }
  }

  void _resetPasswordFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authController.signOut(),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Obx(() {
        final user = _authController.currentUser;

        if (user == null || _authController.isLoading.value) {
          return const LoadingIndicator();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 24),
                _isEditingProfile
                    ? _buildEditProfileForm()
                    : _buildProfileInfo(user),
                const SizedBox(height: 30),
                _isChangingPassword
                    ? _buildChangePasswordForm()
                    : _buildActionButtons(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(File(_profileImage!.path))
                    : (user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? NetworkImage(user.photoUrl!) as ImageProvider
                    : const AssetImage('assets/images/placeholder_avatar.png')),
              ),
              if (_isEditingProfile)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          UserRoleBadge(role: user.role),
          if (user.isEmailVerified)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Email vérifié',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            )
          else
            TextButton.icon(
              onPressed: () => _authController.verifyEmail(),
              icon: const Icon(Icons.email, size: 16),
              label: const Text('Vérifier mon email'),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations personnelles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoItem('Nom', user.fullName),
        _buildInfoItem('Email', user.email),
        _buildInfoItem('Rôle', user.role.toString().split('.').last),
        _buildInfoItem('Membre depuis', user.createdAt.toString().split(' ')[0]),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modifier le profil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _nameController,
          labelText: 'Nom complet',
          hintText: 'Entrez votre nom',
          prefixIcon: Icons.person,
          validator: Validators.validateName,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'Entrez votre email',
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          readOnly: true, // Email cannot be changed
          validator: Validators.validateEmail,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Enregistrer',
                onPressed: _updateProfile,
                isLoading: _userController.isLoading.value,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Annuler',
                onPressed: () {
                  setState(() {
                    _isEditingProfile = false;
                    _loadUserData();
                  });
                },
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChangePasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Changer le mot de passe',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _currentPasswordController,
          labelText: 'Mot de passe actuel',
          hintText: 'Entrez votre mot de passe actuel',
          prefixIcon: Icons.lock,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre mot de passe actuel';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _newPasswordController,
          labelText: 'Nouveau mot de passe',
          hintText: 'Entrez un nouveau mot de passe',
          prefixIcon: Icons.lock_reset,
          obscureText: true,
          validator: Validators.validatePassword,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _confirmPasswordController,
          labelText: 'Confirmer le nouveau mot de passe',
          hintText: 'Confirmez votre nouveau mot de passe',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          validator: (value) => Validators.validatePasswordConfirmation(
            value,
            _newPasswordController.text,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Modifier le mot de passe',
                onPressed: _changePassword,
                isLoading: _authController.isLoading.value,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Annuler',
                onPressed: () {
                  setState(() {
                    _isChangingPassword = false;
                    _resetPasswordFields();
                  });
                },
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (_authController.errorMessage.isNotEmpty) {
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              color: Colors.red.withOpacity(0.1),
              child: Text(
                _authController.errorMessage.value,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomButton(
          text: 'Modifier le profil',
          onPressed: () {
            setState(() {
              _isEditingProfile = true;
            });
          },
          icon: Icons.edit,
          fullWidth: true,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Changer le mot de passe',
          onPressed: () {
            setState(() {
              _isChangingPassword = true;
            });
          },
          icon: Icons.lock,
          fullWidth: true,
          color: Colors.deepPurple,
        ),
      ],
    );
  }
}