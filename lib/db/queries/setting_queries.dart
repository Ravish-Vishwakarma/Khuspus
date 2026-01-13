import 'package:khuspus/db/database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> setSetting(String key, String value) async {
  final db = await AppDatabase.get();

  await db.insert('settings', {
    'key': key,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<String?> getSetting(String key) async {
  final db = await AppDatabase.get();

  final result = await db.query(
    'settings',
    where: '"key" = ?',
    whereArgs: [key],
    limit: 1,
  );

  if (result.isEmpty) return null;
  return result.first['value'] as String;
}
