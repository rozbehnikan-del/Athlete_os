class ApiConfig {
  const ApiConfig({this.baseUrl = defaultBaseUrl});

  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  final String baseUrl;
}
