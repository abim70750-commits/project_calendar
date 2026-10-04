import 'package:flutter/material.dart';

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

String labelOf(ProjectStatus s) {
  switch (s) {
    case ProjectStatus.completed:
      return 'Selesai';
    case ProjectStatus.overdue:
      return 'Terlambat';
    case ProjectStatus.urgent:
      return 'Mendesak';
    case ProjectStatus.warning:
      return 'Waspada';
    case ProjectStatus.safe:
      return 'Aman';
  }
}

/// Short human text for the remaining time.
String remainingText(Project p) {
  if (p.isCompleted) return 'Selesai';
  final left = daysLeftFor(p.deadline);
  if (p.isOverdue) return 'Lewat deadline';
  if (left < 0) return 'Lewat ${-left} hari';
  if (left == 0) return 'Hari ini';
  return 'Sisa $left hari';
}
