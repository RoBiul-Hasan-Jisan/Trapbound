# Trapbound - Flutter port

Flutter/Dart port of the Phaser + TypeScript game (`Trapbound-main`).
Same 30 levels, same trap types, same physics numbers (960x540 logical canvas, gravity 1500,
jump 560, coyote time 100 ms, jump buffer 120 ms, fixed 60 Hz step), same save format.
No game engine dependency: a small custom engine + `CustomPainter`.

## Build the APK

```bash
# 1. create a normal Flutter project shell (generates android/, ios/ ...)
flutter create --org com.trapbound --project-name trapbound trapbound_app

# 2. copy this project's files over it
cp -r lib pubspec.yaml analysis_options.yaml trapbound_app/
rm trapbound_app/test/widget_test.dart          # default test refers to the template app

cd trapbound_app
flutter pub get
flutter run                                     # test on a connected phone / emulator
flutter build apk --release                     # -> build/app/outputs/flutter-apk/app-release.apk
# smaller per-CPU APKs:  flutter build apk --split-per-abi
```

Needs Flutter 3.24+ (Dart 3.4+).

## Files (lib/)

| file | what it is |
|---|---|
| `levels.dart`   | the 30 levels (generated from `levels.ts`) |
| `engine.dart`   | physics, traps, input, death/win logic (port of `scenes.ts` Game scene) |
| `painter.dart`  | draws the world, the stick-man, traps, particles, confetti |
| `backdrop.dart` | dusk sky, glow orbs, stars |
| `screens.dart`  | Menu, Level select (3 worlds), Game screen + pause / win overlays |
| `ui.dart`       | soft buttons, touch pad, jump button |
| `core.dart`     | save data (`shared_preferences`) + synthesized sound effects (`audioplayers`) |

## Notes

* Controls: on-screen pad (left/right, slide between halves) + jump button; keyboard A/D/arrows,
  W/Up/Space, R restart, Esc pause when run on desktop/emulator.
* The app is locked to landscape and immersive full-screen. Back button = pause.
* Fullscreen button was dropped (the app is always fullscreen); `index.html`, `package.json`,
  `vite`, and the `tools/` Playwright solver are web-only and not part of the Flutter app.
* Optional: bundle the Nunito font (see comment in `pubspec.yaml`) for the exact original look.
* Change app name/icon: edit `android:label` in `android/app/src/main/AndroidManifest.xml`,
  and use the `flutter_launcher_icons` package for an icon.
