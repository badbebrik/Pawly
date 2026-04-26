enum AppStartupDestinationKind {
  authenticated,
  unauthenticated,
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

  final AppStartupDestinationKind kind;
  final String? inviteToken;
}
