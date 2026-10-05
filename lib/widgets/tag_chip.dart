import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/tag.dart';
import '../providers/tag_provider.dart';

/// Read-only coloured chip, optionally removable.
class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.tag, this.onDeleted});

  final Tag tag;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final color = tag.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(tag.name,
                overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: 4),
            InkWell(onTap: onDeleted, child: const Icon(Icons.close, size: 14)),
          ],
        ],
      ),
    );
  }
}

/// Selectable chip used by the filter bar and the project form.
class TagFilterChip extends StatelessWidget {
  const TagFilterChip({
    super.key,
    required this.tag,
    required this.selected,
    required this.onSelected,
  });

  final Tag tag;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: tag.color, shape: BoxShape.circle)),
      label: Text(tag.name),
      selected: selected,
      showCheckmark: false,
      selectedColor: tag.color.withAlpha(80),
      side: BorderSide(color: tag.color),
      onSelected: onSelected,
    );
  }
}

/// Create/rename dialog shared by the tag screen and the project form.
/// Returns the tag to persist, or null when cancelled.
Future<Tag?> showTagEditorDialog(BuildContext context, {Tag? existing}) {
  return showDialog<Tag>(
    context: context,
    builder: (_) => _TagEditorDialog(existing: existing),
  );
}

class _TagEditorDialog extends StatefulWidget {
  const _TagEditorDialog({this.existing});

  final Tag? existing;

  @override
  State<_TagEditorDialog> createState() => _TagEditorDialogState();
}

class _TagEditorDialogState extends State<_TagEditorDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late String _colorHex = widget.existing?.colorHex ?? Tag.palette[5];
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    String? error;
    if (name.isEmpty) {
      error = 'Nama tag wajib diisi';
    } else if (name.length > 24) {
      error = 'Maksimal 24 karakter';
    } else if (context
        .read<TagProvider>()
        .nameExists(name, exceptId: widget.existing?.id)) {
      error = 'Nama tag sudah dipakai';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final old = widget.existing;
    Navigator.of(context).pop(
      old == null
          ? Tag(
              id: const Uuid().v4(),
              name: name,
              colorHex: _colorHex,
              createdAt: DateTime.now(),
            )
          : old.copyWith(name: name, colorHex: _colorHex),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Tag baru' : 'Ubah tag'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: 24,
              decoration: InputDecoration(
                labelText: 'Nama tag',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            const Text('Warna'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final hex in Tag.palette)
                  GestureDetector(
                    onTap: () => setState(() => _colorHex = hex),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Tag(
                                id: '',
                                name: '',
                                colorHex: hex,
                                createdAt: DateTime.now())
                            .color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hex == _colorHex ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: hex == _colorHex
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
