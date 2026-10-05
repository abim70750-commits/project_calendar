import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';

/// Display names for enums. They live here (not on the enums) so the models
/// and providers stay free of UI strings and the alarm isolate can reuse them.
extension PriorityL10n on Priority {
  String label(AppLocalizations l10n) {
    switch (this) {
      case Priority.high:
        return l10n.priorityHigh;
      case Priority.medium:
        return l10n.priorityMedium;
      case Priority.low:
        return l10n.priorityLow;
      case Priority.none:
        return l10n.priorityNone;
    }
  }
}

extension StatusFilterL10n on StatusFilter {
  String label(AppLocalizations l10n) {
    switch (this) {
      case StatusFilter.all:
        return l10n.filterStatusAll;
      case StatusFilter.notStarted:
        return l10n.filterStatusNotStarted;
      case StatusFilter.ongoing:
        return l10n.filterStatusOngoing;
      case StatusFilter.completed:
        return l10n.filterStatusCompleted;
      case StatusFilter.overdue:
        return l10n.filterStatusOverdue;
    }
  }
}

extension SortOptionL10n on SortOption {
  String label(AppLocalizations l10n) {
    switch (this) {
      case SortOption.deadlineAsc:
        return l10n.sortDeadlineAsc;
      case SortOption.deadlineDesc:
        return l10n.sortDeadlineDesc;
      case SortOption.startAsc:
        return l10n.sortStartAsc;
      case SortOption.progressDesc:
        return l10n.sortProgressDesc;
      case SortOption.priorityDesc:
        return l10n.sortPriorityDesc;
      case SortOption.createdDesc:
        return l10n.sortCreatedDesc;
    }
  }
}

String reminderLabel(AppLocalizations l10n, int days) =>
    days == 0 ? l10n.reminderOnDeadlineDay : l10n.reminderDaysBefore(days);
