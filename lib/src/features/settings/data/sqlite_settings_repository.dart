import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'settings_repository.dart';

class SQLiteSettingsRepository implements SettingsRepository {
  final Database db;

  SQLiteSettingsRepository(this.db);

  static const String keySessionSize = 'sessionSize';
  static const String keyTheme = 'theme';
  static const String keyModel = 'model';
  static const String keyLastSource = 'lastSource';

  Future<String?> _getValue(String key) async {
    final maps = await db.query(
      'settings',
      columns: ['value'],
      where: 'name = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> _setValue(String key, dynamic value) async {
    final jsonValue = jsonEncode(value);
    await db.insert(
      'settings',
      {'name': key, 'value': jsonValue},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> getSessionSize() async {
    final raw = await _getValue(keySessionSize);
    if (raw == null) return 20;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is int && decoded >= 1 && decoded <= 100) {
        return decoded;
      }
    } catch (_) {}
    return 20;
  }

  @override
  Future<void> setSessionSize(int size) async {
    final clamped = size.clamp(1, 100);
    await _setValue(keySessionSize, clamped);
  }

  @override
  Future<String> getTheme() async {
    final raw = await _getValue(keyTheme);
    if (raw == null) return 'system';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is String && (decoded == 'system' || decoded == 'light' || decoded == 'dark')) {
        return decoded;
      }
    } catch (_) {}
    return 'system';
  }

  @override
  Future<void> setTheme(String theme) async {
    if (theme != 'system' && theme != 'light' && theme != 'dark') return;
    await _setValue(keyTheme, theme);
  }

  @override
  Future<String> getModel() async {
    final raw = await _getValue(keyModel);
    if (raw == null) return 'gemini-2.5-flash';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded.trim();
      }
    } catch (_) {}
    return 'gemini-2.5-flash';
  }

  @override
  Future<void> setModel(String model) async {
    await _setValue(keyModel, model.trim());
  }

  @override
  Future<String> getLastSource() async {
    final raw = await _getValue(keyLastSource);
    if (raw == null) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is String) return decoded;
    } catch (_) {}
    return '';
  }

  @override
  Future<void> setLastSource(String source) async {
    await _setValue(keyLastSource, source.trim());
  }
}
