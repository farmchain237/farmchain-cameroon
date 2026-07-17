import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/locale/locale_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final current = ref.watch(localeControllerProvider);
    final user = Hive.box('auth').get('user') as Map? ?? {};
    final role = user['role'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        children: [
          // Profile section
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1B7A3D),
              child: Text((user['fullName'] as String? ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white)),
            ),
            title: Text(user['fullName'] as String? ?? ''),
            subtitle: Text(user['phone'] as String? ?? ''),
          ),
          const Divider(),

          // Language section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(s.language,
                style: const TextStyle(fontWeight: FontWeight.bold,
                    color: Color(0xFF1B7A3D))),
          ),
          _LangTile(flag: '🇬🇧', label: 'English',
              selected: current == AppLang.en,
              onTap: () => ref.read(localeControllerProvider.notifier).setLang(AppLang.en)),
          _LangTile(flag: '🇫🇷', label: 'Français',
              selected: current == AppLang.fr,
              onTap: () => ref.read(localeControllerProvider.notifier).setLang(AppLang.fr)),
          _LangTile(flag: '🇨🇲', label: 'Pidgin',
              selected: current == AppLang.pcm,
              onTap: () => ref.read(localeControllerProvider.notifier).setLang(AppLang.pcm)),
          const Divider(),

          // Admin section — only visible to ADMIN role
          if (role == 'ADMIN') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(s.adminPanel,
                  style: const TextStyle(fontWeight: FontWeight.bold,
                      color: Color(0xFF1B7A3D))),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined,
                  color: Color(0xFF1B7A3D)),
              title: Text(s.adminPanel),
              subtitle: Text(s.auditUsers),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin'),
            ),
            const Divider(),
          ],

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(s.logout, style: const TextStyle(color: Colors.red)),
            onTap: () async {
              await Hive.box('auth').delete('token');
              await Hive.box('auth').delete('user');
              if (context.mounted) context.go('/welcome');
            },
          ),
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.flag, required this.label,
    required this.selected, required this.onTap,
  });
  final String flag, label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFF1B7A3D))
          : null,
      onTap: onTap,
    );
  }
}
