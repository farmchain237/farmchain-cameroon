import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n/app_strings.dart';
import '../core/locale/locale_controller.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final location = GoRouterState.of(context).uri.toString();

    final tabs = [
      ('/listings', Icons.storefront_outlined, s.marketplace),
      ('/chat', Icons.chat_bubble_outline, s.chat),
      ('/videos/record', Icons.videocam_outlined, s.videos),
      ('/security', Icons.security_outlined, s.security),
      ('/employee/clock', Icons.badge_outlined, s.clockIn),
      ('/settings', Icons.settings_outlined, s.settings),
    ];

    final currentIndex = tabs
        .indexWhere((t) => location.startsWith(t.$1))
        .clamp(0, tabs.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AGROFAMILY',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B7A3D))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          // Globe icon — quick language switcher
          IconButton(
            icon: const Icon(Icons.language, color: Color(0xFF1B7A3D)),
            tooltip: s.switchLanguage,
            onPressed: () => _showLanguagePicker(context, ref, s),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(tabs[i].$1),
        destinations: [
          for (final t in tabs)
            NavigationDestination(icon: Icon(t.$2), label: t.$3),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, S s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _LanguagePicker(),
    );
  }
}

class _LanguagePicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeControllerProvider);
    final ctrl = ref.read(localeControllerProvider.notifier);

    void pick(AppLang lang) {
      ctrl.setLang(lang);
      Navigator.pop(context);
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Language / Langue / Language',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _LangOption(flag: '🇬🇧', label: 'English',
              selected: current == AppLang.en,
              onTap: () => pick(AppLang.en)),
          const SizedBox(height: 8),
          _LangOption(flag: '🇫🇷', label: 'Français',
              selected: current == AppLang.fr,
              onTap: () => pick(AppLang.fr)),
          const SizedBox(height: 8),
          _LangOption(flag: '🇨🇲', label: 'Pidgin',
              selected: current == AppLang.pcm,
              onTap: () => pick(AppLang.pcm)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  const _LangOption({
    required this.flag, required this.label,
    required this.selected, required this.onTap,
  });
  final String flag, label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label, style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFF1B7A3D))
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: selected ? const Color(0xFF1B7A3D) : Colors.grey.shade200)),
    );
  }
}
