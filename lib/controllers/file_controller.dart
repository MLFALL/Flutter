import 'package:file_picker/file_picker.dart' as picker;  // Alias pour éviter le conflit
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/file_model.dart';  // Assurez-vous que vous importez le modèle avec FileType
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../utils/file_utils.dart';
import 'auth_controller.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class FileController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<FileModel> files = <FileModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxDouble uploadProgress = 0.0.obs;

  // Current project ID
  final RxString currentProjectId = ''.obs;

  // Variable pour stocker les erreurs d'affichage
  final RxString viewerError = ''.obs; // Erreur lors de l'affichage du fichier


  void setCurrentProject(String projectId) {
    currentProjectId.value = projectId;
    fetchFiles();
  }

  Future<void> fetchFiles() async {
    if (currentProjectId.value.isEmpty) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      List<FileModel> fetchedFiles = await _firebaseService.getProjectFiles(currentProjectId.value);
      files.value = fetchedFiles;
    } catch (e) {
      errorMessage.value = 'Erreur lors du chargement des fichiers : ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
  // Méthode pour télécharger un fichier
  // Méthode pour télécharger un fichier
  Future<void> uploadFile(File file, String fileName, String fileType) async {
    if (currentProjectId.value.isEmpty) {
      errorMessage.value = 'Aucun projet sélectionné';
      return;
    }

    try {
      isLoading.value = true;
      uploadProgress.value = 0.0;
      errorMessage.value = '';

      // Vérifier la taille du fichier et les restrictions de rôle
      int maxSizeInBytes = await _getMaxFileSizeByRole();
      if (file.lengthSync() > maxSizeInBytes) {
        errorMessage.value = 'La taille du fichier dépasse la limite autorisée pour votre rôle';
        return;
      }

      // Détecter le type de fichier
      String detectedType = FileModel.detectFileType(fileName).toString().split('.').last;

      // Télécharger le fichier vers Firebase Storage
      final String fileUrl = await _storageService.uploadFileAndReturnUrl(
        file: file,
        projectId: currentProjectId.value,
        userId: _authController.currentUser!.id,
      );

      // Créer le modèle de fichier et l'ajouter à Firestore
      final fileModel = FileModel(
        id: '',  // Firestore attribuera l'ID
        projectId: currentProjectId.value,
        name: fileName,
        url: fileUrl,
        type: FileType.values.firstWhere((e) => e.toString() == 'FileType.$detectedType'),  // Utilisation du `FileType` de votre modèle
        size: file.lengthSync(),
        uploadedBy: _authController.currentUser!.id,
        uploadedAt: DateTime.now(),
      );

      await _firebaseService.addProjectFile(fileModel);

      // Rafraîchir la liste des fichiers
      await fetchFiles();
    } catch (e) {
      errorMessage.value = 'Erreur lors de l\'upload du fichier : ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteFile(String fileId, String fileUrl, String projectId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Delete from storage
      await _storageService.deleteFile(fileUrl);

      // Delete record from Firestore
      await _firebaseService.deleteProjectFile(fileId, projectId);

      // Refresh files list
      await fetchFiles();
    } catch (e) {
      errorMessage.value = 'Failed to delete file: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<int> _getMaxFileSizeByRole() async {
    const int MB = 1024 * 1024;

    switch (_authController.currentUser!.role) {
      case 'admin':
        return 100 * MB; // 100MB pour les administrateurs
      case 'manager':
        return 50 * MB; // 50MB pour les chefs de projet
      default:
        return 20 * MB; // 20MB pour les membres de l'équipe
    }
  }

  // Get file extension from name
  String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  // Check if file is an image
  bool isImage(String fileName) {
    final ext = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  // Check if file is a PDF
  bool isPdf(String fileName) {
    return getFileExtension(fileName) == 'pdf';
  }

  // Méthode pour charger les fichiers d'un projet
  Future<void> loadProjectFiles(String projectId) async {
    currentProjectId.value = projectId;
    await fetchFiles();  // Appelle la méthode existante pour récupérer les fichiers
  }
  // Méthode pour télécharger un fichier
  Future<void> downloadFile(FileModel file) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Récupérer l'URL du fichier depuis Firebase Storage
      final firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .refFromURL(file.url);

      // Obtenir le répertoire où sauvegarder le fichier
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDocDir.path}/${file.name}';

      // Télécharger le fichier
      await ref.writeToFile(File(filePath));

      // Confirmer le téléchargement
      Get.snackbar('Succès', 'Fichier téléchargé avec succès : $filePath');
    } catch (e) {
      errorMessage.value = 'Erreur lors du téléchargement du fichier: ${e.toString()}';
      Get.snackbar('Erreur', 'Une erreur est survenue lors du téléchargement du fichier.');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour choisir un fichier et le télécharger
  Future<FileUploadResult> pickAndUploadFile(String projectId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Ouvrir la boîte de dialogue pour choisir un fichier
      final result = await picker.FilePicker.platform.pickFiles();

      if (result == null) {
        return FileUploadResult(success: false, message: 'Aucun fichier sélectionné.');
      }

      final file = result.files.single;

      // Vérifier si un fichier a bien été choisi
      if (file.path == null) {
        return FileUploadResult(success: false, message: 'Le fichier sélectionné est invalide.');
      }

      // Télécharger le fichier
      await uploadFile(File(file.path!), file.name, file.extension ?? 'other');

      return FileUploadResult(success: true);
    } catch (e) {
      return FileUploadResult(success: false, message: 'Erreur lors de l\'upload : ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  // Variable pour stocker le chemin temporaire du fichier téléchargé
  final RxString tempFilePath = ''.obs;  // chemin du fichier temporaire téléchargé

  // Méthode pour charger un fichier dans tempFilePath
  Future<void> loadFileForViewing(FileModel file) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Télécharger le fichier depuis Firebase Storage ou un autre service
      final firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .refFromURL(file.url);

      // Récupérer le répertoire où sauvegarder le fichier
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDocDir.path}/${file.name}';

      // Télécharger le fichier et le sauvegarder localement
      await ref.writeToFile(File(filePath));

      // Mettre à jour tempFilePath avec le chemin du fichier téléchargé
      tempFilePath.value = filePath;
      // Si le fichier est un fichier texte, charger son contenu
      if (FileUtils.isTextExtension(file.name)) {
        final textContent = await File(filePath).readAsString();
        textFileContent.value = textContent;
      }
    } catch (e) {
      errorMessage.value = 'Erreur lors du téléchargement du fichier : ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Variable pour stocker le fichier temporaire téléchargé
  final Rx<File?> tempFile = Rx<File?>(null); // Fichier temporaire téléchargé

  // Variable pour stocker le contenu des fichiers texte
  final RxString textFileContent = ''.obs; // Contenu du fichier texte


}
class FileUploadResult {
  final bool success;
  final String? message;

  FileUploadResult({required this.success, this.message});
}