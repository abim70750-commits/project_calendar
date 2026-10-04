import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/project.dart';
import '../providers/project_provider.dart';
import '../utils/color_logic.dart';
import '../utils/date_utils.dart';
import '../widgets/project_card.dart';
import 'project_detail_screen.dart';
import 'project_form_screen.dart';
import 'settings_screen.dart';

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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Tidak ada project di tanggal ini.')),
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

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProjectProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Calendar'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah project',
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ProjectFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (prov.loadError != null)
                  MaterialBanner(
                    content: Text(prov.loadError!),
                    actions: [
                      TextButton(onPressed: prov.load, child: const Text('Coba lagi'))
                    ],
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _legendDot(colorOf(ProjectStatus.safe), 'Aman'),
                    _legendDot(colorOf(ProjectStatus.warning), '≤ 3 hari'),
                    _legendDot(colorOf(ProjectStatus.urgent), '≤ 1 hari / telat'),
                    _legendDot(colorOf(ProjectStatus.completed), 'Selesai'),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    prov.projects.isEmpty
                        ? 'Belum ada project. Tekan + untuk mulai.'
                        : 'Ketuk tanggal untuk melihat project.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
    );
  }
}
