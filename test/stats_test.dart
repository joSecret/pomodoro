import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/state/models.dart';
import 'package:focus_flow/state/stats.dart';

void main() {
  final now = DateTime(2026, 11, 18, 15);
  DateTime d(int day) => DateTime(2026, 11, day);

  test('no activity means no streaks', () {
    final s = streaksFor({}, now);
    expect(s.current, 0);
    expect(s.best, 0);
  });

  test('current streak counts back from today', () {
    final s = streaksFor({d(16), d(17), d(18)}, now);
    expect(s.current, 3);
    expect(s.best, 3);
  });

  test('streak is kept while today is still empty', () {
    final s = streaksFor({d(16), d(17)}, now);
    expect(s.current, 2);
  });

  test('best streak survives a gap', () {
    final s = streaksFor({d(1), d(2), d(3), d(4), d(10), d(18)}, now);
    expect(s.current, 1);
    expect(s.best, 4);
  });

  test('day math ignores daylight saving changes', () {
    expect(daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
    expect(addDays(DateTime(2026, 3, 29), 1), DateTime(2026, 3, 30));
  });

  test('minutes format', () {
    expect(formatMinutes(0), '0m');
    expect(formatMinutes(25), '25m');
    expect(formatMinutes(60), '1h');
    expect(formatMinutes(250), '4h 10m');
  });
}
