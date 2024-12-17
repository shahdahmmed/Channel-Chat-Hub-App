import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'channel_model.dart';
import 'channel_service.dart';
import 'chat_screen.dart';

class AvailableChannelsScreen extends StatelessWidget {
  final ChannelService _channelService = ChannelService();

  AvailableChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentUser = appProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Channels'),
      ),
      body: StreamBuilder<List<Channel>>(
        stream: _channelService.getAllChannels(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No channels available'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final channel = snapshot.data![index];
              
              return FutureBuilder<bool>(
                future: _channelService.isUserSubscribed(
                  channel.id, 
                  currentUser!.uid
                ),
                builder: (context, subscribedSnapshot) {
                  if (subscribedSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }

                  final isSubscribed = subscribedSnapshot.data ?? false;

                  return ListTile(
                    title: Text(channel.name),
                    trailing: isSubscribed
                        ? ElevatedButton(
                            onPressed: () {
                              appProvider.unsubscribeFromChannel(channel.id);
                            },
                            child: const Text('Unsubscribe'),
                          )
                        : OutlinedButton(
                            onPressed: () {
                              appProvider.subscribeToChannel(channel.id);
                            },
                            child: const Text('Subscribe'),
                          ),
                    onTap: isSubscribed
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(channel: channel),
                              ),
                            );
                          }
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}