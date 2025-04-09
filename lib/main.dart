

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fall_mouhamadoulamine_l3gl_examen/controllers/file_controller.dart';
import 'package:fall_mouhamadoulamine_l3gl_examen/services/auth_service.dart';
import 'package:fall_mouhamadoulamine_l3gl_examen/services/firebase_service.dart';
import 'package:fall_mouhamadoulamine_l3gl_examen/services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/routes.dart';
import 'config/themes.dart';
import 'controllers/admin_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/project_controller.dart';
import 'controllers/task_controller.dart';
import 'controllers/user_controller.dart';
import 'controllers/notification_controller.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
const String defaultAdminPhotoUrl = 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialiser les services
  Get.put(StorageService(), permanent: true);
  Get.put(AuthService(), permanent: true);

  // Créer l'admin si besoin
  await _createDefaultAdminIfNeeded();

  // Notifications en arrière-plan
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Injection des controllers
  Get.put(AuthController(), permanent: true);
  Get.put(UserController(), permanent: true);
  Get.put(NotificationController(), permanent: true);
  Get.put(ProjectController(), permanent: true); // ✅ Ajouté
  Get.put(TaskController(), permanent: true);    // ✅ Ajouté
  Get.put(AdminController());
  Get.put(FileController());
  Get.put(UserController());

  runApp(MyApp());
}


/// Crée un utilisateur administrateur par défaut si c'est la première exécution
Future<void> _createDefaultAdminIfNeeded() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstRun = prefs.getBool('is_first_run') ?? true;

    if (isFirstRun) {
      print('Première exécution de l\'application - création de l\'admin par défaut');

      const String defaultAdminEmail = 'lfallamine26@gmail.com';
      const String defaultAdminPassword = 'passer123!';
      const String defaultAdminPhotoUrl = 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y';  // URL d'une photo de profil par défaut

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final QuerySnapshot adminCheck = await firestore
          .collection('users')
          .where('email', isEqualTo: defaultAdminEmail)
          .where('role', isEqualTo: UserRole.admin.toString().split('.').last)
          .get();

      if (adminCheck.docs.isEmpty) {
        try {
          // Créer l'utilisateur dans Firebase Authentication
          UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: defaultAdminEmail,
            password: defaultAdminPassword,
          );

          // Créer le profil administrateur dans Firestore avec la photo de profil
          final FirebaseService firebaseService = FirebaseService();
          await firebaseService.createDefaultAdminUser(
            uid: userCredential.user!.uid,
            email: defaultAdminEmail,
            profileImageUrl: defaultAdminPhotoUrl, // Ajouter l'URL de la photo par défaut
          );

          print('Utilisateur administrateur par défaut créé avec succès');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // Si l'email existe déjà dans Auth mais pas dans Firestore
            try {
              UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: defaultAdminEmail,
                password: defaultAdminPassword,
              );

              DocumentSnapshot userDoc = await firestore
                  .collection('users')
                  .doc(userCredential.user!.uid)
                  .get();

              if (!userDoc.exists) {
                final FirebaseService firebaseService = FirebaseService();
                await firebaseService.createDefaultAdminUser(
                  uid: userCredential.user!.uid,
                  email: defaultAdminEmail,
                  profileImageUrl: defaultAdminPhotoUrl, // Ajouter l'URL de la photo par défaut
                );
              }

              await FirebaseAuth.instance.signOut();
            } catch (loginError) {
              print('Erreur lors de la connexion à l\'utilisateur admin existant: $loginError');
            }
          } else {
            print('Erreur lors de la création de l\'utilisateur admin: ${e.code}');
          }
        } catch (e) {
          print('Erreur inattendue lors de la création de l\'utilisateur admin: $e');
        }
      }

      await prefs.setBool('is_first_run', false);
    }
  } catch (e) {
    print('Erreur lors de la vérification/création de l\'admin par défaut: $e');
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Projet Collaboratif',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system, // System controls light/dark theme
      initialRoute: '/splash',
      getPages: AppRoutes.routes,
      defaultTransition: Transition.fade,
      debugShowCheckedModeBanner: false,
    );
  }
}