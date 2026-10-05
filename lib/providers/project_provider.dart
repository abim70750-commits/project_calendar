import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/project_repository.dart';
import '../models/project.dart';
import '../models/subtask.dart';
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

/// Lifecycle bucket used by the status filter and the statistics screen.
enum StatusFilter {
  all('Semua'),
  notStarted('Belum Mulai'),
  ongoing('Berlangsung'),
  completed('Selesai'),
  overdue('Overdue');

  const StatusFilter(this.label);
  final String label;
}

enum SortOption {
  deadlineAsc('Deadline terdekat'),
  deadlineDesc('Deadline terjauh'),
  startAsc('Tanggal mulai'),
  progressDesc('Progres tertinggi'),
  priorityDesc('Prioritas tertinggi'),
  createdDesc('Terbaru dibuat');

  const SortOption(this.label);
  final String label;
}

/// Maps a project to exactly one bucket (never [StatusFilter.all]).
StatusFilter bucketOf(Project p, [DateTime? now]) {
  if (p.isCompleted) return StatusFilter.completed;
  if (p.isOverdue) return StatusFilter.overdue;
  final today = dateOnly(now ?? DateTime.now());
  if (today.isBefore(dateOnly(p.startDate))) return StatusFilter.notStarted;
  return StatusFilter.ongoing;
}

class ProjectFilter {
  final StatusFilter status;
  final Priority? priority;
  final String? tagId;

  const ProjectFilter({this.status = StatusFilter.all, this.priority, this.tagId});

  bool get isDefault =>
      status == StatusFilter.all && priority == null && tagId == null;

  ProjectFilter copyWith({
    StatusFilter? status,
    Priority? priority,
    String? tagId,
    bool clearPriority = false,
    bool clearTag = false,
  }) =>
      ProjectFilter(
        status: status ?? this.status,
        priority: clearPriority ? null : (priority ?? this.priority),
        tagId: clearTag ? null : (tagId ?? this.tagId),
      );
}

class ProjectProvider extends ChangeNotifier {
  ProjectProvider(this._repo);

  final ProjectRepository _repo;
  List<Project> _projects = [];
  bool loading = true;
  String? loadError;

  String _query = '';
  ProjectFilter _filter = const ProjectFilter();
  SortOption _sort = SortOption.deadlineAsc;

  String get query => _query;
  ProjectFilter get filter => _filter;
  SortOption get sort => _sort;

  /// Every project including archived ones (statistics, exports).
  List<Project> get all => List.unmodifiable(_projects);

  List<Project> get active =>
      _projects.where((p) => !p.isArchived).toList(growable: false);

  /// Newest finished first, so what was just archived is at the top.
  List<Project> get archived {
    final list = _projects.where((p) => p.isArchived).toList();
    list.sort((a, b) => (b.completedAt ?? b.updatedAt)
        .compareTo(a.completedAt ?? a.updatedAt));
    return list;
  }

  Project? byId(String id) {
    for (final p in _projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---- search / filter / sort -------------------------------------------

  void setQuery(String value) {
    _query = value.trim();
    notifyListeners();
  }

  void setFilter(ProjectFilter value) {
    _filter = value;
    notifyListeners();
  }

  void setSort(SortOption value) {
    _sort = value;
    notifyListeners();
  }

  void resetFilters() {
    _query = '';
    _filter = const ProjectFilter();
    notifyListeners();
  }

  /// Called after a tag is deleted so the filter doesn't point at a ghost.
  void forgetTag(String tagId) {
    if (_filter.tagId == tagId) {
      _filter = _filter.copyWith(clearTag: true);
      notifyListeners();
    }
  }

  bool matches(Project p) {
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      final inName = p.name.toLowerCase().contains(q);
      final inTags = p.tags.any((t) => t.name.toLowerCase().contains(q));
      if (!inName && !inTags) return false;
    }
    if (_filter.status != StatusFilter.all && bucketOf(p) != _filter.status) {
      return false;
    }
    if (_filter.priority != null && p.priority != _filter.priority) return false;
    if (_filter.tagId != null && !p.tags.any((t) => t.id == _filter.tagId)) {
      return false;
    }
    return true;
  }

  int _compare(Project a, Project b) {
    int c;
    switch (_sort) {
      case SortOption.deadlineAsc:
        c = a.deadline.compareTo(b.deadline);
      case SortOption.deadlineDesc:
        c = b.deadline.compareTo(a.deadline);
      case SortOption.startAsc:
        c = a.startDate.compareTo(b.startDate);
      case SortOption.progressDesc:
        c = b.progress.compareTo(a.progress);
      case SortOption.priorityDesc:
        c = b.priority.weight.compareTo(a.priority.weight);
      case SortOption.createdDesc:
        c = b.createdAt.compareTo(a.createdAt);
    }
    // Stable tie-breakers so the list order doesn't jitter between rebuilds.
    if (c != 0) return c;
    c = a.deadline.compareTo(b.deadline);
    if (c != 0) return c;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  /// Non-archived projects after search + filter + sort.
  List<Project> get visible {
    final list = active.where(matches).toList();
    list.sort(_compare);
    return list;
  }

  // ---- loading ------------------------------------------------------------

  /// Initial load. Also runs the overdue check and the auto-archive rule so
  /// stale state is fixed on every startup.
  Future<void> load() async {
    try {
      await OverdueChecker.run(_repo);
      await _autoArchive();
      _projects = await _repo.getAll();
      loadError = null;
    } catch (e) {
      loadError = 'Gagal memuat data: $e';
    }
    loading = false;
    notifyListeners();
  }

  /// Re-reads the database without the startup side effects.
  Future<void> refresh() async {
    try {
      _projects = await _repo.getAll();
      loadError = null;
    } catch (e) {
      loadError = 'Gagal memuat data: $e';
    }
    notifyListeners();
  }

  Future<void> _reload() async {
    _projects = await _repo.getAll();
    notifyListeners();
  }

  /// Completed projects older than 7 days move to the archive automatically.
  Future<int> _autoArchive() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    var changed = 0;
    for (final p in await _repo.getAll()) {
      if (p.isArchived || !p.isCompleted) continue;
      final doneAt = p.completedAt ?? p.updatedAt;
      if (doneAt.isBefore(cutoff)) {
        await _repo.upsert(p.copyWith(isArchived: true));
        changed++;
      }
    }
    return changed;
  }

  /// Projects shown on [day] (after filters). An overdue project keeps showing
  /// up until today so it stays visible instead of silently disappearing.
  List<Project> projectsOn(DateTime day) {
    final d = dateOnly(day);
    final today = dateOnly(DateTime.now());
    return _projects.where((p) {
      if (p.isArchived || !matches(p)) return false;
      var end = dateOnly(p.deadline);
      if (p.isOverdue && !p.isCompleted && today.isAfter(end)) end = today;
      return !d.isBefore(dateOnly(p.startDate)) && !d.isAfter(end);
    }).toList();
  }

  // ---- mutations (callers wrap in runGuarded) ------------------------------

  /// Keeps completedAt consistent with isCompleted no matter which screen saved.
  Project _normalize(Project p) {
    final now = DateTime.now();
    if (p.isCompleted && p.completedAt == null) {
      return p.copyWith(completedAt: now, updatedAt: now);
    }
    if (!p.isCompleted && p.completedAt != null) {
      // Un-completing also pulls the project out of the archive: it is active again.
      return p.copyWith(clearCompletedAt: true, isArchived: false, updatedAt: now);
    }
    return p.copyWith(updatedAt: now);
  }

  Future<void> save(Project p) async {
    await _repo.upsert(_normalize(p));
    await _reload();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _reload();
  }

  Future<void> archive(Project p) => save(p.copyWith(isArchived: true));

  /// A restored finished project gets a fresh completedAt, otherwise the
  /// 7-day rule would archive it again on the next launch.
  Future<void> restore(Project p) => save(p.copyWith(
        isArchived: false,
        completedAt: p.isCompleted ? DateTime.now() : null,
      ));

  /// Clone shifted by one day. Subtasks are copied but reset to "not done"
  /// because the copy is a fresh run of the same work.
  Future<Project> duplicate(Project p) async {
    final now = DateTime.now();
    final newId = const Uuid().v4();
    DateTime plusOneDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);
    final copy = Project(
      id: newId,
      name: '${p.name} (copy)',
      startDate: plusOneDay(p.startDate),
      deadline: plusOneDay(p.deadline),
      progress: 0,
      notes: p.notes,
      subtasks: [
        for (var i = 0; i < p.subtasks.length; i++)
          Subtask(
            id: const Uuid().v4(),
            projectId: newId,
            title: p.subtasks[i].title,
            isDone: false,
            order: i,
          ),
      ],
      priority: p.priority,
      tags: p.tags,
      reminderDays: List<int>.of(p.reminderDays),
      createdAt: now,
      updatedAt: now,
    );
    await _repo.upsert(copy);
    await _reload();
    return copy;
  }

  Future<void> resetAll() async {
    await _repo.clear();
    await _reload();
  }

  // ---- backup ---------------------------------------------------------------

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'app': 'project_calendar',
        'version': 2,
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
