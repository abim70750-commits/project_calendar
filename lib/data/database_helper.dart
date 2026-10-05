import 'package:sqflite/sqflite.dart';

/// Single shared SQLite connection. Used from both the UI isolate and the
/// alarm isolate, so it must open lazily and never assume UI state.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const int schemaVersion = 2;

  // Caching the Future (not the Database) stops two concurrent first callers
  // from both running the open/upgrade path.
  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _openGuarded();

  Future<Database> _openGuarded() async {
    try {
      return await _open();
    } catch (_) {
      // Allow a retry on the next call instead of caching a failed open forever.
      _opening = null;
      rethrow;
    }
  }

  Future<Database> _open() async {
    final path = '${await getDatabasesPath()}/project_calendar.db';
    return openDatabase(
      path,
      version: schemaVersion,
      // Cascade deletes only work when foreign keys are switched on per connection.
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE projects (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            startDate TEXT NOT NULL,
            deadline TEXT NOT NULL,
            progress INTEGER NOT NULL DEFAULT 0,
            notes TEXT NOT NULL DEFAULT '',
            isCompleted INTEGER NOT NULL DEFAULT 0,
            isOverdue INTEGER NOT NULL DEFAULT 0,
            priority TEXT NOT NULL DEFAULT 'none',
            isArchived INTEGER NOT NULL DEFAULT 0,
            customReminder TEXT NOT NULL DEFAULT '1,0',
            completedAt TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE subtasks (
            id TEXT PRIMARY KEY,
            projectId TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
            title TEXT NOT NULL,
            isDone INTEGER NOT NULL DEFAULT 0,
            sortOrder INTEGER NOT NULL DEFAULT 0
          )''');
        await db.execute('CREATE INDEX idx_subtasks_project ON subtasks(projectId)');
        await _createTagTables(db);
      },
      // sqflite already wraps onUpgrade in a transaction, so a failure rolls the whole step back.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              "ALTER TABLE projects ADD COLUMN priority TEXT NOT NULL DEFAULT 'none'");
          await db.execute(
              'ALTER TABLE projects ADD COLUMN isArchived INTEGER NOT NULL DEFAULT 0');
          // Old projects keep the previous behaviour: reminders at H-1 and day H.
          await db.execute(
              "ALTER TABLE projects ADD COLUMN customReminder TEXT NOT NULL DEFAULT '1,0'");
          await db.execute('ALTER TABLE projects ADD COLUMN completedAt TEXT');
          // Without this, already-finished projects would never reach the 7-day auto-archive rule.
          await db.execute(
              'UPDATE projects SET completedAt = updatedAt WHERE isCompleted = 1');
          await _createTagTables(db);
        }
      },
    );
  }

  static Future<void> _createTagTables(Database db) async {
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE project_tags (
        projectId TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
        tagId TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
        PRIMARY KEY (projectId, tagId)
      )''');
    await db.execute('CREATE INDEX idx_project_tags_tag ON project_tags(tagId)');
  }
}
