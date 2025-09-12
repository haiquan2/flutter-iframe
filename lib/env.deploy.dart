class Env {
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://wm5090.pythera.ai/appv2',
  );

  static const sessionsUrl = String.fromEnvironment(
    'SESSIONS_URL',
    defaultValue: 'https://wm5090.pythera.ai/appv1/api/v1/sessions/',

  );
}
