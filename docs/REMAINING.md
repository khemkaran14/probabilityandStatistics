# What's remaining

Status after version 1.3.0: all 17 chapters and 90 lessons are built and
tested. Below is everything left before and after the first store release.

**Who:** 🧑 = you (needs your accounts, devices or decisions) ·
🤖 = can be done in code.

## 1. Must do before release

### Decisions
- [ ] 🧑 Accounts or no accounts? Today progress lives only on the phone
  (lost on uninstall or a new phone; the premium unlock is restored through
  the store). Decide whether 1.0 ships without login or with Firebase login
  (see section 2).
- [ ] 🧑 Price of the "Unlock everything" purchase.
- [ ] 🧑 App name and package ID for the stores (e.g. `com.yourname.chance`).
  Changing the ID after publishing is not possible.

### App polish
- [ ] 🤖 App icon (Android adaptive icon, iOS icon, web favicon).
- [ ] 🤖 Splash screen.
- [ ] 🤖 Store screenshots of the best lessons.
- [ ] 🤖 Short and full store descriptions.
- [ ] 🤖 Privacy policy page (required for apps with purchases).

### Payments (code is done; store setup is not)
- [ ] 🧑 Google Play developer account (one-time fee) and payments profile
  with bank details.
- [ ] 🧑 Create the in-app product `chance_premium_unlock` (one-time,
  non-consumable) in Play Console.
- [ ] 🧑 Add licence testers and test a real purchase and "Restore purchase".
- [ ] 🧑 iOS only: Apple Developer account, the same product in App Store
  Connect, a Sandbox tester.

### Android release build
- [ ] 🧑 Create an upload signing key and keep it safe.
- [ ] 🤖 Configure release signing and build the app bundle (`.aab`).
- [ ] 🤖 Set version, app name and package ID in the Android project.

### Testing on real devices
- [ ] 🧑 Run the manual checklist in `docs/sdlc/04-testing.md` on a real
  Android phone: smooth animations, progress kept after restart, small screen,
  large font.
- [ ] 🧑 Play Console internal testing track with a few friends before
  production.

### Play Console forms
- [ ] 🧑 Content rating questionnaire.
- [ ] 🧑 Data safety form.
- [ ] 🧑 Target audience, app category (Education).

### Code
- [ ] 🤖 Merge `claude/great-euler-4fae7n` into the main branch (pull request).

## 2. Optional: login and accounts (only if you choose them)

- [ ] 🧑 Create a Firebase project and add the Android/iOS apps.
- [ ] 🤖 Sign in with Google, Apple (required on iOS if Google is offered)
  and email.
- [ ] 🤖 Sync progress (XP, streak, finished lessons) to the cloud.
- [ ] 🤖 Link premium to the account.
- [ ] 🤖 "Delete my account" option (required by both stores).
- [ ] 🤖 Update the privacy policy and Data safety form.

## 3. After release (roadmap)

1. [ ] 🤖 Daily reminder notification to protect streaks.
2. [ ] 🤖 "Why" panels under each formula: why the result holds.
3. [ ] 🤖 More practice questions and badges for chapters 7–17.
4. [ ] 🤖 Hindi translation, sound effects, screen-reader descriptions.
5. [ ] 🤖 Tablet layout pass.
6. [ ] 🤖 Server-side purchase validation, if piracy shows up.
7. [ ] 🧑 Watch Play Console crashes and reviews; turn requests into
   roadmap items.
