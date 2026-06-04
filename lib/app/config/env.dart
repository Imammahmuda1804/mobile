import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  const Env._();

  static String get apiBaseUrl {
    final value = dotenv.env['API_BASE_URL']?.trim();
    if (value == null || value.isEmpty) return 'http://192.168.1.10:3000';
    return value;
  }

  static String get webBaseUrl {
    final value = dotenv.env['WEB_BASE_URL']?.trim();
    if (value == null || value.isEmpty) return 'http://localhost:3001';
    return value.replaceFirst(RegExp(r'/$'), '');
  }
}
