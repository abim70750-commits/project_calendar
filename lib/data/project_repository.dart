import 'package:sqflite/sqflite.dart';

import '../models/project.dart';
import '../models/subtask.dart';
import '../models/tag.dart';
import 'database_helper.dart';

class ProjectRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Project>> getAll() async {
    final db = await _helper.database;
    final projectRows = await db.query('projects', orderBy: 'deadline ASC');
    final subtaskRows = await db.query('subtasks', orderBy: 'sortOrder ASC');
    final tagRows = await db.rawQuery('''
      SELECT pt.projectId AS projectId, t.id AS id, t.name AS name,
             t.colorHex AS colorHex, t.createdAt AS createdAt
      FROM project_tags pt JOIN tags t ON t.id = pt.tagId
      ORDER BY LOWER(t.name) ASC''');

    // One query per table, grouped in memory, avoids N+1 reads.
    final subs = <String, List<Subtask>>{};
    for (final row in subtaskRows) {
      final s = Subtask.fromMap(row);
      subs.putIfAbsent(s.projectId, () => []).add(s);
    }
    final tags = <String, List<Tag>>{};
    for (final row in tagRows) {
      tags
          .putIfAbsent(row['projectId'] as String, () => [])
          .add(Tag.fromMap(row));
    }
    return projectRows
        .map((r) => Project.fromMap(
              r,
              subs[r['id'] as String] ?? const [],
              tags[r['id'] as String] ?? const [],
            ))
        .toList();
  }

  Future<void> upsert(Project p) async {
    final db = await _helper.database;
    await db.transaction((txn) => _write(txn, p));
  }

  Future<void> delete(String id) async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      await txn.delete('project_tags', where: 'projectId = ?', whereArgs: [id]);
      await txn.delete('subtasks', where: 'projectId = ?', whereArgs: [id]);
      await txn.delete('projects', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Replaces every project atomically (import "replace"). Tags are kept
  /// because they are managed separately in the tag screen.
  Future<void> replaceAll(List<Project> projects) async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      await txn.delete('project_tags');
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

  /// "Reset all data": projects, subtasks, links and tags.
  Future<void> clear() async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      await txn.delete('project_tags');
      await txn.delete('subtasks');
      await txn.delete('projects');
      await txn.delete('tags');
    });
  }

  Future<void> _write(DatabaseExecutor txn, Project p) async {
    await txn.insert('projects', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    // Children are rewritten wholesale: simpler than diffing and keeps order exact.
    await txn.delete('subtasks', where: 'projectId = ?', whereArgs: [p.id]);
    for (final s in p.subtasks) {
      await txn.insert('subtasks', s.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await txn.delete('project_tags', where: 'projectId = ?', whereArgs: [p.id]);
    final tagIds = <String>{};
    for (final t in p.tags) {
      tagIds.add(await _resolveTagId(txn, t));
    }
    for (final tagId in tagIds) {
      await txn.insert('project_tags', {'projectId': p.id, 'tagId': tagId},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  /// Matches by id first, then by case-insensitive name, and only then creates
  /// the tag. Name matching keeps imported backups from duplicating tags.
  Future<String> _resolveTagId(DatabaseExecutor txn, Tag t) async {
    final byId =
        await txn.query('tags', where: 'id = ?', whereArgs: [t.id], limit: 1);
    if (byId.isNotEmpty) return t.id;
    final byName = await txn.query('tags',
        where: 'LOWER(name) = ?', whereArgs: [t.name.toLowerCase()], limit: 1);
    if (byName.isNotEmpty) return byName.first['id'] as String;
    await txn.insert('tags', t.toMap());
    return t.id;
  }
}
