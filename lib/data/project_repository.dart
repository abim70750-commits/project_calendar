import 'package:sqflite/sqflite.dart';

import '../models/project.dart';
import '../models/subtask.dart';
import 'database_helper.dart';

class ProjectRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Project>> getAll() async {
    final db = await _helper.database;
    final projectRows = await db.query('projects', orderBy: 'deadline ASC');
    final subtaskRows = await db.query('subtasks', orderBy: 'sortOrder ASC');
    // One query per table, grouped in memory, avoids N+1 reads.
    final grouped = <String, List<Subtask>>{};
    for (final row in subtaskRows) {
      final s = Subtask.fromMap(row);
      grouped.putIfAbsent(s.projectId, () => []).add(s);
    }
    return projectRows
        .map((r) => Project.fromMap(r, grouped[r['id'] as String] ?? const []))
        .toList();
  }

  Future<void> upsert(Project p) async {
    final db = await _helper.database;
    await db.transaction((txn) => _write(txn, p));
  }

  Future<void> delete(String id) async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      await txn.delete('subtasks', where: 'projectId = ?', whereArgs: [id]);
      await txn.delete('projects', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Wipes everything and inserts [projects] atomically (import "replace").
  Future<void> replaceAll(List<Project> projects) async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      await txn.delete('subtasks');
      await txn.delete('projects');
      for (final p in projects) {
        await _write(txn, p);
      }
    });
  }

  Future<void> upsertMany(List<Project> projects) async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      for (final p in projects) {
        await _write(txn, p);
      }
    });
  }

  Future<void> clear() => replaceAll(const []);

  Future<void> _write(DatabaseExecutor txn, Project p) async {
    await txn.insert('projects', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    // Subtasks are rewritten wholesale: simpler than diffing and keeps order exact.
    await txn.delete('subtasks', where: 'projectId = ?', whereArgs: [p.id]);
    for (final s in p.subtasks) {
      await txn.insert('subtasks', s.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}
