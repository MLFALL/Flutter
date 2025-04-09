import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../config/routes.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isPasswordVisible = false.obs;

  UserModel? get currentUser => _currentUser.value;
  bool get isLoggedIn => _currentUser.value != null;
  Future<bool> isUserLoggedIn() async {
    // Vérifiez l'état de l'utilisateur
    final user = FirebaseAuth.instance.currentUser;
    return user != null;  // Retourne true si l'utilisateur est connecté
  }
  // Ajoutez cette méthode pour basculer la visibilité du mot de passe
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
  Future<void> loadUserData(String userId) async {
    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        // Utilisation de la méthode fromFirestore pour créer l'utilisateur à partir du DocumentSnapshot
        _currentUser.value = UserModel.fromFirestore(userDoc);  // Appel à fromFirestore avec le DocumentSnapshot
      } else {
        _currentUser.value = null; // Si l'utilisateur n'existe pas
        print('Aucun utilisateur trouvé avec cet ID');
      }
    } catch (e) {
      _currentUser.value = null;  // Si une erreur se produit
      print('Erreur lors de la récupération des données de l\'utilisateur: $e');
    }
  }


  @override
  void onInit() {
    super.onInit();
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        try {
          isLoading.value = true;
          // Charge les données utilisateur
          UserModel? userModel = await _authService.getUserById(user.uid);
          _currentUser.value = userModel;
        } catch (e) {
          errorMessage.value = 'Failed to load user data: ${e.toString()}';
        } finally {
          isLoading.value = false;
        }
      } else {
        _currentUser.value = null; // Si l'utilisateur se déconnecte
      }
    });
  }


  Future<void> signIn(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      UserCredential userCredential = await _authService.signIn(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // Vérifie si l'email est vérifié
        if (user.emailVerified) {
          // Charge les données de l'utilisateur
          await loadCurrentUser();

          // Vérifie le rôle de l'utilisateur et effectue la redirection
          if (_currentUser.value?.role == 'admin') {
            Get.offAllNamed(AppRoutes.adminDashboard); // Redirige vers le tableau de bord admin
          } else if (_currentUser.value?.role == 'projectManager') {
            Get.offAllNamed(AppRoutes.projectsList); // Redirige vers la liste des projets pour un manager
          } else if (_currentUser.value?.role == 'teamMember') {
            Get.offAllNamed(AppRoutes.projectsList); // Redirige vers le tableau de bord de l'équipe
          } else {
            Get.offAllNamed(AppRoutes.home); // Redirige vers l'accueil pour un utilisateur normal
          }
        } else {
          // Si l'email n'est pas vérifié, redirige vers le profil
          Get.offAllNamed(AppRoutes.profile);
          errorMessage.value = 'Veuillez vérifier votre email avant de continuer';
        }
      }
    } catch (e) {
      errorMessage.value = 'Login failed: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp(String email, String password, String name,
      String? profileImagePath, String role) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      String? profileImageUrl;
      if (profileImagePath != null) {
        profileImageUrl = await _uploadProfileImage(profileImagePath);
      }

      await _authService.signUp(
        email: email,
        password: password,
        fullName: name,
        profileImageUrl: profileImageUrl,
        role: role,
      );

      // Redirige directement vers l'accueil après inscription
      Get.offAllNamed(AppRoutes.home);

      // Envoie un email de vérification (sans écran dédié)
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();

    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getFirebaseErrorMessage(e);
    } catch (e) {
      errorMessage.value = 'Erreur inattendue: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
  // Fonction pour télécharger l'image de profil dans Firebase Storage
  Future<String?> _uploadProfileImage(String profileImagePath) async {
    try {
      // Crée une référence Firebase Storage
      FirebaseStorage storage = FirebaseStorage.instance;
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg'; // Nom unique pour l'image
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
  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Email invalide';
      case 'weak-password':
        return 'Le mot de passe doit faire au moins 6 caractères';
      case 'operation-not-allowed':
        return 'La création de compte est désactivée';
      default:
        return 'Erreur lors de la création du compte: ${e.message}';
    }
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _authService.signOut();
      _currentUser.value = null;
    } catch (e) {
      errorMessage.value = 'Sign out failed: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile(String name, File? profileImage) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      String? photoUrl;

      // Si une nouvelle image est fournie
      if (profileImage != null) {
        photoUrl = await _storageService.uploadProfileImage(
          userId: _currentUser.value!.id,
          profileImage: profileImage,
        );
      }

      // Appel à AuthService avec l'URL seulement (pas le File)
      await _authService.updateUserProfile(
        fullName: name,
        photoUrl: photoUrl, // Passez l'URL ici au lieu du File
      );

      // Mise à jour des données locales
      _currentUser.update((user) {
        user!.fullName = name;
        if (photoUrl != null) {
          user.photoUrl = photoUrl;
        }
      });

    } catch (e) {
      errorMessage.value = 'Échec de la mise à jour du profil: ${e.toString()}';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
  Future<bool> resetPassword(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      errorMessage.value = 'Password reset failed: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyEmail() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      // Vérifie si un utilisateur est connecté
      if (_currentUser.value != null) {
        await _authService.sendEmailVerification();
      } else {
        errorMessage.value = 'Aucun utilisateur connecté.';
      }
    } catch (e) {
      errorMessage.value = 'Email verification failed: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> checkIfAdmin() async {
    return _currentUser.value?.role == 'admin';
  }

  Future<bool> checkIfProjectManager() async {
    return _currentUser.value?.role == 'manager';
  }



  /// Recharge les données utilisateur depuis Firestore
  Future<void> loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        isLoading.value = true;
        // Tente de récupérer l'utilisateur depuis Firestore ou une autre source.
        UserModel? userModel = await _authService.getUserById(user.uid);
        if (userModel != null) {
          _currentUser.value = userModel;
        } else {
          errorMessage.value = 'Utilisateur introuvable dans la base de données.';
        }
      } catch (e) {
        errorMessage.value = 'Erreur lors du chargement de l’utilisateur: ${e.toString()}';
      } finally {
        isLoading.value = false;
      }
    } else {
      errorMessage.value = 'Aucun utilisateur connecté.';
    }
  }


  /// Change le mot de passe de l'utilisateur
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      // Vérifiez si l'utilisateur est connecté
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Vous devez d'abord vérifier le mot de passe actuel avec la méthode `reauthenticateWithCredential`
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);

        // Si la réauthentification réussit, vous pouvez mettre à jour le mot de passe
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      errorMessage.value = 'Échec du changement de mot de passe : ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
  // Méthode pour récupérer le nom complet d'un utilisateur en fonction de son userId
  String getUserFullName(String userId) {
    // Vérifie si l'utilisateur actuel a un nom complet
    if (_currentUser.value?.id == userId) {
      return _currentUser.value?.fullName ?? 'Nom inconnu';
    }

    // Si l'utilisateur actuel n'est pas celui qui a posté, charge l'utilisateur par son ID
    // Tu devras peut-être ajouter une logique pour récupérer un utilisateur depuis Firestore si nécessaire
    return 'Nom de l\'auteur'; // Remplace ceci par une vraie logique de récupération si nécessaire
  }


  Future<void> logout() async {
    print("Déconnexion lancée...");
    try {
      isLoading.value = true;
      await FirebaseAuth.instance.signOut();
      _currentUser.value = null;
      print("Déconnexion réussie");
    } catch (e) {
      print("Erreur lors de la déconnexion : $e");
    } finally {
      isLoading.value = false;
    }
  }



}