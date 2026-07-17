import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../l10n/app_strings.dart';

class LocaleController extends Notifier<AppLang> {
  static const _boxKey = 'locale';

  @override
  AppLang build() {
    final saved = Hive.box('auth').get(_boxKey) as String?;
    return _fromCode(saved);
  }

  AppLang _fromCode(String? code) {
    switch (code) {
      case 'fr': return AppLang.fr;
      case 'pcm': return AppLang.pcm;
      default: return AppLang.en;
    }
  }

  void setLang(AppLang lang) {
    final code = lang == AppLang.fr ? 'fr' : lang == AppLang.pcm ? 'pcm' : 'en';
    Hive.box('auth').put(_boxKey, code);
    state = lang;
  }

  Locale get locale {
    switch (state) {
      case AppLang.fr: return const Locale('fr', 'CM');
      case AppLang.pcm: return const Locale('en'); // closest Flutter locale
      case AppLang.en: return const Locale('en');
    }
  }

  S get strings => S(state);
}

final localeControllerProvider =
    NotifierProvider<LocaleController, AppLang>(LocaleController.new);

/// Convenience provider — gives S(currentLang) directly to any screen
final stringsProvider = Provider<S>((ref) {
  final lang = ref.watch(localeControllerProvider);
  return S(lang);
});
