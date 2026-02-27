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
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/pets/presentation/pages/pet_details_page.dart';
import '../../features/pets/presentation/pages/pet_edit_page.dart';
import '../../features/pets/presentation/pages/pets_page.dart';
import '../../features/pet_create/presentation/pages/pet_create_flow_page.dart';
import '../../features/pet_care/presentation/pages/pet_metric_create_page.dart';
import '../../features/pet_care/presentation/pages/pet_metric_picker_page.dart';
import '../../features/pet_care/presentation/pages/pet_analytics_page.dart';
import '../../features/pet_care/presentation/pages/pet_health_home_page.dart';
import '../../features/pet_care/presentation/pages/pet_medical_records_page.dart';
import '../../features/pet_care/presentation/pages/pet_procedures_page.dart';
import '../../features/pet_care/presentation/pages/pet_vet_visits_page.dart';
import '../../features/pet_care/presentation/pages/pet_vaccinations_page.dart';
import '../../features/pet_care/presentation/pages/pet_log_create_page.dart';
import '../../features/pet_care/presentation/pages/pet_log_details_page.dart';
import '../../features/pet_care/presentation/pages/pet_log_edit_page.dart';
import '../../features/pet_care/presentation/pages/pet_log_type_picker_page.dart';
import '../../features/pet_care/presentation/pages/pet_log_type_create_page.dart';
import '../../features/pet_care/presentation/pages/pet_logs_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'app_routes.dart';

GoRouter buildAppRouter({required AuthSessionStore authSessionStore}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) async {
      final location = state.matchedLocation;
      final session = await authSessionStore.read();
      final isAuthenticated = session != null &&
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
        redirect: (_, __) => AppRoutes.pets,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomePage(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
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
                        path: 'edit',
                        name: 'petEdit',
                        builder: (_, state) => PetEditPage(
                          petId: state.pathParameters['petId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'log-types/create',
                        name: 'petLogTypeCreate',
                        builder: (_, state) => PetLogTypeCreatePage(
                          petId: state.pathParameters['petId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'log-types/pick',
                        name: 'petLogTypePicker',
                        builder: (_, state) => PetLogTypePickerPage(
                          petId: state.pathParameters['petId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'metrics/create',
                        name: 'petMetricCreate',
                        builder: (_, state) => PetMetricCreatePage(
                          petId: state.pathParameters['petId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'metrics/pick',
                        name: 'petMetricPicker',
                        builder: (_, state) => PetMetricPickerPage(
                          petId: state.pathParameters['petId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'health',
                        name: 'petHealthHome',
                        builder: (_, state) => PetHealthHomePage(
                          petId: state.pathParameters['petId']!,
                        ),
                        routes: <RouteBase>[
                          GoRoute(
                            path: 'visits',
                            name: 'petVetVisits',
                            builder: (_, state) => PetVetVisitsPage(
                              petId: state.pathParameters['petId']!,
                            ),
                            routes: <RouteBase>[
                              GoRoute(
                                path: ':visitId',
                                name: 'petVetVisitDetails',
                                builder: (_, state) => PetVetVisitDetailsPage(
                                  petId: state.pathParameters['petId']!,
                                  visitId: state.pathParameters['visitId']!,
                                ),
                              ),
                            ],
                          ),
                          GoRoute(
                            path: 'vaccinations',
                            name: 'petVaccinations',
                            builder: (_, state) => PetVaccinationsPage(
                              petId: state.pathParameters['petId']!,
                            ),
                            routes: <RouteBase>[
                              GoRoute(
                                path: ':vaccinationId',
                                name: 'petVaccinationDetails',
                                builder: (_, state) =>
                                    PetVaccinationDetailsPage(
                                  petId: state.pathParameters['petId']!,
                                  vaccinationId:
                                      state.pathParameters['vaccinationId']!,
                                ),
                              ),
                            ],
                          ),
                          GoRoute(
                            path: 'procedures',
                            name: 'petProcedures',
                            builder: (_, state) => PetProceduresPage(
                              petId: state.pathParameters['petId']!,
                            ),
                            routes: <RouteBase>[
                              GoRoute(
                                path: ':procedureId',
                                name: 'petProcedureDetails',
                                builder: (_, state) => PetProcedureDetailsPage(
                                  petId: state.pathParameters['petId']!,
                                  procedureId:
                                      state.pathParameters['procedureId']!,
                                ),
                              ),
                            ],
                          ),
                          GoRoute(
                            path: 'medical-records',
                            name: 'petMedicalRecords',
                            builder: (_, state) => PetMedicalRecordsPage(
                              petId: state.pathParameters['petId']!,
                            ),
                            routes: <RouteBase>[
                              GoRoute(
                                path: ':recordId',
                                name: 'petMedicalRecordDetails',
                                builder: (_, state) =>
                                    PetMedicalRecordDetailsPage(
                                  petId: state.pathParameters['petId']!,
                                  recordId: state.pathParameters['recordId']!,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'analytics',
                        name: 'petAnalytics',
                        builder: (_, state) => PetAnalyticsPage(
                          petId: state.pathParameters['petId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'logs',
                        name: 'petLogs',
                        builder: (_, state) => PetLogsPage(
                          petId: state.pathParameters['petId']!,
                        ),
                        routes: <RouteBase>[
                          GoRoute(
                            path: 'create',
                            name: 'petLogCreate',
                            builder: (_, state) => PetLogCreatePage(
                              petId: state.pathParameters['petId']!,
                            ),
                          ),
                          GoRoute(
                            path: ':logId',
                            name: 'petLogDetails',
                            builder: (_, state) => PetLogDetailsPage(
                              petId: state.pathParameters['petId']!,
                              logId: state.pathParameters['logId']!,
                            ),
                            routes: <RouteBase>[
                              GoRoute(
                                path: 'edit',
                                name: 'petLogEdit',
                                builder: (_, state) => PetLogEditPage(
                                  petId: state.pathParameters['petId']!,
                                  logId: state.pathParameters['logId']!,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
      location == AppRoutes.calendar ||
      location.startsWith('${AppRoutes.calendar}/') ||
      location == AppRoutes.pets ||
      location.startsWith('${AppRoutes.pets}/') ||
      location == AppRoutes.settings ||
      location.startsWith('${AppRoutes.settings}/') ||
      location == AppRoutes.petCreate ||
      location.startsWith('${AppRoutes.petCreate}/');
}
