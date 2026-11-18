import 'package:flutter/material.dart';

import '../state/models.dart';
import '../state/stats.dart';
import '../theme.dart';
import 'card.dart';
import 'heatmap.dart';
import 'segmented.dart';

/// Shared layout for Focus Stats and Task Stats.
class StatsView extends StatefulWidget {
  const StatsView({
    super.key,
    required this.ranges,
    required this.initial,
    required this.headline,
    required this.bigValue,
    required this.subValue,
    required this.activityTitle,
    required this.byDay,
    required this.byHourToday,
    required this.unit,
    required this.shortUnit,
    required this.dayDetails,
  });

  final List<StatsRange> ranges;
  final StatsRange initial;
  final String Function(StatsRange) headline;
  final String Function(StatsRange) bigValue;
  final String Function(StatsRange) subValue;
  final String activityTitle;
  final Map<DateTime, int> byDay;
  final List<int> byHourToday;
  final String Function(int) unit;
  final String Function(int) shortUnit;

  /// Screen-specific rows for the hover card of one day.
  final List<(String, String)> Function(DateTime day) dayDetails;

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  late StatsRange range = widget.initial;

  String _activitySubtitle() {
    final today = dayOf(DateTime.now());
    if (range == StatsRange.day) {
      final active = widget.byHourToday.where((v) => v > 0).length;
      return 'Today · $active active ${active == 1 ? 'hour' : 'hours'}';
    }
    final from = range == StatsRange.month
        ? DateTime(today.year, today.month)
        : addDays(today, -(range.days - 1));
    final active = widget.byDay.entries
        .where((e) => !e.key.isBefore(from) && !e.key.isAfter(today) && e.value > 0)
        .length;
    final span = switch (range) {
      StatsRange.week => 'Last 7 days',
      StatsRange.month => 'This month',
      _ => 'Last 12 months',
    };
    return '$span · $active active ${active == 1 ? 'day' : 'days'}';
  }

  /// Day rows plus how the day compares with the selected period.
  List<(String, String)> _details(DateTime day) {
    final rows = [...widget.dayDetails(day)];
    final v = widget.byDay[day] ?? 0;
    final (total, span) = _periodTotal();
    if (v > 0 && total > 0 && range != StatsRange.day) {
      final share = (v / total * 100).round();
      rows.add(('Share of ${range.thisLabel.replaceFirst('this ', '')}', '$share%'));
      final avg = total / span;
      final diff = ((v - avg) / avg * 100).round();
      rows.add(('vs daily average', '${diff >= 0 ? '+' : ''}$diff%'));
    }
    return rows;
  }

  (int, int) _periodTotal() {
    final today = dayOf(DateTime.now());
    final from = range == StatsRange.month
        ? DateTime(today.year, today.month)
        : addDays(today, -(range.days - 1));
    final span = daysBetween(from, today) + 1;
    var total = 0;
    for (var i = 0; i < span; i++) {
      total += widget.byDay[addDays(from, i)] ?? 0;
    }
    return (total, span);
  }

  static const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Real numbers under the heatmap: total, daily average and best day.
  List<Widget> _summary() {
    if (range == StatsRange.day) return const [];
    final today = dayOf(DateTime.now());
    final from = range == StatsRange.month
        ? DateTime(today.year, today.month)
        : addDays(today, -(range.days - 1));
    final span = daysBetween(from, today) + 1;
    var total = 0;
    DateTime? bestDay;
    var best = 0;
    for (var i = 0; i < span; i++) {
      final d = addDays(from, i);
      final v = widget.byDay[d] ?? 0;
      total += v;
      if (v > best) {
        best = v;
        bestDay = d;
      }
    }
    Widget tile(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFeatures: tabularFigures)),
            ],
          ),
        );
    return [
      const SizedBox(height: 18),
      const Divider(height: 1, color: AppColors.divider),
      const SizedBox(height: 16),
      Row(children: [
        tile('Total', widget.unit(total)),
        tile('Daily average', widget.unit((total / span).round())),
        tile(
            'Best day',
            bestDay == null
                ? '—'
                : '${_wd[bestDay.weekday - 1]} ${bestDay.day} · '
                    '${widget.unit(best)}'),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeDays =
        widget.byDay.entries.where((e) => e.value > 0).map((e) => e.key).toSet();
    final streaks = streaksFor(activeDays, DateTime.now());
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 36, 40, 40),
      children: [
        Center(
          child: Segmented<StatsRange>(
            values: widget.ranges,
            selected: range,
            label: (r) => r.label,
            onChanged: (r) => setState(() => range = r),
          ),
        ),
        const SizedBox(height: 28),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.headline(range),
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              BigNumber(widget.bigValue(range), size: 48),
              const SizedBox(height: 8),
              Text(widget.subValue(range),
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.activityTitle,
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(_activitySubtitle(),
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 22),
              ActivityHeatmap(
                range: range,
                byDay: widget.byDay,
                byHourToday: widget.byHourToday,
                unit: widget.unit,
                shortUnit: widget.shortUnit,
                details: _details,
              ),
              ..._summary(),
            ],
          ),
        ),
        const SectionLabel('All time'),
        StreakCard(streaks: streaks, activeDays: activeDays),
      ],
    );
  }
}

class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streaks, required this.activeDays});
  final Streaks streaks;
  final Set<DateTime> activeDays;

  @override
  Widget build(BuildContext context) {
    final today = dayOf(DateTime.now());
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BigNumber('${streaks.current}'),
                      const SizedBox(height: 6),
                      Text(
                          streaks.current == 1
                              ? 'Day current streak'
                              : 'Days current streak',
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const VerticalDivider(color: AppColors.divider, width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BigNumber(streaks.best == 0 ? '—' : '${streaks.best}'),
                      const SizedBox(height: 6),
                      Text(
                          streaks.best == 0
                              ? 'No best streak yet'
                              : (streaks.best == 1
                                  ? 'Day best streak'
                                  : 'Days best streak'),
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('Last 7 days',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 6; i >= 0; i--)
                () {
                  final d = addDays(today, -i);
                  final on = activeDays.contains(d);
                  return Column(children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on ? AppColors.accent : AppColors.heat[1],
                        border: d == today
                            ? Border.all(color: AppColors.accentSoft, width: 2)
                            : null,
                      ),
                      child: on
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(letters[d.weekday - 1],
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ]);
                }(),
            ],
          ),
        ],
      ),
    );
  }
}
