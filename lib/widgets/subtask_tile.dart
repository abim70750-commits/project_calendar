import 'package:flutter/material.dart';

import '../models/subtask.dart';

class SubtaskTile extends StatelessWidget {
  const SubtaskTile({
    super.key,
    required this.subtask,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Subtask subtask;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 0, right: 32),
      leading: Checkbox(value: subtask.isDone, onChanged: (_) => onToggle()),
      title: Text(
        subtask.title,
        style: TextStyle(
          decoration: subtask.isDone ? TextDecoration.lineThrough : null,
          color: subtask.isDone ? Theme.of(context).disabledColor : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              tooltip: 'Ubah', icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
          IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete),
        ],
      ),
    );
  }
}
