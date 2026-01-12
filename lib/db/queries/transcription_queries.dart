import 'package:khuspus/db/database.dart';

Future<int> insertTranscript({
  required String originalText,
  required String polishedText,
  required String audioPath,
}) async {
  final db = await AppDatabase.get();

  return await db.insert('transcripts', {
    'originalText': originalText,
    'polishedText': polishedText,
    'audioPath': audioPath,
    'created_at': DateTime.now().millisecondsSinceEpoch,
  });
}
