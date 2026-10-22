import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// True once [init] completed. Every accessor below is null-safe, so calling
  /// them before init returns `null`/`false` instead of throwing.
  static bool get isReady => _prefs != null;

  /// Test hook: inject a `SharedPreferences` instance (e.g.
  /// `SharedPreferences.setMockInitialValues({})` + `getInstance()`).
  static void setInstanceForTesting(SharedPreferences? prefs) {
    _prefs = prefs;
  }

  // String
  static Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  // Bool
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  // Int
  static Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  // String list
  static Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  static List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  // Double
  static Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  static double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  // JSON Object
  static Future<bool> setObject(String key, Map<String, dynamic> value) async {
    return await _prefs?.setString(key, jsonEncode(value)) ?? false;
  }

  static Map<String, dynamic>? getObject(String key) {
    final String? data = _prefs?.getString(key);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  // Remove
  static Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  // Clear all
  static Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  // Check if key exists
  static bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }
}