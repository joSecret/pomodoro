import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/models.dart';
import '../theme.dart';
import '../widgets/points.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.state});
  final AppState state;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  bool _showDone = false;
  int _points = 1;
  bool _tooBig = false;
  int _tooBigToken = 0;

  void _warnTooBig() {
    final token = ++_tooBigToken;
    setState(() => _tooBig = true);
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && token == _tooBigToken) setState(() => _tooBig = false);
    });
  }

  AppState get s => widget.state;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    s.addTask(_input.text, points: _points);
    _input.clear();
    setState(() {
      _points = 1;
      _tooBig = false;
    });
    _focus.requestFocus();
  }

  Future<void> _menu(TaskItem t, Offset at) async {
    final choice = await showMenu<String>(
      context: context,
      color: AppColors.surfaceHigh,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy),
      items: [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'pin', child: Text(t.pinned ? 'Unpin' : 'Pin')),
        const PopupMenuItem(value: 'done', child: Text('Mark as done')),
        const PopupMenuItem(
            value: 'delete',
            child: Text('Delete', style: TextStyle(color: AppColors.danger))),
      ],
    );
    switch (choice) {
      case 'edit':
        _edit(t);
      case 'pin':
        s.togglePin(t);
      case 'done':
        s.complete(t);
      case 'delete':
        s.delete(t);
    }
  }

  Future<void> _edit(TaskItem t) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _EditTaskDialog(task: t, state: s),
    );
  }

  @override
  Widget build(BuildContext context) {
    final open = s.openTasks;
    final done = s.doneTasks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(32, 44, 32, 12),
          child: Text('Pending Tasks',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              _AddField(
                controller: _input,
                focus: _focus,
                onSubmit: _submit,
                picker: PointsPicker(
                  value: _points,
                  onChanged: (v) => setState(() {
                    _points = v;
                    _tooBig = false;
                  }),
                  onTooBig: _warnTooBig,
                ),
              ),
              TooBigNote(visible: _tooBig),
              const SizedBox(height: 14),
              if (open.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('All clear. Add a task above.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
                  ),
                ),
              for (final t in open)
                _TaskRow(
                  key: ValueKey(t.id),
                  task: t,
                  onTap: () => s.togglePin(t),
                  onMenu: (pos) => _menu(t, pos),
                  onDone: () => s.complete(t),
                  onDelete: () => s.delete(t),
                ),
              if (done.isNotEmpty) ...[
                const SizedBox(height: 18),
                Row(children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _showDone = !_showDone),
                    icon: Icon(_showDone
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right),
                    label: Text('Completed (${done.length})'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  if (_showDone)
                    TextButton(
                      onPressed: s.clearCompleted,
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted),
                      child: const Text('Clear'),
                    ),
                ]),
                if (_showDone)
                  for (final t in done.take(100))
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle,
                          color: AppColors.success, size: 20),
                      title: Text(t.title,
                          style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough)),
                      trailing: IconButton(
                        tooltip: 'Move back to pending',
                        icon: const Icon(Icons.undo, size: 18),
                        color: AppColors.textMuted,
                        onPressed: () => s.reopen(t),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AddField extends StatelessWidget {
  const _AddField({
    required this.controller,
    required this.focus,
    required this.onSubmit,
    required this.picker,
  });
  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onSubmit;
  final Widget picker;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.only(left: 16, right: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x2EFFFFFF)),
      ),
      child: Row(children: [
        IconButton(
          onPressed: onSubmit,
          icon: const Icon(Icons.add_circle, size: 28),
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focus,
            onSubmitted: (_) => onSubmit(),
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Add a task',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 8),
        picker,
      ]),
    );
  }
}

class _TaskRow extends StatefulWidget {
  const _TaskRow({
    super.key,
    required this.task,
    required this.onTap,
    required this.onMenu,
    required this.onDone,
    required this.onDelete,
  });
  final TaskItem task;
  final VoidCallback onTap;
  final ValueChanged<Offset> onMenu;
  final VoidCallback onDone;
  final VoidCallback onDelete;

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _dismissible(t),
      const Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
    ]);
  }

  Widget _dismissible(TaskItem t) {
    return Dismissible(
      key: ValueKey('dismiss-${t.id}'),
      background: _swipeBg(AppColors.success, Icons.check, 'Done', true),
      secondaryBackground:
          _swipeBg(AppColors.danger, Icons.delete_outline, 'Delete', false),
      onDismissed: (dir) => dir == DismissDirection.startToEnd
          ? widget.onDone()
          : widget.onDelete(),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPressStart: (d) => widget.onMenu(d.globalPosition),
          onSecondaryTapDown: (d) => widget.onMenu(d.globalPosition),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: t.pinned
                  ? AppColors.surfaceHigh
                  : (_hover ? const Color(0x0FFFFFFF) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Expanded(
                child: Text(t.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 12),
              if (!t.isDefault) ...[
                PointsBadge(task: t),
                const SizedBox(width: 16),
              ],
              Icon(
                t.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 22,
                color: t.pinned ? AppColors.accentSoft : AppColors.textSecondary,
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _swipeBg(Color c, IconData icon, String label, bool left) {
    return Container(
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EditTaskDialog extends StatefulWidget {
  const _EditTaskDialog({required this.task, required this.state});
  final TaskItem task;
  final AppState state;

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  late final _c = TextEditingController(text: widget.task.title);
  late int _points = widget.task.points;
  bool _tooBig = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _save() {
    widget.state.edit(widget.task, _c.text, _points);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Edit task'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _c, autofocus: true, onSubmitted: (_) => _save()),
            const SizedBox(height: 18),
            Row(children: [
              const Text('Size',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              PointsPicker(
                value: _points,
                onChanged: (v) => setState(() {
                  _points = v;
                  _tooBig = false;
                }),
                onTooBig: () => setState(() => _tooBig = true),
              ),
              const SizedBox(width: 12),
              Text('${widget.task.spent} done',
                  style: const TextStyle(color: AppColors.textMuted)),
            ]),
            TooBigNote(visible: _tooBig),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
