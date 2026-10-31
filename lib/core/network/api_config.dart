/// Configuration des URLs de l'API backend.
///
/// - **Web / desktop** : `localhost` fonctionne.
/// - **Émulateur Android** : remplacer par `http://10.0.2.2:8080`.
/// - **Appareil physique** : mettre l'IP LAN de la machine (ex. `http://192.168.1.20:8080`).
abstract final class ApiConfig {
  ApiConfig._();

  static const String host = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'localhost',
  );

  /// Port de l'API ; surchargeable pour passer par un proxy local.
  static const String port = String.fromEnvironment(
    'API_PORT',
    defaultValue: '8080',
  );

  static const String baseUrl = 'http://$host:$port';
  static const String apiUrl = '$baseUrl/api';
  static const String wsUrl = 'ws://$host:$port/ws';
}
