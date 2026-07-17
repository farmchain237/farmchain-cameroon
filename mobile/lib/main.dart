import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/locale/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('listings_cache');
  await Hive.openBox('pending_uploads');
  await Hive.openBox('auth');
  await initializeDateFormatting('en');
  await initializeDateFormatting('fr_CM');
  runApp(const ProviderScope(child: AgroFamilyApp()));
}

class AgroFamilyApp extends ConsumerWidget {
  const AgroFamilyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final localeCtrl = ref.watch(localeControllerProvider.notifier);

    return MaterialApp.router(
      title: 'AGROFAMILY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: localeCtrl.locale,
      supportedLocales: const [Locale('en'), Locale('fr', 'CM')],
      routerConfig: router,
    );
  }
}
