import 'package:sqflite/sqflite.dart';

import '../models/tag.dart';
import 'database_helper.dart';

class TagRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Tag>> getAll() async {
    final db = await _helper.database;
    final rows = await db.query('tags', orderBy: 'LOWER(name) ASC');
    return rows.map(Tag.fromMap).toList();
  }

  Future<void> upsert(Tag tag) async {
    final db = await _helper.database;
    // UPDATE-then-INSERT instead of REPLACE: REPLACE deletes the row first,
    // which would cascade away every project_tags link of a merely renamed tag.
    final updated = await db
        .update('tags', tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
    if (updated == 0) {
      await db.insert('tags', tag.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort);
    }
  }

  /// Deleting a tag removes its links through ON DELETE CASCADE; projects stay.
  Future<void> delete(String id) async {
    final db = await _helper.database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  /// tagId -> number of projects using it.
  Future<Map<String, int>> usageCounts() async {
    final db = await _helper.database;
    final rows = await db.rawQuery(
        'SELECT tagId, COUNT(*) AS c FROM project_tags GROUP BY tagId');
    return {
      for (final r in rows) r['tagId'] as String: (r['c'] as num).toInt(),
    };
  }
}
