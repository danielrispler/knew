import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SQLiteDatabaseHelper {
  static Database? _db;

  static const int currentSchemaVersion = 1;

  static Future<Database> getDatabase() async {
    if (_db != null && _db!.isOpen) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'knew.db');

    _db = await openDatabase(
      path,
      version: currentSchemaVersion,
      onCreate: (db, version) async {
        await createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await handleUpgrade(db, oldVersion, newVersion);
      },
    );
    return _db!;
  }

  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE words (
        id TEXT NOT NULL PRIMARY KEY,
        english TEXT NOT NULL CHECK (length(trim(english)) > 0),
        english_key TEXT NOT NULL UNIQUE CHECK (length(english_key) > 0),
        meanings TEXT NOT NULL,
        source TEXT,
        context TEXT,
        level INTEGER NOT NULL DEFAULT 0 CHECK (level BETWEEN 0 AND 6),
        due_date TEXT NOT NULL CHECK (length(due_date) = 10),
        last_reviewed_at TEXT,
        times_correct INTEGER NOT NULL DEFAULT 0 CHECK (times_correct >= 0),
        times_wrong INTEGER NOT NULL DEFAULT 0 CHECK (times_wrong >= 0),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE INDEX words_due_date ON words (due_date);
    ''');

    await db.execute('''
      CREATE TABLE settings (
        name TEXT NOT NULL PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
  }

  static Future<void> handleUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.transaction((txn) async {
      // Step-by-step non-destructive transactional migration handler
      // e.g. if (oldVersion < 2) { ... }
    });
  }
}
