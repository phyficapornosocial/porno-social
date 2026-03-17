import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static late Box<dynamic> _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('ps_cache');
  }

  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final cached = _box.get('user_$uid');
    if (cached == null) return null;

    final map = Map<String, dynamic>.from(
      cached['data'] as Map<dynamic, dynamic>,
    );
    final ts = cached['ts'] as int;

    final ageMs = DateTime.now().millisecondsSinceEpoch - ts;
    if (ageMs > 10 * 60 * 1000) {
      await _box.delete('user_$uid');
      return null;
    }

    return map;
  }

  static Future<void> setUser(String uid, Map<String, dynamic> data) async {
    await _box.put('user_$uid', {
      'data': data,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> clearAll() async {
    await _box.clear();
  }
}
