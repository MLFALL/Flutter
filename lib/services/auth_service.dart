import 'dart:io';
import 'package:fall_mouhamadoulamine_l3gl_examen/services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'package:path/path.dart' as path;

/// Service gérant l'authentification des utilisateurs
class AuthService {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final StorageService _storageService = StorageService();

  // Fonction pour inscrire un utilisateur et créer son profil dans Firestore
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,  // Le rôle de l'utilisateur
    String? profileImageUrl, // URL de l'image de profil (peut être null)
  }) async {
    try {
      // Créer l'utilisateur dans Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Créer le profil de l'utilisateur dans Firestore avec les informations
      await _firebaseService.createUserDocument(
        userCredential.user!.uid,    // UID de l'utilisateur créé
        email,                       // L'email de l'utilisateur
        fullName,                    // Le nom complet de l'utilisateur
        role,                        // Le rôle de l'utilisateur
        profileImageUrl,             // L'URL de l'image de profil (peut être null)
      );
    } catch (e) {
      print('Erreur lors de la création de l\'utilisateur: $e');
      rethrow;
    }
  }



  /// Connexion avec email et mot de passe
  Future<UserCredential> signIn({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      // Mettre à jour la date de dernière connexion
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Vérification d'email
  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Vérifie si l'email est vérifié
  Future<bool> checkEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  /// Mise à jour du profil utilisateur
  Future<void> updateUserProfile({
    required String fullName,
    String? photoUrl,
  }) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fullName': fullName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }


  /// Télécharge l'image de profil et renvoie l'URL


  /// Vérifie si l'utilisateur actuel est admin
  Future<bool> isCurrentUserAdmin() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['role'] == UserRole.admin.toString().split('.').last;
    }
    return false;
  }

  /// Crée un nouvel utilisateur dans Firestore
  Future<void> _createUserInFirestore({
    required String uid,
    required String email,
    required String fullName,
    required UserRole role,
    String? photoUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'id': uid, // Ajout explicite de l'ID
        'email': email,
        'fullName': fullName,
        'photoUrl': photoUrl,
        'role': _enumToString(role), // Méthode helper pour la conversion
        'status': _enumToString(UserStatus.active),
        'isEmailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // En cas d'échec dans Firestore, supprimer l'utilisateur Auth pour éviter les incohérences
      await _auth.currentUser?.delete();
      rethrow;
    }
  }

// Helper pour convertir les enums en String
  String _enumToString(dynamic enumValue) {
    return enumValue.toString().split('.').last;
  }

  /// Récupère les détails de l'utilisateur actuel
  Future<UserModel?> getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      return UserModel.fromFirestore(userDoc);
    }
    return null;
  }

  /// Change le rôle d'un utilisateur (disponible uniquement pour les admins)
  Future<void> changeUserRole(String userId, UserRole newRole) async {
    if (!await isCurrentUserAdmin()) {
      throw Exception("Accès non autorisé");
    }

    await _firestore.collection('users').doc(userId).update({
      'role': newRole.toString().split('.').last,
    });
  }

  /// Change le statut d'un utilisateur (activer/désactiver)
  Future<void> changeUserStatus(String userId, UserStatus newStatus) async {
    if (!await isCurrentUserAdmin()) {
      throw Exception("Accès non autorisé");
    }

    await _firestore.collection('users').doc(userId).update({
      'status': newStatus.toString().split('.').last,
    });
  }
  /// Récupère les détails d'un utilisateur spécifique par son uid
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      } else {
        throw Exception('Utilisateur non trouvé');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des données de l\'utilisateur: ${e.toString()}');
    }
  }

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required UserRole role,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await docRef.set({
      'id': uid,
      'email': email,
      'fullName': fullName,
      'role': role.toString().split('.').last,
      'status': 'active',
      'photoUrl': null,
      'isEmailVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }
  // Fonction pour créer un utilisateur et son profil dans Firestore
  Future<void> signUpAndCreateDocument(String email, String password, String role, String fullName, String? profileImagePath) async {
    try {
      // Créer l'utilisateur dans Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Si une image de profil est fournie, on l'upload dans Firebase Storage
      String? profileImageUrl;
      if (profileImagePath != null) {
        profileImageUrl = await _uploadProfileImage(profileImagePath);
      }

      // Créer le document du profil dans Firestore avec le rôle et l'image de profil (si disponible)
      await _firebaseService.createUserDocument(
        userCredential.user!.uid,
        userCredential.user!.email!,
        role,
        fullName,
        profileImageUrl,  // L'URL de l'image de profil
      );

    } catch (e) {
      print('Erreur lors de l\'inscription de l\'utilisateur : $e');
    }
  }

// Fonction pour télécharger l'image de profil
  Future<String?> _uploadProfileImage(String imagePath) async {
    // Vérifie si l'application est exécutée sur le Web
    if (kIsWeb) {
      print('Téléchargement d\'image non pris en charge sur le Web.');
      return null;  // Ou retourne un message d'erreur ou une autre solution pour le Web
    }

    try {
      final File file = File(imagePath);
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/${file.uri.pathSegments.last}');
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erreur lors du téléchargement de l\'image de profil: $e');
      return null;
    }
  }
}