import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/project.dart';
import '../providers/project_provider.dart';
import '../providers/tag_provider.dart';
import '../utils/color_logic.dart';
import '../utils/date_utils.dart';
import '../widgets/filter_chips.dart';
import '../widgets/project_card.dart';
import '../widgets/search_bar.dart';
import 'archive_screen.dart';
import 'project_detail_screen.dart';
import 'project_form_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  void _openDetail(String id) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: id)));
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _showDay(DateTime day) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        // Consumer so the sheet reflects edits without being reopened.
        return Consumer<ProjectProvider>(builder: (_, prov, __) {
          final list = prov.projectsOn(day);
          return ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(formatDate(day), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(prov.filter.isDefault && prov.query.isEmpty
                          ? 'Tidak ada project di tanggal ini.'
                          : 'Tidak ada project yang cocok dengan filter di tanggal ini.'),
                    ),
                  ),
                for (final Project p in list)
                  ProjectCard(
                    project: p,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _openDetail(p.id);
                    },
                  ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _legendDot(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );

  Widget _emptyState(ProjectProvider prov) {
    final filtering = !prov.filter.isDefault || prov.query.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Text(
            filtering
                ? 'Tidak ada project yang cocok.'
                : 'Belum ada project. Tekan + untuk mulai.',
            textAlign: TextAlign.center,
          ),
          if (filtering)
            TextButton(onPressed: prov.resetFilters, child: const Text('Reset filter')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProjectProvider>();
    final tags = context.watch<TagProvider>().tags;
    final visible = prov.visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Calendar'),
        actions: [
          IconButton(
            tooltip: 'Statistik',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _push(const StatsScreen()),
          ),
          IconButton(
            tooltip: 'Arsip',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => _push(const ArchiveScreen()),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings),
            onPressed: () => _push(const SettingsScreen()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah project',
        onPressed: () => _push(const ProjectFormScreen()),
        child: const Icon(Icons.add),
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              // Bottom padding keeps the last card clear of the FAB.
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                if (prov.loadError != null)
                  MaterialBanner(
                    content: Text(prov.loadError!),
                    actions: [
                      TextButton(onPressed: prov.load, child: const Text('Coba lagi'))
                    ],
                  ),
                ProjectSearchBar(
                  query: prov.query,
                  sort: prov.sort,
                  onQueryChanged: prov.setQuery,
                  onSortChanged: prov.setSort,
                ),
                const SizedBox(height: 4),
                ProjectFilterChips(
                  filter: prov.filter,
                  tags: tags,
                  onChanged: prov.setFilter,
                ),
                TableCalendar<Project>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focused,
                  locale: 'id_ID',
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  availableCalendarFormats: const {CalendarFormat.month: 'Bulan'},
                  headerStyle: const HeaderStyle(
                      formatButtonVisible: false, titleCentered: true),
                  selectedDayPredicate: (d) => isSameDay(_selected, d),
                  eventLoader: prov.projectsOn,
                  onPageChanged: (d) => _focused = d,
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selected = selected;
                      _focused = focused;
                    });
                    _showDay(selected);
                  },
                  calendarBuilders: CalendarBuilders<Project>(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      return Positioned(
                        bottom: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final p in events.take(4))
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                    color: colorOf(statusOf(p)),
                                    shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _legendDot(colorOf(ProjectStatus.safe), 'Aman'),
                    _legendDot(colorOf(ProjectStatus.warning), '≤ 3 hari'),
                    _legendDot(colorOf(ProjectStatus.urgent), '≤ 1 hari / telat'),
                    _legendDot(colorOf(ProjectStatus.completed), 'Selesai'),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Daftar Project (${visible.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (visible.isEmpty)
                  _emptyState(prov)
                else
                  for (final p in visible)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ProjectCard(project: p, onTap: () => _openDetail(p.id)),
                    ),
              ],
            ),
    );
  }
}
