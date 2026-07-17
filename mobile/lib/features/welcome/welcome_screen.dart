import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/locale/locale_controller.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  AppLang? _selected;

  void _confirm() {
    if (_selected == null) return;
    ref.read(localeControllerProvider.notifier).setLang(_selected!);
    context.go('/auth/phone');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.agriculture, size: 80, color: Color(0xFF1B7A3D)),
              const SizedBox(height: 16),
              const Text(
                'AGROFAMILY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.bold,
                  color: Color(0xFF1B7A3D), letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connecting farmers, buyers & communities\n'
                'Reliant les agriculteurs, acheteurs et communautés\n'
                'Wi dey connect farm people, buyer dem na community',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              const Text(
                'Choose your language\nChoisissez votre langue\nPick de language wey yu want',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              _LangTile(flag: '🇬🇧', label: 'English',
                  selected: _selected == AppLang.en,
                  onTap: () => setState(() => _selected = AppLang.en)),
              const SizedBox(height: 12),
              _LangTile(flag: '🇫🇷', label: 'Français',
                  selected: _selected == AppLang.fr,
                  onTap: () => setState(() => _selected = AppLang.fr)),
              const SizedBox(height: 12),
              _LangTile(flag: '🇨🇲', label: 'Pidgin',
                  selected: _selected == AppLang.pcm,
                  onTap: () => setState(() => _selected = AppLang.pcm)),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: _selected == null ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF1B7A3D),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _selected == null
                      ? 'Select / Choisir / Pick'
                      : _selected == AppLang.fr
                          ? 'Continuer'
                          : _selected == AppLang.pcm
                              ? 'Kontinu'
                              : 'Continue',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: _selected == null ? Colors.grey : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1B7A3D) : Colors.white,
          border: Border.all(color: const Color(0xFF1B7A3D), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$flag  $label',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF1B7A3D)),
        ),
      ),
    );
  }
}
