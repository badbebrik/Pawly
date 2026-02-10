class GoogleAuthConstants {
  const GoogleAuthConstants._();

// DEBUG constants!!! will be reset in GoogleCloud when released.
  static const String androidClientId =
      '924161373583-v03t8gqd06iu7pn4juu7qtsve6irqcio.apps.googleusercontent.com';
  static const String iosClientId =
      '924161373583-08tc3gb7qhfvnku046oj13qulugo6ak9.apps.googleusercontent.com';
  static const String iosReverseClientId =
      'com.googleusercontent.apps.924161373583-08tc3gb7qhfvnku046oj13qulugo6ak9';

  static const String serverClientId =
      String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
        defaultValue:
            '924161373583-qugnk1i3p4gtqfv2pg46tqjqi9f4a88a.apps.googleusercontent.com',
      );

  static bool get hasServerClientId => serverClientId.isNotEmpty;
}
