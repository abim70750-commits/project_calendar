import 'package:flutter/material.dart';

import '../data/tag_repository.dart';
import '../models/tag.dart';

class TagProvider extends ChangeNotifier {
  /// [onChanged] lets the project list re-read its embedded tags after a
  /// rename or delete, without the two providers knowing about each other.
  TagProvider(this._repo, {this.onChanged});

  final TagRepository _repo;
  final Future<void> Function()? onChanged;

  List<Tag> _tags = [];
  Map<String, int> _usage = {};
  String? loadError;

  List<Tag> get tags => List.unmodifiable(_tags);

  int usageOf(String tagId) => _usage[tagId] ?? 0;

  Tag? byId(String id) {
    for (final t in _tags) {
      if (t.id == id) return t;
    }
    return null;
  }

  bool nameExists(String name, {String? exceptId}) {
    final n = name.trim().toLowerCase();
    return _tags.any((t) => t.id != exceptId && t.name.toLowerCase() == n);
  }

  Future<void> load() async {
    try {
      _tags = await _repo.getAll();
      _usage = await _repo.usageCounts();
      loadError = null;
    } catch (e) {
      loadError = e.toString();
    }
    notifyListeners();
  }

  /// Creates or updates; callers wrap this in runGuarded to surface errors.
  Future<void> save(Tag tag) async {
    await _repo.upsert(tag);
    await load();
    await onChanged?.call();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
    await onChanged?.call();
  }
}
