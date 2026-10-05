import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../models/tag.dart';
import '../providers/project_provider.dart';
import '../utils/date_utils.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static const Color _doneColor = Color(0xFF43A047);
  static const Color _activityColor = Color(0xFF1E88E5);

  static Color _bucketColor(StatusFilter s) {
    switch (s) {
      case StatusFilter.completed:
        return Colors.grey;
      case StatusFilter.overdue:
        return const Color(0xFFE53935);
      case StatusFilter.ongoing:
        return const Color(0xFF43A047);
      case StatusFilter.notStarted:
        return const Color(0xFF1E88E5);
      case StatusFilter.all:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Statistics cover archived projects too: archiving is housekeeping, not deletion.
    final all = context.watch<ProjectProvider>().all;
    final now = DateTime.now();
    final today = dateOnly(now);

    final buckets = <StatusFilter, int>{
      for (final s in StatusFilter.values)
        if (s != StatusFilter.all) s: 0,
    };
    for (final p in all) {
      final b = bucketOf(p, now);
      buckets[b] = (buckets[b] ?? 0) + 1;
    }
    final total = all.length;
    final completed = buckets[StatusFilter.completed] ?? 0;
    final rate = total == 0 ? 0.0 : completed / total;

    // The app stores no per-day progress history, so the 7-day chart shows
    // projects completed per day next to projects touched per day.
    final days = [
      for (var i = 6; i >= 0; i--)
        DateTime(today.year, today.month, today.day - i),
    ];
    int countOn(DateTime day, DateTime? Function(Project) pick) => all.where((p) {
          final t = pick(p);
          return t != null && dateOnly(t) == day;
        }).length;
    final doneSeries =
        days.map((d) => countOn(d, (p) => p.isCompleted ? p.completedAt : null)).toList();
    final activitySeries = days.map((d) => countOn(d, (p) => p.updatedAt)).toList();
    final labels = days.map((d) => DateFormat('E', 'id_ID').format(d)).toList();

    final tagCounts = <String, int>{};
    final tagById = <String, Tag>{};
    for (final p in all) {
      for (final t in p.tags) {
        tagById[t.id] = t;
        tagCounts[t.id] = (tagCounts[t.id] ?? 0) + 1;
      }
    }
    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topTags.take(5).toList();

    final planned = all.map((p) => daysLeftFor(p.deadline, p.startDate) + 1).toList();
    final avgPlanned =
        planned.isEmpty ? 0.0 : planned.reduce((a, b) => a + b) / planned.length;
    final actual = all
        .where((p) => p.isCompleted && p.completedAt != null)
        .map((p) {
          final d = daysLeftFor(p.completedAt!, p.startDate) + 1;
          return d < 1 ? 1 : d;
        })
        .toList();
    final avgActual =
        actual.isEmpty ? null : actual.reduce((a, b) => a + b) / actual.length;

    final theme = Theme.of(context);

    Widget tile(String label, String value) => SizedBox(
          width: 150,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(label, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: total == 0
          ? const Center(child: Text('Belum ada data untuk dihitung.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    tile('Total project', '$total'),
                    tile('Tingkat selesai', '${(rate * 100).round()}%'),
                    tile('Durasi rencana rata-rata', '${avgPlanned.toStringAsFixed(1)} hari'),
                    tile('Durasi aktual rata-rata',
                        avgActual == null ? '-' : '${avgActual.toStringAsFixed(1)} hari'),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Status project', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 16,
                    child: Row(
                      children: [
                        for (final e in buckets.entries)
                          if (e.value > 0)
                            Expanded(
                              flex: e.value,
                              child: Container(color: _bucketColor(e.key)),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    for (final e in buckets.entries)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 10, height: 10, color: _bucketColor(e.key)),
                          const SizedBox(width: 4),
                          Text('${e.key.label}: ${e.value}',
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('7 hari terakhir', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _WeekBarsPainter(
                      labels: labels,
                      done: doneSeries,
                      activity: activitySeries,
                      doneColor: _doneColor,
                      activityColor: _activityColor,
                      textColor: theme.colorScheme.onSurface,
                      gridColor: theme.dividerColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 10, height: 10, color: _doneColor),
                    const SizedBox(width: 4),
                    const Text('Selesai', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 16),
                    Container(width: 10, height: 10, color: _activityColor),
                    const SizedBox(width: 4),
                    const Text('Diperbarui', style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Top 5 tag', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (top5.isEmpty)
                  const Text('Belum ada tag yang dipakai.')
                else
                  for (final e in top5)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 96,
                            child: Text(tagById[e.key]!.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: e.value / top5.first.value,
                              minHeight: 10,
                              color: tagById[e.key]!.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${e.value}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
              ],
            ),
    );
  }
}

/// Grouped bars (two per day) drawn by hand so no chart package is needed.
class _WeekBarsPainter extends CustomPainter {
  _WeekBarsPainter({
    required this.labels,
    required this.done,
    required this.activity,
    required this.doneColor,
    required this.activityColor,
    required this.textColor,
    required this.gridColor,
  });

  final List<String> labels;
  final List<int> done;
  final List<int> activity;
  final Color doneColor;
  final Color activityColor;
  final Color textColor;
  final Color gridColor;

  void _text(Canvas canvas, String s, Offset center, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: textColor, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 22.0;
    const topPad = 16.0;
    final chartH = size.height - labelH - topPad;
    final baseY = topPad + chartH;
    final maxV = [...done, ...activity, 1].reduce((a, b) => a > b ? a : b);
    final group = size.width / labels.length;
    final barW = group * 0.26;

    canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY),
        Paint()..color = gridColor..strokeWidth = 1);

    for (var i = 0; i < labels.length; i++) {
      final cx = group * i + group / 2;
      void bar(int v, double left, Color c) {
        final h = chartH * (v / maxV);
        if (v > 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(left, baseY - h, barW, h), const Radius.circular(3)),
            Paint()..color = c,
          );
          _text(canvas, '$v', Offset(left + barW / 2, baseY - h - 8), 10);
        }
      }

      bar(done[i], cx - barW - 2, doneColor);
      bar(activity[i], cx + 2, activityColor);
      _text(canvas, labels[i], Offset(cx, baseY + labelH / 2), 11);
    }
  }

  @override
  bool shouldRepaint(covariant _WeekBarsPainter old) =>
      old.done != done || old.activity != activity || old.labels != labels;
}
