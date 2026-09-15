import 'package:flutter/foundation.dart';

class ApiConstants {
  // Dynamic base URL depending on web host or localhost
  static String get baseUrl {
    if (kIsWeb) {
      // Check if running on localhost (dev mode)
      // In production (Vercel), use relative /api path
      // In dev mode (localhost:8080 flutter), point to Node server on port 3000
      return const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000/api');
    }
    // Mobile / Android emulator URL
    return 'https://drians.vercel.app/api';
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
