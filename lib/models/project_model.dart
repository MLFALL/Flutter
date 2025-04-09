import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fall_mouhamadoulamine_l3gl_examen/models/user_model.dart';

/// Statut d'un projet
enum ProjectStatus { pending, inProgress, completed, cancelled }

/// Niveau de priorité d'un projet
enum ProjectPriority { low, medium, high, urgent }

/// Modèle représentant un projet dans l'application
class ProjectModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  ProjectStatus status;
  ProjectPriority priority;
  final String createdBy;
  late final List<UserModel> members;
  final List<UserModel> teamMembers;
  double completionPercentage;
  final DateTime createdAt;
  DateTime updatedAt;



  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.status = ProjectStatus.pending,
    required this.priority,
    required this.createdBy,
    required this.members,
    this.teamMembers = const [],
    this.completionPercentage = 0.0,
    required this.createdAt,
    required this.updatedAt,

  });

  /// Crée une instance à partir d'un DocumentSnapshot Firestore
  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Conversion des membres en objets UserModel au lieu de String
    List<UserModel> membersList = [];
    if (data['members'] != null) {
      membersList = (data['members'] as List).map((item) {
        return UserModel.fromFirestore(item);  // Si UserModel a une méthode `fromFirestore`
      }).toList();
    }

    return ProjectModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: ProjectStatus.values.firstWhere(
            (e) => e.toString() == 'ProjectStatus.${data['status'] ?? 'pending'}',
        orElse: () => ProjectStatus.pending,
      ),
      priority: ProjectPriority.values.firstWhere(
            (e) => e.toString() == 'ProjectPriority.${data['priority'] ?? 'medium'}',
        orElse: () => ProjectPriority.medium,
      ),
      createdBy: data['createdBy'] ?? '',
      members: membersList,
      completionPercentage: data['completionPercentage']?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),

    );
  }

  /// Convertit l'instance en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'createdBy': createdBy,
      'members': members.map((u) => u.toFirestore()).toList(),
      'completionPercentage': completionPercentage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Crée une copie de l'objet avec des valeurs potentiellement mises à jour
  ProjectModel copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    ProjectStatus? status,
    ProjectPriority? priority,
    List<UserModel>? members,
    double? completionPercentage,
    DateTime? updatedAt,
    List<UserModel>? teamMembers,
  }) {
    return ProjectModel(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdBy: this.createdBy,
      members: members ?? this.members,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      teamMembers: teamMembers ?? this.teamMembers,
    );
  }

  /// Calcule si le projet est en retard
  bool get isOverdue {
    return DateTime.now().isAfter(endDate) && status != ProjectStatus.completed;
  }

  /// Calcule le nombre de jours restants jusqu'à la date d'échéance
  int get daysRemaining {
    final difference = endDate.difference(DateTime.now()).inDays;
    return difference < 0 ? 0 : difference;
  }

  /// Calcule le pourcentage de progression dans le temps du projet
  double get timeProgressPercentage {
    final totalDuration = endDate.difference(startDate).inDays;
    if (totalDuration == 0) return 100;

    final elapsedDuration = DateTime.now().difference(startDate).inDays;
    if (elapsedDuration < 0) return 0;
    if (elapsedDuration > totalDuration) return 100;

    return (elapsedDuration / totalDuration) * 100;
  }


  // Méthode pour calculer la progression du projet
  double calculateProgress() {
    final totalDuration = endDate.difference(startDate).inDays;
    if (totalDuration == 0) return 1.0; // Le projet est déjà terminé si la durée est 0

    final elapsedDuration = DateTime.now().difference(startDate).inDays;
    if (elapsedDuration < 0) return 0.0; // Avant le début du projet
    if (elapsedDuration > totalDuration) return 1.0; // Après la fin du projet

    return elapsedDuration / totalDuration;
  }

}