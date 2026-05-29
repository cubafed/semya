/// App-wide constants. Change [ownerBootstrapSecret] before first production deploy.
class AppConstants {
  AppConstants._();

  static const String appName = 'Семья';

  /// Secret for creating the first family space (owner flow).
  /// Override via --dart-define=OWNER_SECRET=... in release builds.
  static const String ownerBootstrapSecret = String.fromEnvironment(
    'OWNER_SECRET',
    defaultValue: 'change-me-before-release',
  );

  static const int inviteCodeLength = 8;
  static const Duration inviteDefaultTtl = Duration(hours: 72);
  static const int messagesPageSize = 30;
}
