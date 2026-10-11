# 4. Quality Assurance & Testing

## Automated tests (`flutter test`, 30 tests)

| Level | File | Covers |
|---|---|---|
| Unit: state | `test/app_state_test.dart` | Level thresholds, first-time vs replay XP, streak grow/break, DST-safe day maths, daily goal, once-a-day challenge, 7-day history, persistence round trip, corrupt data, reset, access rules, purchase outcomes |
| Unit: content & simulations | `test/lessons_test.dart` | Catalogue ↔ registry consistency, valid quiz answers, stable daily challenge, Galton ball conservation, coin share → p, Monty Hall host rules and switch ≈ 2/3, CLT mean 3.5 and sd σ/√n |
| Widget: user flows | `test/app_flow_test.dart` | Onboarding → tabs; free lesson → quiz → XP → share; locked lesson → paywall → purchase → plays; daily challenge pays once; progress & settings, reset |

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

## Bugs found by testing in this release

* Goal picker, page headers and long button labels overflowed on narrow screens.
* `ListTile` ink inside `SoftCard` was invisible (missing `Material`).
* After buying premium, the expanded chapter jumped to a different chapter
  because the unlock banner disappeared and list items shifted (fixed with keys).
* Two private classes named `_Step` broke the single-file DartPad bundle.
