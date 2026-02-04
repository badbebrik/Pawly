import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/post_register_choice_page.dart';
import '../../features/auth/presentation/pages/register_flow_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/guides/presentation/pages/guide_details_page.dart';
import '../../features/guides/presentation/pages/guides_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/pets/presentation/pages/pet_details_page.dart';
import '../../features/pets/presentation/pages/pets_page.dart';
import '../../features/pet_create/presentation/pages/pet_create_flow_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'app_routes.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (_, __) => const RegisterFlowPage(),
      ),
      GoRoute(
        path: AppRoutes.postRegisterChoice,
        name: 'postRegisterChoice',
        builder: (_, __) => const PostRegisterChoicePage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        redirect: (_, __) => AppRoutes.guides,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomePage(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.guides,
                name: 'guides',
                pageBuilder: (_, __) => const NoTransitionPage<void>(
                  child: GuidesPage(),
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':guideId',
                    name: 'guideDetails',
                    builder: (_, state) => GuideDetailsPage(
                      guideId: state.pathParameters['guideId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.calendar,
                name: 'calendar',
                pageBuilder: (_, __) => const NoTransitionPage<void>(
                  child: CalendarPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.pets,
                name: 'pets',
                pageBuilder: (_, __) => const NoTransitionPage<void>(
                  child: PetsPage(),
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':petId',
                    name: 'petDetails',
                    builder: (_, state) => PetDetailsPage(
                      petId: state.pathParameters['petId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                pageBuilder: (_, __) => const NoTransitionPage<void>(
                  child: SettingsPage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.petCreate,
        name: "petCreate",
        builder: (_, __) => const PetCreateFlowPage(),
      ),
    ],
  );
}
