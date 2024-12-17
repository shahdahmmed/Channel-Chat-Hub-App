import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize notification settings
  Future<void> initNotifications() async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        String? token = await _messaging.getToken();
        
        // Save token to Firestore for the current user
        await _saveTokenToFirestore(token);

        // Setup message listeners
        _setupForegroundMessageHandler();
        _setupBackgroundMessageHandler();
      }
    } catch (e) {
      _logNotificationError(e);
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('user_tokens').doc(currentUser.uid).set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
      }, SetOptions(merge: true));
    } catch (e) {
      _logNotificationError(e);
    }
  }

  // Handle foreground messages
  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleIncomingMessage(message, isForeground: true);
    });
  }

  // Setup background message handler
  void _setupBackgroundMessageHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleIncomingMessage(message, isForeground: false);
    });
  }

  // Comprehensive message handling
  void _handleIncomingMessage(RemoteMessage message, {bool isForeground = false}) {
    // Log message receipt
    _analytics.logEvent(
      name: 'notification_received',
      parameters: {
        'type': message.data['type'] ?? 'unknown',
        'channel': message.data['channel'] ?? 'global',
        'foreground': isForeground,
      },
    );

    // Extract notification details
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // Custom handling based on notification type
      switch (data['type']) {
        case 'channel_message':
          _handleChannelMessage(data);
          break;
        case 'system_alert':
          _handleSystemAlert(data);
          break;
        default:
          _handleGenericNotification(notification, data);
      }
    }
  }

  // Handle channel-specific messages
  void _handleChannelMessage(Map<String, dynamic> data) {
    // Additional logic for channel-specific messages
    print('Channel Message: ${data['message']}');
    // Could trigger local notification, update UI, etc.
  }

  // Handle system-wide alerts
  void _handleSystemAlert(Map<String, dynamic> data) {
    // System-wide notification handling
    print('System Alert: ${data['message']}');
  }

  // Generic notification handler
  void _handleGenericNotification(RemoteNotification notification, Map<String, dynamic> data) {
    print('Generic Notification: ${notification.title}');
  }

  // Subscribe to a specific channel/topic
  Future<void> subscribeToChannel(String channelId) async {
    try {
      await _messaging.subscribeToTopic(channelId);
      
      // Log channel subscription
      await _analytics.logEvent(
        name: 'channel_subscription',
        parameters: {'channel_id': channelId},
      );
    } catch (e) {
      _logNotificationError(e);
    }
  }

  // Unsubscribe from a channel/topic
  Future<void> unsubscribeFromChannel(String channelId) async {
    try {
      await _messaging.unsubscribeFromTopic(channelId);
      
      // Log channel unsubscription
      await _analytics.logEvent(
        name: 'channel_unsubscription',
        parameters: {'channel_id': channelId},
      );
    } catch (e) {
      _logNotificationError(e);
    }
  }

  // Send custom notification to a specific channel
  Future<void> sendChannelNotification({
    required String channelId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // In a real-world scenario, this would typically be done via a server
      // Here we're simulating the process
      await _messaging.sendMessage(
        to: '/topics/$channelId',
        data: {
          'type': 'channel_message',
          'channel': channelId,
          'title': title,
          'body': body,
          ...?data,
        },
      );

      // Log notification send event
      await _analytics.logEvent(
        name: 'notification_sent',
        parameters: {
          'channel': channelId,
          'title': title,
        },
      );
    } catch (e) {
      _logNotificationError(e);
    }
  }

  // Error logging method
  void _logNotificationError(dynamic error) {
    print('Notification Service Error: $error');
    _analytics.logEvent(
      name: 'notification_error',
      parameters: {'error': error.toString()},
    );
  }
}