import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  UserModel? _currentUser;
  final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 10);

  UserModel? get currentUser => _currentUser;

  Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userStr = prefs.getString('auth_user_cache');
    if (userStr != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userStr));
      } catch (_) {}
    }
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      _currentUser = null;
      await prefs.remove('auth_token');
      await prefs.remove('auth_user_cache');
    }
  }

  Future<void> _saveUserCache(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user_cache', jsonEncode({
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'phone': user.phone,
      'role': user.role,
      'balance': user.balance,
      'avatarUrl': user.avatarUrl,
    }));
  }

  String? get token => _token;

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // --- Auth APIs ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(_timeout);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final token = data['data']['token'];
      await setToken(token);
      if (data['data']['user'] != null) {
        final user = UserModel.fromJson(data['data']['user']);
        await _saveUserCache(user);
      }
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Login failed');
  }

  Future<Map<String, dynamic>> register(String email, String password, String name, String? phone) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
      }),
    ).timeout(_timeout);

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      final token = data['data']['token'];
      await setToken(token);
      if (data['data']['user'] != null) {
        final user = UserModel.fromJson(data['data']['user']);
        await _saveUserCache(user);
      }
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Registration failed');
  }

  Future<UserModel?> getProfile() async {
    if (_token == null) {
      _currentUser = null;
      return null;
    }

    // Try fetching fresh data from server
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profile}'),
        headers: _headers,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final user = UserModel.fromJson(data['data']);
          await _saveUserCache(user);
          return user;
        }
      }
    } catch (_) {}

    // Fallback to cache if request fails/pending
    return _currentUser;
  }

  Future<void> logout() async {
    await setToken(null);
  }

  // --- Game Catalog APIs ---

  Future<List<GameModel>> getGames({String? search, String? category}) async {
    var uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.games}');
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (category != null && category.isNotEmpty) queryParams['category'] = category;

    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(uri, headers: _headers).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List list = data['data'] ?? [];
        return list.map((g) => GameModel.fromJson(g)).toList();
      }
    }
    throw Exception('Failed to fetch games');
  }

  Future<GameModel> getGameBySlug(String slug) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.games}/$slug');
    final response = await http.get(uri, headers: _headers).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return GameModel.fromJson(data['data']);
      }
    }
    throw Exception('Failed to fetch game details');
  }

  // --- Transaction APIs ---

  Future<TransactionModel> createTransaction({
    required String productId,
    required String gameUserId,
    String? gameServerId,
    String paymentMethod = 'QRIS',
    String? email,
    String? phone,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.transactions}'),
      headers: _headers,
      body: jsonEncode({
        'productId': productId,
        'gameUserId': gameUserId,
        'gameServerId': gameServerId,
        'paymentMethod': paymentMethod,
        'email': email,
        'phone': phone,
        'notes': notes,
      }),
    ).timeout(_timeout);

    final data = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
      return TransactionModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to create transaction');
  }

  Future<List<TransactionModel>> getMyTransactions() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.transactions}'),
      headers: _headers,
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List list = data['data'] ?? [];
        return list.map((t) => TransactionModel.fromJson(t)).toList();
      }
    }
    throw Exception('Failed to fetch transaction history');
  }

  Future<TransactionModel> getTransactionDetail(String idOrInvoice) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.transactions}/$idOrInvoice'),
      headers: _headers,
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return TransactionModel.fromJson(data['data']);
      }
    }
    throw Exception('Failed to fetch transaction');
  }

  // --- Admin APIs ---

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminDashboard}'),
      headers: _headers,
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      }
    }
    throw Exception('Failed to fetch admin stats');
  }

  Future<List<TransactionModel>> getAdminTransactions({String? status, String? search}) async {
    var uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminTransactions}');
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (search != null) queryParams['search'] = search;
    if (queryParams.isNotEmpty) uri = uri.replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List list = data['data'] ?? [];
        return list.map((t) => TransactionModel.fromJson(t)).toList();
      }
    }
    throw Exception('Failed to fetch admin transactions');
  }

  Future<void> updateTransactionStatus(String id, String status) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminTransactions}'),
      headers: _headers,
      body: jsonEncode({'id': id, 'status': status}),
    ).timeout(_timeout);

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update transaction status');
    }
  }
}
