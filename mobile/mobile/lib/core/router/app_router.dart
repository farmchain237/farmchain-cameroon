import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../features/auth/phone_entry_screen.dart';
import '../../features/auth/otp_verify_screen.dart';
import '../../features/listings/listings_screen.dart';
import '../../features/listings/listing_detail_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/videos/record_video_screen.dart';
import '../../features/security/security_tab_screen.dart';
import '../../features/employee/clock_in_screen.dart';
import '../../shared/home_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final loggedIn = Hive.box('auth').get('token') != null;

  return GoRouter(
    initialLocation: loggedIn ? '/listings' : '/auth/phone',
    routes: [
      GoRoute(path: '/auth/phone', builder: (_, __) => const PhoneEntryScreen()),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) => OtpVerifyScreen(phone: state.extra as String),
      ),
      ShellRoute(
        builder: (_, __, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/listings', builder: (_, __) => const ListingsScreen()),
          GoRoute(
            path: '/listings/:id',
            builder: (_, state) => ListingDetailScreen(listingId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/chat', builder: (_, __) => const ChatListScreen()),
          GoRoute(path: '/videos/record', builder: (_, __) => const RecordVideoScreen()),
          GoRoute(path: '/security', builder: (_, __) => const SecurityTabScreen()),
          GoRoute(path: '/employee/clock', builder: (_, __) => const ClockInScreen()),
        ],
      ),
    ],
  );
});
