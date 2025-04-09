# fall_mouhamadoulamine_l3gl_examen

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Projet de Gestion de Projets Collaboratifs - Flutter & Firebase


## 📱 Vue d'ensemble

Application mobile de gestion de projets collaboratifs développée avec Flutter et Firebase. Cette application permet aux équipes de créer, gérer et suivre des projets collaboratifs avec un système complet de gestion des tâches, tableau Kanban, communication intégrée et tableau de bord analytique.

## ✨ Fonctionnalités

- **Authentification avancée**
    - Connexion/Inscription sécurisée par email et mot de passe
    - Vérification d'email et récupération de mot de passe
    - Gestion des rôles (admin, projectManager, teamMember)

- **Gestion de projets**
    - Création et gestion complète des projets
    - Tableau Kanban interactif
    - Statistiques et rapports de progression
    - Filtrage et recherche avancés

- **Gestion des tâches**
    - Création de tâches avec priorités et dates limites
    - Assignation à des membres spécifiques
    - Suivi de l'avancement en pourcentage
    - Commentaires et discussions par tâche

- **Tableau de bord analytique**
    - Vue d'ensemble personnalisée selon le rôle
    - Statistiques en temps réel
    - Graphiques interactifs
    - Pour les administrateurs: gestion des utilisateurs et performances d'équipe

- **Système de communication**
    - Fil de discussion pour chaque tâche
    - Système de mention des membres (@utilisateur)
    - Notifications internes

- **Gestion de fichiers**
    - Partage de documents au sein des projets et tâches
    - Prévisualisation des fichiers PDF et images
    - Stockage local efficient

- **Interface utilisateur**
    - Design moderne et intuitif
    - Support des thèmes clair/sombre
    - Interface adaptative pour différentes tailles d'écran
    - Animations fluides

## 🛠️ Technologies utilisées

- **Flutter** - Framework UI multiplateforme
- **GetX** - Gestion d'état, injection de dépendances et navigation
- **Firebase**
    - Firebase Authentication - Authentification sécurisée
    - Cloud Firestore - Base de données NoSQL en temps réel
- **Stockage local** - Pour les fichiers et images
- **Charts_flutter** - Pour les graphiques et visualisations
- **Path_provider** Pour la gestion du stockage local
- **Flutter_local_notifications** - Pour les notifications locales

## 📥 Installation

### Prérequis

- Flutter (dernière version stable)
- Dart SDK
- Android Studio (pour les émulateurs)
- Git

### Configuration

1. Clonez le dépôt:
   ```bash
   git clone https://github.com/MLFALL/Flutter.git
   cd fall_mouhamadoulamine_l3gl_examen
   ```

2. Installez les dépendances:
   ```bash
   flutter pub get
   ```

3. Configurez Firebase:
    - Créez un projet dans Firebase Console
    - Ajoutez les applications Android ,iOS et Web
    - Téléchargez les fichiers de configuration
    - Suivez les instructions d'installation de Firebase sur [firebase.flutter.dev](https://firebase.flutter.dev/docs/overview)

4. Lancez l'application:
   ```bash
   flutter run
   ```

## 📂 Structure du projet

```
fall_mouhamadoulamine_l3gl_examen/
│
├── lib/
│ ├── config/
│ │   ├── constants.dart
│ │   ├── routes.dart
│ │   └── themes.dart
│ │
│ ├── models/
│ │   ├── project_model.dart
│ │   ├── task_model.dart
│ │   ├── user_model.dart
│ │   ├── comment_model.dart
│ │   └── file_model.dart
│ │
│ ├── controllers/
│ │   ├── auth_controller.dart
│ │   ├── project_controller.dart
│ │   ├── task_controller.dart
│ │   ├── user_controller.dart
│ │   ├── file_controller.dart
│ │   ├── admin_controller.dart
│ │   └── notification_controller.dart
│ │
│ ├── screens/
│ │   ├── auth/
│ │   │   ├── login_screen.dart
│ │   │   ├── register_screen.dart
│ │   │   ├── forgot_password_screen.dart
│ │   │   └── profile_screen.dart
│ │   │
│ │   ├── projects/
│ │   │   ├── projects_list_screen.dart
│ │   │   ├── project_details_screen.dart
│ │   │   ├── create_project_screen.dart
│ │   │   └── kanban_board_screen.dart
│ │   │
│ │   ├── tasks/
│ │   │   ├── tasks_list_screen.dart
│ │   │   ├── task_details_screen.dart
│ │   │   └── create_task_screen.dart
│ │   │
│ │   ├── admin/
│ │   │   ├── admin_dashboard_screen.dart
│ │   │   └── manage_users_screen.dart
│ │   │
│ │   ├── files/
│ │   │   ├── file_list_screen.dart
│ │   │   └── file_viewer_screen.dart
│ │   │
│ │   ├── home_screen.dart
│ │   └── splash_screen.dart
│ │
│ ├── services/
│ │   ├── firebase_service.dart
│ │   ├── auth_service.dart
│ │   ├── storage_service.dart
│ │   ├── notification_service.dart
│ │   └── analytics_service.dart
│ │
│ ├── utils/
│ │   ├── helpers.dart
│ │   ├── validators.dart
│ │   ├── date_utils.dart
│ │   └── file_utils.dart
│ │
│ ├── widgets/
│ │   ├── common/
│ │   │   ├── custom_button.dart
│ │   │   ├── custom_text_field.dart
│ │   │   ├── loading_indicator.dart
│ │   │   ├── error_message.dart
│ │   │   └── empty_state.dart
│ │   │
│ │   ├── project/
│ │   │   ├── project_card.dart
│ │   │   ├── project_status_badge.dart
│ │   │   └── project_progress_chart.dart
│ │   │
│ │   ├── task/
│ │   │   ├── task_card.dart 
│ │   │   ├── task_priority_badge.dart
│ │   │   └── task_progress_indicator.dart
│ │   │
│ │   ├── user/
│ │   │   ├── user_avatar.dart
│ │   │   └── user_role_badge.dart
│ │   │
│ │   └── charts/
│ │       ├── project_status_chart.dart
│ │       └── team_performance_chart.dart
│ │
│ └── main.dart
│
├── assets/
│ ├── images/
│ │   ├── logo.png
│ │   ├── placeholder_avatar.png
│ │   └── welcome_illustration.png
│ │
│ ├── icons/
│ │   └── app_icon.png
│ │
│ └── fonts/
│     └── custom_font.ttf
│
├── pubspec.yaml
└── README.md
```

## 🔒 Sécurité

- **Authentification sécurisée** - Vérification d'email et protection par mot de passe
- **Règles Firestore** - Contrôle d'accès précis basé sur les rôles
- **Stockage local sécurisé** - Données sensibles chiffrées
- **Validation des entrées** - Protection contre les injections et autres vulnérabilités

## 🔄 Flux de travail Git

Nous utilisons un flux de travail basé sur les branches pour gérer le développement:

- `main` - Code de production
- `master` - Branche de développement principale
- `feature/*` - Fonctionnalités en cours de développement
- `bugfix/*` - Corrections de bugs
- `release/*` - Préparation des releases

## 📋 Convention de commits

Nous suivons la convention de commits [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - Nouvelle fonctionnalité
- `fix:` - Correction de bug
- `docs:` - Documentation
- `style:` - Formatage (pas de changement de code)
- `refactor:` - Refactorisation du code
- `test:` - Ajout ou modification de tests
- `chore:` - Tâches de maintenance


## 📖 Documentation

- [Rapport Technique](./docs/rapport_technique.pdf) - Architecture et choix de conception
- [Manuel d'Utilisation](./docs/manuel_utilisation.pdf) - Guide pour les utilisateurs finaux
- [Structure de la base de données](./docs/structure_firebase.pdf) - Documentation Firebase

## 🧪 Tests

L'application comprend plusieurs niveaux de tests:

- **Tests unitaires** - Pour les modèles et la logique métier
- **Tests de widget** - Pour les composants d'interface
- **Tests d'intégration** - Pour les flux complets

Pour exécuter les tests:
```bash
flutter test
```

## 🔜 Roadmap

- [ ] Intégration avec Google Calendar et autres services de calendrier
- [ ] Mode hors ligne amélioré
- [ ] Support de l'authentification biométrique
- [ ] Version Windows de l'application
- [ ] Importation/Exportation de projets

## 👥 Contribution

Les contributions sont les bienvenues! Veuillez suivre ces étapes:

1. Forkez le projet
2. Créez votre branche de fonctionnalité (`git checkout -b feature/amazing-feature`)
3. Committez vos changements (`git commit -m 'feat: Add amazing feature'`)
4. Poussez vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👏 Remerciements

- [Flutter](https://flutter.dev/) pour le framework incroyable
- [Firebase](https://firebase.google.com/) pour les services backend
- [GetX](https://github.com/jonataslaw/getx) pour la gestion d'état simplifiée
- [Flutter Community](https://flutter.dev/community) pour le support et les ressources

## 📞 Contact

Pour toute question ou suggestion, n'hésitez pas à ouvrir une issue ou à me contacter directement à [lfallamine26@gmail.com].

---

Développé avec ❤️ et Flutter