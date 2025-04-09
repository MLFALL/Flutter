import 'package:cloud_firestore/cloud_firestore.dart';

/// Types de rôles utilisateur disponibles dans l'application
enum UserRole { admin, projectManager, teamMember }

/// Statut d'activité d'un utilisateur
enum UserStatus { active, inactive }

/// Modèle représentant un utilisateur de l'application
class UserModel {
  final String id;
  final String email;
   String fullName;
  String? photoUrl;
  UserRole role;
  UserStatus status;
  bool isEmailVerified;
  final DateTime createdAt;
  DateTime lastLogin;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.photoUrl,
    required this.role,
    this.status = UserStatus.active,
    this.isEmailVerified = false,
    required this.createdAt,
    required this.lastLogin,
  });

  set name(String newName) => fullName = newName;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  /// Factory à utiliser quand tu charges depuis une liste `Map<String, dynamic>`
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      photoUrl: data['photoUrl'],
      role: UserRole.values.firstWhere(
            (e) => e.toString() == 'UserRole.${data['role'] ?? 'teamMember'}',
        orElse: () => UserRole.teamMember,
      ),
      status: UserStatus.values.firstWhere(
            (e) => e.toString() == 'UserStatus.${data['status'] ?? 'active'}',
        orElse: () => UserStatus.active,
      ),
      isEmailVerified: data['isEmailVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'role': role.toString().split('.').last,
      'status': status.toString().split('.').last,
      'isEmailVerified': isEmailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
    };
  }

  /// Crée une copie de l'objet avec des valeurs potentiellement mises à jour
  UserModel copyWith({
    String? email,
    String? fullName,
    String? photoUrl,
    UserRole? role,
    UserStatus? status,
    bool? isEmailVerified,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
  /// ✅ Getter pour connaître le statut actif
  bool get isActive => status == UserStatus.active;
}