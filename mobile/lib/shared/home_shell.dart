import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    ('/listings', Icons.storefront_outlined, 'Marché'),
    ('/chat', Icons.chat_bubble_outline, 'Discussions'),
    ('/videos/record', Icons.videocam_outlined, 'Vidéos'),
    ('/security', Icons.security_outlined, 'Sécurité'),
    ('/employee/clock', Icons.badge_outlined, 'Pointage'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t.$1)).clamp(0, _tabs.length - 1);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: [
          for (final t in _tabs) NavigationDestination(icon: Icon(t.$2), label: t.$3),
        ],
      ),
    );
  }
}
