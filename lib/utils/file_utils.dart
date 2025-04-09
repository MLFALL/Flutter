// utils/file_utils.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

class FileUtils {
  /// Get file extension from file name
  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  /// Get appropriate icon for file type
  static IconData getIconForFileType(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return Icons.movie;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Icons.audio_file;
      case 'txt':
      case 'md':
        return Icons.article;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Get color for file type
  static Color getColorForFileType(String extension) {
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Colors.purple;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return Colors.red.shade800;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Colors.blue.shade800;
      case 'txt':
      case 'md':
        return Colors.grey.shade700;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }

  /// Format file size to human-readable format
  static String formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Check if file can be previewed in the app
  static bool canPreview(String extension) {
    return isImageExtension(extension) ||
        extension == 'pdf' ||
        isTextExtension(extension);
  }

  /// Check if extension is for an image file
  static bool isImageExtension(String extension) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp'];
    return imageExtensions.contains(extension);
  }

  /// Check if extension is for a text file
  static bool isTextExtension(String extension) {
    final textExtensions = ['txt', 'md', 'json', 'xml', 'html', 'css', 'js', 'dart'];
    return textExtensions.contains(extension);
  }

  /// Generate a unique file name
  static String generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    final extension = getFileExtension(originalName);
    final baseName = originalName.substring(0, originalName.lastIndexOf('.'));

    return '${baseName}_${timestamp}_$random.$extension';
  }

  /// Check if file size is within allowed limit based on user role
  static bool isFileSizeAllowed(int sizeInBytes, String userRole) {
    // Define size limits for different roles (in bytes)
    const limits = {
      'admin': 104857600, // 100 MB
      'projectManager': 52428800, // 50 MB
      'teamMember': 20971520, // 20 MB
      'guest': 5242880, // 5 MB
    };

    final limit = limits[userRole] ?? limits['guest']!;
    return sizeInBytes <= limit;
  }

  /// Get allowed file size for user role in human-readable format
  static String getAllowedFileSizeForRole(String userRole) {
    switch (userRole) {
      case 'admin':
        return '100 MB';
      case 'projectManager':
        return '50 MB';
      case 'teamMember':
        return '20 MB';
      case 'guest':
      default:
        return '5 MB';
    }
  }
}