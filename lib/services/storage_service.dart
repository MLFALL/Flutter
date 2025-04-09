import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import '../models/file_model.dart';
import 'firebase_service.dart';

/// Service pour gérer le téléchargement et le stockage de fichiers
class StorageService {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Télécharge un fichier dans Firebase Storage et enregistre ses métadonnées dans Firestore
  Future<FileModel> uploadFile({
    required File file,
    required String projectId,
    String? taskId,
    required String userId,
  }) async {
    try {
      // Validation de la taille du fichier (max 10 MB)
      int fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception("Le fichier est trop volumineux. La limite est de 10 MB.");
      }

      // Générer un nom de fichier unique
      String fileName = path.basename(file.path);
      String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Télécharger le fichier dans Storage
      Reference storageRef = _storage.ref().child('project_files/$projectId/$uniqueFileName');
      UploadTask uploadTask = storageRef.putFile(file);

      // Attendre la fin du téléchargement
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Détecter le type de fichier
      FileType fileType = FileModel.detectFileType(fileName);

      // Créer un document dans Firestore pour le fichier
      DocumentReference fileRef = await _firestore.collection('files').add({
        'projectId': projectId,
        'taskId': taskId,
        'name': fileName,
        'url': downloadUrl,
        'type': fileType.toString().split('.').last,
        'size': fileSize,
        'uploadedBy': userId,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      // Récupérer le document pour renvoyer le modèle complet
      DocumentSnapshot fileDoc = await fileRef.get();
      return FileModel.fromFirestore(fileDoc);
    } catch (e) {
      rethrow;
    }
  }
  /// ✅ Nouvelle méthode : upload simple qui retourne juste l'URL
  Future<String> uploadFileAndReturnUrl({
    required File file,
    required String projectId,
    required String userId,
  }) async {
    try {
      int fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception("Le fichier est trop volumineux. La limite est de 10 MB.");
      }

      String fileName = path.basename(file.path);
      String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      Reference storageRef = _storage.ref().child('project_files/$projectId/$uniqueFileName');
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }
  /// Supprime un fichier
  Future<void> deleteFile(String fileId) async {
    try {
      // Récupérer les informations du fichier
      DocumentSnapshot fileDoc = await _firestore.collection('files').doc(fileId).get();
      if (!fileDoc.exists) {
        throw Exception("Le fichier n'existe pas");
      }

      Map<String, dynamic> fileData = fileDoc.data() as Map<String, dynamic>;
      String fileUrl = fileData['url'] as String;

      // Supprimer le fichier de Storage
      try {
        Reference fileRef = _storage.refFromURL(fileUrl);
        await fileRef.delete();
      } catch (e) {
        print("Erreur lors de la suppression du fichier dans Storage: $e");
        // Continuer malgré l'erreur pour supprimer au moins l'entrée dans Firestore
      }

      // Supprimer l'entrée dans Firestore
      await _firestore.collection('files').doc(fileId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère tous les fichiers d'un projet
  Future<List<FileModel>> getProjectFiles(String projectId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('files')
          .where('projectId', isEqualTo: projectId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FileModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère tous les fichiers d'une tâche
  Future<List<FileModel>> getTaskFiles(String taskId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('files')
          .where('taskId', isEqualTo: taskId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FileModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Télécharge un fichier localement (pour l'affichage hors ligne)
  Future<File> downloadFileLocally(String fileUrl, String destinationPath) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      final File file = File(destinationPath);
      await ref.writeToFile(file);
      return file;
    } catch (e) {
      rethrow;
    }
  }

  /// Télécharge une image de profil dans Firebase Storage
  Future<String> uploadProfileImage({
    required String userId,
    required File profileImage,
  }) async {
    try {
      // Vérification de la taille (5MB max)
      if ((await profileImage.length()) > 5 * 1024 * 1024) {
        throw Exception("L'image de profil ne doit pas dépasser 5MB");
      }

      // Génération d'un nom de fichier unique avec timestamp
      String fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = _storage.ref().child('profile_images/$fileName');

      // Métadonnées pour une meilleure gestion
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_by': userId,
          'uploaded_at': DateTime.now().toString(),
        },
      );

      // Upload avec gestion des erreurs
      await storageRef.putFile(profileImage, metadata);
      return await storageRef.getDownloadURL();
    } on FirebaseException catch (e) {
      print('Firebase Storage Error: ${e.code} - ${e.message}');
      throw Exception("Échec de l'upload de l'image de profil");
    } catch (e) {
      print('Unexpected Error: $e');
      rethrow;
    }
  }
  Future<void> deleteOldProfileImages(String userId) async {
    try {
      // Lister toutes les images de profil de l'utilisateur
      final listResult = await _storage.ref()
          .child('profile_images')
          .listAll();

      // Filtrer pour ne garder que celles de l'utilisateur
      final userImages = listResult.items.where(
              (ref) => ref.name.contains('profile_${userId}_')
      );

      // Supprimer toutes les anciennes images
      await Future.wait(
          userImages.map((ref) => ref.delete())
      );
    } catch (e) {
      print('Error deleting old profile images: $e');
      // Ne pas bloquer le flux principal en cas d'erreur
    }
  }

}