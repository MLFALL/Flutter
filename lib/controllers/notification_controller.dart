import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';
import 'auth_controller.dart';

class NotificationController extends GetxController {
  final NotificationService _notificationService = NotificationService();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initializeNotifications();
  }

  Future<void> initializeNotifications() async {
    try {
      // Request permissions for notifications
      await _notificationService.requestPermissions();

      // Initialize Firebase Messaging
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Get token for this device
      String? token = await messaging.getToken();
      if (token != null && _authController.currentUser != null) {
        await _notificationService.saveUserToken(
            _authController.currentUser!.id,
            token
        );
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        if (_authController.currentUser != null) {
          _notificationService.saveUserToken(
              _authController.currentUser!.id,
              newToken
          );
        }
      });

      // Configure foreground messaging
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleNewNotification(message);
      });

      // Configure background/terminated state messaging
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // Load existing notifications for the user
      if (_authController.currentUser != null) {
        await fetchUserNotifications();
      }
    } catch (e) {
      errorMessage.value = 'Failed to initialize notifications: ${e.toString()}';
    }
  }

  // Handle incoming notification while app is open
  void _handleNewNotification(RemoteMessage message) {
    Map<String, dynamic> notificationData = {
      'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': message.notification?.title ?? 'New Notification',
      'body': message.notification?.body ?? '',
      'data': message.data,
      'timestamp': DateTime.now(),
      'read': false,
    };

    // Add to local notifications list
    notifications.insert(0, notificationData);

    // Increment unread counter
    unreadCount.value++;

    // Show local notification
    _notificationService.showLocalNotification(
      notificationData['id'],
      notificationData['title'],
      notificationData['body'],
      notificationData['data'],
    );
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // Extract data from notification
    Map<String, dynamic> data = message.data;

    // Navigate based on the notification type
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'project_update':
          if (data.containsKey('projectId')) {
            Get.toNamed('/projects/${data['projectId']}');
          }
          break;
        case 'task_update':
          if (data.containsKey('taskId')) {
            Get.toNamed('/tasks/${data['taskId']}');
          }
          break;
        case 'comment':
          if (data.containsKey('taskId')) {
            Get.toNamed('/tasks/${data['taskId']}?openComments=true');
          }
          break;
        case 'admin_alert':
          Get.toNamed('/admin/dashboard');
          break;
        default:
          Get.toNamed('/notifications');
      }
    }

    // Mark notification as read
    if (message.messageId != null) {
      markNotificationAsRead(message.messageId!);
    }
  }

  Future<void> fetchUserNotifications() async {
    if (_authController.currentUser == null) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      List<Map<String, dynamic>> userNotifications =
      await _notificationService.getUserNotifications(_authController.currentUser!.id);

      notifications.value = userNotifications;

      // Count unread notifications
      unreadCount.value = notifications.where((note) => note['read'] == false).length;
    } catch (e) {
      errorMessage.value = 'Failed to fetch notifications: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      // Update locally
      int index = notifications.indexWhere((note) => note['id'] == notificationId);
      if (index != -1 && notifications[index]['read'] == false) {
        notifications[index]['read'] = true;
        unreadCount.value--;

        // Update in database
        await _notificationService.markNotificationAsRead(notificationId);
      }
    } catch (e) {
      errorMessage.value = 'Failed to mark notification as read: ${e.toString()}';
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Update all notifications locally
      for (int i = 0; i < notifications.length; i++) {
        notifications[i]['read'] = true;
      }
      unreadCount.value = 0;

      // Update in database
      if (_authController.currentUser != null) {
        await _notificationService.markAllNotificationsAsRead(_authController.currentUser!.id);
      }
    } catch (e) {
      errorMessage.value = 'Failed to mark all notifications as read: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Remove from local list
      int index = notifications.indexWhere((note) => note['id'] == notificationId);
      if (index != -1) {
        if (notifications[index]['read'] == false) {
          unreadCount.value--;
        }
        notifications.removeAt(index);

        // Remove from database
        await _notificationService.deleteNotification(notificationId);
      }
    } catch (e) {
      errorMessage.value = 'Failed to delete notification: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Clear local notifications
      notifications.clear();
      unreadCount.value = 0;

      // Clear in database
      if (_authController.currentUser != null) {
        await _notificationService.clearAllNotifications(_authController.currentUser!.id);
      }
    } catch (e) {
      errorMessage.value = 'Failed to clear notifications: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to create notification snackbar
  void showNotificationSnackBar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 4),
      icon: Icon(Icons.notifications, color: Colors.white),
    );
  }
}

// This static function needs to be top-level (outside any class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background handling
  // await Firebase.initializeApp();

  // Handle the notification - usually just storing it for when the app opens
  // Implementation depends on your app's needs
  print("Handling a background message: ${message.messageId}");
}