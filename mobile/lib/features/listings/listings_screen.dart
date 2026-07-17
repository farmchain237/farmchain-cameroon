import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../core/api/api_client.dart';
import '../../core/l10n/app_strings.dart';
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

  static const _crops = [
    'CACAO', 'CAFE', 'PLANTAIN', 'MAIS', 'TOMATE', 'MANIOC'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/listings',
          queryParameters: {
            if (_cropFilter != null) 'cropType': _cropFilter
          });
      setState(() => _listings = res.data as List<dynamic>);
      await Hive.box('listings_cache').put('latest', res.data);
    } catch (_) {
      final cached = Hive.box('listings_cache').get('latest');
      if (cached != null) setState(() => _listings = List.from(cached));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Check user role from saved profile
  String get _userRole {
    final user = Hive.box('auth').get('user');
    if (user is Map) return user['role'] as String? ?? '';
    return '';
  }

  bool get _canCreateListing =>
      ['FARMER', 'ADMIN'].contains(_userRole);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeControllerProvider);

    // "All" label in each language
    final allLabel = lang == AppLang.fr
        ? 'Tout'
        : lang == AppLang.pcm
            ? 'Ɔl tin'
            : 'All';

    return Scaffold(
      body: Column(
        children: [
          // Crop filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(allLabel),
                    selected: _cropFilter == null,
                    onSelected: (_) {
                      setState(() => _cropFilter = null);
                      _load();
                    },
                  ),
                ),
                for (final c in _crops)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _cropFilter == c,
                      onSelected: (_) {
                        setState(() => _cropFilter = c);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Listings body
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _listings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.storefront_outlined,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(s.noConnection,
                                    style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _load,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(s.retry),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _listings.length,
                            itemBuilder: (_, i) {
                              final l = _listings[i] as Map<String, dynamic>;
                              return _ListingCard(listing: l, s: s);
                            },
                          ),
                  ),
          ),
        ],
      ),

      // Only show "New listing" button for sellers and admins
      floatingActionButton: _canCreateListing
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/listings/create'),
              backgroundColor: const Color(0xFF1B7A3D),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(s.newListing,
                  style: const TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.s});
  final Map<String, dynamic> listing;
  final S s;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/listings/${listing['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Crop icon
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B7A3D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.eco_outlined,
                    color: Color(0xFF1B7A3D), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${listing['cropType']} — Grade ${listing['grade']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${listing['qtyKg']} kg · ${listing['region']}',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${listing['pricePerKg']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1B7A3D)),
                  ),
                  Text('XAF/kg',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
