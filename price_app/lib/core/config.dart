/// Values are passed at build time: --dart-define-from-file=env.json
class Config {
  /// Local docker web is http://localhost:8080 and proxies /api.
  /// The image build overrides this with /api so the site stays on the same host.
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080/api');

  /// LINE Official Account ID including the leading @, e.g. @merichly
  static const lineOaId = String.fromEnvironment('LINE_OA_ID');
}
