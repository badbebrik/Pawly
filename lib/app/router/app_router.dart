import 'package:go_router/go_router.dart';

import '../../core/network/session/auth_session_store.dart';
import '../../features/acl/presentation/pages/acl_access_page.dart';
import '../../features/acl/presentation/pages/acl_create_invite_page.dart';
import '../../features/acl/presentation/pages/acl_invite_details_page.dart';
import '../../features/acl/presentation/pages/acl_invite_preview_page.dart';
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

GoRouter buildAppRouter({required AuthSessionStore authSessionStore}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) async {
      final location = state.matchedLocation;
      final session = await authSessionStore.read();
      final isAuthenticated =
          session != null &&
          session.accessToken.isNotEmpty &&
          session.refreshToken.isNotEmpty;

      if (_isSplashRoute(location)) {
        return null;
      }

      if (!isAuthenticated && _isProtectedRoute(location)) {
        return AppRoutes.login;
      }

      if (isAuthenticated && _isPublicAuthRoute(location)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, state) => LoginPage(
          redirectLocation: state.uri.queryParameters['redirect'],
        ),
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
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'access',
                        name: 'aclAccess',
                        builder: (_, state) => AclAccessPage(
                          petId: state.pathParameters['petId']!,
                        ),
                        routes: <RouteBase>[
                          GoRoute(
                            path: 'invite',
                            name: 'aclCreateInvite',
                            builder: (_, state) => AclCreateInvitePage(
                              petId: state.pathParameters['petId']!,
                            ),
                          ),
                          GoRoute(
                            path: 'invites/:inviteId',
                            name: 'aclInviteDetails',
                            builder: (_, state) => AclInviteDetailsPage(
                              petId: state.pathParameters['petId']!,
                              inviteId: state.pathParameters['inviteId']!,
                            ),
                          ),
                        ],
                      ),
                    ],
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
      GoRoute(
        path: AppRoutes.aclInvitePreview,
        name: 'aclInvitePreview',
        builder: (_, state) => AclInvitePreviewPage(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
    ],
  );
}

bool _isSplashRoute(String location) => location == AppRoutes.splash;

bool _isPublicAuthRoute(String location) {
  return location == AppRoutes.login || location == AppRoutes.register;
}

bool _isProtectedRoute(String location) {
  return location == AppRoutes.postRegisterChoice ||
      location == AppRoutes.home ||
      location.startsWith('${AppRoutes.home}/') ||
      location == AppRoutes.guides ||
      location.startsWith('${AppRoutes.guides}/') ||
      location == AppRoutes.calendar ||
      location.startsWith('${AppRoutes.calendar}/') ||
      location == AppRoutes.pets ||
      location.startsWith('${AppRoutes.pets}/') ||
      location == AppRoutes.settings ||
      location.startsWith('${AppRoutes.settings}/') ||
      location == AppRoutes.petCreate ||
      location.startsWith('${AppRoutes.petCreate}/');
}
