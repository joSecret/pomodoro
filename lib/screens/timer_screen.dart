import 'dart:math';

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/models.dart';
import '../theme.dart';
import '../widgets/points.dart';
import '../widgets/segmented.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pinned = state.pinnedTasks;
    return LayoutBuilder(builder: (context, c) {
      final ring = min(380.0, min(c.maxWidth - 80, c.maxHeight - 360))
          .clamp(200.0, 380.0);
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Segmented<TimerMode>(
                  values: TimerMode.values,
                  selected: state.mode,
                  label: (m) => m.label,
                  onChanged: (m) => _switchMode(context, m),
                ),
                const SizedBox(height: 28),
                SizedBox.square(
                  dimension: ring,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: state.isFresh ? 0 : state.progress,
                    ),
                    child: Center(child: _TimeLabel(state: state, ring: ring)),
                  ),
                ),
                const SizedBox(height: 28),
                _SessionDots(state: state),
                const SizedBox(height: 22),
                _PinnedTasks(tasks: pinned),
                const SizedBox(height: 22),
                _Controls(state: state),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _switchMode(BuildContext context, TimerMode m) async {
    if (m == state.mode) return;
    if (state.running) {
      final secs = (state.remaining.inMilliseconds / 1000).ceil();
      final left = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Switch to ${m.label}?'),
          content: Text(
              'Your ${state.mode.label} timer is running ($left left). It will be '
              'paused and kept, so you can come back and resume it.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Keep ${state.mode.label.toLowerCase()}')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Switch')),
          ],
        ),
      );
      if (ok != true) return;
    }
    state.setMode(m);
  }
}

/// Asks what the user is working on before a fresh Work session when no task
/// is pinned. Returns false if the user cancelled.
Future<bool> askFocusTask(BuildContext context, AppState state) async {
  final result = await showDialog<_FocusChoice>(
    context: context,
    builder: (_) => _FocusTaskDialog(state: state),
  );
  if (result == null) return false;
  if (result.task != null) state.focusOn(result.task!);
  if (result.newTitle != null) {
    state.addTask(result.newTitle!, pinned: true, points: result.points);
  }
  return true;
}

class _FocusChoice {
  const _FocusChoice({this.task, this.newTitle, this.points = 1});
  final TaskItem? task;
  final String? newTitle;
  final int points;
}

class _FocusTaskDialog extends StatefulWidget {
  const _FocusTaskDialog({required this.state});
  final AppState state;

  @override
  State<_FocusTaskDialog> createState() => _FocusTaskDialogState();
}

class _FocusTaskDialogState extends State<_FocusTaskDialog> {
  final _c = TextEditingController();
  int _points = 1;
  bool _tooBig = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _start() {
    final text = _c.text.trim();
    Navigator.pop(
        context,
        text.isEmpty
            ? const _FocusChoice()
            : _FocusChoice(newTitle: text, points: _points));
  }

  @override
  Widget build(BuildContext context) {
    final open = widget.state.openTasks.where((t) => !t.isDefault).toList();
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('What are you working on?'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _c,
                  autofocus: true,
                  onSubmitted: (_) => _start(),
                  decoration: const InputDecoration(
                    hintText: 'Type a new task',
                    prefixIcon: Icon(Icons.edit_outlined, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PointsPicker(
                value: _points,
                onChanged: (v) => setState(() {
                  _points = v;
                  _tooBig = false;
                }),
                onTooBig: () => setState(() => _tooBig = true),
              ),
            ]),
            TooBigNote(visible: _tooBig),
            if (open.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('Or pick one of your tasks',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final t in open)
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        leading: const Icon(Icons.radio_button_unchecked,
                            size: 18, color: AppColors.textMuted),
                        title: Text(t.title, style: const TextStyle(fontSize: 15)),
                        trailing: PointsBadge(task: t, size: 7),
                        onTap: () => Navigator.pop(context, _FocusChoice(task: t)),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const _FocusChoice()),
          child: const Text('Start without a task'),
        ),
        FilledButton(onPressed: _start, child: const Text('Start')),
      ],
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.state, required this.ring});
  final AppState state;
  final double ring;

  @override
  Widget build(BuildContext context) {
    final fresh = state.isFresh;
    final r = state.remaining;
    // Round up so the display never shows 00:00 while time is left.
    final secs = (r.inMilliseconds / 1000).ceil();
    final text = fresh
        ? '${state.minutesFor[state.mode]}'
        : '${(secs ~/ 60).toString().padLeft(2, '0')}:'
            '${(secs % 60).toString().padLeft(2, '0')}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: ring * (fresh ? 0.27 : 0.21),
            fontWeight: FontWeight.w300,
            color: const Color(0xFFCFCDE0),
            fontFeatures: tabularFigures,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          fresh ? 'minutes' : (state.running ? state.mode.label : 'Paused'),
          style: const TextStyle(fontSize: 18, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Offset.zero & size;
    final circle = rect.deflate(stroke / 2);
    canvas.drawArc(
      circle,
      0,
      2 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.ringTrack,
    );
    if (progress > 0) {
      canvas.drawArc(
        circle,
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..shader = const SweepGradient(
            colors: [AppColors.accentSoft, AppColors.accent, AppColors.accentSoft],
            transform: GradientRotation(-pi / 2),
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _SessionDots extends StatelessWidget {
  const _SessionDots({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < AppState.sessionsPerCycle; i++)
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < state.completedInCycle
                  ? AppColors.accent
                  : Colors.transparent,
              border: Border.all(
                color: i < state.completedInCycle
                    ? AppColors.accent
                    : (i == state.completedInCycle &&
                            state.mode == TimerMode.work)
                        ? AppColors.accentSoft
                        : AppColors.textMuted,
                width: 1.5,
              ),
            ),
            child: Text(
              '${i + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: i < state.completedInCycle
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _PinnedTasks extends StatelessWidget {
  const _PinnedTasks({required this.tasks});
  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Text('No pinned task. Pin one from Tasks.',
          style: TextStyle(fontSize: 15, color: AppColors.textMuted));
    }
    return Column(
      children: [
        for (final t in tasks.take(3))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.push_pin, size: 18, color: AppColors.accentSoft),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    t.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentSoft,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PointsBadge(task: t, size: 9),
              ],
            ),
          ),
        if (tasks.length > 3)
          Text('+${tasks.length - 3} more',
              style: const TextStyle(color: AppColors.textMuted)),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final label = state.running ? 'Pause' : (state.isFresh ? 'Start' : 'Resume');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIcon(
          icon: Icons.refresh_rounded,
          tip: 'Reset',
          onTap: state.isFresh ? null : state.reset,
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 230,
          height: 74,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              textStyle:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            onPressed: state.running ? state.pause : () => _start(context),
            child: Text(label),
          ),
        ),
        const SizedBox(width: 18),
        _RoundIcon(
          icon: Icons.skip_next_rounded,
          tip: 'Skip to next',
          onTap: state.skip,
        ),
      ],
    );
  }
}

Future<void> _start(BuildContext context) async {
  // Ask only before a fresh Work session with nothing pinned.
  final s = (context.findAncestorWidgetOfExactType<TimerScreen>())!.state;
  if (s.mode == TimerMode.work && s.isFresh && s.pinnedTasks.isEmpty) {
    if (!await askFocusTask(context, s)) return;
  }
  s.start();
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.tip, this.onTap});
  final IconData icon;
  final String tip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        iconSize: 24,
        color: AppColors.textSecondary,
        disabledColor: AppColors.textMuted.withValues(alpha: 0.4),
        style: IconButton.styleFrom(
          fixedSize: const Size(50, 50),
          backgroundColor: const Color(0x22FFFFFF),
        ),
      ),
    );
  }
}
