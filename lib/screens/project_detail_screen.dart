import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../models/subtask.dart';
import '../providers/project_provider.dart';
import '../utils/color_logic.dart';
import '../utils/date_utils.dart';
import '../utils/l10n_extensions.dart';
import '../widgets/priority_badge.dart';
import '../widgets/progress_slider.dart';
import '../widgets/status_badge.dart';
import '../widgets/subtask_tile.dart';
import '../widgets/tag_chip.dart';
import 'project_form_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final TextEditingController _notes = TextEditingController();
  bool _notesLoaded = false;
  bool _editingNotes = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save(Project p) =>
      runGuarded(context, () => context.read<ProjectProvider>().save(p));

  /// Re-numbers order from list position so persisted order always matches the UI.
  Future<void> _saveSubtasks(Project p, List<Subtask> subs) => _save(p.copyWith(
        subtasks: [
          for (var i = 0; i < subs.length; i++) subs[i].copyWith(order: i)
        ],
      ));

  Future<String?> _askText(String title, String initial) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.detailSubtaskHint),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text),
              child: Text(l10n.commonSave)),
        ],
      ),
    );
  }

  Future<void> _addSubtask(Project p) async {
    final title =
        (await _askText(AppLocalizations.of(context)!.detailSubtaskNewTitle, ''))
            ?.trim();
    if (title == null || title.isEmpty) return;
    await _saveSubtasks(p, [
      ...p.subtasks,
      Subtask(id: const Uuid().v4(), projectId: p.id, title: title),
    ]);
  }

  Future<void> _editSubtask(Project p, Subtask s) async {
    final title = (await _askText(
            AppLocalizations.of(context)!.detailSubtaskEditTitle, s.title))
        ?.trim();
    if (title == null || title.isEmpty) return;
    await _saveSubtasks(
        p, [for (final x in p.subtasks) x.id == s.id ? x.copyWith(title: title) : x]);
  }

  Future<void> _delete(Project p) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.detailDeleteTitle),
        content: Text(l10n.detailDeleteMessage(p.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await runGuarded(context, () async {
      await context.read<ProjectProvider>().delete(p.id);
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _duplicate(Project p) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ProjectProvider>();
    await runGuarded(context, () async {
      final copy = await provider.duplicate(p, nameSuffix: l10n.detailDuplicateSuffix);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.detailDuplicated)));
      // Replace (not push) so Back returns to the list, not to the original.
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(projectId: copy.id)));
    });
  }

  Future<void> _toggleArchive(Project p) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ProjectProvider>();
    await runGuarded(context, () async {
      if (p.isArchived) {
        await provider.restore(p);
      } else {
        await provider.archive(p);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(p.isArchived ? l10n.detailRestored : l10n.detailArchived)));
    });
  }

  Widget _notesSection(Project p) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.detailNotesTitle, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: true, label: Text(l10n.detailNotesEdit)),
                ButtonSegment(value: false, label: Text(l10n.detailNotesView)),
              ],
              selected: {_editingNotes},
              onSelectionChanged: (s) async {
                final toView = !s.first;
                // Leaving edit mode saves, so a rendered preview is never ahead of storage.
                if (toView && _notes.text != p.notes) {
                  await _save(p.copyWith(notes: _notes.text));
                }
                if (mounted) setState(() => _editingNotes = s.first);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_editingNotes) ...[
          TextField(
            controller: _notes,
            minLines: 5,
            maxLines: 14,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.detailNotesHint,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: () async {
                await _save(p.copyWith(notes: _notes.text));
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.detailNotesSaved)));
              },
              child: Text(l10n.detailNotesSave),
            ),
          ),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: p.notes.trim().isEmpty
                ? Text(l10n.detailNotesEmpty)
                : MarkdownBody(data: p.notes, selectable: true),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = context.watch<ProjectProvider>().byId(widget.projectId);
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.detailNotFound)),
      );
    }
    if (!_notesLoaded) {
      _notes.text = p.notes;
      _notesLoaded = true;
    }
    final color = colorOf(statusOf(p));
    final reminders = [...p.reminderDays]..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.detailTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (p.isArchived)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.archive, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.detailArchivedBanner)),
                ],
              ),
            ),
          Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(project: p),
              PriorityBadge(priority: p.priority),
              Text(remainingText(l10n, p),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          if (p.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final t in p.tags) TagChip(tag: t)],
            ),
          ],
          const SizedBox(height: 12),
          Text(l10n.detailStartLine(formatDate(context, p.startDate))),
          Text(l10n.detailDeadlineLine(formatDate(context, p.deadline))),
          Text(reminders.isEmpty
              ? l10n.detailRemindersNone
              : l10n.detailRemindersLine(
                  reminders.map((d) => reminderLabel(l10n, d)).join(', '))),
          const SizedBox(height: 16),
          ProgressSlider(
            value: p.progress,
            enabled: !p.isCompleted,
            onSaved: (v) => _save(p.copyWith(progress: v)),
          ),
          const Divider(height: 32),
          _notesSection(p),
          const Divider(height: 32),
          Row(
            children: [
              Text(
                  l10n.detailSubtasksTitle(
                      p.subtasks.where((s) => s.isDone).length, p.subtasks.length),
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(
                  tooltip: l10n.detailAddSubtask,
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _addSubtask(p)),
            ],
          ),
          if (p.subtasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l10n.detailSubtasksEmpty),
            )
          else ...[
            Text(l10n.detailSubtasksReorderHint, style: const TextStyle(fontSize: 11)),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                // ReorderableListView reports newIndex as if the item were still in place.
                if (newIndex > oldIndex) newIndex -= 1;
                final list = [...p.subtasks];
                list.insert(newIndex, list.removeAt(oldIndex));
                _saveSubtasks(p, list);
              },
              children: [
                for (final s in p.subtasks)
                  SubtaskTile(
                    key: ValueKey(s.id),
                    subtask: s,
                    onToggle: () => _saveSubtasks(p, [
                      for (final x in p.subtasks)
                        x.id == s.id ? x.copyWith(isDone: !x.isDone) : x
                    ]),
                    onEdit: () => _editSubtask(p, s),
                    onDelete: () => _saveSubtasks(
                        p, p.subtasks.where((x) => x.id != s.id).toList()),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _save(p.copyWith(
              isCompleted: !p.isCompleted,
              // Completing clears the sticky overdue flag, as specified.
              isOverdue: false,
              progress: p.isCompleted ? p.progress : 100,
            )),
            icon: Icon(p.isCompleted ? Icons.undo : Icons.check_circle),
            label: Text(p.isCompleted ? l10n.detailUndoComplete : l10n.detailMarkComplete),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProjectFormScreen(project: p))),
            icon: const Icon(Icons.edit),
            label: Text(l10n.commonEdit),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _duplicate(p),
            icon: const Icon(Icons.copy),
            label: Text(l10n.detailDuplicateButton),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _toggleArchive(p),
            icon: Icon(p.isArchived ? Icons.unarchive : Icons.archive),
            label: Text(p.isArchived ? l10n.detailRestoreButton : l10n.detailArchiveButton),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _delete(p),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete),
            label: Text(l10n.detailDeleteButton),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
