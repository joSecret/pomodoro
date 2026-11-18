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

  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1100, 780),
      minimumSize: Size(760, 640),
      center: true,
      title: 'Focus Flow',
      backgroundColor: Color(0xFF1C1A3A),
      // On macOS the title bar is hidden but the native window buttons stay
      // visible over the sidebar. Windows and Linux keep their normal frame.
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: true,
    );
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    await windowManager.waitUntilReadyToShow(
        mac ? options : const WindowOptions(
          size: Size(1100, 780),
          minimumSize: Size(760, 640),
          center: true,
          title: 'Focus Flow',
        ), () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final prefs = await SharedPreferences.getInstance();
  if (_demo) await prefs.clear();
  final state = AppState(prefs);
  if (_demo) state.seedDemo();
  runApp(FocusFlowApp(state: state));
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
            // Lets the user drag the window by the empty top strip on
            // platforms where the title bar is hidden.
            if (!kIsWeb)
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 32,
                child: DragToMoveArea(child: SizedBox.expand()),
              ),
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
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: switch (_tab) {
                          0 => TimerScreen(state: widget.state),
                          1 => TasksScreen(state: widget.state),
                          2 => FocusStatsScreen(state: widget.state),
                          _ => TaskStatsScreen(state: widget.state),
                        },
                      ),
                    ),
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
