import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';
import '../services/repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final Repository _repo = Repository.instance;

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;

  AuthProvider() {
    // Refresh token-ഉം expire ആയാൽ ഓട്ടോമാറ്റിക്കായി login screen-ലേക്ക്
    _api.onSessionExpired = _expire;
  }

  /// App തുറക്കുമ്പോൾ: സൂക്ഷിച്ച token ഉണ്ടോ എന്ന് നോക്കുന്നു
  Future<void> init() async {
    await _api.loadTokens();
    if (!_api.hasToken) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      user = await _repo.me();
      status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      // Network ഇല്ലാത്തതുകൊണ്ടാണെങ്കിൽ token കളയരുത്
      if (e.statusCode == 401) {
        await _api.clearTokens();
      }
      status = AuthStatus.unauthenticated;
    } catch (_) {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    await _repo.login(username, password);
    // phone, route എന്നിവ കിട്ടാൻ /me/ വിളിക്കുന്നു
    user = await _repo.me();
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.clearTokens();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _expire() {
    user = null;
    status = AuthStatus.unauthenticated;
    _api.clearTokens();
    notifyListeners();
  }
}
