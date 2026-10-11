# What's remaining

Status after version 1.4.0: everything that can be done in code is done.
All 90 lessons, "why" panels, daily reminders, sound effects, badges,
accessibility, tablet layout, app icon, splash screens, signed CI builds, the
privacy policy page, store text, feature graphic and screenshots are built,
and CI is green.

What's left needs **your** accounts, devices or decisions. Do them in this
order.

## 1. Decide (5 minutes)

- [ ] **Package ID.** It is `com.khemkaran.chance`. It can never change
  after the first Play upload. Happy with it? If not, tell Claude the new
  one before step 4.
- [ ] **Price** of "Unlock everything" (a one-time purchase). Typical for
  education apps in India: ₹199–₹499.
- [ ] **Accounts or not?** The app works without sign-in; progress stays on
  the phone and the purchase is restored by the store. Cloud sync (Firebase)
  is optional and can come later.

## 2. Privacy policy (15 minutes)

- [ ] Open `web/privacy.html`, replace `CONTACT_EMAIL` with your support
  email, commit.
- [ ] Put it online. Easiest: download the `chance-web` artifact from the
  latest CI run (GitHub → Actions → run → Artifacts), unzip it, drag the
  folder onto <https://app.netlify.com/drop>. Your policy is then at
  `https://<name>.netlify.app/privacy.html`. (GitHub Pages also works for a
  public repository.)

## 3. Google Play developer account (1–2 days for verification)

- [ ] Sign up at <https://play.google.com/console> (one-time US$25 fee,
  identity verification).
- [ ] Set up a **payments profile** with your bank details (needed to sell
  the in-app purchase).

## 4. Signing key (10 minutes, on your Mac)

- [ ] Create the upload key and **back it up** (losing it means you can't
  update the app without contacting Google support):
  ```
  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] Add four secrets in GitHub → repository Settings → Secrets and
  variables → Actions:

  | Secret | Value |
  |---|---|
  | `ANDROID_KEYSTORE_BASE64` | output of `base64 -i ~/upload-keystore.jks` |
  | `ANDROID_KEYSTORE_PASSWORD` | the keystore password you chose |
  | `ANDROID_KEY_ALIAS` | `upload` |
  | `ANDROID_KEY_PASSWORD` | the key password you chose |

- [ ] Re-run CI (or push anything). The run's `chance-aab` artifact is now
  signed and ready for the Play Store.

## 5. Create the app in Play Console (1 hour)

- [ ] Create app → name **Chance: Probability & Stats**, app, free, accept
  the declarations.
- [ ] Testing → Internal testing → create a release → upload the `.aab`.
- [ ] Store listing: copy the text from `docs/store/listing.md`; upload
  `docs/store/icon-512.png`, `docs/store/feature-graphic.png` and the 8
  images in `docs/store/screenshots/`.
- [ ] App content forms:
  - Privacy policy: your URL from step 2
  - Ads: no ads
  - Data safety: no data collected or shared
  - Content rating questionnaire: education, no objectionable content
  - Target audience: 13+ (or include under-13s if you want; that adds
    Families policy checks)
- [ ] Monetize → Products → In-app products → create **`chance_premium_unlock`**
  (exactly this id), set the price, **activate** it. This option appears only
  after a build has been uploaded.
- [ ] Settings → License testing → add your Gmail, so test purchases are free.

## 6. Test on your phone (1 hour)

- [ ] Join the internal test from its opt-in link and install from Play.
- [ ] Run the checklist in `docs/sdlc/04-testing.md`, especially:
  - buy the unlock, uninstall, reinstall, **Restore purchase**
  - daily reminder: set it 2 minutes ahead, lock the phone, wait
  - sounds on and off; TalkBack reads the animation description
- [ ] Tell Claude about anything that looks or feels wrong.

## 7. Go live (about 2 weeks)

- [ ] New personal Play accounts must run a **closed test with at least 12
  testers for 14 days** before production. Invite friends or classmates.
- [ ] Then apply for production access and promote the release.

## 8. Optional

- [ ] **iPhone:** Apple Developer Program (US$99/year), a Mac with Xcode,
  the same product id as a Non-Consumable in App Store Connect, TestFlight.
  See `docs/sdlc/05-release.md`.
- [ ] **Merge the work:** ask Claude to open a pull request from
  `claude/great-euler-4fae7n` into your main branch.

## Not done, on purpose

- **Hindi translation.** It means moving every lesson's text into
  translation files, then having a native speaker check the maths wording.
  It's the next big roadmap item (`docs/sdlc/06-maintenance.md`).
- **Server-side purchase checks.** They need a server; not worth it until
  piracy shows up.
- **Accounts / cloud sync.** Waiting on your decision in step 1.
