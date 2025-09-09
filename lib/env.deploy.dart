class Env {
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: '',
  );

  static const sessionsUrl = String.fromEnvironment(
    'SESSIONS_URL',
    defaultValue: '',
  );
}
