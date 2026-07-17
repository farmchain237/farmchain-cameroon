import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/locale/locale_controller.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _users = [];
  List<dynamic> _orders = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final usersRes = await ApiClient.instance.dio.get('/admin/users');
      final ordersRes = await ApiClient.instance.dio.get('/admin/orders');
      final statsRes = await ApiClient.instance.dio.get('/admin/stats');
      setState(() {
        _users = usersRes.data as List<dynamic>;
        _orders = ordersRes.data as List<dynamic>;
        _stats = statsRes.data as Map<String, dynamic>;
      });
    } catch (_) {
      // Show empty state if not yet connected
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.adminPanel),
        backgroundColor: const Color(0xFF1B7A3D),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: s.users),
            Tab(text: s.allOrders),
            Tab(text: s.revenue),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _UsersTab(users: _users, s: s, onRefresh: _loadData),
                _OrdersTab(orders: _orders, s: s),
                _StatsTab(stats: _stats, s: s),
              ],
            ),
    );
  }
}

// ── Users tab ────────────────────────────────────────────────────
class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.users, required this.s, required this.onRefresh});
  final List<dynamic> users;
  final dynamic s;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(child: Text(s.loading));
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, i) {
          final u = users[i] as Map<String, dynamic>;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1B7A3D),
              child: Text((u['fullName'] as String? ?? '?')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white)),
            ),
            title: Text(u['fullName'] ?? ''),
            subtitle: Text('${u['role']} · ${u['phone']}'),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _handleAction(context, action, u),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'suspend', child: Text(s.suspendUser)),
                PopupMenuItem(value: 'delete', child: Text(s.delete)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleAction(BuildContext context, String action, Map u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(action == 'suspend' ? s.suspendUser : s.delete),
        content: Text('${u['fullName']} — ${u['phone']}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: call /admin/users/:id/suspend or /admin/users/:id endpoint
            },
            child: Text(s.yes, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Orders tab ───────────────────────────────────────────────────
class _OrdersTab extends StatelessWidget {
  const _OrdersTab({required this.orders, required this.s});
  final List<dynamic> orders;
  final dynamic s;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return Center(child: Text(s.loading));
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final o = orders[i] as Map<String, dynamic>;
        return ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text('${o['listing']?['cropType'] ?? ''} — ${o['totalPriceXaf']} XAF'),
          subtitle: Text(o['status'] ?? ''),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(o['status'] as String? ?? '').withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(o['status'] ?? '',
                style: TextStyle(
                    color: _statusColor(o['status'] as String? ?? ''),
                    fontSize: 11)),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'RELEASED': return Colors.green;
      case 'ESCROWED': return Colors.blue;
      case 'DISPUTED': return Colors.red;
      default: return Colors.orange;
    }
  }
}

// ── Stats / Revenue tab ──────────────────────────────────────────
class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.stats, required this.s});
  final Map<String, dynamic> stats;
  final dynamic s;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatCard(label: s.totalUsers, value: '${stats['totalUsers'] ?? 0}',
              icon: Icons.people_outline, color: Colors.blue),
          const SizedBox(height: 12),
          _StatCard(label: s.activeListings, value: '${stats['activeListings'] ?? 0}',
              icon: Icons.storefront_outlined, color: const Color(0xFF1B7A3D)),
          const SizedBox(height: 12),
          _StatCard(label: s.revenue,
              value: '${stats['totalRevenueXaf'] ?? 0} XAF',
              icon: Icons.account_balance_wallet_outlined, color: Colors.orange),
          const SizedBox(height: 12),
          _StatCard(label: s.platformFee,
              value: '${stats['totalFeesXaf'] ?? 0} XAF',
              icon: Icons.percent_outlined, color: Colors.purple),
          const SizedBox(height: 12),
          _StatCard(label: s.disputes, value: '${stats['disputes'] ?? 0}',
              icon: Icons.gavel_outlined, color: Colors.red),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label, required this.value,
    required this.icon, required this.color,
  });
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 13)),
                Text(value, style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
