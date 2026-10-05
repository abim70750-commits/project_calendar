import 'package:flutter/material.dart';

import '../models/project.dart';

Color priorityColor(Priority p) {
  switch (p) {
    case Priority.high:
      return const Color(0xFFE53935);
    case Priority.medium:
      return const Color(0xFFFB8C00);
    case Priority.low:
      return const Color(0xFF1E88E5);
    case Priority.none:
      return Colors.grey;
  }
}

/// Hidden for [Priority.none] so cards without a priority stay uncluttered.
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final Priority priority;

  @override
  Widget build(BuildContext context) {
    if (priority == Priority.none) return const SizedBox.shrink();
    final color = priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 12, color: color),
          const SizedBox(width: 3),
          Text(priority.label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
