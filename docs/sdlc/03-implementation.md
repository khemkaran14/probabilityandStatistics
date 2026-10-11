# 3. Implementation

Flutter 3.47 / Dart 3.13. Plugins: `shared_preferences`, `in_app_purchase`,
`share_plus`. Everything else is the Flutter SDK.

## Requirement → code

| Req | Where |
|---|---|
| F1 catalogue | `lib/data/catalogue.dart` |
| F2 lesson format | `lib/engine/`, `lib/screens/lesson_screen.dart`, `lib/screens/quiz_screen.dart` |
| F3 lessons | `lib/lessons/*.dart`, one file per lesson |
| F4–F6 XP, levels, goal, streak, saving | `lib/state/app_state.dart`, `lib/services/key_value_store.dart` |
| F7 onboarding | `lib/screens/onboarding_screen.dart` |
| F8 navigation | `lib/screens/shell_screen.dart` |
| F9 practice | `lib/screens/practice_screen.dart`, `lib/data/practice_bank.dart` |
| F10 progress & badges | `lib/screens/progress_screen.dart`, `lib/data/achievements.dart` |
| F11 freemium | `Lesson.preview`, `AppState.canOpen`, `lib/screens/paywall_screen.dart`, `lib/services/purchase_service.dart`, `lib/services/backends.dart` |
| F12 share | `lib/services/share_service.dart`, quiz result and settings |
| F13 settings | `lib/screens/settings_screen.dart` |

## The lessons

Chapters 1–6 are complete (36 lessons), plus the Galton board (ch 7), the
Central Limit Theorem (ch 10) and Monty Hall (ch 5 and 17). Most newer lessons
build on `lib/lessons/kit.dart`: `TickSim` (one discrete step every
`interval` seconds), canvas helpers (`label`, `bar`, `paintDie`, …),
`simCanvas` (no painter class needed) and the try-it controls
(`LabeledSlider`, `ChoiceRow`, `ControlRow`, `ActionButton`).

Highlights:

| Lesson | Simulation | What the learner controls |
|---|---|---|
| Mean, median & mode (ch 1) | Values drop onto a number line as a dot plot; mean, median and mode markers move live | Symmetric vs long-tail data; add an outlier of 200 |
| Standard deviation (ch 1) | Rolling sample of 12; each row shows a value and its distance from the mean; ±1 sd band | Spread of the data |
| Venn diagrams & addition rule (ch 3) | Darts land uniformly; share in each region estimates its probability; compared with exact circle areas | Pull the circles apart until mutually exclusive; "Throw 500" |
| Bayes: the medical test (ch 5, preview) | 1,000 people with exact counts for the rates; tested row by row; positives split into sick vs healthy | Disease prevalence; false-positive rate |
| Galton board (binomial) | Balls bounce left/right with p at each of 8 rows; bins fill; bell curve overlay after 20 balls | Tilt p |
| Coin flips (Law of Large Numbers) | Flips speed up 3→40/s; running share of heads vs the true p; history thins itself so memory stays bounded | Coin bias, "Flip 100" |
| Monty Hall | Auto-plays rounds phase by phase (pick → host opens → offer → reveal), tallies stay vs switch | Play rounds yourself; "Simulate 1,000" |
| Central Limit Theorem | Rolls n dice, histograms the averages over every possible value, overlays N(3.5, σ/√n) | Number of dice 1–10, "Roll 500" |

## Conventions

* One lesson = one file with a `LessonSim`, a `CustomPainter` and a `LessonSpec`.
* Painters repaint from the sim (`super(repaint: sim)`); widgets never rebuild per frame.
* Plugins only in `lib/services/backends.dart`; the rest of the app sees interfaces.
* Private class names must be unique across `lib/`, because the DartPad
  bundle merges every file into one.
* `dart format` at 120 columns (set in `analysis_options.yaml`).
