import 'package:sqflite/sqflite.dart';

/// Single shared SQLite connection. Used from both the UI isolate and the
/// alarm isolate, so it must open lazily and never assume UI state.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final path = '${await getDatabasesPath()}/project_calendar.db';
    final db = await openDatabase(
      path,
      version: 1,
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
      },
    );
    _db = db;
    return db;
  }
}
