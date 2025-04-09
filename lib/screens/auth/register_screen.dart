import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../config/constants.dart';
import '../../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  XFile? _profileImage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
// Fonction pour télécharger l'image de profil dans Firebase Storage
  Future<String?> _uploadProfileImage(String profileImagePath) async {
    try {
      // Créer une référence dans Firebase Storage
      FirebaseStorage storage = FirebaseStorage.instance;
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';  // Nom unique
      Reference reference = storage.ref().child('profile_images').child(fileName);

      // Télécharge l'image
      await reference.putFile(File(profileImagePath));

      // Récupère l'URL de l'image téléchargée
      String profileImageUrl = await reference.getDownloadURL();

      return profileImageUrl;
    } catch (e) {
      print('Erreur lors du téléchargement de l\'image de profil: $e');
      return null;
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _authController.errorMessage.value = 'Les mots de passe ne correspondent pas';
        return;
      }

      try {
        File? profileImage;
        if (_profileImage != null) {
          profileImage = File(_profileImage!.path);
        }

        // Récupérer le rôle sélectionné (par exemple "admin", "projectManager", "teamMember")
        UserRole role = UserRole.teamMember; // Exemple par défaut, tu peux ajouter un champ pour permettre à l'utilisateur de choisir son rôle
        String roleString = role.toString().split('.').last;
        String? profileImageUrl;

        // Si une image de profil est fournie, on l'upload dans Firebase Storage
        if (profileImage != null) {
          profileImageUrl = await _uploadProfileImage(profileImage.path);
        }

        // Appel de la méthode d'inscription avec les informations nécessaires
        await _authController.signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
          profileImageUrl,  // L'URL de l'image de profil
          roleString,  // Ajout du rôle ici
        );

        Get.offAllNamed('/verify-email');
      } catch (e) {
        // L'erreur est déjà gérée par le controller
        print('Erreur lors de l\'inscription: $e');
      }
    }

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription'),
        elevation: 0,
      ),
      body: Obx(() {
        return _authController.isLoading.value
            ? const LoadingIndicator()
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImage != null
                            ? FileImage(File(_profileImage!.path))
                            : const AssetImage('assets/images/placeholder_avatar.png')
                        as ImageProvider,
                      ),
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
                ),
                const SizedBox(height: 30),
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
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Mot de passe',
                  hintText: 'Entrez votre mot de passe',
                  prefixIcon: Icons.lock,
                  obscureText: true,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirmer le mot de passe',
                  hintText: 'Confirmez votre mot de passe',
                  prefixIcon: Icons.lock,
                  obscureText: true,
                  validator: (value) => Validators.validatePasswordConfirmation(
                    value,
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: 'S\'inscrire',
                  onPressed: _register,
                  fullWidth: true,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Vous avez déjà un compte ?'),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
                if (_authController.errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.withOpacity(0.1),
                    child: Text(
                      _authController.errorMessage.value,
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
}