import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _selectedLang;

  Future<void> _confirm() async {
    if (_selectedLang == null) return;
    await Hive.box('auth').put('locale', _selectedLang);
    if (mounted) context.go('/auth/phone');
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
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B7A3D),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connecting farmers, buyers & communities\nReliant les agriculteurs, acheteurs et communautés',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 56),
              const Text(
                'Choose your language / Choisissez votre langue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              _LangButton(
                flag: '🇬🇧',
                label: 'English',
                selected: _selectedLang == 'en',
                onTap: () => setState(() => _selectedLang = 'en'),
              ),
              const SizedBox(height: 16),
              _LangButton(
                flag: '🇫🇷',
                label: 'Français',
                selected: _selectedLang == 'fr',
                onTap: () => setState(() => _selectedLang = 'fr'),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _selectedLang == null ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF1B7A3D),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _selectedLang == null
                      ? 'Select a language / Choisir une langue'
                      : _selectedLang == 'en'
                          ? 'Continue'
                          : 'Continuer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedLang == null ? Colors.grey : Colors.white,
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

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1B7A3D) : Colors.white,
          border: Border.all(color: const Color(0xFF1B7A3D), width: 2),
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
