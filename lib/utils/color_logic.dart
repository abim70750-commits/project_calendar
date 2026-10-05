import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import 'date_utils.dart';

enum ProjectStatus { completed, overdue, urgent, warning, safe }

/// Status is computed on the fly (never stored) so it can't go stale.
ProjectStatus statusOf(Project p, [DateTime? now]) {
  if (p.isCompleted) return ProjectStatus.completed;
  if (p.isOverdue) return ProjectStatus.overdue;
  final left = daysLeftFor(p.deadline, now);
  if (left <= 1) return ProjectStatus.urgent;
  if (left <= 3) return ProjectStatus.warning;
  return ProjectStatus.safe;
}

Color colorOf(ProjectStatus s) {
  switch (s) {
    case ProjectStatus.completed:
      return Colors.grey;
    case ProjectStatus.overdue:
    case ProjectStatus.urgent:
      return const Color(0xFFE53935);
    case ProjectStatus.warning:
      return const Color(0xFFFBC02D);
    case ProjectStatus.safe:
      return const Color(0xFF43A047);
  }
}

String labelOf(AppLocalizations l10n, ProjectStatus s) {
  switch (s) {
    case ProjectStatus.completed:
      return l10n.statusCompleted;
    case ProjectStatus.overdue:
      return l10n.statusOverdue;
    case ProjectStatus.urgent:
      return l10n.statusUrgent;
    case ProjectStatus.warning:
      return l10n.statusWarning;
    case ProjectStatus.safe:
      return l10n.statusSafe;
  }
}

/// Short human text for the remaining time.
String remainingText(AppLocalizations l10n, Project p) {
  if (p.isCompleted) return l10n.statusCompleted;
  final left = daysLeftFor(p.deadline);
  if (p.isOverdue) return l10n.remainingPastDeadline;
  if (left < 0) return l10n.remainingDaysLate(-left);
  if (left == 0) return l10n.remainingToday;
  return l10n.remainingDaysLeft(left);
}
