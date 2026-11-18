import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/models.dart';
import '../state/stats.dart';
import '../widgets/stats_view.dart';

class FocusStatsScreen extends StatelessWidget {
  const FocusStatsScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final byDay = perDay(state.sessions, (s) => s.endedAt, (s) => s.minutes);
    final today = dayOf(now);
    final byHour = List<int>.filled(24, 0);
    for (final s in state.sessions) {
      if (dayOf(s.endedAt) == today) byHour[s.endedAt.hour] += s.minutes;
    }
    Iterable<FocusSession> inRange(StatsRange r) {
      final from = periodStart(r, now);
      return state.sessions.where((s) => !s.endedAt.isBefore(from));
    }

    return StatsView(
      ranges: StatsRange.values,
      initial: StatsRange.week,
      headline: (r) => 'Focus ${r.thisLabel}',
      bigValue: (r) => formatMinutes(
          inRange(r).fold<int>(0, (a, s) => a + s.minutes)),
      subValue: (r) {
        final n = inRange(r).length;
        return '$n ${n == 1 ? 'session' : 'sessions'}';
      },
      activityTitle: 'Activity',
      byDay: byDay,
      byHourToday: byHour,
      unit: formatMinutes,
      shortUnit: formatMinutes,
      dayDetails: (day) {
        final list = state.sessions.where((x) => dayOf(x.endedAt) == day).toList()
          ..sort((a, b) => a.endedAt.compareTo(b.endedAt));
        if (list.isEmpty) return const [('Focus', 'none')];
        String hm(DateTime t) =>
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        final mins = list.fold<int>(0, (a, x) => a + x.minutes);
        final first = list.first.endedAt
            .subtract(Duration(minutes: list.first.minutes));
        return [
          ('Focus', formatMinutes(mins)),
          ('Sessions', '${list.length}'),
          ('Active', '${hm(first)} – ${hm(list.last.endedAt)}'),
        ];
      },
    );
  }
}
