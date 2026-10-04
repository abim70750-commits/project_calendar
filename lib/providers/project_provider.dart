import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../models/project.dart';
import '../services/overdue_checker.dart';
import '../utils/date_utils.dart';

/// Runs [action] and reports any failure through a SnackBar instead of crashing.
Future<void> runGuarded(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }
}

class ProjectProvider extends ChangeNotifier {
  ProjectProvider(this._repo);

  final ProjectRepository _repo;
  List<Project> _projects = [];
  bool loading = true;
  String? loadError;

  List<Project> get projects => List.unmodifiable(_projects);

  Project? byId(String id) {
    for (final p in _projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Initial load: also runs the overdue check so stale flags are fixed on every startup.
  Future<void> load() async {
    try {
      await OverdueChecker.run(_repo);
      _projects = await _repo.getAll();
      loadError = null;
    } catch (e) {
      loadError = 'Gagal memuat data: $e';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _reload() async {
    _projects = await _repo.getAll();
    notifyListeners();
  }

  /// Projects shown on [day]. An overdue project keeps showing up until today
  /// so it stays visible on the calendar instead of silently disappearing.
  List<Project> projectsOn(DateTime day) {
    final d = dateOnly(day);
    final today = dateOnly(DateTime.now());
    return _projects.where((p) {
      var end = dateOnly(p.deadline);
      if (p.isOverdue && !p.isCompleted && today.isAfter(end)) end = today;
      return !d.isBefore(dateOnly(p.startDate)) && !d.isAfter(end);
    }).toList();
  }

  Future<void> save(Project p) async {
    await _repo.upsert(p.copyWith(updatedAt: DateTime.now()));
    await _reload();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _reload();
  }

  Future<void> resetAll() async {
    await _repo.clear();
    await _reload();
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'app': 'project_calendar',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'projects': _projects.map((p) => p.toJson()).toList(),
      });

  /// Parses first, writes second, so a malformed file can't wipe existing data.
  Future<int> importJson(String raw, {required bool replace}) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['projects'] is! List) {
      throw const FormatException('Format file tidak dikenali');
    }
    final imported = (decoded['projects'] as List)
        .map((e) => Project.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (replace) {
      await _repo.replaceAll(imported);
    } else {
      await _repo.upsertMany(imported);
    }
    await _reload();
    return imported.length;
  }
}
