import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

/// Types de notifications dans l'application
enum NotificationType {
  projectAssignment,
  taskAssignment,
  taskReminder,
  taskStatusChange,
  projectStatusChange,
  commentAdded,
  fileUploaded,
}

/// Service pour gérer les notifications dans l'application
class NotificationService {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialise le service de notifications
  Future<void> initialize() async {
    // Configurer les notifications locales
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Configurer les notifications FCM en arrière-plan
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Gérer les notifications FCM en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(
        title: message.notification?.title ?? 'Nouvelle notification',
        body: message.notification?.body ?? '',
      );
    });

    // Gérer le clic sur une notification FCM
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });
  }

  /// Gestionnaire de messages FCM en arrière-plan
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Notification reçue en arrière-plan: ${message.data}");
  }

  /// Affiche une notification locale
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Notifications',
      channelDescription: 'Notifications pour les tâches et projets',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
    );
  }

  /// Gère le clic sur une notification
  void _handleNotificationClick(RemoteMessage message) {
    if (message.data.containsKey('type')) {
      final String type = message.data['type'];

      switch (type) {
        case 'taskAssignment':
          final String taskId = message.data['taskId'] ?? '';
          if (taskId.isNotEmpty) {
            Get.toNamed('/task-details', arguments: taskId);
          }
          break;
        case 'projectAssignment':
          final String projectId = message.data['projectId'] ?? '';
          if (projectId.isNotEmpty) {
            Get.toNamed('/project-details', arguments: projectId);
          }
          break;
        default:
          Get.toNamed('/notifications');
      }
    }
  }

  /// Envoie une notification aux membres assignés à une tâche
  Future<void> sendTaskAssignmentNotification({
    required String taskId,
    required String taskTitle,
    required List<String> assignedUsers,
    required String senderName,
  }) async {
    try {
      for (String userId in assignedUsers) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
        if (!userDoc.exists) continue;

        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String? fcmToken = userData['fcmToken'];

        if (fcmToken != null) {
          await _firestore.collection('notifications').add({
            'userId': userId,
            'title': 'Nouvelle tâche assignée',
            'body': '$senderName vous a assigné la tâche: $taskTitle',
            'type': NotificationType.taskAssignment.toString().split('.').last,
            'taskId': taskId,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Erreur lors de l\'envoi des notifications: $e');
    }
  }

  /// Planifie une notification de rappel pour une tâche
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime dueDate,
    required String userId,
  }) async {
    try {
      // Créer une notification 24 heures avant la date d'échéance
      DateTime reminderTime = dueDate.subtract(const Duration(hours: 24));

      // Ignorer si la date de rappel est déjà passée
      if (reminderTime.isBefore(DateTime.now())) return;

      // Enregistrer le rappel dans Firestore
      await _firestore.collection('scheduled_notifications').add({
        'userId': userId,
        'taskId': taskId,
        'title': 'Rappel: $taskTitle',
        'body': 'Cette tâche doit être terminée dans 24 heures',
        'scheduledFor': Timestamp.fromDate(reminderTime),
        'sent': false,
      });

      // Note: Pour une implémentation complète, un Cloud Function Firebase serait nécessaire
      // pour envoyer les notifications à l'heure prévue
    } catch (e) {
      print('Erreur lors de la planification du rappel: $e');
    }
  }

  /// Récupère les notifications non lues pour l'utilisateur actuel
  Future<List<Map<String, dynamic>>> getUnreadNotificationsForCurrentUser() async {
    try {
      String? userId = _firebaseService.currentUserId;
      if (userId == null) return [];

      QuerySnapshot querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      })
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des notifications: $e');
      return [];
    }
  }

  /// Marque une notification comme lue
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Erreur lors du marquage de la notification: $e');
    }
  }
  Future<void> requestPermissions() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Permissions accordées : ${settings.authorizationStatus}');
  }

  Future<void> saveUserToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    } catch (e) {
      print('Erreur lors de la sauvegarde du token FCM : $e');
    }
  }

  Future<void> showLocalNotification(
      String id,
      String title,
      String body,
      Map<String, dynamic> data,
      ) async {
    await _showLocalNotification(title: title, body: body);
  }
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des notifications utilisateur : $e');
      return [];
    }
  }
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in querySnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Erreur lors du marquage de toutes les notifications comme lues : $e');
    }
  }
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Erreur lors de la suppression de la notification : $e');
    }
  }
  Future<void> clearAllNotifications(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Erreur lors de la suppression de toutes les notifications : $e');
    }
  }




}