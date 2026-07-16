import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});
  final String listingId;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  Map<String, dynamic>? _listing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiClient.instance.dio.get('/listings/${widget.listingId}');
    setState(() => _listing = res.data as Map<String, dynamic>);
  }

  Future<void> _openChat() async {
    await ApiClient.instance.dio.post('/chat/channels/listing', data: {'listingId': widget.listingId});
    if (mounted) context.push('/chat');
  }

  @override
  Widget build(BuildContext context) {
    if (_listing == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l = _listing!;
    final videos = (l['videos'] as List<dynamic>? ?? []);

    return Scaffold(
      appBar: AppBar(title: Text('${l['cropType']} · Grade ${l['grade']}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${l['qtyKg']} kg disponible', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${l['pricePerKg']} XAF / kg'),
          const SizedBox(height: 16),
          Text('Vidéos de traçabilité', style: Theme.of(context).textTheme.titleLarge),
          if (videos.isEmpty) const Text('Aucune vidéo pour le moment'),
          for (final v in videos)
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: Text(v['type']),
              subtitle: Text(v['recordedAt']),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openChat,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Contacter le vendeur'),
          ),
        ],
      ),
    );
  }
}
