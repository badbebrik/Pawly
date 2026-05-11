import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeBranchResetControllerProvider =
    NotifierProvider<HomeBranchResetController, Set<int>>(
  HomeBranchResetController.new,
);

class HomeBranchResetController extends Notifier<Set<int>> {
  static const int calendarBranchIndex = 0;
  static const int petsBranchIndex = 1;
  static const int settingsBranchIndex = 2;

  @override
  Set<int> build() => const <int>{};

  void requestResetAfterExternalNavigation() {
    state = <int>{
      ...state,
      petsBranchIndex,
      settingsBranchIndex,
    };
  }

  bool consumeResetFor(int branchIndex) {
    if (!state.contains(branchIndex)) {
      return false;
    }

    state = <int>{
      for (final index in state)
        if (index != branchIndex) index,
    };
    return true;
  }
}
