import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class EnvManager {
  Future<Map<String, String>> _loadEnv() async {
    String jsonString = await rootBundle.loadString('lib/assets/env.json');
    Map<String, String> config = Map<String, String>.from(jsonDecode(jsonString));

    return config;
  }

  static Map<String, String>? _env;

  EnvManager._privateConstructor();

  static final EnvManager _busManager = EnvManager._privateConstructor();

  factory EnvManager() {
    return _busManager;
  }

  static Future<String> env(key) async {
    _env ??= await _busManager._loadEnv();
    return _env![key]!;
  }
}
