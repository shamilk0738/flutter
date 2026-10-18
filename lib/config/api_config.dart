/// Backend URL ഇവിടെ മാത്രം മാറ്റിയാൽ മതി.
///
/// Android emulator  : http://10.0.2.2:8000/api
/// iOS simulator     : http://127.0.0.1:8000/api
/// Real phone (WiFi) : http://<PC-IP>:8000/api
class ApiConfig {
  static const String baseUrl = 'http://192.168.1.102:8000/api';
  static const Duration timeout = Duration(seconds: 20);
}
