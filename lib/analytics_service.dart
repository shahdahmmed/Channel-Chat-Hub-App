import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Log channel subscription event
  Future<void> logChannelSubscription(String channelId, bool subscribed) async {
    await _analytics.logEvent(
      name: 'channel_subscription',
      parameters: {
        'channel_id': channelId,
        'subscribed': subscribed,
      },
    );
  }

  // Log first-time login
  Future<void> logFirstTimeLogin(String userId) async {
    await _analytics.setUserId(id: userId);
    await _analytics.logLogin(loginMethod: 'email');
  }

  // Log message sent event
  Future<void> logMessageSent(String channelId) async {
    await _analytics.logEvent(
      name: 'message_sent',
      parameters: {
        'channel_id': channelId,
      },
    );
  }

  // Log channel creation
  Future<void> logChannelCreation(String channelId) async {
    await _analytics.logEvent(
      name: 'channel_created',
      parameters: {
        'channel_id': channelId,
      },
    );
  }
}