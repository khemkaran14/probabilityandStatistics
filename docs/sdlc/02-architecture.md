# 2. System Architecture & Design

## Overall system architecture

```
            ┌──────────────────────── Flutter app ────────────────────────┐
            │                                                             │
 UI layer   │  screens/   onboarding · shell (4 tabs) · lesson · quiz ·   │
            │             paywall · learn · practice · progress · settings│
            │  widgets/   shared cards, buttons, chips                    │
            │                          │  reads / calls                    │
 State      │  state/app_state.dart  ── AppState (ChangeNotifier)         │
            │   XP · levels · streak · daily goal · badges · premium ·    │
            │   settings · activity history          exposed by AppScope  │
            │                          │                                   │
 Services   │  services/  KeyValueStore ── SharedPreferences (device)     │
            │             PurchaseService ── in_app_purchase (Play/App St)│
            │             ShareService ── share_plus                       │
            │                                                             │
 Content    │  data/catalogue.dart   chapters + lessons (+ free/preview)  │
            │  data/practice_bank.dart extra practice questions           │
            │  engine/               LessonSim + LessonSpec contracts     │
            │  lessons/              one file per animated lesson          │
            └─────────────────────────────────────────────────────────────┘
```

* **No backend.** Everything runs on device; this keeps the app offline,
  private and free to operate.
* **Services sit behind small interfaces** (`KeyValueStore`,
  `PurchaseService`, `ShareService`) so tests and the DartPad preview can use
  in-memory fakes.
* **State** is a single `AppState` `ChangeNotifier`, provided to the widget
  tree by an `InheritedNotifier` (`AppScope`). It saves itself after every
  change. A `clock` function is injected so streak logic is testable.

## Detailed module / component design

### Lesson engine

```
LessonSim (ChangeNotifier)          LessonSpec (data)
  playing, speed                      id, chapterLabel, title, subtitle
  advance(dt)  ← ticker every frame   createSim()  → LessonSim
  step(), reset()                     buildVisual(sim) → CustomPaint
                                      stats(sim), bigIdea, formula(sim)
                                      buildTryIt(sim), quiz
```

`LessonScreen` owns one `Ticker`; it calls `sim.advance(dt × speed)` while
playing. Painters take the sim as their `repaint` listenable, so only the
canvas repaints each frame (N1).

### Access control (freemium)

`Lesson.isFree(chapter)` = chapter is free **or** lesson is marked
`preview`. `AppState.canOpen(lesson)` = free **or** premium. Opening a
locked lesson routes to the paywall.

### XP, levels, streak

* Quiz: `10 + 10 × correct` XP, first completion only (replays give no XP).
* Daily challenge: `10 × correct + 20` bonus, once per calendar day.
* Level *n* starts at `50 · n · (n − 1)` XP (0, 100, 300, 600, …).
* Streak: any XP earned today counts as activity. Activity yesterday →
  streak + 1; a gap → streak resets to 1.

### Persistence keys (SharedPreferences, prefix `chance.`)

`xp`, `completed`, `perfect`, `streak`, `bestStreak`, `lastActive`,
`dailyGoal`, `history` (JSON day → XP, last 60 days), `challengeDay`,
`challengesDone`, `premium`, `onboarded`, `haptics`.

### Navigation

```
first launch → Onboarding ─► Shell ┬ Learn ──► Lesson ──► Quiz ──► Result (share)
                                   │      └─► Paywall (locked lesson)
                                   ├ Practice ─► Quiz (daily / free practice)
                                   ├ Progress (level, stats, badges)
                                   └ Settings ─► Paywall / restore / reset
```
