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
  bool _navigating = false;

  // Fix 2: set language immediately on tap, not on Continue press
  // so by the time Continue is pressed, it's already saved
  void _selectLang(AppLang lang) {
    setState(() => _selected = lang);
    // Save immediately — don't wait for Continue button
    ref.read(localeControllerProvider.notifier).setLang(lang);
  }

  void _confirm() {
    if (_selected == null || _navigating) return;
    setState(() => _navigating = true);
    // Small delay to ensure Hive write completes before navigation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) context.go('/auth/phone');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Fix 1: SingleChildScrollView moves content up and handles small screens
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.agriculture,
                  size: 70, color: Color(0xFF1B7A3D)),
              const SizedBox(height: 12),
              const Text(
                'AGROFAMILY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B7A3D),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Connecting farmers, buyers & communities\n'
                'Reliant les agriculteurs, acheteurs et communautés\n'
                'Wi dey connect farm people, buyer dem na community',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              const Text(
                'Choose your language\n'
                'Choisissez votre langue\n'
                'Pick de language wey yu want',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              _LangTile(
                flag: '🇬🇧',
                label: 'English',
                selected: _selected == AppLang.en,
                onTap: () => _selectLang(AppLang.en),
              ),
              const SizedBox(height: 10),
              _LangTile(
                flag: '🇫🇷',
                label: 'Français',
                selected: _selected == AppLang.fr,
                onTap: () => _selectLang(AppLang.fr),
              ),
              const SizedBox(height: 10),
              _LangTile(
                flag: '🇨🇲',
                label: 'Pidgin',
                selected: _selected == AppLang.pcm,
                onTap: () => _selectLang(AppLang.pcm),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: (_selected == null || _navigating)
                    ? null
                    : _confirm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF1B7A3D),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _navigating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _selected == null
                            ? 'Select / Choisir / Pick'
                            : _selected == AppLang.fr
                                ? 'Continuer'
                                : _selected == AppLang.pcm
                                    ? 'Kontinu'
                                    : 'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _selected == null
                              ? Colors.grey
                              : Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
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
          border:
              Border.all(color: const Color(0xFF1B7A3D), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$flag  $label',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF1B7A3D),
          ),
        ),
      ),
    );
  }
}
