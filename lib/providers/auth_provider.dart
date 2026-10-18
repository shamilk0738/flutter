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
    _api.onSessionExpired = _expire;
  }

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
