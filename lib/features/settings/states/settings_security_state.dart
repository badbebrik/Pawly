class SettingsSecurityState {
  const SettingsSecurityState({
    required this.isChangingPassword,
    required this.isLoggingOut,
  });

  factory SettingsSecurityState.initial() {
    return const SettingsSecurityState(
      isChangingPassword: false,
      isLoggingOut: false,
    );
  }

  final bool isChangingPassword;
  final bool isLoggingOut;

  SettingsSecurityState copyWith({
    bool? isChangingPassword,
    bool? isLoggingOut,
  }) {
    return SettingsSecurityState(
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    );
  }
}
