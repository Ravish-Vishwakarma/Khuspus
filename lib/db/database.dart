import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'db_path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get() async {
    if (_db != null) return _db!;

    final path = getDatabasePath();

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedDefaultSettings(db);
      },
    );

    return _db!;
  }

  // ------------------------
  // TABLE CREATION
  // ------------------------
  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE transcripts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        originalText TEXT NOT NULL,
        polishedText TEXT NOT NULL,
        audioPath TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE memories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        before TEXT NOT NULL UNIQUE,
        after TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY NOT NULL UNIQUE,
        value TEXT
      );
    ''');
  }

  // ------------------------
  // DEFAULT SETTINGS
  // ------------------------
  static Future<void> _seedDefaultSettings(Database db) async {
    const defaults = {
      'transcriptionModel': 'small.en',
      'aiModel': 'gemma3:1b',
      'launcherShortcut': 'Shift+Ctrl+L',
      'autoRefine': 'false',
      'wordsProcessed': '0',
      'aiCorrections': '0',
      'userName': 'UserName',
      'polish_prompt':
          '''You are an intelligent text refinement assistant inside a voice-to-text application.

Your job is to:

1. Detect whether the transcription contains a request to transform or format the text (e.g., summarize, rewrite formally, make it shorter, convert to markdown, create bullet points, turn into an email, etc.).
2. If a transformation request exists anywhere in the transcription, treat it as an instruction and perform that transformation.
3. Remove filler words, repetitions, and speech artifacts.
4. Correct grammar and spelling.
5. Improve clarity and structure.

Rules:
- If a transformation request is present, do not include the instruction text in the output.
- Only return the final processed result.
- Do not add commentary or explanations.
- If no transformation is requested, return a clean, polished version of the text.

TRANSCRIPTION:
"{{transcription}}"''',
    };

    for (final entry in defaults.entries) {
      await db.insert('settings', {
        'key': entry.key,
        'value': entry.value,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
