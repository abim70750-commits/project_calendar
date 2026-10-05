import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/tag.dart';
import '../providers/project_provider.dart';
import 'priority_badge.dart';
import 'tag_chip.dart';

/// Two horizontally scrolling rows: status first, then priority and tags.
class ProjectFilterChips extends StatelessWidget {
  const ProjectFilterChips({
    super.key,
    required this.filter,
    required this.tags,
    required this.onChanged,
  });

  final ProjectFilter filter;
  final List<Tag> tags;
  final ValueChanged<ProjectFilter> onChanged;

  Widget _row(List<Widget> chips) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (final c in chips) Padding(padding: const EdgeInsets.only(right: 8), child: c),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row([
          for (final s in StatusFilter.values)
            ChoiceChip(
              label: Text(s.label),
              selected: filter.status == s,
              onSelected: (_) => onChanged(filter.copyWith(status: s)),
            ),
        ]),
        _row([
          for (final p in Priority.values)
            FilterChip(
              avatar: Icon(Icons.flag, size: 16, color: priorityColor(p)),
              label: Text(p == Priority.none ? 'Tanpa' : p.label),
              selected: filter.priority == p,
              onSelected: (on) => onChanged(on
                  ? filter.copyWith(priority: p)
                  : filter.copyWith(clearPriority: true)),
            ),
          for (final t in tags)
            TagFilterChip(
              tag: t,
              selected: filter.tagId == t.id,
              onSelected: (on) => onChanged(
                  on ? filter.copyWith(tagId: t.id) : filter.copyWith(clearTag: true)),
            ),
        ]),
      ],
    );
  }
}
