import 'package:cloud_firestore/cloud_firestore.dart';

/// Type de fichier pris en charge
enum FileType { image, pdf, document, other }

/// Modèle représentant un fichier partagé dans l'application
class FileModel {
  final String id;
  final String projectId;
  final String? taskId; // Peut être null si le fichier est associé seulement au projet
  final String name;
  final String url;
  final FileType type;
  final int size; // Taille en octets
  final String uploadedBy;
  final DateTime uploadedAt;

  FileModel({
    required this.id,
    required this.projectId,
    this.taskId,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  /// Crée une instance à partir d'un DocumentSnapshot Firestore
  factory FileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FileModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      taskId: data['taskId'],
      name: data['name'] ?? '',
      url: data['url'] ?? '',
      type: FileType.values.firstWhere(
            (e) => e.toString() == 'FileType.${data['type'] ?? 'other'}',
        orElse: () => FileType.other,
      ),
      size: data['size'] ?? 0,
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
    );
  }

  /// Convertit l'instance en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'taskId': taskId,
      'name': name,
      'url': url,
      'type': type.toString().split('.').last,
      'size': size,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  /// Détecte le type de fichier basé sur l'extension
  static FileType detectFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(extension)) {
      return FileType.image;
    } else if (extension == 'pdf') {
      return FileType.pdf;
    } else if (['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(extension)) {
      return FileType.document;
    } else {
      return FileType.other;
    }
  }

  /// Calcule une chaîne de caractères représentant la taille du fichier de manière lisible
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}