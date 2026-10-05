import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../widgets/project_card.dart';
import 'project_detail_screen.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  Future<void> _delete(BuildContext context, Project p) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.archiveDeleteTitle),
        content: Text(l10n.archiveDeleteMessage(p.name)),
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
    if (ok != true || !context.mounted) return;
    final provider = context.read<ProjectProvider>();
    await runGuarded(context, () => provider.delete(p.id));
  }

  Future<void> _restore(BuildContext context, Project p) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ProjectProvider>();
    await runGuarded(context, () async {
      await provider.restore(p);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.detailRestored)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final archived = context.watch<ProjectProvider>().archived;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.archiveTitle(archived.length))),
      body: archived.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.archiveEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(l10n.archiveAutoNote,
                      style: const TextStyle(fontSize: 11)),
                ),
                for (final p in archived) ...[
                  ProjectCard(
                    project: p,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProjectDetailScreen(projectId: p.id))),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _restore(context, p),
                        icon: const Icon(Icons.unarchive),
                        label: Text(l10n.commonRestore),
                      ),
                      TextButton.icon(
                        onPressed: () => _delete(context, p),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.commonDelete),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
