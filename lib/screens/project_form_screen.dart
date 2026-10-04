import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';
import '../providers/project_provider.dart';
import '../utils/date_utils.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key, this.project});

  /// Null means "create"; non-null means "edit".
  final Project? project;

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.project?.name ?? '');
  DateTime? _start;
  DateTime? _deadline;
  String? _startError;
  String? _deadlineError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _start = widget.project?.startDate;
    _deadline = widget.project?.deadline;
  }

  @override
  void dispose() {
    _name.dispose();
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
    final now = DateTime.now();
    final old = widget.project;
    final project = old == null
        ? Project(
            id: const Uuid().v4(),
            name: _name.text.trim(),
            startDate: _start!,
            deadline: _deadline!,
            createdAt: now,
            updatedAt: now,
          )
        : old.copyWith(
            name: _name.text.trim(),
            startDate: _start,
            deadline: _deadline,
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

  @override
  Widget build(BuildContext context) {
    final editing = widget.project != null;
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
