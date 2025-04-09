import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un commentaire dans un fil de discussion
class CommentModel {
  final String id;
  final String taskId;
  final String userId;
  final String message;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.message,
    required this.createdAt,
  });

  /// Crée une instance à partir d'un DocumentSnapshot Firestore
  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convertit l'instance en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'userId': userId,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}