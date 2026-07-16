import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/locale/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Offline-first local cache: listings, chat drafts, pending uploads survive
  // app kills on patchy 2G/3G. See core/api/offline_queue.dart for the retry logic.
  await Hive.initFlutter();
  await Hive.openBox('listings_cache');
  await Hive.openBox('pending_uploads');
  await Hive.openBox('auth');

  // NOTE: Firebase (push notifications) intentionally not initialized yet —
  // requires google-services.json from a Firebase account we haven't created.
  // Will be re-added when notifications are set up.
  await initializeDateFormatting('en');
  await initializeDateFormatting('fr_CM');

  runApp(const ProviderScope(child: FarmChainApp()));
}

class FarmChainApp extends ConsumerWidget {
  const FarmChainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: 'AGROFAMILY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: const [Locale('fr', 'CM'), Locale('en')],
      localizationsDelegates: const [
        // GlobalMaterialLocalizations.delegate, etc. — wire up flutter_localizations
        // plus generated AppLocalizations once .arb files are added under assets/i18n/.
      ],
      routerConfig: router,
    );
  }
}
