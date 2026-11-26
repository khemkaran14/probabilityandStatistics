# Changelog

## 1.6.1

- Fix: buying the unlock could spin forever. Google Play reports some
  failures (e.g. an app not installed from Play) without a product id, and
  those were ignored; a store error while starting the purchase also left
  the button spinning. Both now end with a clear message.
- "Purchase cancelled" instead of "No purchase found to restore" when a
  purchase is cancelled
- 248 tests

## 1.6.0

- **Accounts required** (when Firebase is configured): after the welcome
  pages learners continue with Google, then complete a profile once: name,
  **mobile number verified by SMS code**, optional photo (Google's or their
  own upload) and an unticked "Send me offers and updates" consent box
  (time of consent recorded)
- **Profile screen** (photo in the Learn header, or Settings → Account):
  edit name, photo, mobile and offers consent; sign out; delete account
  (also deletes the photo)
- Firestore rules check that the saved phone and email are the ones Firebase
  verified; new `storage.rules` for profile photos
- `tool/export_users.py`: CSV of users who agreed to offers (or `--all`)
- Privacy policy rewritten for accounts, phone, photo and offers consent;
  `tool/make_privacy.py` builds `web/privacy.html` from it
- **Free-plan mode by default:** the mobile number is typed (format
  checked, saved as unverified) and the Google photo is used; SMS
  verification and photo upload switch on with the `FIREBASE_PHONE_OTP` and
  `FIREBASE_PHOTO_UPLOAD` build variables after upgrading Firebase to Blaze
- No "Signed in" message after the required sign-in: it covered the
  profile screen's button
- Builds without Firebase still work without sign-in
- 246 tests

- Package ID changed to `com.divyrs.chance` (Android and iOS) before the
  first Play upload

## 1.5.0

- Optional **Sign in with Google** (Settings → Account, or "Sign in" on the
  first onboarding page): progress is saved to the account with Firebase and
  merged safely with the phone's progress, so it comes back on a new phone
- Sign out (progress stays on the phone) and **Delete account** (deletes the
  account and its cloud data)
- Sign-in turns on only when the Firebase project is configured
  (docs/FIREBASE_SETUP.md); builds without it are unchanged
- Firestore security rules (`firestore.rules`): each learner can only read
  and write their own progress
- Privacy policy updated for optional accounts, with a delete-account
  section
- CI: `chance-apk-test-unlock`, a test build where Unlock succeeds without
  payment
- 235 tests

## 1.4.0

- "Why does this work?" panel under the formula in all 90 lessons
- Daily reminder notification: on/off and time in Settings, skipped on days
  the goal is already met
- Sound effects for answers and finishing a quiz (switch in Settings)
- 12 new badges (one per chapter group, plus "Halfway there"), 22 in total;
  16 new practice questions for chapters 7–17
- Accessibility: every animation is described for screen readers and the
  playback controls are labelled
- Tablets and landscape: navigation rail instead of the bottom bar
- App icon and splash screens on Android, iOS and web; package ID
  `com.divyrs.chance`
- CI builds a signed Android App Bundle when the signing secrets are set
- Privacy policy page, store listing, feature graphic and 8 screenshots
- Monty Hall: win-rate labels stay readable over the ⅓ and ⅔ markers
- 219 tests

## 1.3.0

- All 17 chapters are complete: 52 new animated lessons, 90 in total
  - Ch 7: Bernoulli, geometric, negative binomial, hypergeometric, Poisson,
    discrete uniform
  - Ch 8: continuous uniform, normal curve, standard normal, 68-95-99.7 rule,
    exponential, gamma & beta, t / chi-square / F
  - Ch 9–10: joint & marginal tables, covariance, correlation, correlation vs
    causation, Chebyshev; the Law of Large Numbers links the coin-flip lesson
  - Ch 11–12: populations & samples, sampling methods, sampling bias, sampling
    distributions, standard error, point estimates (why n − 1), maximum
    likelihood, confidence intervals, margin of error, sample size
  - Ch 13: hypothesis tests, p-values, type I & II errors, power, z-test,
    t-test, chi-square, ANOVA
  - Ch 14–15: best-fit line, residuals, R², multiple regression, logistic
    regression; priors & posteriors, updating, Bayesian vs frequentist
  - Ch 16–17: A/B testing, Monte Carlo, random walks, Markov chains,
    next-word prediction; Simpson's paradox, the gambler's fallacy,
    St Petersburg, base-rate fallacy (links the Bayes lesson)
- Kit: distribution formulas (normal, binomial, Poisson, gamma, beta, t,
  chi-square, F) and a `Plot` helper for axes, curves and bars
- 46 new tests check the distributions and each new lesson against its maths
  (209 tests)

## 1.2.0

- Chapters 1–6 are complete: 30 new animated lessons, 38 in total
  - Ch 1: types of data, percentiles & quartiles, skew & shape, outliers, z-scores
  - Ch 2: bar & pie charts, histograms, box plots, scatter plots,
    stem-and-leaf plots, how graphs lie
  - Ch 3: experiments & events, the complement rule, mutually exclusive events
  - Ch 4: multiplication principle, permutations, combinations, arrangements
    with repeats, pigeonhole principle, birthday paradox
  - Ch 5: conditional probability, independence, tree diagrams,
    multiplication rule, law of total probability
  - Ch 6: discrete vs continuous, PMF & CDF, expected value, variance,
    linearity of expectation
- Shared lesson toolkit (`lib/lessons/kit.dart`)
- 31 new simulation tests check each lesson against its maths (111 tests)

## 1.1.0

- 4 new lessons: Mean, median & mode (add an outlier and watch the mean run);
  Standard deviation (every value's distance from the mean, live);
  Addition rule & Venn diagrams (darts on overlapping circles);
  Bayes' theorem: the medical test (1,000 people, free preview)
- Chapters 1 and 3 now have playable lessons, so the free tier starts with
  the basics
- `--dart-define=CHANCE_DEV=true` unlocks purchases in test builds
- Every lesson screen is now checked for layout problems on a 360 dp phone

## 1.0.0

- Bottom navigation: Learn, Practice, Progress, Settings
- First-launch onboarding with a daily XP goal
- Progress saved on the device: XP, levels, daily goal, streak, 7-day chart
- Practice tab: daily challenge (once-a-day bonus) and free practice rounds
- 10 badges
- One-time in-app purchase to unlock all chapters, with restore
- Share quiz results and the app
- New lessons: Coin flips (Law of Large Numbers), Monty Hall (with a
  play-it-yourself game), Central Limit Theorem with dice
- Galton board is now a free preview lesson
- Fixes for layouts on narrow phones

## 0.1.0

- Lesson engine, 17-chapter catalogue, Galton board lesson with quiz
