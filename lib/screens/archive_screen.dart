import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../providers/project_provider.dart';
import '../widgets/project_card.dart';
import 'project_detail_screen.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  Future<void> _delete(BuildContext context, Project p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus permanen?'),
        content: Text('"${p.name}" akan dihapus dari arsip dan tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final provider = context.read<ProjectProvider>();
    await runGuarded(context, () => provider.delete(p.id));
  }

  Future<void> _restore(BuildContext context, Project p) async {
    final provider = context.read<ProjectProvider>();
    await runGuarded(context, () async {
      await provider.restore(p);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Project dipulihkan')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final archived = context.watch<ProjectProvider>().archived;
    return Scaffold(
      appBar: AppBar(title: Text('Arsip (${archived.length})')),
      body: archived.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Arsip kosong. Project yang selesai lebih dari 7 hari masuk ke sini otomatis.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8, left: 4),
                  child: Text('Project selesai > 7 hari diarsipkan otomatis.',
                      style: TextStyle(fontSize: 11)),
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
                        label: const Text('Pulihkan'),
                      ),
                      TextButton.icon(
                        onPressed: () => _delete(context, p),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
