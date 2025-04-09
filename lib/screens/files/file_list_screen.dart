// screens/files/file_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/file_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/file_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../utils/file_utils.dart';

class FileListScreen extends StatelessWidget {
  final FileController _fileController = Get.find<FileController>();
  final String projectId;

  FileListScreen({required this.projectId});

  @override
  Widget build(BuildContext context) {
    // Load files for this project when screen is opened
    _fileController.loadProjectFiles(projectId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Fichiers du Projet'),
      ),
      body: Obx(() {
        if (_fileController.isLoading.value) {
          return LoadingIndicator();
        }

        if (_fileController.files.isEmpty) {
          return EmptyState(
            title: 'Pas de fichiers',
            description: 'Aucun fichier dans ce projet',
            icon: Icons.insert_drive_file_outlined,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _fileController.files.length,
          itemBuilder: (context, index) {
            final file = _fileController.files[index];
            return _buildFileCard(context, file);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _uploadNewFile(),
        child: Icon(Icons.upload_file),
        tooltip: 'Télécharger un fichier',
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, FileModel file) {
    final String fileExtension = FileUtils.getFileExtension(file.name);
    final Color fileIconColor = FileUtils.getColorForFileType(fileExtension);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          FileUtils.getIconForFileType(fileExtension),
          color: fileIconColor,
          size: 40,
        ),
        title: Text(file.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              // Récupère l'instance du UserController avec Get.find()
              final userController = Get.find<UserController>();
              final userName = userController.getUserNameById(file.uploadedBy);

              return Text(
                'Ajouté par: ${userName.value}', // Utilisation de 'userName.value' pour obtenir la valeur de RxString
                style: TextStyle(fontSize: 12),
              );
            }),
            Text(
              'Le ${DateFormat('dd/MM/yyyy à HH:mm').format(file.uploadedAt)}',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              FileUtils.formatFileSize(file.size),
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove_red_eye),
              onPressed: () => _viewFile(file),
              tooltip: 'Visualiser',
            ),
            IconButton(
              icon: Icon(Icons.download),
              onPressed: () => _fileController.downloadFile(file),
              tooltip: 'Télécharger',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteFile(file),
              tooltip: 'Supprimer',
            ),
          ],
        ),
        onTap: () => _viewFile(file),
      ),
    );
  }

  void _viewFile(FileModel file) {
    final String fileExtension = FileUtils.getFileExtension(file.name);

    if (FileUtils.canPreview(fileExtension)) {
      Get.toNamed('/file-viewer', arguments: {'file': file});
    } else {
      Get.snackbar(
        'Aperçu non disponible',
        'Ce type de fichier ne peut pas être prévisualisé dans l\'application',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _uploadNewFile() async {
    final result = await _fileController.pickAndUploadFile(projectId);

    if (result.success) {
      Get.snackbar(
        'Téléchargement réussi',
        'Le fichier a été téléchargé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
      );
    } else {
      Get.snackbar(
        'Erreur de téléchargement',
        result.message ?? 'Une erreur est survenue',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  void _confirmDeleteFile(FileModel file) {
    Get.dialog(
      AlertDialog(
        title: Text('Supprimer le fichier'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${file.name}" ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _fileController.deleteFile(file.id, file.url, file.projectId);
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}