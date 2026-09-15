import 'package:flutter/material.dart';
import 'app.dart';
import 'core/network/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().initToken();
  runApp(const DrianStoreApp());
}
