import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../providers/tag_provider.dart';
import '../utils/date_utils.dart';
import '../utils/l10n_extensions.dart';
import '../widgets/priority_badge.dart';
import '../widgets/tag_chip.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key, this.project});

  /// Null means "create"; non-null means "edit".
  final Project? project;

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  static const List<int> _reminderChoices = [0, 1, 2, 3, 5, 7, 14, 30];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.project?.name ?? '');
  late final TextEditingController _notes =
      TextEditingController(text: widget.project?.notes ?? '');
  DateTime? _start;
  DateTime? _deadline;
  bool _startMissing = false;
  bool _deadlineMissing = false;
  bool _deadlineBeforeStart = false;
  Priority _priority = Priority.none;
  final Set<String> _selectedTags = {};
  List<int> _reminders = List<int>.of(kDefaultReminders);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    if (p != null) {
      _start = p.startDate;
      _deadline = p.deadline;
      _priority = p.priority;
      _selectedTags.addAll(p.tags.map((t) => t.id));
      _reminders = List<int>.of(p.reminderDays);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isStart) async {
    final l10n = AppLocalizations.of(context)!;
    final initial = (isStart ? _start : _deadline) ?? _start ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isStart ? l10n.formPickStartHelp : l10n.formPickDeadlineHelp,
      cancelText: l10n.commonCancel,
      confirmText: l10n.commonSelect,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = dateOnly(picked);
        _startMissing = false;
      } else {
        _deadline = dateOnly(picked);
        _deadlineMissing = false;
      }
      _deadlineBeforeStart =
          _start != null && _deadline != null && _deadline!.isBefore(_start!);
    });
  }

  Future<void> _addReminder() async {
    final l10n = AppLocalizations.of(context)!;
    final options = _reminderChoices.where((d) => !_reminders.contains(d)).toList();
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.formReminderDialogTitle),
        children: [
          for (final d in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(d),
              child: Text(reminderLabel(l10n, d)),
            ),
        ],
      ),
    );
    if (picked != null && _reminders.length < kMaxReminders) {
      setState(() => _reminders = [..._reminders, picked]);
    }
  }

  Future<void> _newTag() async {
    final tag = await showTagEditorDialog(context);
    if (tag == null || !mounted) return;
    final provider = context.read<TagProvider>();
    await runGuarded(context, () async {
      await provider.save(tag);
      if (mounted) setState(() => _selectedTags.add(tag.id));
    });
  }

  bool _validate() {
    final formOk = _formKey.currentState!.validate();
    setState(() {
      _startMissing = _start == null;
      _deadlineMissing = _deadline == null;
      _deadlineBeforeStart =
          _start != null && _deadline != null && _deadline!.isBefore(_start!);
    });
    return formOk && !_startMissing && !_deadlineMissing && !_deadlineBeforeStart;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    final provider = context.read<ProjectProvider>();
    final tags = context
        .read<TagProvider>()
        .tags
        .where((t) => _selectedTags.contains(t.id))
        .toList();
    final now = DateTime.now();
    final old = widget.project;
    final project = old == null
        ? Project(
            id: const Uuid().v4(),
            name: _name.text.trim(),
            startDate: _start!,
            deadline: _deadline!,
            notes: _notes.text,
            priority: _priority,
            tags: tags,
            reminderDays: List<int>.of(_reminders),
            createdAt: now,
            updatedAt: now,
          )
        : old.copyWith(
            name: _name.text.trim(),
            startDate: _start,
            deadline: _deadline,
            notes: _notes.text,
            priority: _priority,
            tags: tags,
            reminderDays: List<int>.of(_reminders),
            // Moving the deadline forward gives an overdue project a second chance.
            isOverdue: old.isOverdue &&
                !now.isBefore(dateOnly(_deadline!).add(const Duration(days: 1))),
          );
    await runGuarded(context, () async {
      await provider.save(project);
      if (mounted) Navigator.of(context).pop();
    });
    if (mounted) setState(() => _saving = false);
  }

  Widget _dateField(String label, DateTime? value, String? error, bool isStart) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () => _pick(isStart),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(value == null ? l10n.formPickDate : formatDate(context, value)),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editing = widget.project != null;
    final tags = context.watch<TagProvider>().tags;
    final sortedReminders = [..._reminders]..sort((a, b) => b.compareTo(a));

    // Errors are derived from flags (not stored strings) so they re-render in the active language.
    final startError = _startMissing ? l10n.formStartRequired : null;
    final deadlineError = _deadlineMissing
        ? l10n.formDeadlineRequired
        : (_deadlineBeforeStart ? l10n.formDeadlineBeforeStart : null);

    return Scaffold(
      appBar: AppBar(
          title: Text(editing ? l10n.formTitleEdit : l10n.formTitleCreate)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                  labelText: l10n.formNameLabel, border: const OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.formNameRequired : null,
            ),
            const SizedBox(height: 16),
            _dateField(l10n.formStartDateLabel, _start, startError, true),
            const SizedBox(height: 16),
            _dateField(l10n.formDeadlineLabel, _deadline, deadlineError, false),
            _sectionTitle(l10n.formPriorityTitle),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in Priority.values)
                  ChoiceChip(
                    avatar: Icon(Icons.flag, size: 16, color: priorityColor(p)),
                    label: Text(p.label(l10n)),
                    selected: _priority == p,
                    onSelected: (_) => setState(() => _priority = p),
                  ),
              ],
            ),
            _sectionTitle(l10n.formTagsTitle),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in tags)
                  TagFilterChip(
                    tag: t,
                    selected: _selectedTags.contains(t.id),
                    onSelected: (on) => setState(() {
                      if (on) {
                        _selectedTags.add(t.id);
                      } else {
                        _selectedTags.remove(t.id);
                      }
                    }),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(l10n.formNewTag),
                  onPressed: _newTag,
                ),
              ],
            ),
            _sectionTitle(l10n.formRemindersTitle),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in sortedReminders)
                  InputChip(
                    label: Text(reminderLabel(l10n, d)),
                    onDeleted: () => setState(() => _reminders.remove(d)),
                  ),
                if (_reminders.length < kMaxReminders)
                  ActionChip(
                    avatar: const Icon(Icons.add_alarm, size: 18),
                    label: Text(l10n.formAddReminder),
                    onPressed: _addReminder,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _reminders.isEmpty
                  ? l10n.formReminderNone
                  : l10n.formReminderHintMax(kMaxReminders),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            _sectionTitle(l10n.formNotesTitle),
            TextField(
              controller: _notes,
              minLines: 4,
              maxLines: 10,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.formNotesHint,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? l10n.formSaving : l10n.formSave),
            ),
          ],
        ),
      ),
    );
  }
}
