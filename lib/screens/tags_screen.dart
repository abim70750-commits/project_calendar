import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final tags = context.read<TagProvider>();
    final projects = context.read<ProjectProvider>();
    final used = tags.usageOf(tag.id);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tagsDeleteTitle),
        content: Text(used == 0
            ? l10n.tagsDeleteUnused(tag.name)
            : l10n.tagsDeleteUsed(tag.name, used)),
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
      await tags.delete(tag.id);
      projects.forgetTag(tag.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<TagProvider>();
    final tags = provider.tags;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tagsTitle)),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.tagsNewTooltip,
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: tags.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  provider.loadError == null
                      ? l10n.tagsEmpty
                      : l10n.errorLoadTags(provider.loadError!),
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
                  subtitle: Text(l10n.tagsUsage(used)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l10n.commonEdit,
                        icon: const Icon(Icons.edit),
                        onPressed: () => _edit(existing: t),
                      ),
                      IconButton(
                        tooltip: l10n.commonDelete,
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
