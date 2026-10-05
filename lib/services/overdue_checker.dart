import '../data/project_repository.dart';
import '../utils/date_utils.dart';

class OverdueChecker {
  /// Flags projects whose deadline day has fully elapsed (deadline + 24h).
  /// The flag is sticky: only completing the project clears it.
  static Future<int> run(ProjectRepository repo) async {
    final now = DateTime.now();
    var changed = 0;
    for (final p in await repo.getAll()) {
      if (p.isCompleted || p.isOverdue) continue;
      final cutoff = dateOnly(p.deadline).add(const Duration(days: 1));
      if (now.isAfter(cutoff)) {
        await repo.upsert(p.copyWith(isOverdue: true, updatedAt: now));
        changed++;
      }
    }
    return changed;
  }
}
