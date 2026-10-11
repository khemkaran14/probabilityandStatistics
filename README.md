# Chance – Probability & Statistics, Animated

Flutter app (Android + iOS + web). Version 0.1: home screen with the full
17-chapter catalogue, the reusable animated-lesson engine, and the first
complete lesson (Galton board → binomial distribution) with a 3-question quiz.

## Try it online in 1 minute (no install)

1. Open https://dartpad.dev
2. Delete the sample code and paste the whole of `dartpad_preview.dart`.
3. Press **Run**. The app appears on the right.

## Run it on your computer

1. Install Flutter: https://docs.flutter.dev/get-started/install
   (Windows, macOS or Linux). Then run `flutter doctor` and fix what it lists.
2. For Android: install Android Studio, then create an emulator in
   Device Manager, or plug in your phone with USB debugging on.
3. For iOS: you need a Mac with Xcode.
4. In this folder, generate the platform folders once:

   ```
   flutter create --org com.yourname --project-name chance --platforms android,ios,web .
   ```

5. Run it:

   ```
   flutter pub get
   flutter run            # picks your phone/emulator
   flutter run -d chrome  # or in the browser
   ```

## Project structure

```
lib/
  main.dart                 app entry
  theme/app_theme.dart      light, colourful palette + theme
  data/catalogue.dart       all chapters and lessons
  engine/lesson_sim.dart    base class for every animation (play/step/reset/speed)
  engine/lesson_spec.dart   what a lesson provides: visual, stats, big idea, try-it, quiz
  lessons/galton_board.dart lesson 1: simulation + painter + quiz
  lessons/registry.dart     list of built lessons
  screens/                  home, lesson and quiz screens
  widgets/common.dart       shared buttons and cards
  state/progress.dart       XP and finished lessons (in memory for now)
tool/make_dartpad.py        rebuilds dartpad_preview.dart from lib/
```

## Adding a new lesson

1. Create `lib/lessons/<name>.dart` with a `LessonSim` subclass, a
   `CustomPainter`, and a `LessonSpec`.
2. Add it to `lib/lessons/registry.dart`.
3. Give the matching entry in `lib/data/catalogue.dart` the same `id`.
