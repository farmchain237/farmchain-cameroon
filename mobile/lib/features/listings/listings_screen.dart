import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../core/api/api_client.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  List<dynamic> _listings = [];
  bool _loading = true;
  String? _cropFilter;

  static const _crops = ['CACAO', 'CAFE', 'PLANTAIN', 'MAIS', 'TOMATE', 'MANIOC'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/listings', queryParameters: {
        if (_cropFilter != null) 'cropType': _cropFilter,
      });
      setState(() => _listings = res.data as List<dynamic>);
      // Cache last successful result for offline browsing.
      await Hive.box('listings_cache').put('latest', res.data);
    } catch (_) {
      // No signal — fall back to last cached listings so the farmer/buyer
      // isn't staring at a blank screen on 2G.
      final cached = Hive.box('listings_cache').get('latest');
      if (cached != null) setState(() => _listings = List.from(cached));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marché')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(label: 'Tout', selected: _cropFilter == null, onTap: () {
                  setState(() => _cropFilter = null);
                  _load();
                }),
                for (final c in _crops)
                  _FilterChip(label: c, selected: _cropFilter == c, onTap: () {
                    setState(() => _cropFilter = c);
                    _load();
                  }),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      itemCount: _listings.length,
                      itemBuilder: (_, i) {
                        final l = _listings[i] as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.eco_outlined),
                          title: Text('${l['cropType']} — Grade ${l['grade']}'),
                          subtitle: Text('${l['qtyKg']} kg · ${l['pricePerKg']} XAF/kg'),
                          onTap: () => context.push('/listings/${l['id']}'),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}
