import 'package:flutter/foundation.dart';

class ApiConstants {
  // Dynamic base URL depending on web host or localhost
  static String get baseUrl {
    // URL API akan di-inject otomatis via GitHub Actions Secret (--dart-define)
    // Jika tidak ada (misal run lokal), akan fallback ke localhost
    return const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000/api');
  }

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';

  static const String games = '/games';
  static const String transactions = '/transactions';
  
  static const String adminDashboard = '/admin/dashboard';
  static const String adminGames = '/admin/games';
  static const String adminProducts = '/admin/products';
  static const String adminTransactions = '/admin/transactions';
}
