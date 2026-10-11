# 6. Ongoing Maintenance & Enhancements

## Adding a lesson (the main ongoing work)

1. Create `lib/lessons/<name>.dart` with a `LessonSim` subclass, a
   `CustomPainter` and a `LessonSpec` (copy `coin_flips.dart` as a template).
2. Register it in `lib/lessons/registry.dart`.
3. Give its catalogue entry in `lib/data/catalogue.dart` the same `id`
   (and `preview: true` to make it free in a premium chapter).
4. Add simulation tests to `test/lessons_test.dart` (does it converge to the
   theory?). The catalogue/registry consistency tests run automatically.
5. `python3 tool/make_dartpad.py`, update `CHANGELOG.md`.

## Roadmap

Ordered by value for learners and for store growth:

1. ~~All 17 chapters~~ (1.1–1.3), ~~"why" panels, reminders, sounds,
   accessibility, tablet layout~~ (1.4).
2. **Accounts and cloud sync** (optional): Firebase Auth with Google/Apple
   sign-in, progress in Firestore, account deletion. Only if learners ask to
   keep progress across devices.
3. **Localisation, Hindi first.** Move every lesson's text (titles, big
   ideas, why panels, quizzes) into ARB files with `flutter_localizations`,
   then have a native speaker translate and review the maths wording.
4. More practice questions per chapter and spaced repetition of missed ones.
5. Server-side receipt validation if piracy becomes visible.

## Keeping it healthy

* Bump Flutter every few months: update `FLUTTER_VERSION` in CI, run
  `flutter pub upgrade`, run the manual checklist.
* Watch Play Console *Android vitals* (crashes, ANRs, slow frames): Play
  ranks stable apps higher.
* Reply to store reviews and turn repeated requests into roadmap items.
