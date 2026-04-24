import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/deep_links/invite_deep_link_parser.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../catalog/presentation/providers/pet_dictionaries_providers.dart';

const _minimumSplashDuration = Duration(seconds: 3);
const _initialLinkTimeout = Duration(seconds: 5);

enum AppStartupDestinationKind {
  authenticated,
  unauthenticated,
  invitePreview,
}

class AppStartupDestination {
  const AppStartupDestination._({
    required this.kind,
    this.inviteToken,
  });

  const AppStartupDestination.authenticated()
      : this._(kind: AppStartupDestinationKind.authenticated);

  const AppStartupDestination.authenticatedWithInvite(String token)
      : this._(
          kind: AppStartupDestinationKind.authenticated,
          inviteToken: token,
        );

  const AppStartupDestination.unauthenticated()
      : this._(kind: AppStartupDestinationKind.unauthenticated);

  const AppStartupDestination.unauthenticatedWithInvite(String token)
      : this._(
          kind: AppStartupDestinationKind.unauthenticated,
          inviteToken: token,
        );

  const AppStartupDestination.invitePreview(String token)
      : this._(
          kind: AppStartupDestinationKind.invitePreview,
          inviteToken: token,
        );

  final AppStartupDestinationKind kind;
  final String? inviteToken;
}

final appStartupProvider = FutureProvider<AppStartupDestination>((ref) async {
  debugPrint('[PawlyDeepLink][startup] begin');
  final launchFuture = ref.refresh(appLaunchProvider.future);
  final initialInviteTokenFuture = _readInitialInviteToken();
  final minimumSplashFuture = Future<void>.delayed(_minimumSplashDuration);

  final launch = await launchFuture;
  debugPrint('[PawlyDeepLink][startup] appLaunch=$launch');
  final initialInviteToken = await initialInviteTokenFuture;
  debugPrint(
    '[PawlyDeepLink][startup] initialInviteToken=${_maskToken(initialInviteToken)}',
  );

  if (launch == AppLaunchDestination.authenticated) {
    debugPrint('[PawlyDeepLink][startup] syncing dictionaries');
    await ref.read(petDictionariesSyncProvider.future);
  }

  await minimumSplashFuture;

  debugPrint('[PawlyDeepLink][startup] destination=$launch');
  return switch (launch) {
    AppLaunchDestination.authenticated =>
      initialInviteToken != null && initialInviteToken.isNotEmpty
          ? AppStartupDestination.authenticatedWithInvite(initialInviteToken)
          : const AppStartupDestination.authenticated(),
    AppLaunchDestination.unauthenticated =>
      initialInviteToken != null && initialInviteToken.isNotEmpty
          ? AppStartupDestination.unauthenticatedWithInvite(initialInviteToken)
          : const AppStartupDestination.unauthenticated(),
  };
});

Future<String?> _readInitialInviteToken() async {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    debugPrint('[PawlyDeepLink][startup] initialLink unsupported platform');
    return null;
  }

  try {
    debugPrint('[PawlyDeepLink][startup] getInitialLink start');
    final uri = await AppLinks()
        .getInitialLink()
        .timeout(_initialLinkTimeout, onTimeout: () => null);
    debugPrint(
      '[PawlyDeepLink][startup] getInitialLink uri=${describeInviteUri(uri)}',
    );
    return extractInviteToken(uri);
  } catch (error, stackTrace) {
    debugPrint('[PawlyDeepLink][startup] getInitialLink error=$error');
    debugPrintStack(stackTrace: stackTrace);
    return null;
  }
}

String _maskToken(String? token) {
  if (token == null || token.isEmpty) {
    return 'null';
  }
  if (token.length <= 8) {
    return '${token.length} chars';
  }
  return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
}
