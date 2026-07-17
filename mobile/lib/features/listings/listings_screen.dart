import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../core/api/api_client.dart';
import '../../core/locale/locale_controller.dart';

class ListingsScreen extends ConsumerStatefulWidget {
  const ListingsScreen({super.key});

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> {
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
      final res = await ApiClient.instance.dio.get('/listings',
          queryParameters: {if (_cropFilter != null) 'cropType': _cropFilter});
      setState(() => _listings = res.data as List<dynamic>);
      await Hive.box('listings_cache').put('latest', res.data);
    } catch (_) {
      final cached = Hive.box('listings_cache').get('latest');
      if (cached != null) setState(() => _listings = List.from(cached));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: const Text('All / Tout'),
                    selected: _cropFilter == null,
                    onSelected: (_) { setState(() => _cropFilter = null); _load(); },
                  ),
                ),
                for (final c in _crops)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _cropFilter == c,
                      onSelected: (_) { setState(() => _cropFilter = c); _load(); },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _listings.isEmpty
                        ? Center(child: Text(s.noConnection))
                        : ListView.builder(
                            itemCount: _listings.length,
                            itemBuilder: (_, i) {
                              final l = _listings[i] as Map<String, dynamic>;
                              return ListTile(
                                leading: const Icon(Icons.eco_outlined,
                                    color: Color(0xFF1B7A3D)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF1B7A3D),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(s.newListing,
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
