enum TimerMode { work, shortBreak, longBreak }

extension TimerModeX on TimerMode {
  String get label => switch (this) {
        TimerMode.work => 'Work',
        TimerMode.shortBreak => 'Short Break',
        TimerMode.longBreak => 'Long Break',
      };
}

class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.pinned = false,
    this.points = 1,
    this.spent = 0,
    this.completedAt,
    this.isDefault = false,
    this.deleteAllDefaults = false,
  });

  final String id;
  String title;
  bool pinned;
  final DateTime createdAt;
  DateTime? completedAt;

  /// Onboarding tasks shipped with the app. They do not count in stats.
  final bool isDefault;

  /// Estimated size in pomodoros (1..maxPoints).
  int points;

  /// Work sessions finished while this task was pinned.
  int spent;

  static const maxPoints = 8;

  /// Swiping this onboarding task left removes every onboarding task.
  final bool deleteAllDefaults;

  bool get isDone => completedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'pinned': pinned,
        'points': points,
        'spent': spent,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'isDefault': isDefault,
        'deleteAllDefaults': deleteAllDefaults,
      };

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
        id: j['id'] as String,
        title: j['title'] as String,
        pinned: j['pinned'] as bool? ?? false,
        points: j['points'] as int? ?? 1,
        spent: j['spent'] as int? ?? 0,
        createdAt: DateTime.parse(j['createdAt'] as String),
        completedAt: j['completedAt'] == null
            ? null
            : DateTime.parse(j['completedAt'] as String),
        isDefault: j['isDefault'] as bool? ?? false,
        deleteAllDefaults: j['deleteAllDefaults'] as bool? ?? false,
      );
}

/// One finished work (focus) session.
class FocusSession {
  FocusSession({required this.endedAt, required this.minutes, this.taskTitle});

  final DateTime endedAt;
  final int minutes;

  /// The task that was pinned while this session ran, if any.
  final String? taskTitle;

  Map<String, dynamic> toJson() => {
        'endedAt': endedAt.toIso8601String(),
        'minutes': minutes,
        if (taskTitle != null) 'taskTitle': taskTitle,
      };

  factory FocusSession.fromJson(Map<String, dynamic> j) => FocusSession(
        endedAt: DateTime.parse(j['endedAt'] as String),
        minutes: j['minutes'] as int,
        taskTitle: j['taskTitle'] as String?,
      );
}

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Calendar-safe day arithmetic (immune to daylight-saving shifts).
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;
