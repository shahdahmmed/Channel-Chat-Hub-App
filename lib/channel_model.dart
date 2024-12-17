import 'package:cloud_firestore/cloud_firestore.dart';

class Channel {
  final String id;
  final String name;
  final List<String> subscribedUserIds;

  Channel({
    required this.id,
    required this.name,
    this.subscribedUserIds = const [],
  });

  factory Channel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Channel(
      id: doc.id,
      name: data['name'] ?? '',
      subscribedUserIds: List<String>.from(data['subscribedUserIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'subscribedUserIds': subscribedUserIds,
    };
  }
}