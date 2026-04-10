import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';

/// Top-level background message handler for FCM.
/// MUST be a top-level function (not a class method) for background isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 1. Initialize Firebase in this isolate (required!)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Initialize local notifications in this isolate
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();
  await localNotifications.initialize(settings: initializationSettings);

  if (kDebugMode) {
    print("Background message received: ${message.messageId}");
  }

  // 3. Show local notification for data-only messages
  // (FCM "notification" messages are shown by OS automatically,
  //  but "data" messages need manual handling)
  if (message.data.isNotEmpty && message.notification == null) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          channelShowBadge: true,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final title = message.data['title'] ?? 'New Notification';
    final body =
        message.data['body'] ??
        message.data['description'] ??
        message.data['message'] ??
        '';

    if (body.isNotEmpty) {
      await localNotifications.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
        payload: message.data.toString(),
      );
    }
  }
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Initialize local notifications with POSITIONAL argument (v21 requirement)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(settings: initializationSettings);

    // 2. Request permissions for iOS and Android 13+
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Explicitly request notification permission for Android 13+
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();

      // Create notification channel for background/persistent alerts
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );
      await androidPlugin?.createNotificationChannel(channel);
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted notification permissions');
      }

      // Get the token (optional, for logging)
      String? token = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }

      // Subscribe to a generic topic for all users (for global broadcasts)
      await _messaging.subscribeToTopic('broadcast_all');

      // Subscribe to a generic topic for all users (legacy/compatible)
      await _messaging.subscribeToTopic('all_events');

      // Setup message listeners
      _setupInteractions();
    }
  }

  static void _setupInteractions() {
    // 1. Foreground messaging
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Received message in foreground');
      }
      _showLocalNotification(message);
    });

    // 2. Handling notification click when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message);
    });

    // 3. Handling notification click when app was terminated
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNavigation(message);
      }
    });
  }

  static void _handleNavigation(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification clicked, data: ${message.data}');
    }

    final screen = message.data['screen'];
    final eventId = message.data['eventId'];

    // We use a global key or a navigation context helper if available,
    // but often with GoRouter we can just use the context from a known place
    // or rely on the fact that the app will rebuild and redirect.
    // For simplicity in this static service, we'll use a global observer or
    // just document that the app should handle it on startup.
    
    // NOTE: In a real app, you'd integrate this with your GoRouter instance.
    // Since this is a static service, we'll try to use the navigator key if available
    // or store the pending navigation for the shell to pick up.
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          channelShowBadge: true,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final title =
        message.notification?.title ??
        message.data['title'] ??
        'New Notification';
    final body =
        message.notification?.body ??
        message.data['body'] ??
        message.data['description'] ??
        message.data['message'] ??
        '';

    if (body.isNotEmpty) {
      await _localNotifications.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
        payload: message.data.toString(),
      );
    }
  }

  /// Subscribes the user to a topic for a specific event
  static Future<void> subscribeToEventTopic(String eventId) async {
    try {
      await _messaging.subscribeToTopic('event_$eventId');
    } catch (e) {
      if (kDebugMode) print('Subscription error: $e');
    }
  }

  /// Unsubscribes the user from a topic for a specific event
  static Future<void> unsubscribeFromEventTopic(String eventId) async {
    try {
      await _messaging.unsubscribeFromTopic('event_$eventId');
    } catch (e) {
      if (kDebugMode) print('Unsubscription error: $e');
    }
  }

  /// Track notification IDs that have already been shown locally to avoid duplicates
  static final Set<String> _shownNotificationIds = {};
  static String? _listeningUserId;

  /// Timestamp of when the listener was started — we only show notifications
  /// added AFTER this moment to avoid replaying old history on startup.
  static DateTime? _listenerStartedAt;

  /// Listens to the Firestore 'notifications' collection for the current user
  /// and shows a local notification for any document added AFTER listener start.
  static void startFirestoreListener(String userId) {
    if (userId.isEmpty || _listeningUserId == userId) return;
    _listeningUserId = userId;
    // Record the exact moment this session's listener begins.
    _listenerStartedAt = DateTime.now();

    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              final id = change.doc.id;

              if (data == null || _shownNotificationIds.contains(id)) continue;
              _shownNotificationIds.add(id);

              final createdAt = data['createdAt'] as Timestamp?;
              if (createdAt == null) continue;

              final notifTime = createdAt.toDate();

              // Only show if the document was created AFTER the listener started.
              // We allow a small 5s buffer for Firestore propagation delay.
              if (_listenerStartedAt != null &&
                  notifTime.isAfter(
                    _listenerStartedAt!.subtract(const Duration(seconds: 5)),
                  )) {
                _showLocalNotificationDirect(
                  id: id.hashCode,
                  title: data['title'] ?? 'New Update',
                  body: data['description'] ?? '',
                  payload: data['eventId'] ?? '',
                );
              }
            }
          }
        });
  }

  static Future<void> _showLocalNotificationDirect({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          channelShowBadge: true,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }
}
