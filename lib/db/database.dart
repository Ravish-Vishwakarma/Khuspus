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
      'autoRefine': 'false',
      'aiModel': 'gemma3:1b',
      'transcriptionModel': 'small.en',
      'wordsProcessed': '78',
      'aiCorrections': '1',
      'userName': 'Ravish Vishwakarma',
      'launcherShortcut': 'Shift+Meta+F24',
      'polish_prompt': '''
You are an expert editor. Polish the following text to be clear, concise, and grammatically perfect.
Do not add any commentary, just return the polished text.{{memory}}

Original text: "{{transcription}}"

If the user's text contains the keyword 'SYSTEM', treat the words following 'SYSTEM' as a direct command and perform that action on the text instead of polishing.
''',
    };

    for (final entry in defaults.entries) {
      await db.insert('settings', {
        'key': entry.key,
        'value': entry.value,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
