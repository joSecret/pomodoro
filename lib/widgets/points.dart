import 'package:flutter/material.dart';

import '../state/models.dart';
import '../theme.dart';

const tooBigMessage =
    'More than ${TaskItem.maxPoints} pomodoros means the task is too big. '
    'Split it into smaller tasks.';

/// Stepper for a task's size in pomodoros (1..8). Pressing + at the limit
/// calls [onTooBig] instead of going higher.
class PointsPicker extends StatelessWidget {
  const PointsPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onTooBig,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback onTooBig;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, String tip, VoidCallback? onTap) => IconButton(
          tooltip: tip,
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          color: AppColors.textSecondary,
          disabledColor: AppColors.textMuted.withValues(alpha: 0.4),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        );
    return Tooltip(
      message: 'Size in pomodoros (1 = 25 min of focus)',
      waitDuration: const Duration(milliseconds: 600),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0x22000000),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          btn(Icons.remove, 'Fewer', value > 1 ? () => onChanged(value - 1) : null),
          const Icon(Icons.timer_outlined, size: 16, color: AppColors.accentSoft),
          const SizedBox(width: 4),
          SizedBox(
            width: 14,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: tabularFigures)),
          ),
          btn(Icons.add, 'More',
              value < TaskItem.maxPoints ? () => onChanged(value + 1) : onTooBig),
        ]),
      ),
    );
  }
}

/// Shows progress on a task: one dot per pomodoro, filled when done.
class PointsBadge extends StatelessWidget {
  const PointsBadge({super.key, required this.task, this.size = 8});
  final TaskItem task;
  final double size;

  @override
  Widget build(BuildContext context) {
    final over = task.spent - task.points;
    return Tooltip(
      message: '${task.spent} of ${task.points} '
          '${task.points == 1 ? 'pomodoro' : 'pomodoros'} done',
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < task.points; i++)
          Container(
            width: size,
            height: size,
            margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < task.spent ? AppColors.accentSoft : Colors.transparent,
              border: Border.all(
                  color: i < task.spent ? AppColors.accentSoft : AppColors.textMuted,
                  width: 1.4),
            ),
          ),
        if (over > 0)
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text('+$over',
                style: TextStyle(
                    fontSize: size + 3,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF5A524))),
          ),
      ]),
    );
  }
}

/// Inline warning shown under a points picker.
class TooBigNote extends StatelessWidget {
  const TooBigNote({super.key, required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(children: const [
                Icon(Icons.call_split, size: 18, color: Color(0xFFF5A524)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(tooBigMessage,
                      style: TextStyle(color: Color(0xFFF5A524), fontSize: 14)),
                ),
              ]),
            ),
    );
  }
}
