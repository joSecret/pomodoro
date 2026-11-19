import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Single source of truth for tasks, focus sessions and the running timer.
/// Everything is saved locally with shared_preferences, which works the same
/// on macOS, Windows and Linux.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _load();
  }

  static const _kTasks = 'tasks_v1';
  static const _kSessions = 'sessions_v1';
  static const _kCycle = 'cycle_v1';
  static const sessionsPerCycle = 4;

  final SharedPreferences _prefs;

  final List<TaskItem> tasks = [];
  final List<FocusSession> sessions = [];

  // ---- Timer ---------------------------------------------------------------

  final Map<TimerMode, int> minutesFor = {
    TimerMode.work: 25,
    TimerMode.shortBreak: 5,
    TimerMode.longBreak: 15,
  };

  TimerMode mode = TimerMode.work;
  bool running = false;
  int completedInCycle = 0;
  Duration remaining = const Duration(minutes: 25);
  DateTime? _endsAt;
  Timer? _ticker;

  Duration get total => Duration(minutes: minutesFor[mode]!);
  bool get isFresh => !running && remaining == total;
  double get progress =>
      1 - remaining.inMilliseconds / max(1, total.inMilliseconds);

  /// Time left on modes the user switched away from, so coming back to a
  /// tab resumes where it was instead of starting over.
  final Map<TimerMode, Duration> _saved = {};

  Duration remainingFor(TimerMode m) =>
      m == mode ? remaining : (_saved[m] ?? Duration(minutes: minutesFor[m]!));

  void setMode(TimerMode m) {
    if (m == mode) return;
    if (running) {
      _tick();
      _stopTicker();
    }
    if (remaining != total) {
      _saved[mode] = remaining;
    } else {
      _saved.remove(mode);
    }
    mode = m;
    remaining = _saved.remove(m) ?? total;
    notifyListeners();
  }

  void start() {
    if (running) return;
    running = true;
    _endsAt = DateTime.now().add(remaining);
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    notifyListeners();
  }

  void pause() {
    if (!running) return;
    _tick();
    _stopTicker();
    notifyListeners();
  }

  void reset() {
    _stopTicker();
    _saved.remove(mode);
    remaining = total;
    notifyListeners();
  }

  /// Ends the current phase now, as if the time had run out.
  void skip() {
    _stopTicker();
    _finishPhase(countSession: false);
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    running = false;
    _endsAt = null;
  }

  void _tick() {
    final end = _endsAt;
    if (end == null) return;
    final left = end.difference(DateTime.now());
    if (left <= Duration.zero) {
      _stopTicker();
      SystemSound.play(SystemSoundType.alert);
      _finishPhase(countSession: true);
      return;
    }
    // Only rebuild when the visible second changes.
    final changed = left.inSeconds != remaining.inSeconds;
    remaining = left;
    if (changed) notifyListeners();
  }

  void _finishPhase({required bool countSession}) {
    _saved.remove(mode);
    if (mode == TimerMode.work) {
      if (countSession) {
        final focus = pinnedTasks;
        if (focus.isNotEmpty) {
          focus.first.spent++;
          _saveTasks(notify: false);
        }
        sessions.add(FocusSession(
            endedAt: DateTime.now(),
            minutes: minutesFor[TimerMode.work]!,
            taskTitle: focus.isEmpty ? null : focus.first.title));
        _saveSessions();
      }
      completedInCycle = min(sessionsPerCycle, completedInCycle + 1);
      mode = completedInCycle >= sessionsPerCycle
          ? TimerMode.longBreak
          : TimerMode.shortBreak;
    } else {
      if (mode == TimerMode.longBreak) completedInCycle = 0;
      mode = TimerMode.work;
    }
    _saved.remove(mode);
    _prefs.setInt(_kCycle, completedInCycle);
    remaining = total;
    notifyListeners();
  }

  // ---- Tasks ---------------------------------------------------------------

  List<TaskItem> get openTasks => tasks.where((t) => !t.isDone).toList();
  List<TaskItem> get doneTasks =>
      tasks.where((t) => t.isDone).toList()
        ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  List<TaskItem> get pinnedTasks =>
      tasks.where((t) => t.pinned && !t.isDone).toList();

  TaskItem? addTask(String title, {bool pinned = false, int points = 1}) {
    final t = title.trim();
    if (t.isEmpty) return null;
    final item = TaskItem(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      title: t,
      createdAt: DateTime.now(),
      pinned: pinned,
      points: points.clamp(1, TaskItem.maxPoints),
    );
    tasks.insert(0, item);
    _saveTasks();
    return item;
  }

  /// Makes [t] the task shown under the timer.
  void focusOn(TaskItem t) {
    t.pinned = true;
    _saveTasks();
  }

  void togglePin(TaskItem t) {
    t.pinned = !t.pinned;
    _saveTasks();
  }

  void complete(TaskItem t) {
    t.completedAt = DateTime.now();
    t.pinned = false;
    _saveTasks();
  }

  void reopen(TaskItem t) {
    t.completedAt = null;
    _saveTasks();
  }

  void edit(TaskItem t, String title, int points) {
    if (title.trim().isNotEmpty) t.title = title.trim();
    t.points = points.clamp(1, TaskItem.maxPoints);
    _saveTasks();
  }

  void delete(TaskItem t) {
    if (t.deleteAllDefaults) {
      tasks.removeWhere((x) => x.isDefault);
    } else {
      tasks.remove(t);
    }
    _saveTasks();
  }

  void clearCompleted() {
    tasks.removeWhere((t) => t.isDone);
    _saveTasks();
  }

  // ---- Persistence ---------------------------------------------------------

  void _load() {
    final rawTasks = _prefs.getString(_kTasks);
    if (rawTasks == null) {
      tasks.addAll(_defaultTasks());
      _saveTasks(notify: false);
    } else {
      tasks.addAll((jsonDecode(rawTasks) as List)
          .map((e) => TaskItem.fromJson(e as Map<String, dynamic>)));
    }
    final rawSessions = _prefs.getString(_kSessions);
    if (rawSessions != null) {
      sessions.addAll((jsonDecode(rawSessions) as List)
          .map((e) => FocusSession.fromJson(e as Map<String, dynamic>)));
    }
    completedInCycle = _prefs.getInt(_kCycle) ?? 0;
    if (completedInCycle >= sessionsPerCycle) mode = TimerMode.longBreak;
    remaining = total;
  }

  void _saveTasks({bool notify = true}) {
    _prefs.setString(
        _kTasks, jsonEncode(tasks.map((t) => t.toJson()).toList()));
    if (notify) notifyListeners();
  }

  void _saveSessions() {
    _prefs.setString(
        _kSessions, jsonEncode(sessions.map((s) => s.toJson()).toList()));
  }

  static List<TaskItem> _defaultTasks() {
    final now = DateTime.now();
    var i = 0;
    TaskItem d(String title, {bool pinned = false, bool all = false}) =>
        TaskItem(
          id: 'default-${i++}',
          title: title,
          createdAt: now,
          pinned: pinned,
          isDefault: true,
          deleteAllDefaults: all,
        );
    return [
      d('Your pinned tasks will show up on the timer too!', pinned: true),
      d('👉 Swipe right on a task to mark it done ✅'),
      d('Swipe left on a task to delete it 👈'),
      d('Click a task to pin 📌 it, right-click or long press for more options'),
      d('Swipe left on this task to remove all the starter tasks 👈',
          all: true),
    ];
  }

  /// Fills the app with sample history. Only used for design previews
  /// (run with --dart-define=DEMO=true).
  void seedDemo() {
    final rnd = Random(7);
    final today = dayOf(DateTime.now());
    for (var back = 200; back >= 0; back--) {
      final day = addDays(today, -back);
      if (rnd.nextDouble() < 0.35 && back > 6) continue;
      final n = back == 0 ? 2 : rnd.nextInt(7);
      for (var k = 0; k < n; k++) {
        sessions.add(FocusSession(
            endedAt: day.add(Duration(hours: 9 + k * 2)), minutes: 25));
      }
      final done = back == 0 ? 1 : rnd.nextInt(4);
      for (var k = 0; k < done; k++) {
        tasks.add(TaskItem(
          id: 'demo-$back-$k',
          title: const ['Write report', 'Review PR', 'Plan sprint', 'Read docs'][k % 4],
          createdAt: day,
          completedAt: day.add(Duration(hours: 10 + k)),
        ));
      }
    }
    var n = 0;
    for (final (title, pts, spent) in [
      ('Design the onboarding screens', 4, 1),
      ('Write the Q4 report', 3, 3),
      ('Fix login bug on Windows', 2, 0),
      ('Prepare slides for Friday', 5, 6),
    ]) {
      tasks.insert(
          n++,
          TaskItem(
            id: 'demo-open-$n',
            title: title,
            createdAt: today,
            points: pts,
            spent: spent,
          ));
    }
    completedInCycle = 2;
    notifyListeners();
  }
}
