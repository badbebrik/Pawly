import 'package:flutter_riverpod/flutter_riverpod.dart';

final pendingDeepLinkTargetProvider =
    NotifierProvider<DeepLinkNavigationController, String?>(
  DeepLinkNavigationController.new,
);

class DeepLinkNavigationController extends Notifier<String?> {
  @override
  String? build() => null;

  void setPendingTarget(String target) {
    state = target;
  }

  void clear() {
    state = null;
  }
}
