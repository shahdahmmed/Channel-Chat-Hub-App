import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
import 'channel_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    print('Handling background message: ${message.data}');
    // You can also implement custom logic here to display local notifications
    // For example, you could use a package like flutter_local_notifications
    // to show a local notification in the background
  }




class ChannelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  late final FirebaseAnalyticsObserver observer ;
  final FlutterLocalNotificationsPlugin _localNotification = FlutterLocalNotificationsPlugin();



  ChannelService() {
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
   _initializeFirebaseMessaging();
    observer = FirebaseAnalyticsObserver(analytics: _analytics);

  }
  Future<void> setup() async {
  
    // Android-specific notification channel
    const channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high,
    );
    await _localNotification
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotification.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (details) {
     
    });

  }
Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotification.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['type'].toString(),
      );
    }
  }

  void _initializeFirebaseMessaging() async {
    await _firebaseMessaging.requestPermission();  // Request permission for iOS notifications
    


    // Handle notifications when the app is in the foreground
    FirebaseMessaging.onMessage.listen((message) {
      print('Foreground message received: ${message.notification?.title}');
      showNotification(message);
    });
    

    // Handle notifications when the app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Background Notification: ${message.data}');
      // Handle the notification tap here if necessary
    });
    setup();

    // Get device FCM token (for sending notifications to specific devices)
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
  }
// Show notification dialog when app is in the foreground



  // Create a new channel
  Future<Channel> createChannel({
    required String name, 
    required String creatorId,
  }) async {
    final channelId = const Uuid().v4();
    final channel = Channel(
      id: channelId,
      name: name,
      subscribedUserIds: [creatorId],
    );

    await _firestore.collection('channels').doc(channelId).set(channel.toFirestore());
    return channel;
  }
  Future<void> logSubscriptionEvent(String channel, bool isSubscribed) async {
    _analytics.setAnalyticsCollectionEnabled(true);
    await _analytics.logEvent(
      name: isSubscribed ? 'channel_subscribed' : 'channel_unsubscribed',
      parameters: {
        'channel_name': channel,
        'user_id': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    print(isSubscribed
        ? "Logged channel_subscribed for $channel"
        : "Logged channel_unsubscribed for $channel");
  }

  // Subscribe to a channel
  Future<void> subscribeToChannel(String channelId, String userId) async {
    await _firestore.collection('channels').doc(channelId).update({
      'subscribedUserIds': FieldValue.arrayUnion([userId])
    });
   DocumentSnapshot channelRef =await _firestore.collection('channels').doc(channelId).get();
   await _firebaseMessaging.subscribeToTopic(channelRef['name']);
     logSubscriptionEvent(channelRef['name'], true);

   
  }

  // Unsubscribe from a channel
  Future<void> unsubscribeFromChannel(String channelId, String userId) async {
    await _firestore.collection('channels').doc(channelId).update({
      'subscribedUserIds': FieldValue.arrayRemove([userId])
    });
   DocumentSnapshot channelRef =await _firestore.collection('channels').doc(channelId).get();
   await _firebaseMessaging.unsubscribeFromTopic(channelRef['name']);
    logSubscriptionEvent(channelRef['name'], false);
}

  // Get all channels

  Stream<List<Channel>> getAllChannels() {
    return _firestore.collection('channels')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Channel.fromFirestore(doc))
        .toList());
  }

  // Get user's subscribed channels
  Stream<List<Channel>> getUserChannels(String userId) {
    return _firestore.collection('channels')
        .where('subscribedUserIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Channel.fromFirestore(doc))
        .toList());
  }

  // Check if a user is subscribed to a channel
  Future<bool> isUserSubscribed(String channelId, String userId) async {
    final doc = await _firestore.collection('channels').doc(channelId).get();
    final channel = Channel.fromFirestore(doc);
    return channel.subscribedUserIds.contains(userId);
  }
}