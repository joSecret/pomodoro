import 'models.dart';

enum StatsRange { day, week, month, year }

extension StatsRangeX on StatsRange {
  String get label => switch (this) {
        StatsRange.day => 'Day',
        StatsRange.week => 'Week',
        StatsRange.month => 'Month',
        StatsRange.year => 'Year',
      };
  String get thisLabel => switch (this) {
        StatsRange.day => 'today',
        StatsRange.week => 'this week',
        StatsRange.month => 'this month',
        StatsRange.year => 'this year',
      };

  /// Number of days covered by the activity grid.
  int get days => switch (this) {
        StatsRange.day => 1,
        StatsRange.week => 7,
        StatsRange.month => 30,
        StatsRange.year => 365,
      };
}

/// Groups values per calendar day.
Map<DateTime, int> perDay<T>(
    Iterable<T> items, DateTime Function(T) date, int Function(T) value) {
  final map = <DateTime, int>{};
  for (final it in items) {
    final d = dayOf(date(it));
    map[d] = (map[d] ?? 0) + value(it);
  }
  return map;
}

/// Start of the current period (inclusive).
DateTime periodStart(StatsRange r, DateTime now) {
  final today = dayOf(now);
  return switch (r) {
    StatsRange.day => today,
    StatsRange.week => addDays(today, 1 - today.weekday),
    StatsRange.month => DateTime(now.year, now.month),
    StatsRange.year => DateTime(now.year),
  };
}

class Streaks {
  const Streaks(this.current, this.best);
  final int current;
  final int best;
}

/// Current streak counts back from today; if today has nothing yet it counts
/// back from yesterday, so the streak is not lost before the day is over.
Streaks streaksFor(Set<DateTime> activeDays, DateTime now) {
  if (activeDays.isEmpty) return const Streaks(0, 0);
  final sorted = activeDays.toList()..sort();
  var best = 1, run = 1;
  for (var i = 1; i < sorted.length; i++) {
    final gap = daysBetween(sorted[i - 1], sorted[i]);
    run = gap == 1 ? run + 1 : 1;
    if (run > best) best = run;
  }
  var day = dayOf(now);
  if (!activeDays.contains(day)) day = addDays(day, -1);
  var current = 0;
  while (activeDays.contains(day)) {
    current++;
    day = addDays(day, -1);
  }
  return Streaks(current, best);
}

String formatMinutes(int m) {
  if (m < 60) return '${m}m';
  final h = m ~/ 60, r = m % 60;
  return r == 0 ? '${h}h' : '${h}h ${r}m';
}
