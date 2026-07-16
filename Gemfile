import 'package:flutter/material.dart';

/// Placeholder chat screen. Real chat (Stream Chat) will be wired in once
/// the Stream account is created and its API keys are added.
/// Keeping this screen in the app so the tab and navigation stay in place.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discussions')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('Chat coming soon', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'La messagerie sera activée dans une prochaine mise à jour.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
