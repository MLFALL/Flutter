import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'auth_controller.dart';

class UserController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  final RxList<UserModel> teamMembers = <UserModel>[].obs;
  final RxMap<String, UserModel> userCache = <String, UserModel>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

// Réactif pour récupérer les noms des utilisateurs
  final RxMap<String, RxString> userNamesCache = <String, RxString>{}.obs;

  String? get currentUserId => _authController.currentUser?.id;
  AuthController get authController => _authController;

  @override
  void onInit() {
    super.onInit();
    // Cache the current user immediately
    if (_authController.currentUser != null) {
      cacheUser(_authController.currentUser!);
    }
  }



  // Fetch team members for a project
  Future<void> fetchTeamMembers(List<String> memberIds) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      List<UserModel> members = [];

      // Vérifie d'abord le cache pour chaque utilisateur avant de récupérer depuis Firestore
      for (String userId in memberIds) {
        if (userCache.containsKey(userId)) {
          members.add(userCache[userId]!);
        } else {
          try {
            UserModel user = await _firebaseService.getUserById(userId);
            cacheUser(user); // Cache l'utilisateur
            members.add(user);
          } catch (e) {
            print('Error fetching user $userId: $e');
            // Continue with other users even if one fails
          }
        }
      }

      teamMembers.value = members;
    } catch (e) {
      errorMessage.value = 'Failed to fetch team members: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Cache user data to avoid repeated fetching
  void cacheUser(UserModel user) {
    userCache[user.id] = user;
  }

  // Get user from cache or fetch if not available
  Future<UserModel?> getUser(String userId) async {
    // Return from cache if available
    if (userCache.containsKey(userId)) {
      return userCache[userId];
    }

    // Otherwise fetch from Firebase
    try {
      UserModel user = await _firebaseService.getUserById(userId);
      cacheUser(user);
      return user;
    } catch (e) {
      errorMessage.value = 'Failed to get user: ${e.toString()}';
      return null;
    }
  }

  // Search users by email or name (for adding to projects)
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (query.length < 3) {
        return [];
      }

      List<UserModel> result = await _firebaseService.searchUsers(query);

      // Cache results
      for (UserModel user in result) {
        cacheUser(user);
      }

      return result;
    } catch (e) {
      errorMessage.value = 'Search failed: ${e.toString()}';
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  // Check if user exists (when inviting to project)
  Future<bool> checkUserExists(String email) async {
    try {
      return await _firebaseService.checkUserExists(email);
    } catch (e) {
      errorMessage.value = 'Failed to check user: ${e.toString()}';
      return false;
    }
  }

  // Get user display information (avatar + name)
  Map<String, String> getUserDisplayInfo(String userId) {
    if (userCache.containsKey(userId)) {
      UserModel user = userCache[userId]!;
      return {
        'name': user.fullName,
        'photoUrl': user.photoUrl ?? '',
      };
    } else {
      // Return placeholder if user not found
      return {
        'name': 'Unknown User',
        'photoUrl': '',
      };
    }
  }

  // Format user role for display
  String formatUserRole(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'manager':
        return 'Project Manager';
      default:
        return 'Team Member';
    }
  }
  // ✅ GETTER OBSERVABLE POUR UTILISATION AVEC Obx
  Rx<UserModel?> getUserById(String userId) {
    return Rx<UserModel?>(userCache[userId]);
  }
  // Fonction qui renvoie un RxString pour un nom utilisateur spécifique
  RxString getUserNameById(String userId) {
    if (!userNamesCache.containsKey(userId)) {
      // Si le nom n'est pas dans le cache, on l'ajoute
      var rxName = RxString('');
      userNamesCache[userId] = rxName;

      // Charge le nom de l'utilisateur depuis Firestore
      _fetchUserNameFromFirestore(userId, rxName);
    }
    return userNamesCache[userId]!;
  }
  // Fonction pour récupérer le nom de l'utilisateur depuis Firestore
  Future<void> _fetchUserNameFromFirestore(String userId, RxString rxName) async {
    try {
      var userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        rxName.value = userDoc.data()?['name'] ?? 'Inconnu';
      } else {
        rxName.value = 'Inconnu';
      }
    } catch (e) {
      rxName.value = 'Inconnu';
    }
  }

  // Ajoutez cette méthode à votre UserController
  void changeUserRole(String userId, UserRole newRole) async {
    try {
      // Vérifiez d'abord si l'utilisateur est dans le cache
      if (userCache.containsKey(userId)) {
        // Récupérer l'utilisateur depuis le cache
        UserModel user = userCache[userId]!;

        // Mettre à jour le rôle de l'utilisateur
        user.role = newRole;

        // Mettre à jour l'utilisateur dans le cache
        userCache[userId] = user;

        // Si vous voulez également mettre à jour Firestore, vous pouvez faire ceci :
        await _firestore.collection('users').doc(userId).update({
          'role': newRole,
        });

        // Vous pouvez également mettre à jour d'autres états ou informer l'utilisateur du succès
        print('Role of user $userId updated to $newRole');
      } else {
        // Si l'utilisateur n'est pas dans le cache, essayez de récupérer depuis Firestore
        UserModel? user = await getUser(userId);
        if (user != null) {
          user.role = newRole;
          // Mettez à jour dans le cache et Firestore
          cacheUser(user);

          await _firestore.collection('users').doc(userId).update({
            'role': newRole,
          });

          print('Role of user $userId updated to $newRole');
        } else {
          print('User not found in cache or Firestore');
        }
      }
    } catch (e) {
      errorMessage.value = 'Failed to change user role: ${e.toString()}';
      print('Error changing user role: $e');
    }
  }

  // Liste des utilisateurs observée
  var users = <UserModel>[].obs;

  // Méthode pour activer/désactiver un utilisateur
  void toggleUserStatus(String userId) async {
    // Trouver l'utilisateur par son ID
    final userIndex = users.indexWhere((user) => user.id == userId);
    if (userIndex == -1) return;

    final user = users[userIndex];

    // Basculez le statut de l'utilisateur
    final newStatus = user.isActive ? UserStatus.inactive : UserStatus.active;

    // Mettez à jour le modèle local
    users[userIndex] = user.copyWith(status: newStatus);

    // Mettez à jour l'utilisateur dans Firestore
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': newStatus.toString().split('.').last,
      });
    } catch (e) {
      // Gérez les erreurs ici si nécessaire
      print("Erreur lors de la mise à jour du statut de l'utilisateur : $e");
    }
  }

  // Récupérer tous les utilisateurs de la base de données
  Future<List<UserModel>> getAllUsers() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      QuerySnapshot snapshot = await _firestore.collection('users').get();

      List<UserModel> allUsers = snapshot.docs.map((doc) {
        return UserModel.fromFirestore(doc);
      }).toList();

      // On peut aussi les stocker dans la liste observable si tu veux les afficher dans l'UI
      users.value = allUsers;

      // Cache les utilisateurs pour un accès rapide ensuite
      for (var user in allUsers) {
        cacheUser(user);
      }

      return allUsers;
    } catch (e) {
      errorMessage.value = 'Failed to get all users: ${e.toString()}';
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour mettre à jour le profil utilisateur
  Future<void> updateUserProfile(String fullName, File? profileImage) async {
    try {
      // Vérifiez si l'utilisateur actuel est dans le cache
      final currentUser = _authController.currentUser;
      if (currentUser != null) {
        // Mettez à jour le nom complet de l'utilisateur
        currentUser.fullName = fullName;

        // Si une image de profil est fournie, téléchargez-la
        if (profileImage != null) {
          String photoUrl = await _firebaseService.uploadProfileImage(profileImage);
          currentUser.photoUrl = photoUrl;
        }

        // Mettez à jour l'utilisateur dans le cache
        cacheUser(currentUser);

        // Mettez à jour l'utilisateur dans Firestore
        await _firestore.collection('users').doc(currentUser.id).update({
          'fullName': fullName,
          if (profileImage != null) 'photoUrl': currentUser.photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('Profile updated for user ${currentUser.id}');
      } else {
        print('Current user is not logged in');
      }
    } catch (e) {
      errorMessage.value = 'Failed to update user profile: ${e.toString()}';
      print('Error updating user profile: $e');
    }
  }
}