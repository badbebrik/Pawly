import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/home_branch_reset_controller.dart';
import '../widgets/home_bottom_navigation_bar.dart';

class HomePage extends ConsumerWidget {
  const HomePage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: HomeBottomNavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          final shouldResetBranch = ref
              .read(homeBranchResetControllerProvider.notifier)
              .consumeResetFor(index);
          navigationShell.goBranch(
            index,
            initialLocation:
                shouldResetBranch || index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
