# Focus Flow

A Pomodoro timer with tasks and focus statistics, built with Flutter for
macOS, Windows and Linux from one codebase.

- **Timer**: Work (25 min), Short Break (5 min), Long Break (15 min), four
  sessions per cycle, pinned tasks shown under the ring.
- **Tasks**: add tasks, click to pin, swipe right to complete, swipe left to
  delete, right-click or long press for more options.
- **Focus Stats** and **Task Stats**: day / week / month / year activity
  heatmaps with the real value in each tile, hover for details, totals,
  daily average, best day and streaks.
- All data is stored locally on the computer (no account, no network).

## Download

Every push to `main` builds a macOS `.dmg` on GitHub Actions:
**Actions → Build → latest run → Artifacts → FocusFlow-macOS**.
Tagged versions (`v1.0.0`, …) also attach the `.dmg`, a Windows `.zip` and a
Linux `.tar.gz` to a GitHub Release.

### First launch on macOS

The app is not signed with an Apple Developer ID yet, so macOS blocks the
first launch of a downloaded copy:

1. Open the `.dmg` and drag **Focus Flow** into **Applications**.
2. Open it once. When macOS refuses, go to **System Settings → Privacy &
   Security**, scroll down and click **Open Anyway**.

Or, in Terminal: `xattr -dr com.apple.quarantine "/Applications/Focus Flow.app"`

## Run from source

Requirements: [Flutter](https://docs.flutter.dev/get-started/install) (stable
channel). On macOS also Xcode; on Windows Visual Studio with "Desktop
development with C++"; on Linux `clang cmake ninja-build pkg-config
libgtk-3-dev`.

```bash
flutter pub get
flutter run -d macos     # or: -d windows, -d linux
```

Build a release yourself:

```bash
flutter build macos --release   # build/macos/Build/Products/Release/Focus Flow.app
flutter build windows --release # build/windows/x64/runner/Release/
flutter build linux --release   # build/linux/x64/release/bundle/
```

### Design preview with sample data

```bash
flutter run -d chrome --dart-define=DEMO=true --dart-define=PREVIEW_CHROME=true
```

`DEMO=true` wipes local data and fills in sample history, so use it only for
previews.

## Project layout

```
lib/
  main.dart                 window setup and sidebar shell
  theme.dart                colors and fonts
  state/                    data model, persistence, timer and stats logic
  screens/                  Timer, Tasks, Focus Stats, Task Stats
  widgets/                  sidebar, segmented control, heatmap, cards
tool/make_icon.py           regenerates the app icon for all platforms
.github/workflows/build.yml CI builds (.dmg, Windows, Linux)
```

The Nunito font is bundled (`assets/fonts`, SIL Open Font License) so the app
looks the same on every platform.
