# Chance – Probability & Statistics, Animated

A Flutter app (Android, iOS, web) that teaches probability and statistics
with short animated lessons. Every lesson follows **watch → understand →
play → check**: an animation you can play, pause, step and speed up; one big
idea with a live formula; a control to change the experiment; and a quiz.

**Version 1.4**

- 90 animated lessons covering all 17 chapters: data & averages, seeing data,
  probability basics, counting, conditional probability, random variables,
  discrete and continuous distributions, two variables, limit theorems,
  sampling, estimation, hypothesis testing, regression, Bayesian thinking,
  real-world statistics and paradoxes
- A "Why does this work?" panel in every lesson
- 17-chapter, 94-lesson catalogue; chapters 1–3 and preview lessons are free,
  the rest unlock with one in-app purchase
- XP, levels, a daily goal and a daily streak, saved on the device
- Daily reminder notification, sound effects, vibration
- Practice tab: daily challenge and free practice
- Progress tab: level, stats, 7-day chart, 22 badges
- Onboarding, settings, sharing, screen-reader labels, tablet layout
- Release-ready: app icon, splash screens, signed CI builds, privacy policy
  and store listing ([docs/store](docs/store/listing.md))

**Before publishing:** see [docs/REMAINING.md](docs/REMAINING.md) for the
steps only you can do (store accounts, signing key, product setup).

How it was planned, designed, tested and released, phase by phase:
[docs/sdlc](docs/sdlc/README.md).

## Try it online in 1 minute (no install)

1. Open https://dartpad.dev
2. Delete the sample code and paste the whole of `dartpad_preview.dart`.
3. Press **Run**. In DartPad, progress lives in memory and the purchase
   button unlocks everything instantly, so you can try the full app.

## Run it on your computer

1. Install Flutter 3.47 or newer: https://docs.flutter.dev/get-started/install,
   then run `flutter doctor` and fix what it lists.
2. Android: install Android Studio and create an emulator, or plug in a phone
   with USB debugging on. iOS needs a Mac with Xcode.
3. In this folder:

   ```
   flutter pub get
   flutter run            # picks your phone/emulator
   flutter run -d chrome  # or in the browser
   ```

   Add `--dart-define=CHANCE_DEV=true` to make the unlock button work
   without a store, so you can try the paid lessons:

   ```
   flutter run -d chrome --dart-define=CHANCE_DEV=true
   ```

## Checks (same as CI)

```
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
python3 tool/make_dartpad.py   # refresh the DartPad bundle after editing lib/
```

## Project structure

```
lib/
  main.dart                   app entry: loads services and state, onboarding or tabs
  theme/app_theme.dart        light, colourful palette + theme
  data/catalogue.dart         all chapters and lessons, free/preview flags
  data/practice_bank.dart     extra questions, daily challenge selection
  data/achievements.dart      badges
  engine/lesson_sim.dart      base class for every animation (play/step/reset/speed)
  engine/lesson_spec.dart     what a lesson provides: visual, stats, big idea, try-it, quiz
  lessons/                    one file per animated lesson + registry.dart;
                              kit.dart holds shared sim, drawing and control helpers
  screens/                    onboarding, shell (tabs), learn, lesson, quiz,
                              practice, progress, settings, paywall
  data/why.dart               "Why does this work?" text for every lesson
  services/                   storage, purchases, sharing, reminders and sounds behind interfaces;
                              backends.dart wires the real plugins
  state/app_state.dart        XP, levels, streak, goal, premium, settings (saved)
  widgets/common.dart         shared cards, chips, buttons, progress ring
test/                         unit tests (state, simulations) and widget tests (user flows)
tool/make_dartpad.py          rebuilds dartpad_preview.dart from lib/
tool/make_icons.py            draws the app icon, splash logo and store graphics
tool/make_sounds.py           synthesises the sound effects in assets/sounds/
web/privacy.html              privacy policy page (ships with the web build)
docs/store/                   store listing text, icon, feature graphic, screenshots
tool/dartpad_stubs/           plugin-free stand-ins used in the DartPad bundle
docs/sdlc/                    requirements, design, implementation, testing, release, maintenance
```

## Adding a lesson

See [docs/sdlc/06-maintenance.md](docs/sdlc/06-maintenance.md#adding-a-lesson-the-main-ongoing-work).

## Publishing

Play Store and App Store steps, including the in-app product id
`chance_premium_unlock`: [docs/sdlc/05-release.md](docs/sdlc/05-release.md).
