import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import 'app_routes.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (_, __) => const HomePage(),
      ),
    ],
  );
}
