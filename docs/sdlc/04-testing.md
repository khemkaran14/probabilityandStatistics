# 4. Quality Assurance & Testing

## Automated tests (`flutter test`, 219 tests)

| Level | File | Covers |
|---|---|---|
| Unit: state | `test/app_state_test.dart` | Level thresholds, first-time vs replay XP, streak grow/break, DST-safe day maths, daily goal, once-a-day challenge, 7-day history, persistence round trip, corrupt data, reset, access rules, purchase outcomes |
| Unit: content & simulations | `test/lessons_test.dart` | Catalogue ↔ registry consistency, valid quiz answers, stable daily challenge, Galton ball conservation, coin share → p, Monty Hall host rules and switch ≈ 2/3, CLT mean 3.5 and sd σ/√n, mean/median/mode definitions and outlier effect, sd formula and target spread, Venn estimates vs exact areas, Bayes counts vs the formula |
| Unit: chapters 1–6 | `test/lessons_ch1_6_test.dart` | Each of the 30 newer lessons against its maths: quantiles and fences, z-scores, histogram counts, correlation sign, stem-and-leaf rebuild, complement and birthday formulas, card counts, nPr / nCr / repeats, pigeonhole guarantee, conditional counts, independence, tree and total-probability convergence, CDF, expected value, variance k, hat-check average 1 |
| Unit: chapters 7–17 | `test/lessons_ch7_17_test.dart` | Each of the 52 newest lessons against its maths: distribution means and variances, waiting times, Poisson counts, the 68-95-99.7 rule, covariance vs correlation under unit changes, confounding, Chebyshev bound, sampling methods and bias, standard error, n − 1 unbiasedness, MLE, interval coverage, test error rates and power, least squares and R² = r², multiple and logistic regression, Bayesian updating and credible intervals, Monte Carlo π, random-walk distance, Markov stationary shares, softmax, Simpson's paradox, gambler's fallacy, St Petersburg |
| Unit: distributions | `test/kit_test.dart` | Every pdf integrates to 1, `lgamma`, `normalCdf`, and textbook critical values (t, χ², F) |
| Widget: every lesson | `test/lesson_screens_test.dart` | Each lesson screen runs its animation for 5 s, opens its "why" panel and scrolls end to end on a 360 dp phone with no overflow or exception |
| Widget: user flows | `test/app_flow_test.dart` | Onboarding → tabs; free lesson → quiz → XP → sounds → share; locked lesson → paywall → purchase → plays; daily challenge pays once; progress & settings, reset; reminder on/off, time picker, skipped after the goal, refused permission; tablet navigation rail; screen-reader labels |

Tests run against in-memory fakes (`MemoryStore`, `FakePurchaseService`,
`FakeShareService`) and an injected clock, on a 390×844 phone screen so
layout overflows fail the test.

## Continuous integration

`.github/workflows/ci.yml` runs on every push and pull request:
format check → `flutter analyze` → `flutter test` → DartPad bundle is up to
date → web build and Android APK build (artifacts attached to the run).

## Manual checks before a release

Run on a real Android phone (and iPhone if shipping iOS):

- [ ] First launch shows onboarding; relaunch skips it
- [ ] Each lesson animates smoothly at ½×, 1×, 3×; step and reset work
- [ ] Finish a quiz → XP, daily goal ring and streak update; kill and relaunch → still there
- [ ] Locked lesson → paywall → buy with a Play test account → unlocks
- [ ] Uninstall/reinstall → "Restore purchase" unlocks again
- [ ] Share sheet opens from quiz result and settings
- [ ] Smallest supported phone (360 dp wide) and a tablet: no overflow
- [ ] Large system font size: text wraps, nothing clipped
- [ ] Daily reminder: allow notifications, set the time 2 minutes ahead, lock
  the phone → the reminder arrives; meet the goal → no reminder that day;
  reboot → it still arrives
- [ ] Sound effects play on answers, respect the silent switch (iPhone) and
  don't stop music that is playing
- [ ] TalkBack / VoiceOver: the animation is described, buttons are named
- [ ] Tablet or landscape: navigation rail on the left

## Bugs found by testing in this release

* Goal picker, page headers and long button labels overflowed on narrow screens.
* `ListTile` ink inside `SoftCard` was invisible (missing `Material`).
* After buying premium, the expanded chapter jumped to a different chapter
  because the unlock banner disappeared and list items shifted (fixed with keys).
* Two private classes named `_Step` broke the single-file DartPad bundle.
* 1.2: "value + button" rows overflowed on 360 dp phones (now `ControlRow`,
  which wraps); the bulb factory painter read per-sim fault rates as
  constants; a muddled outliers quiz question had no correct option; labels
  overlapped in the conditional-probability and total-probability stages.
* 1.4: the settings test relied on "Reset progress" being built before it was
  scrolled to; the Monty Hall win-rate labels were crossed by the ⅓ and ⅔
  markers.
* 1.3: the random walk's 1D distance used both axes; three quiz prompts
  depended on the animation to make sense (now self-contained); the loaded
  die in the chi-square lesson was too weak to detect reliably; joint-table
  marginal bars ran off the canvas; labels overlapped in the MLE,
  point-estimate and gambler's-fallacy lessons.
