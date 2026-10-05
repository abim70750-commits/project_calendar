import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tag.dart';
import '../providers/project_provider.dart';
import '../providers/tag_provider.dart';
import '../widgets/tag_chip.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  @override
  void initState() {
    super.initState();
    // Usage counts change whenever projects are edited, so refresh on entry.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TagProvider>().load();
    });
  }

  Future<void> _edit({Tag? existing}) async {
    final tag = await showTagEditorDialog(context, existing: existing);
    if (tag == null || !mounted) return;
    final provider = context.read<TagProvider>();
    await runGuarded(context, () => provider.save(tag));
  }

  Future<void> _delete(Tag tag) async {
    final tags = context.read<TagProvider>();
    final projects = context.read<ProjectProvider>();
    final used = tags.usageOf(tag.id);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus tag?'),
        content: Text(used == 0
            ? 'Tag "${tag.name}" akan dihapus.'
            : 'Tag "${tag.name}" akan dilepas dari $used project. Project-nya tetap ada.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await runGuarded(context, () async {
      await tags.delete(tag.id);
      projects.forgetTag(tag.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TagProvider>();
    final tags = provider.tags;
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Tag')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tag baru',
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: tags.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  provider.loadError ?? 'Belum ada tag. Tekan + untuk membuat.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: tags.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final t = tags[i];
                final used = provider.usageOf(t.id);
                return ListTile(
                  leading: CircleAvatar(backgroundColor: t.color, radius: 12),
                  title: Text(t.name),
                  subtitle: Text('$used project'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Ubah',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _edit(existing: t),
                      ),
                      IconButton(
                        tooltip: 'Hapus',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(t),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
