import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/models.dart';
import '../state/stats.dart';
import '../widgets/stats_view.dart';

class TaskStatsScreen extends StatelessWidget {
  const TaskStatsScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final real = state.tasks.where((t) => !t.isDefault).toList();
    final done = real.where((t) => t.isDone).toList();
    final byDay = perDay(done, (t) => t.completedAt!, (_) => 1);
    final today = dayOf(now);
    final byHour = List<int>.filled(24, 0);
    for (final t in done) {
      if (dayOf(t.completedAt!) == today) byHour[t.completedAt!.hour]++;
    }
    String plural(int n) => n == 1 ? '1 task' : '$n tasks';

    return StatsView(
      ranges: const [StatsRange.week, StatsRange.month, StatsRange.year],
      initial: StatsRange.week,
      headline: (r) => 'Completed ${r.thisLabel}',
      bigValue: (r) {
        final from = periodStart(r, now);
        return '${done.where((t) => !t.completedAt!.isBefore(from)).length}';
      },
      subValue: (r) {
        final from = periodStart(r, now);
        final created = real.where((t) => !t.createdAt.isBefore(from)).length;
        return '$created created · ${state.openTasks.length} open';
      },
      activityTitle: 'Completion activity',
      byDay: byDay,
      byHourToday: byHour,
      unit: plural,
      shortUnit: (n) => '$n',
      dayDetails: (day) {
        final doneThatDay =
            done.where((t) => dayOf(t.completedAt!) == day).toList();
        final created = real.where((t) => dayOf(t.createdAt) == day).length;
        return [
          ('Completed', '${doneThatDay.length}'),
          ('Created', '$created'),
          for (final t in doneThatDay.take(3))
            ('✓', t.title.length > 36 ? '${t.title.substring(0, 35)}…' : t.title),
          if (doneThatDay.length > 3) ('', '+${doneThatDay.length - 3} more'),
        ];
      },
    );
  }
}
