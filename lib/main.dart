import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'screens/focus_stats_screen.dart';
import 'screens/task_stats_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/timer_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/sidebar.dart';

const _demo = bool.fromEnvironment('DEMO');
const _startTab = int.fromEnvironment('START_TAB');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) await _setupWindow();

  final prefs = await SharedPreferences.getInstance();
  if (_demo) await prefs.clear();
  final state = AppState(prefs);
  if (_demo) state.seedDemo();
  runApp(FocusFlowApp(state: state));
}

/// Sizes and centers the window. Any failure here must never keep the window
/// from showing, so errors are logged and the window is shown anyway.
Future<void> _setupWindow() async {
  try {
    await windowManager.ensureInitialized();
    // The macOS title bar is configured natively in MainFlutterWindow.swift.
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(1100, 780),
        minimumSize: Size(760, 640),
        center: true,
        title: 'Focus Flow',
      ),
    );
  } catch (e, st) {
    debugPrint('Window setup failed: $e\n$st');
  } finally {
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (_) {}
  }
}

class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Flow',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeShell(state: state),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.state});
  final AppState state;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = _startTab;
  bool _collapsed = false;

  static const _items = [
    NavItem(Icons.timer_outlined, 'Timer'),
    NavItem(Icons.checklist_rounded, 'Tasks'),
    NavItem(Icons.bar_chart_rounded, 'Focus Stats'),
    NavItem(Icons.check_circle_outline, 'Task Stats'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgTop, Color(0xFF242238), AppColors.bgBottom],
          ),
        ),
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: widget.state,
              builder: (context, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Sidebar(
                    items: _items,
                    selected: _tab,
                    onSelect: (i) => setState(() => _tab = i),
                    collapsed: _collapsed,
                    onToggle: () => setState(() => _collapsed = !_collapsed),
                  ),
                  Expanded(
                    child: Stack(children: [
                      Positioned.fill(child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: switch (_tab) {
                          0 => TimerScreen(state: widget.state),
                          1 => TasksScreen(state: widget.state),
                          2 => FocusStatsScreen(state: widget.state),
                          _ => TaskStatsScreen(state: widget.state),
                        },
                      ),
                    )),
                      // Empty strip at the top: drag here to move the window
                      // (the macOS title bar is hidden behind the content).
                      if (reserveTrafficLights && !kIsWeb)
                        const Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          height: 22,
                          child: DragToMoveArea(child: SizedBox.expand()),
                        ),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
