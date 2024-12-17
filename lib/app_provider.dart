import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'channel_model.dart';
import 'channel_service.dart';
import 'auth_service.dart';

class AppProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChannelService _channelService = ChannelService();
  final AuthService _authService = AuthService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  User? get currentUser => _auth.currentUser;

  Stream<List<Channel>> getUserChannels() {
    if (currentUser == null) {
      return Stream.value([]);
    }
    return _channelService.getUserChannels(currentUser!.uid);
  }

  Future<void> createChannel(String name, String description) async {
    if (currentUser == null) {
      throw Exception('User must be logged in to create a channel');
    }

    final channel = await _channelService.createChannel(
      name: name, 
      creatorId: currentUser!.uid
    );

    // Log channel creation event
    await _analytics.logEvent(
      name: 'channel_created',
      parameters: {
        'channel_id': channel.id,
        'channel_name': channel.name,
      },
    );

    notifyListeners();
  }

  Future<void> subscribeToChannel(String channelId) async {
    if (currentUser == null) {
      throw Exception('User must be logged in to subscribe to a channel');
    }

    await _channelService.subscribeToChannel(channelId, currentUser!.uid);
    
    // Log channel subscription event
    await _analytics.logEvent(
      name: 'channel_subscribed',
      parameters: {
        'channel_id': channelId,
        'user_id': currentUser!.uid,
      },
    );

    notifyListeners();
  }

  Future<void> unsubscribeFromChannel(String channelId) async {
    if (currentUser == null) {
      throw Exception('User must be logged in to unsubscribe from a channel');
    }

    await _channelService.unsubscribeFromChannel(channelId, currentUser!.uid);
    
    // Log channel unsubscription event
    await _analytics.logEvent(
      name: 'channel_unsubscribed',
      parameters: {
        'channel_id': channelId,
        'user_id': currentUser!.uid,
      },
    );

    notifyListeners();
  }

  // Add sign out method
  Future<void> signOut() async {
    await _authService.signOut();
    notifyListeners();
  }

  // Ensure user display name
  String getUserDisplayName() {
    return currentUser?.displayName ?? 
           currentUser?.email?.split('@').first ?? 
           currentUser?.phoneNumber ?? 
           'Anonymous';
  }
}