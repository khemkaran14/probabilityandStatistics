# Turning on sign-in, profiles and cloud sync

The app's accounts use **Firebase** (Google's backend). Until you do the
steps below, builds have **no sign-in at all** and work as before. Once the
5 GitHub variables in step 6 are set, every new build **requires** users to:

1. sign in with Google (name, email and photo come from their Google account),
2. complete a short profile: name, **mobile number**, and an unticked
   "Send me offers and updates" box,

and saves their profile and progress in Firebase, where you can see them
(step 9).

**Start on the free Spark plan.** On it, users type their mobile number
(checked for a valid format, not verified by SMS) and the Google account
photo is used. When you grow, [upgrade to Blaze](#upgrade-to-blaze-later)
to switch on **SMS-verified numbers** and **photo upload** with two
variables, no code change.

Setup takes about 30 minutes. **First do the signing-key step in
[REMAINING.md](REMAINING.md) (step 4):** Google sign-in only works from apps
signed with a key you've registered.

## 1. Create the Firebase project (5 min)

1. Go to <https://console.firebase.google.com> and sign in with the Google
   account that should own the data (your Divyrs account, not a personal
   one).
2. **Create a project** → name it `chance` → turn **off** Google Analytics
   → **Create project**. You stay on the free **Spark** plan; no card needed.

## 2. Turn on Google sign-in (3 min)

1. Left menu → **Build → Authentication** → **Get started**.
2. **Sign-in method** tab → **Google** → **Enable** → pick your **support
   email** (shown on Google's sign-in screen, so use your Divyrs email) →
   **Save**.
3. Open **Google** again → expand **Web SDK configuration** → copy the
   **Web client ID** (ends in `.apps.googleusercontent.com`) for step 6.

## 3. Create the database (3 min)

1. **Build → Firestore Database → Create database**.
2. Location: **asia-south1 (Mumbai)** (can't be changed later) → **Start in
   production mode** → **Create**.
3. **Rules** tab → replace everything with
   [`firestore.rules`](../firestore.rules) from this repository →
   **Publish**. Each user can only read and write their own record.

## 4. Register the Android app (10 min)

1. ⚙ **Project settings → Your apps → Android** icon.
2. **Package name:** `com.divyrs.chance` (exactly). Nickname: `Chance`.
3. **SHA-1** of your upload key. On your Mac:
   ```
   keytool -list -v -keystore ~/upload-keystore.jks -alias upload
   ```
   Copy the `SHA1:` value. After registering, use **Add fingerprint** to add
   the `SHA256:` value too (needed later for SMS).
4. **Register app** → download `google-services.json` (don't add it to the
   project; you only need values from it) → skip the rest of the wizard.

## 5. Add Play's signing key (5 min)

Play re-signs your app, so sign-in in the Play version needs Play's key too:
Play Console → **Test and release → Setup → App signing** → copy the
**SHA-1** and **SHA-256** of the *App signing key certificate* → Firebase →
**Project settings → Your apps → Add fingerprint** (add both).

## 6. Give the values to GitHub (5 min)

Open `google-services.json` in a text editor. GitHub → repository →
**Settings → Secrets and variables → Actions → Variables** tab → **New
repository variable**:

| Variable name | Where to find it |
|---|---|
| `FIREBASE_API_KEY` | `"current_key"` (starts with `AIza`) |
| `FIREBASE_PROJECT_ID` | `"project_id"` |
| `FIREBASE_SENDER_ID` | `"project_number"` |
| `FIREBASE_ANDROID_APP_ID` | `"mobilesdk_app_id"` (`1:1234…:android:…`) |
| `GOOGLE_WEB_CLIENT_ID` | the Web client ID from step 2.3 |

These identify your project; they aren't passwords (the rules in step 3
keep the data safe), so variables are fine.

Then **Actions → latest run → Re-run all jobs**. The new APK and app bundle
require sign-in.

## 7. Check it works (on your phone)

1. Install the new `chance-apk` from the CI run.
2. After the welcome pages: **Continue with Google** → pick your account.
3. **Complete your profile**: check your name, type your mobile number,
   optionally tick the offers box → **Start learning**.
4. Firebase → **Authentication → Users** shows you; **Firestore Database →
   Data → users** shows your profile and progress.
5. Uninstall, reinstall, sign in again: you go straight in with your
   progress.

| What you see | Fix |
|---|---|
| "Sign-in cancelled" right after picking an account | SHA-1 missing or wrong (steps 4.3 and 5), or wrong Web client ID (step 2.3) |
| "Couldn't save your profile (permission-denied)" | Rules not published (step 3.3) |

## 8. Update Play Console before publishing this build

1. **App content → App access** → **All or some functionality is
   restricted** → **Add instructions**: "Tap Continue with Google and sign
   in with any Google account. On 'Complete your profile' enter any valid
   10-digit mobile number, e.g. 9999900000."
2. **App content → Data safety** → **Yes**, the app collects data:

   | Data type | Collected | Shared | Optional? | Purposes |
   |---|---|---|---|---|
   | Personal info → **Name** | Yes | No | Required | App functionality, Account management |
   | Personal info → **Email address** | Yes | No | Required | App functionality, Account management, Developer communications |
   | Personal info → **Phone number** | Yes | No | Required | App functionality, Account management, Developer communications |
   | App activity → **App interactions** | Yes | No | Required | App functionality |

   (Add Photos → **Photos**, optional, App functionality, once photo upload
   is switched on.)
   - Encrypted in transit: **Yes**. Users can request deletion: **Yes**.
   - Account creation: **"My app allows users to create an account"** →
     **OAuth (Google)**.
   - **Delete account URL:** `https://divyrs.com/chance/privacy#delete-account`
3. **Privacy policy:** publish the text from
   [`docs/store/privacy-policy.md`](store/privacy-policy.md) on your site
   first (replace `YOUR_PUBLIC_EMAIL`).
4. **Store listing:** mention that a free account is needed (see
   `docs/store/listing.md`).

## 9. Seeing your users (admin)

- **Quick look:** Firebase console → **Authentication → Users** (email,
  sign-up date) and **Firestore Database → Data → users → (user)** →
  `profile` (name, phone, whether it's verified, offers consent) and
  `progress`.
- **Spreadsheet export:** run [`tool/export_users.py`](../tool/export_users.py)
  on your Mac (instructions at the top of the file). By default it exports
  **only users who ticked "Send me offers"**, with the time they agreed and
  whether their number was SMS-verified.

**Use the contact details responsibly:** only send offers to users who
opted in (India's DPDP Act and Google Play policy require consent), include
a way to stop messages, and honour deletion requests within 30 days.
Numbers typed on the free plan aren't verified, so some may be wrong.

## Upgrade to Blaze later

When you want **SMS-verified mobile numbers** and **photo upload**:

1. **Blaze plan:** Firebase console → bottom-left **Spark → Upgrade →
   Blaze** → add a billing account. Then Google Cloud console → **Billing →
   Budgets & alerts** → set e.g. ₹500/month. Blaze keeps the free
   allowances; you mainly pay per SMS (roughly ₹1 per code in India).
2. **Phone sign-in:** **Authentication → Sign-in method → Add new provider
   → Phone → Enable**. Under **Phone numbers for testing** add e.g.
   `+91 99999 00000` with code `123456` (for Google's reviewers). In
   **Settings → SMS region policy**, allow only the countries you serve.
3. **Play Integrity:** Google Cloud console → **APIs & Services → Library →
   Play Integrity API → Enable**. Make sure both **SHA-256** fingerprints
   are in Firebase (steps 4.3 and 5).
4. **Photo storage:** **Build → Storage → Get started** → asia-south1 →
   production mode. **Rules** tab → paste [`storage.rules`](../storage.rules)
   → **Publish**. Copy the bucket name from the **Files** tab (after
   `gs://`, e.g. `chance-12345.firebasestorage.app`).
5. **GitHub variables:** add
   - `FIREBASE_PHONE_OTP` = `true`
   - `FIREBASE_PHOTO_UPLOAD` = `true`
   - `FIREBASE_STORAGE_BUCKET` = the bucket name from step 4

   then re-run CI and publish the new build.
6. **Play Console:** App access instructions → use the test number
   `9999900000` and code `123456`; Data safety → add **Photos** (optional).

Existing users keep their typed numbers (marked unverified). New sign-ups,
and anyone who changes their number, verify it by SMS.

| Problem after upgrading | Fix |
|---|---|
| "Couldn't verify the number (app-not-authorized / missing-client-identifier)" | SHA-256 missing or Play Integrity API off (step 3) |
| "Couldn't verify the number (billing-not-enabled)" | Blaze plan not active (step 1) |
| "Couldn't upload the photo" | Storage not created, rules not published, or wrong `FIREBASE_STORAGE_BUCKET` (steps 4–5) |

## Building on your Mac (optional)

Copy `firebase_config.example.json` to `firebase_config.json` (git-ignored),
fill in the same values, and run:

```
flutter run --dart-define-from-file=firebase_config.json
```

For debug builds, also add your Mac's debug key fingerprints in Firebase:
`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`.

## iPhone (later)

In Firebase, add an **iOS app** with bundle ID `com.divyrs.chance`, then
add `FIREBASE_IOS_APP_ID` and `GOOGLE_IOS_CLIENT_ID` (from
`GoogleService-Info.plist`: `GOOGLE_APP_ID` and `CLIENT_ID`) to your build
settings. In Xcode, add a URL type with the `REVERSED_CLIENT_ID` value
([google_sign_in iOS guide](https://pub.dev/packages/google_sign_in_ios#ios-integration)),
and add "Sign in with Apple" (Apple requires it when Google sign-in is
offered).
