import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../core/api/api_client.dart';

/// Wires the pre-built Stream Chat channel list UI to our backend's token
/// endpoint. Channels are auto-created server-side (see ChatService) when a
/// buyer first messages on a listing, or by region+crop group.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  StreamChatClient? _client;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final res = await ApiClient.instance.dio.post('/chat/token');
    final data = res.data as Map<String, dynamic>;

    const streamApiKey = String.fromEnvironment('STREAM_API_KEY');
    final client = StreamChatClient(streamApiKey);
    await client.connectUser(
      User(id: data['streamUserId'] as String),
      data['token'] as String,
    );
    setState(() => _client = client);
  }

  @override
  Widget build(BuildContext context) {
    if (_client == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamChat(
      client: _client!,
      child: Scaffold(
        appBar: AppBar(title: const Text('Discussions')),
        body: StreamChannelListView(
          controller: StreamChannelListController(
            client: _client!,
            filter: Filter.in_('members', [_client!.state.currentUser!.id]),
            channelStateSort: const [SortOption('last_message_at')],
          ),
          onChannelTap: (channel) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StreamChannel(
                channel: channel,
                child: Scaffold(
                  appBar: const StreamChannelHeader(),
                  body: const Column(
                    children: [
                      Expanded(child: StreamMessageListView()),
                      StreamMessageInput(), // supports text/image/voice notes/video out of the box
                    ],
                  ),
                ),
              ),
            ));
          },
        ),
      ),
    );
  }
}
