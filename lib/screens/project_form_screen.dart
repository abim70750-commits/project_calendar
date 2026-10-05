import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';
import '../providers/project_provider.dart';
import '../providers/tag_provider.dart';
import '../utils/date_utils.dart';
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
  String? _startError;
  String? _deadlineError;
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
    final initial = (isStart ? _start : _deadline) ?? _start ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Pilih tanggal mulai' : 'Pilih deadline',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = dateOnly(picked);
        _startError = null;
      } else {
        _deadline = dateOnly(picked);
        _deadlineError = null;
      }
    });
  }

  Future<void> _addReminder() async {
    final options = _reminderChoices.where((d) => !_reminders.contains(d)).toList();
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Ingatkan sebelum deadline'),
        children: [
          for (final d in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(d),
              child: Text(d == 0 ? 'Hari-H (hari deadline)' : '$d hari sebelum deadline'),
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
    String? startErr;
    String? deadlineErr;
    if (_start == null) startErr = 'Tanggal mulai wajib dipilih';
    if (_deadline == null) {
      deadlineErr = 'Deadline wajib dipilih';
    } else if (_start != null && _deadline!.isBefore(_start!)) {
      deadlineErr = 'Deadline tidak boleh sebelum tanggal mulai';
    }
    setState(() {
      _startError = startErr;
      _deadlineError = deadlineErr;
    });
    return formOk && startErr == null && deadlineErr == null;
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
    return InkWell(
      onTap: () => _pick(isStart),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(value == null ? 'Pilih tanggal' : formatDate(value)),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );

  @override
  Widget build(BuildContext context) {
    final editing = widget.project != null;
    final tags = context.watch<TagProvider>().tags;
    final sortedReminders = [..._reminders]..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Ubah Project' : 'Project Baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Nama project', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama project wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _dateField('Tanggal mulai', _start, _startError, true),
            const SizedBox(height: 16),
            _dateField('Deadline', _deadline, _deadlineError, false),
            _sectionTitle('Prioritas'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in Priority.values)
                  ChoiceChip(
                    avatar: Icon(Icons.flag, size: 16, color: priorityColor(p)),
                    label: Text(p.label),
                    selected: _priority == p,
                    onSelected: (_) => setState(() => _priority = p),
                  ),
              ],
            ),
            _sectionTitle('Tag'),
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
                  label: const Text('Tag baru'),
                  onPressed: _newTag,
                ),
              ],
            ),
            _sectionTitle('Pengingat deadline'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in sortedReminders)
                  InputChip(
                    label: Text(reminderLabel(d)),
                    onDeleted: () => setState(() => _reminders.remove(d)),
                  ),
                if (_reminders.length < kMaxReminders)
                  ActionChip(
                    avatar: const Icon(Icons.add_alarm, size: 18),
                    label: const Text('Tambah'),
                    onPressed: _addReminder,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _reminders.isEmpty
                  ? 'Tidak ada pengingat khusus untuk project ini.'
                  : 'Maksimal $kMaxReminders pengingat, dikirim pada jam notifikasi harian.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            _sectionTitle('Catatan awal (markdown)'),
            TextField(
              controller: _notes,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Tulis catatan dengan markdown...',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
