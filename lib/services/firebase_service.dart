
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/comment_model.dart';
import '../models/file_model.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

/// Service principal pour initialiser et accéder aux services Firebase
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  /// Initialise tous les services Firebase
  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();

    // Configurer les permissions de notification FCM si nécessaire
    await _configureFCM();
  }

  /// Obtenir une instance de FirebaseAuth
  FirebaseAuth get auth => FirebaseAuth.instance;

  /// Obtenir une instance de FirebaseFirestore
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Obtenir une instance de FirebaseStorage
  FirebaseStorage get storage => FirebaseStorage.instance;

  /// Obtenir une instance de FirebaseMessaging
  FirebaseMessaging get messaging => FirebaseMessaging.instance;

  /// Configure Firebase Cloud Messaging pour les notifications
  Future<void> _configureFCM() async {
    // Demander la permission pour les notifications
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');

      // S'abonner au topic 'all' pour les notifications globales
      await messaging.subscribeToTopic('all');

      // Récupérer le token FCM
      String? token = await messaging.getToken();
      if (token != null) {
        // Stocker le token dans Firestore pour l'utilisateur actuel si nécessaire
        User? currentUser = auth.currentUser;
        if (currentUser != null) {
          await firestore
              .collection('users')
              .doc(currentUser.uid)
              .update({'fcmToken': token});
        }
      }
    }
  }

  /// Vérifie si l'utilisateur est connecté
  bool get isUserLoggedIn => auth.currentUser != null;

  /// Obtenir l'ID de l'utilisateur actuellement connecté
  String? get currentUserId => auth.currentUser?.uid;

  // Nouvelle méthode pour récupérer les fichiers d'un projet
  Future<List<FileModel>> getProjectFiles(String projectId) async {
    try {
      // Rechercher les fichiers associés à ce projet dans Firestore
      var snapshot = await firestore
          .collection('projects') // Collection de projets
          .doc(projectId) // ID du projet
          .collection('files') // Sous-collection des fichiers du projet
          .get();

      // Convertir les documents Firestore en objets FileModel
      return snapshot.docs.map((doc) {
        return FileModel.fromFirestore(doc); // Suppose que vous avez une méthode de conversion Firestore dans FileModel
      }).toList();
    } catch (e) {
      print('Error fetching project files: $e');
      throw Exception('Failed to load project files');
    }
  }

  // Récupérer tous les utilisateurs
  Future<List<UserModel>> getAllUsers() async {
    try {
      // Vous pouvez récupérer les utilisateurs à partir de la collection "users"
      QuerySnapshot snapshot = await firestore.collection('users').get();

      // Convertir chaque document en un objet UserModel
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  // Récupérer tous les projets
  Future<List<ProjectModel>> getAllProjects() async {
    try {
      // Vous pouvez récupérer les projets à partir de la collection "projects"
      QuerySnapshot snapshot = await firestore.collection('projects').get();

      // Convertir chaque document en un objet ProjectModel
      return snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to load projects: $e');
    }
  }

  /// Met à jour le statut actif de L'utilisateur
  Future<void> updateUserActiveStatus(String userId, bool isActive) async {
    try {
      // Accéder au document utilisateur dans Firestore et mettre à jour le champ 'isActive'
      await firestore.collection('users').doc(userId).update({
        'isActive': isActive,
      });
      print('Statut actif de l\'utilisateur mis à jour avec succès');
    } catch (e) {
      print('Erreur lors de la mise à jour du statut actif de l\'utilisateur: $e');
      throw Exception('Échec de la mise à jour du statut actif de l\'utilisateur');
    }
  }
  /// Met à jour le rôle de l'utilisateur
  Future<void> updateUserRole(String userId, String role) async {
    try {
      // Accéder au document utilisateur dans Firestore et mettre à jour le champ 'role'
      await firestore.collection('users').doc(userId).update({
        'role': role,
      });
      print('Rôle de l\'utilisateur mis à jour avec succès');
    } catch (e) {
      print('Erreur lors de la mise à jour du rôle de l\'utilisateur: $e');
      throw Exception('Échec de la mise à jour du rôle de l\'utilisateur');
    }
  }
  // Nouvelle méthode pour récupérer les tâches d'un projet
  Future<List<TaskModel>> getProjectTasks(String projectId) async {
    try {
      // Rechercher les tâches associées à ce projet dans Firestore
      var snapshot = await firestore
          .collection('projects') // Collection de projets
          .doc(projectId) // ID du projet
          .collection('tasks') // Sous-collection des tâches du projet
          .get();

      // Convertir les documents Firestore en objets TaskModel
      return snapshot.docs.map((doc) {
        return TaskModel.fromFirestore(doc); // Suppose que vous avez une méthode de conversion Firestore dans TaskModel
      }).toList();
    } catch (e) {
      print('Error fetching project tasks: $e');
      throw Exception('Failed to load project tasks');
    }
  }
  Future<void> addTaskComment(CommentModel comment) async {
    try {
      // Ajouter le commentaire à la sous-collection 'comments' de la tâche
      await firestore
          .collection('tasks') // Collection des tâches
          .doc(comment.taskId) // ID de la tâche
          .collection('comments') // Sous-collection des commentaires de la tâche
          .add(comment.toFirestore()); // Convertir le commentaire en Map pour Firestore
    } catch (e) {
      print('Error adding task comment: $e');
      throw Exception('Failed to add task comment');
    }
  }
  /// Créer une nouvelle tâche
  Future<void> createTask(TaskModel task) async {
    try {
      // Ajouter la tâche à la collection 'tasks' du projet
      await firestore
          .collection('projects') // Collection des projets
          .doc(task.projectId) // Utilise l'ID du projet pour la tâche
          .collection('tasks') // Sous-collection des tâches du projet
          .add(task.toFirestore()); // Enregistrer la tâche dans Firestore
    } catch (e) {
      print('Error creating task: $e');
      throw Exception('Failed to create task');
    }
  }

  /// Supprimer une tâche de Firestore
  Future<void> deleteTask(String taskId, String projectId) async {
    try {
      // Supprimer la tâche de la sous-collection des tâches d'un projet spécifique
      await firestore
          .collection('projects') // Collection des projets
          .doc(projectId) // ID du projet
          .collection('tasks') // Sous-collection des tâches
          .doc(taskId) // ID de la tâche à supprimer
          .delete(); // Suppression de la tâche
    } catch (e) {
      print('Error deleting task: $e');
      throw Exception('Failed to delete task');
    }
  }

  /// Mettre à jour une tâche existante dans Firestore
  Future<void> updateTask(TaskModel task) async {
    try {
      // Mettre à jour la tâche dans la sous-collection des tâches du projet
      await firestore
          .collection('projects') // Collection des projets
          .doc(task.projectId) // ID du projet
          .collection('tasks') // Sous-collection des tâches
          .doc(task.id) // ID de la tâche à mettre à jour
          .update(task.toFirestore()); // Utilise la méthode toFirestore de TaskModel
    } catch (e) {
      print('Error updating task: $e');
      throw Exception('Failed to update task');
    }
  }

  /// Mettre à jour la progression d'une tâche
  Future<void> updateTaskProgress(String taskId, double progress) async {
    try {
      await firestore
          .collection('tasks') // Collection des tâches
          .doc(taskId) // ID de la tâche
          .update({
        'progress': progress, // Met à jour la progression de la tâche
      });
    } catch (e) {
      print('Error updating task progress: $e');
      throw Exception('Failed to update task progress');
    }
  }

  /// Récupérer une tâche par son ID
  Future<TaskModel> getTaskById(String taskId) async {
    try {
      final doc = await firestore
          .collection('tasks') // Collection des tâches
          .doc(taskId) // ID de la tâche
          .get();

      if (doc.exists) {
        return TaskModel.fromFirestore(doc); // Utilise la méthode fromFirestore pour convertir en objet TaskModel
      } else {
        throw Exception('Task not found');
      }
    } catch (e) {
      print('Error getting task by ID: $e');
      throw Exception('Failed to get task by ID');
    }
  }

  // Méthode pour récupérer un utilisateur par son ID
  Future<UserModel> getUserById(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      rethrow; // Relance l'erreur si une exception se produit
    }
  }
  // Méthode pour vérifier si un utilisateur existe en fonction de son email
  Future<bool> checkUserExists(String email) async {
    try {
      final querySnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      // Si la taille du résultat est supérieure à 0, l'utilisateur existe
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      rethrow; // Relance l'erreur si une exception se produit
    }
  }

  // Méthode pour rechercher des utilisateurs par email ou nom
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final querySnapshot = await firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff') // Assurer la recherche sur le nom
          .get();

      // Convertir les résultats en une liste de UserModel
      return querySnapshot.docs.map((doc) {
        return UserModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      rethrow; // Relancer l'erreur si nécessaire
    }
  }

  // Nouvelle méthode pour récupérer les projets d'un utilisateur spécifique
  Future<List<ProjectModel>> getUserProjects(String userId) async {
    try {
      // Rechercher les projets associés à cet utilisateur dans Firestore
      var snapshot = await firestore
          .collection('projects') // Collection des projets
          .where('userId', isEqualTo: userId) // Filtrer par 'userId'
          .get();

      // Convertir les documents Firestore en objets ProjectModel
      return snapshot.docs.map((doc) {
        return ProjectModel.fromFirestore(doc); // Suppose que vous avez une méthode de conversion Firestore dans ProjectModel
      }).toList();
    } catch (e) {
      print('Error fetching user projects: $e');
      throw Exception('Failed to load user projects');
    }
  }

  // Méthode pour créer un projet
  Future<void> createProject(ProjectModel project) async {
    try {
      // Ajouter un nouveau projet dans la collection 'projects' de Firestore
      await firestore.collection('projects').add(project.toFirestore());
      print('Projet créé avec succès');
    } catch (e) {
      print('Erreur lors de la création du projet: $e');
      throw Exception('Échec de la création du projet');
    }
  }

  // Méthode pour mettre à jour un projet
  Future<void> updateProject(ProjectModel project) async {
    try {
      // Mettre à jour le projet dans la collection 'projects' de Firestore
      await firestore
          .collection('projects')
          .doc(project.id) // Utilise l'ID du projet pour le mettre à jour
          .update(project.toFirestore());
      print('Projet mis à jour avec succès');
    } catch (e) {
      print('Erreur lors de la mise à jour du projet: $e');
      throw Exception('Échec de la mise à jour du projet');
    }
  }
// Méthode pour supprimer un projet
  Future<void> deleteProject(String projectId) async {
    try {
      // Supprimer le projet de la collection 'projects' en utilisant son ID
      await firestore.collection('projects').doc(projectId).delete();
      print('Projet supprimé avec succès');
    } catch (e) {
      print('Erreur lors de la suppression du projet: $e');
      throw Exception('Échec de la suppression du projet');
    }
  }
  Future<void> addMemberToProject(String projectId, String memberId) async {
    try {
      // Récupérer le projet
      DocumentSnapshot projectSnapshot = await firestore.collection('projects').doc(projectId).get();

      if (projectSnapshot.exists) {
        // Ajouter le membre à la liste des membres du projet
        await firestore.collection('projects').doc(projectId).update({
          'members': FieldValue.arrayUnion([memberId]), // Ajoute l'ID du membre à la liste
        });
        print('Membre ajouté avec succès');
      } else {
        throw Exception('Le projet n\'existe pas');
      }
    } catch (e) {
      print('Erreur lors de l\'ajout du membre au projet: $e');
      throw Exception('Échec de l\'ajout du membre');
    }
  }
  Future<void> removeMemberFromProject(String projectId, String memberId) async {
    try {
      // Récupérer le projet
      DocumentSnapshot projectSnapshot = await firestore.collection('projects').doc(projectId).get();

      if (projectSnapshot.exists) {
        // Supprimer le membre de la liste des membres du projet
        await firestore.collection('projects').doc(projectId).update({
          'members': FieldValue.arrayRemove([memberId]), // Supprime l'ID du membre de la liste
        });
        print('Membre supprimé avec succès');
      } else {
        throw Exception('Le projet n\'existe pas');
      }
    } catch (e) {
      print('Erreur lors de la suppression du membre du projet: $e');
      throw Exception('Échec de la suppression du membre');
    }
  }
  Future<ProjectModel?> getProjectById(String projectId) async {
    try {
      // Récupérer le projet depuis Firestore
      DocumentSnapshot projectSnapshot = await firestore.collection('projects').doc(projectId).get();

      if (projectSnapshot.exists) {
        // Convertir le document en modèle ProjectModel
        return ProjectModel.fromFirestore(projectSnapshot);
      } else {
        throw Exception('Le projet n\'existe pas');
      }
    } catch (e) {
      print('Erreur lors de la récupération du projet: $e');
      throw Exception('Échec de la récupération du projet');
    }
  }
  Future<void> updateProjectStatus(String projectId, String newStatus) async {
    try {
      // Mettre à jour le statut du projet
      await firestore.collection('projects').doc(projectId).update({
        'status': newStatus, // Met à jour le statut du projet
      });
      print('Statut du projet mis à jour avec succès');
    } catch (e) {
      print('Erreur lors de la mise à jour du statut du projet: $e');
      throw Exception('Échec de la mise à jour du statut du projet');
    }
  }

  /// Ajouter un fichier à un projet dans Firestore
  Future<void> addProjectFile(FileModel file) async {
    try {
      // Ajouter le fichier dans la sous-collection 'files' du projet
      await _firestore
          .collection('projects') // Collection des projets
          .doc(file.projectId) // Utilise l'ID du projet
          .collection('files') // Sous-collection des fichiers du projet
          .add(file.toFirestore()); // Utilise la méthode toFirestore de FileModel
      print('Fichier ajouté avec succès');
    } catch (e) {
      print('Erreur lors de l\'ajout du fichier: $e');
      throw Exception('Échec de l\'ajout du fichier');
    }
  }

  /// Supprimer un fichier d'un projet dans Firestore
  Future<void> deleteProjectFile(String fileId, String projectId) async {
    try {
      // Supprimer le fichier de la sous-collection des fichiers du projet
      await _firestore
          .collection('projects') // Collection des projets
          .doc(projectId) // ID du projet
          .collection('files') // Sous-collection des fichiers
          .doc(fileId) // ID du fichier à supprimer
          .delete(); // Suppression du fichier
      print('Fichier supprimé avec succès');
    } catch (e) {
      print('Erreur lors de la suppression du fichier: $e');
      throw Exception('Échec de la suppression du fichier');
    }
  }

  /// Récupérer les commentaires d'une tâche
  Future<List<CommentModel>> getTaskComments(String taskId) async {
    try {
      // Récupérer les commentaires de la tâche spécifique dans Firestore
      var snapshot = await firestore
          .collection('tasks') // Collection des tâches
          .doc(taskId) // ID de la tâche
          .collection('comments') // Sous-collection des commentaires
          .get();

      // Convertir chaque document de commentaire en un objet CommentModel
      return snapshot.docs.map((doc) {
        return CommentModel.fromFirestore(doc); // Assurez-vous que vous avez la méthode de conversion fromFirestore dans CommentModel
      }).toList();
    } catch (e) {
      print('Error fetching task comments: $e');
      throw Exception('Failed to load task comments');
    }
  }

  /// Récupérer les membres d'un projet spécifique
  Future<List<UserModel>> getProjectMembers(String projectId) async {
    try {
      // Récupérer le projet depuis Firestore
      DocumentSnapshot projectSnapshot = await firestore.collection('projects').doc(projectId).get();

      if (projectSnapshot.exists) {
        // Récupérer les membres du projet à partir du champ 'members'
        List<dynamic> memberIds = projectSnapshot['members'] ?? [];

        // Si la liste des membres existe, on récupère les utilisateurs associés
        if (memberIds.isNotEmpty) {
          List<UserModel> members = [];
          for (var memberId in memberIds) {
            // Pour chaque ID de membre, récupérer les informations de l'utilisateur
            UserModel member = await getUserById(memberId);
            members.add(member);
          }
          return members;
        } else {
          return [];
        }
      } else {
        throw Exception('Le projet n\'existe pas');
      }
    } catch (e) {
      print('Erreur lors de la récupération des membres du projet: $e');
      throw Exception('Échec de la récupération des membres du projet');
    }
  }

  /// Méthode pour télécharger l'image de profil d'un utilisateur
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      // Générer un chemin unique pour l'image
      String filePath = 'profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Télécharger le fichier vers Firebase Storage
      UploadTask uploadTask = storage.ref(filePath).putFile(imageFile);

      // Attendre que l'upload soit terminé
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

      // Récupérer l'URL de téléchargement du fichier
      String photoUrl = await snapshot.ref.getDownloadURL();

      return photoUrl;
    } catch (e) {
      print("Erreur lors du téléchargement de l'image : $e");
      rethrow;
    }
  }

  /// Crée un utilisateur admin par défaut dans Firestore
  Future<void> createDefaultAdminUser({
    required String uid,
    required String email,
    String? profileImageUrl, // URL de l'image de profil
  }) async {
    try {
      final userModel = UserModel(
        id: uid,
        email: email,
        fullName: 'Admin Default',
        photoUrl: profileImageUrl,
        role: UserRole.admin,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userModel.toFirestore());

      print('Utilisateur admin créé avec succès avec photo');
    } catch (e) {
      print('Erreur lors de la création de l\'utilisateur admin: $e');
    }
  }

  // Créer un document utilisateur dans Firestore avec un profil
  Future<void> createUserDocument(
      String userId,
      String email,
      String role,  // Ajout du rôle ici
      String fullName,
      String? profileImageUrl,
      ) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Données du profil utilisateur
      Map<String, dynamic> userData = {
        'email': email,
        'role': role,  // Sauvegarder le rôle de l'utilisateur
        'fullName': fullName,
        'profileImageUrl': profileImageUrl,  // URL de l'image de profil (peut être null)
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,  // L'utilisateur est actif par défaut
      };

      // Créer le document utilisateur dans la collection 'users'
      await firestore.collection('users').doc(userId).set(userData);

      print('Document utilisateur créé avec succès dans Firestore');
    } catch (e) {
      print('Erreur lors de la création du document utilisateur : $e');
    }
  }}