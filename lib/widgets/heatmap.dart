import 'dart:math';

import 'package:flutter/material.dart';

import '../state/models.dart';
import '../state/stats.dart';
import '../theme.dart';

const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

int _level(int v, int maxV) {
  if (v <= 0 || maxV <= 0) return 0;
  return (v / maxV * 4).ceil().clamp(1, 4);
}

/// Activity heatmap. Shows hours for Day, 7 tiles for Week, a calendar for
/// Month and a contribution-style grid for Year.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    super.key,
    required this.range,
    required this.byDay,
    required this.byHourToday,
    required this.unit,
    required this.shortUnit,
    required this.details,
    this.showLegend = true,
  });

  final StatsRange range;
  final Map<DateTime, int> byDay;
  final List<int> byHourToday;
  final String Function(int) unit;

  /// Compact value printed inside tiles, e.g. "1h 20m" or "3".
  final String Function(int) shortUnit;

  /// Rows (label, value) shown in the hover card for a day.
  final List<(String, String)> Function(DateTime day) details;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final grid = switch (range) {
      StatsRange.day => _hours(),
      StatsRange.week => _week(),
      StatsRange.month => _month(),
      StatsRange.year => _year(),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        grid,
        if (showLegend) ...[
          const SizedBox(height: 18),
          const Align(alignment: Alignment.centerRight, child: HeatLegend()),
        ],
      ],
    );
  }

  Widget _cell(int level,
      {double radius = 10,
      String? tip,
      DateTime? day,
      bool today = false,
      Widget? label}) {
    final box = Container(
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.fromLTRB(4, 4, 9, 7),
      child: label,
      decoration: BoxDecoration(
        color: AppColors.heat[level],
        borderRadius: BorderRadius.circular(radius),
        border: today
            ? Border.all(color: AppColors.accentSoft, width: 1.5)
            : null,
      ),
    );
    if (day != null) {
      return Tooltip(
        richMessage: _hoverCard(day),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        waitDuration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: const Color(0xFF34315A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x337C73F5)),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 6)),
          ],
        ),
        child: box,
      );
    }
    return tip == null ? box : Tooltip(message: tip, child: box);
  }

  Widget _hours() {
    final maxV = byHourToday.fold(0, max);
    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var h = 0; h < 24; h++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  children: [
                    Expanded(
                        child: _cell(_level(byHourToday[h], maxV),
                            radius: 6,
                            tip: '${h.toString().padLeft(2, '0')}:00 · '
                                '${unit(byHourToday[h])}')),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 16,
                      child: h % 3 == 0
                          ? Text('$h', style: _labelStyle)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _week() {
    final today = dayOf(DateTime.now());
    final days = [for (var i = 6; i >= 0; i--) addDays(today, -i)];
    final maxV = days.map((d) => byDay[d] ?? 0).fold(0, max);
    return LayoutBuilder(builder: (context, c) {
      final size = min(110.0, (c.maxWidth - 6 * 10) / 7);
      return Row(
        children: [
          for (final d in days) ...[
            Column(
              children: [
                SizedBox(
                  width: size,
                  height: size,
                  child: _cell(_level(byDay[d] ?? 0, maxV),
                      radius: 14,
                      today: d == today,
                      day: d,
                      label: _valueText(byDay[d] ?? 0, size / 9)),
                ),
                const SizedBox(height: 10),
                Text(_wd[d.weekday - 1], style: _labelStyle),
                Text('${d.day}',
                    style: _labelStyle.copyWith(color: AppColors.textMuted)),
              ],
            ),
            if (d != today) const SizedBox(width: 10),
          ],
        ],
      );
    });
  }

  Widget _month() {
    final today = dayOf(DateTime.now());
    final first = DateTime(today.year, today.month);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final lead = first.weekday - 1;
    final cells = lead + daysInMonth;
    final rows = (cells / 7).ceil();
    final maxV = [
      for (var i = 0; i < daysInMonth; i++) byDay[addDays(first, i)] ?? 0
    ].fold(0, max);
    return LayoutBuilder(builder: (context, c) {
      final size = min(56.0, (c.maxWidth - 6 * 8) / 7);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            for (var i = 0; i < 7; i++)
              Container(
                width: size,
                margin: EdgeInsets.only(right: i < 6 ? 8 : 0),
                alignment: Alignment.center,
                child: Text(_wd[i], style: _labelStyle),
              ),
          ]),
          const SizedBox(height: 8),
          for (var r = 0; r < rows; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                for (var col = 0; col < 7; col++)
                  Container(
                    width: size,
                    height: size,
                    margin: EdgeInsets.only(right: col < 6 ? 8 : 0),
                    child: () {
                      final idx = r * 7 + col - lead;
                      if (idx < 0 || idx >= daysInMonth) return null;
                      final d = addDays(first, idx);
                      final future = d.isAfter(today);
                      return Stack(children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: future ? 0.35 : 1,
                            child: _cell(_level(byDay[d] ?? 0, maxV),
                                radius: 10,
                                today: d == today,
                                day: d),
                          ),
                        ),
                        if ((byDay[d] ?? 0) > 0)
                          Positioned(
                            left: 2,
                            right: 6,
                            bottom: 5,
                            child: IgnorePointer(
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: _valueText(byDay[d]!, 10),
                              ),
                            ),
                          ),
                        Positioned(
                          left: 7,
                          top: 5,
                          child: IgnorePointer(
                            child: Text('${d.day}',
                                style: _labelStyle.copyWith(fontSize: 11)),
                          ),
                        ),
                      ]);
                    }(),
                  ),
              ]),
            ),
        ],
      );
    });
  }

  Widget _year() {
    final today = dayOf(DateTime.now());
    // 53 columns of weeks, the last column holds the current week.
    final lastMonday = addDays(today, 1 - today.weekday);
    final start = addDays(lastMonday, -52 * 7);
    final maxV = byDay.entries
        .where((e) => !e.key.isBefore(start))
        .map((e) => e.value)
        .fold(0, max);
    return LayoutBuilder(builder: (context, c) {
      const gap = 3.0, labelW = 30.0;
      final size = min(14.0, (c.maxWidth - labelW - 52 * gap) / 53);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month labels above the first week of each month.
          SizedBox(
            height: 18,
            child: Stack(children: [
              for (var w = 0; w < 53; w++)
                if (() {
                  final d = addDays(start, w * 7);
                  return d.day <= 7;
                }())
                  Positioned(
                    left: labelW + w * (size + gap),
                    child: Text(_months[addDays(start, w * 7).month - 1],
                        style: _labelStyle.copyWith(fontSize: 11)),
                  ),
            ]),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelW,
                child: Column(children: [
                  for (var r = 0; r < 7; r++)
                    SizedBox(
                      height: size + gap,
                      child: r.isEven
                          ? Text(_wd[r],
                              style: _labelStyle.copyWith(fontSize: 10))
                          : null,
                    ),
                ]),
              ),
              for (var w = 0; w < 53; w++)
                Padding(
                  padding: EdgeInsets.only(right: w < 52 ? gap : 0),
                  child: Column(children: [
                    for (var r = 0; r < 7; r++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: gap),
                        child: SizedBox(
                          width: size,
                          height: size,
                          child: () {
                            final d = addDays(start, w * 7 + r);
                            if (d.isAfter(today)) return null;
                            return _cell(_level(byDay[d] ?? 0, maxV),
                                radius: 3,
                                day: d);
                          }(),
                        ),
                      ),
                  ]),
                ),
            ],
          ),
        ],
      );
    });
  }
}

extension on ActivityHeatmap {
  TextSpan _hoverCard(DateTime d) {
    const full = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', //
      'Sunday'
    ];
    final rows = details(d);
    return TextSpan(
      style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 13, height: 1.55, color: AppColors.textPrimary),
      children: [
        TextSpan(
          text: '${full[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        for (final (label, value) in rows) ...[
          const TextSpan(text: '\n'),
          TextSpan(
              text: '$label  ',
              style: const TextStyle(color: AppColors.textSecondary)),
          TextSpan(
              text: value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontFeatures: tabularFigures)),
        ],
      ],
    );
  }

  Widget _valueText(int v, double size, {bool compact = false}) {
    if (v <= 0) return const SizedBox.shrink();
    final text = shortUnit(v);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Text(
          compact ? text.replaceAll(' ', '') : text,
          maxLines: 1,
          style: TextStyle(
            fontSize: size.clamp(10, 13),
            fontWeight: FontWeight.w600,
            fontFeatures: tabularFigures,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

const _labelStyle = TextStyle(
  fontSize: 13,
  color: AppColors.textSecondary,
  fontFeatures: tabularFigures,
);

class HeatLegend extends StatelessWidget {
  const HeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Less', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(width: 8),
        for (final c in AppColors.heat)
          Container(
            width: 13,
            height: 13,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
                color: c, borderRadius: BorderRadius.circular(3)),
          ),
        const SizedBox(width: 4),
        const Text('More', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}
