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

1. **Lessons for the free chapters (1–3)** so the free tier is complete:
   mean/median/mode, standard deviation, histograms, Venn diagrams.
2. **Bayes' theorem: the medical test** – high search interest, works well
   as a short video for social media.
3. **Birthday paradox, Normal curve & 68-95-99.7, Poisson, Regression.**
4. **Daily reminder notification** (`flutter_local_notifications`) to protect streaks.
5. **"Why" panels** under each formula, answering the top complaint about
   competing apps: no explanation of *why* a result holds.
6. Localisation (Hindi first), sound effects, accessibility pass
   (screen-reader descriptions of each animation).
7. Server-side receipt validation if piracy becomes visible.

## Keeping it healthy

* Bump Flutter every few months: update `FLUTTER_VERSION` in CI, run
  `flutter pub upgrade`, run the manual checklist.
* Watch Play Console *Android vitals* (crashes, ANRs, slow frames): Play
  ranks stable apps higher.
* Reply to store reviews and turn repeated requests into roadmap items.
