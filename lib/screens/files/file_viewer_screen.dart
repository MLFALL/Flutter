// screens/files/file_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/file_controller.dart';
import '../../models/file_model.dart';
import '../../utils/file_utils.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_message.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // You'll need to add this package

class FileViewerScreen extends StatelessWidget {
  final FileController _fileController = Get.find<FileController>();

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = Get.arguments;
    final FileModel file = args['file'];

    return Scaffold(
      appBar: AppBar(
        title: Text(file.name),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _fileController.downloadFile(file),
            tooltip: 'Télécharger',
          ),
        ],
      ),
      body: Obx(() {
        if (_fileController.isLoading.value) {
          return LoadingIndicator();
        }

        if (_fileController.viewerError.value.isNotEmpty) {
          return ErrorMessage(
            message: _fileController.viewerError.value,
            onAction: () => _fileController.loadFileForViewing(file),  // Fonction de réessai
            actionText: 'Réessayer',
            isVisible: true,  // S'assurer que l'erreur est visible
          );
        }

        // Get file extension to determine how to display it
        final String fileExtension = FileUtils.getFileExtension(file.name);

        if (fileExtension == 'pdf') {
          return _buildPdfViewer();
        } else if (FileUtils.isImageExtension(fileExtension)) {
          return _buildImageViewer(file);
        } else if (FileUtils.isTextExtension(fileExtension)) {
          return _buildTextViewer();
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FileUtils.getIconForFileType(fileExtension),
                  size: 80,
                  color: FileUtils.getColorForFileType(fileExtension),
                ),
                SizedBox(height: 16),
                Text(
                  'Aperçu non disponible pour ce format de fichier',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _fileController.downloadFile(file),
                  child: Text('Télécharger le fichier'),
                ),
              ],
            ),
          );
        }
      }),
    );
  }

  Widget _buildPdfViewer() {
    return Container(
      child: PDFView(
        filePath: _fileController.tempFilePath.value,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
      ),
    );
  }

  Widget _buildImageViewer(FileModel file) {
    return Center(
      child: InteractiveViewer(
        panEnabled: true,
        boundaryMargin: EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 4,
        child: Image.file(
          _fileController.tempFile.value!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildTextViewer() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Text(
        _fileController.textFileContent.value,
        style: TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}