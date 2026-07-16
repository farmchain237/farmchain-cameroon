import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class LocaleController extends Notifier<Locale> {
  static const _boxKey = 'locale';

  @override
  Locale build() {
    final box = Hive.box('auth');
    final saved = box.get(_boxKey) as String?;
    return saved == 'fr' ? const Locale('fr', 'CM') : const Locale('en');
  }

  void toggle() {
    final next = state.languageCode == 'en' ? const Locale('fr', 'CM') : const Locale('en');
    Hive.box('auth').put(_boxKey, next.languageCode);
    state = next;
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);
