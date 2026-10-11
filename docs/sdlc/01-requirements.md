# 1. Requirements Gathering & Analysis

## Problem

Probability and statistics are taught mostly as formulas. Learners memorise
`μ = n·p` without ever *seeing* why it is true. Existing visual-learning apps
(e.g. *Algorithms: Explained and Animated*) prove the format works, but
reviewers of those apps ask for more depth (why a result holds, edge cases)
and the probability/statistics niche has no strong animated app.

## Target users

| Persona | Need |
|---|---|
| High-school / college student | Understand a topic before an exam, in short sessions |
| Self-learner / developer moving into data & ML | Build intuition for distributions, sampling, Bayes |
| Teacher | Show a live animation in class |

## Functional requirements

| ID | Requirement | Priority |
|---|---|---|
| F1 | Browse a catalogue of 17 chapters / ~100 lessons | Must |
| F2 | Each built lesson follows **watch → understand → play → check**: animated simulation with play/pause/step/reset/speed, a "big idea" card with a live formula, an interactive "try it" control, a quiz with explanations | Must |
| F3 | Lessons at launch: Galton board (binomial), Coin flips (Law of Large Numbers), Monty Hall, Central Limit Theorem | Must |
| F4 | XP for finishing quizzes; levels derived from XP | Must |
| F5 | Daily goal and daily streak | Must |
| F6 | Progress is saved on the device between launches | Must |
| F7 | First-launch onboarding that sets a daily goal | Should |
| F8 | Bottom navigation: Learn, Practice, Progress, Settings | Must |
| F9 | Practice tab: a daily challenge (5 questions, once-a-day bonus) and free practice from finished lessons | Should |
| F10 | Progress tab: level, stats, 7-day activity, badges | Should |
| F11 | Freemium: chapters 1–3 and marked preview lessons are free; everything else unlocks with a one-time in-app purchase; restore purchases | Must |
| F12 | Share quiz results and the app | Could |
| F13 | Settings: daily goal, haptics, restore purchases, reset progress | Should |
| F14 | "Why does this work?" explanation in every lesson (1.4) | Should |
| F15 | Daily reminder notification, skipped once the day's goal is met (1.4) | Should |
| F16 | Sound effects with an off switch (1.4) | Could |
| F17 | Screen-reader descriptions of animations and labelled controls (1.4) | Should |

## Non-functional requirements

| ID | Requirement |
|---|---|
| N1 | Animations run at 60 fps on mid-range Android phones (custom painters, no per-frame widget rebuilds of the whole screen) |
| N2 | Light, bright, colourful theme; readable contrast; works at phone width and centres on tablets / web |
| N3 | Works fully offline; no ads; no personal data collected (Play "Data safety": none) |
| N4 | One codebase for Android, iOS and web (Flutter) |
| N5 | Adding a lesson = one new file + one registry line |
| N6 | Every change passes `flutter analyze` and `flutter test` in CI |

## Out of scope for 1.0

Accounts / cloud sync, server-side receipt validation, localisation
(English only). Reminders, sound effects and accessibility labels were added
in 1.4.
