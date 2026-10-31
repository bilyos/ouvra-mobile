import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/bookings/presentation/screens/booking_detail_screen.dart';
import '../../features/bookings/presentation/screens/booking_form_screen.dart';
import '../../features/bookings/presentation/screens/bookings_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/home/presentation/screens/all_categories_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/providers/presentation/screens/become_provider_screen.dart';
import '../../features/providers/presentation/screens/my_provider_profile_screen.dart';
import '../../features/providers/presentation/screens/provider_detail_screen.dart';
import '../../features/requests/presentation/screens/my_quotes_screen.dart';
import '../../features/requests/presentation/screens/my_requests_screen.dart';
import '../../features/requests/presentation/screens/new_request_screen.dart';
import '../../features/requests/presentation/screens/request_detail_screen.dart';
import '../../features/requests/presentation/screens/request_feed_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import 'app_routes.dart';

/// Configuration go_router. Un `StatefulShellRoute` gère la barre d'onglets
/// (Accueil / Recherche / Réservations / Messages / Profil), état préservé.
abstract final class AppRouter {
  AppRouter._();

  static final _rootKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, state) =>
            ResetPasswordScreen(email: state.extra as String?),
      ),
      GoRoute(
          path: AppRoutes.becomeProvider,
          builder: (_, __) => const BecomeProviderScreen()),
      GoRoute(
          path: AppRoutes.myProviderProfile,
          builder: (_, __) => const MyProviderProfileScreen()),
      GoRoute(
          path: AppRoutes.roleSelection,
          builder: (_, __) => const RoleSelectionScreen()),
      GoRoute(
          path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: AppRoutes.allCategories,
          builder: (_, __) => const AllCategoriesScreen()),
      GoRoute(path: AppRoutes.map, builder: (_, __) => const MapScreen()),
      GoRoute(
          path: AppRoutes.notifications,
          builder: (_, __) => const NotificationsScreen()),
      // Fil de demandes : les chemins fixes avant `/requests/:id`
      GoRoute(
        path: AppRoutes.newRequest,
        builder: (_, state) => NewRequestScreen(
            categoryId: state.uri.queryParameters['category']),
      ),
      GoRoute(
          path: AppRoutes.requestFeed,
          builder: (_, __) => const RequestFeedScreen()),
      GoRoute(
          path: AppRoutes.myRequests,
          builder: (_, __) => const MyRequestsScreen()),
      GoRoute(
        path: '/requests/:id',
        builder: (_, state) =>
            RequestDetailScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
          path: AppRoutes.myQuotes, builder: (_, __) => const MyQuotesScreen()),
      GoRoute(
        path: '/provider/:id',
        builder: (_, state) =>
            ProviderDetailScreen(providerId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'book',
            builder: (_, state) =>
                BookingFormScreen(providerId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (_, state) =>
            BookingDetailScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            conversationId: state.pathParameters['id']!,
            peerName: extra?['name'] as String?,
            peerAvatar: extra?['avatarUrl'] as String?,
          );
        },
      ),

      // Coquille avec barre d'onglets
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.search,
                builder: (_, __) => const SearchScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.bookings,
                builder: (_, __) => const BookingsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.chats,
                builder: (_, __) => const ChatListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
}
