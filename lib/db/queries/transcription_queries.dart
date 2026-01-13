import 'dart:io';

import 'package:khuspus/db/database.dart';

Future<int> insertTranscript({
  required String originalText,
  required String polishedText,
  required String audioPath,
}) async {
  final db = await AppDatabase.get();

  var id = await db.insert('transcripts', {
    'originalText': originalText,
    'polishedText': polishedText,
    'audioPath': audioPath,
    'created_at': DateTime.now().millisecondsSinceEpoch,
  });
  return id;
}

Future<int> updatePolishedTranscript({
  required int id,
  required String polishedText,
}) async {
  final db = await AppDatabase.get();

  var rid = await db.update(
    'transcripts',
    {'polishedText': polishedText},
    where: 'id = ?',
    whereArgs: [id],
  );
  return rid;
}

Future<List<Map<String, dynamic>>> loadTranscripts() async {
  final db = await AppDatabase.get();

  return await db.query('transcripts', orderBy: 'id DESC');
}

Future<void> deleteTranscripts(int id, String path) async {
  final file = File(path);

  if (await file.exists()) {
    await file.delete();
  }
  final db = await AppDatabase.get();
  await db.delete('transcripts', where: 'id = ?', whereArgs: [id]);
}
