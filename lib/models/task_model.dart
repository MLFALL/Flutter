import 'package:cloud_firestore/cloud_firestore.dart';

import 'comment_model.dart';

/// Priorité d'une tâche
enum TaskPriority { low, medium, high, urgent }

/// Statut d'une tâche
enum TaskStatus { todo, inProgress, completed, cancelled }

/// Modèle représentant une tâche dans l'application
class TaskModel {
  final String id;
  final String projectId;
  final String title;
  final String description;
  TaskStatus status;
  TaskPriority priority;
  final DateTime dueDate;
  final List<String> assignedTo;
  final String createdBy;
  double completionPercentage;
  final DateTime createdAt;
  DateTime updatedAt;

  final List<CommentModel> comments;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    this.status = TaskStatus.todo,
    required this.priority,
    required this.dueDate,
    required this.assignedTo,
    required this.createdBy,
    this.completionPercentage = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.comments = const [],
  });

  /// Crée une instance à partir d'un DocumentSnapshot Firestore
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: TaskStatus.values.firstWhere(
            (e) => e.toString() == 'TaskStatus.${data['status'] ?? 'todo'}',
        orElse: () => TaskStatus.todo,
      ),
      priority: TaskPriority.values.firstWhere(
            (e) => e.toString() == 'TaskPriority.${data['priority'] ?? 'medium'}',
        orElse: () => TaskPriority.medium,
      ),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      assignedTo: List<String>.from(data['assignedTo'] ?? []),
      createdBy: data['createdBy'] ?? '',
      completionPercentage: data['completionPercentage']?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      comments: [],
    );
  }

  /// Convertit l'instance en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'dueDate': Timestamp.fromDate(dueDate),
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'completionPercentage': completionPercentage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Crée une copie de l'objet avec des valeurs potentiellement mises à jour
  TaskModel copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    List<String>? assignedTo,
    double? completionPercentage,
    DateTime? updatedAt,
    String? projectId,
    List<CommentModel>? comments,
  }) {
    return TaskModel(
      id: this.id,
      projectId: projectId ?? this.projectId, // Assigner projectId si fourni, sinon garder l'existant
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: this.createdBy,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      comments: comments ?? this.comments,
    );
  }

  /// Calcule si la tâche est en retard
  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && status != TaskStatus.completed;
  }

  /// Calcule le nombre de jours restants jusqu'à la date d'échéance
  int get daysRemaining {
    final difference = dueDate.difference(DateTime.now()).inDays;
    return difference < 0 ? 0 : difference;
  }


}