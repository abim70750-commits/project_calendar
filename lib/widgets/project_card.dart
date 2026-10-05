import 'package:flutter/material.dart';

import '../models/project.dart';
import '../utils/color_logic.dart';
import '../utils/date_utils.dart';
import 'priority_badge.dart';
import 'status_badge.dart';
import 'tag_chip.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorOf(statusOf(project));
    final shownTags = project.tags.take(3).toList();
    final extraTags = project.tags.length - shownTags.length;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(project.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(project: project),
                ],
              ),
              if (project.priority != Priority.none || shownTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    PriorityBadge(priority: project.priority),
                    for (final t in shownTags) TagChip(tag: t),
                    if (extraTags > 0)
                      Text('+$extraTags', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text('Deadline ${formatDate(project.deadline)} • ${remainingText(project)}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: project.progress / 100, color: color),
              const SizedBox(height: 4),
              Text('${project.progress}%', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
