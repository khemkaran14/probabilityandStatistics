# Turning on Google sign-in and cloud sync

The app's sign-in uses **Firebase** (Google's free backend). Until you do the
steps below, builds simply have no sign-in: everything else works as before.
It takes about 30 minutes, and the free Spark plan is plenty.

**Do the signing-key step in [REMAINING.md](REMAINING.md) (step 4) first.**
Google only lets sign-in work from apps signed with a key you've registered,
and CI builds without your key use a different throwaway key every run.

## 1. Create the Firebase project (5 min)

1. Go to <https://console.firebase.google.com> and sign in with your Google
   account.
2. **Create a project** → name it `chance` → you can turn **off** Google
   Analytics (the app doesn't use it) → **Create project**.

## 2. Turn on Google sign-in (2 min)

1. Left menu → **Build → Authentication** → **Get started**.
2. **Sign-in method** tab → **Google** → **Enable**.
3. Pick your **support email** → **Save**.
4. Open **Google** again and expand **Web SDK configuration**. Copy the
   **Web client ID** (it ends in `.apps.googleusercontent.com`). You'll need
   it in step 5.

## 3. Create the database (3 min)

1. Left menu → **Build → Firestore Database** → **Create database**.
2. Location: **asia-south1 (Mumbai)** (or the region nearest your users;
   it can't be changed later) → **Start in production mode** → **Create**.
3. Open the **Rules** tab, replace everything with the contents of
   [`firestore.rules`](../firestore.rules) from this repository →
   **Publish**. These rules let each learner read and write only their own
   progress.

## 4. Register the Android app (10 min)

1. Project overview (top left) → ⚙ **Project settings** → **Your apps** →
   the **Android** icon.
2. **Package name:** `com.divyrs.chance` (exactly). Nickname: `Chance`.
3. **SHA-1:** run this on your Mac with the upload key from REMAINING.md
   step 4, and copy the `SHA1:` line:
   ```
   keytool -list -v -keystore ~/upload-keystore.jks -alias upload
   ```
4. **Register app**. Download `google-services.json` when offered, but
   **don't add it to the project**: you only need a few values from it. Skip
   the remaining steps of the wizard.
5. Later, once the app is on Play Console: **Test and release → Setup → App
   signing** shows the **App signing key certificate SHA-1**. Add it in
   Firebase too (**Project settings → Your apps → Add fingerprint**).
   Without it, sign-in fails in the version people download from Play.

## 5. Give the values to GitHub (5 min)

Open the downloaded `google-services.json` in any text editor and find these
values. Then in GitHub → your repository → **Settings → Secrets and variables
→ Actions → Variables** tab → **New repository variable**, add each one:

| Variable name | Where to find it |
|---|---|
| `FIREBASE_API_KEY` | `"current_key"` (starts with `AIza`) |
| `FIREBASE_PROJECT_ID` | `"project_id"` |
| `FIREBASE_SENDER_ID` | `"project_number"` |
| `FIREBASE_ANDROID_APP_ID` | `"mobilesdk_app_id"` (looks like `1:1234…:android:…`) |
| `GOOGLE_WEB_CLIENT_ID` | the Web client ID from step 2.4 |

These identify your project; they aren't passwords. The database rules
(step 3) are what keep the data safe, so variables (not secrets) are fine.

Then run CI again (Actions → latest run → **Re-run all jobs**, or push any
change). The new APK and app bundle have **Settings → Account → Sign in with
Google**, and a "Sign in" link on the first onboarding page.

## 6. Check it works

1. Install the new `chance-apk` from the CI run.
2. Settings → **Sign in with Google** → pick your account. You should see
   your name and "Progress saved to your account".
3. Finish a lesson, then look in Firebase → Firestore Database → **Data**:
   a `users` collection with your progress appears.
4. On a second phone (or after uninstalling and reinstalling), sign in again:
   your XP and lessons come back.

If the app says **"Sign-in cancelled"** right after you pick an account, or
"Google sign-in failed (clientConfigurationError)", the SHA-1 doesn't match
the key the APK was signed with (step 4.3), or the Web client ID is wrong
(step 2.4). Google reports both mistakes as a cancelled sign-in.

## 7. Update Play Console (when you publish)

Because the app now has optional accounts:

- **Data safety:** declare that the app collects **Name**, **Email
  address** (Personal info) and **App interactions** (App activity), for
  **App functionality** and **Account management**. Collection is
  **optional**, data is **encrypted in transit**, it is **not shared**, and
  users **can request deletion**.
- **Delete account URL:** `https://<your-site>/privacy.html#delete-account`
  (the privacy policy page from REMAINING.md step 2).
- **App access:** sign-in is optional, so choose "All functionality is
  available without special access".

## Building on your Mac (optional)

Copy `firebase_config.example.json` to `firebase_config.json` (it's
git-ignored), fill in the same values, and run:

```
flutter run --dart-define-from-file=firebase_config.json
```

Sign-in only works on a real phone or emulator whose build is signed with a
registered SHA-1. For debug builds, add your Mac's debug key too:
`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`.

## iPhone (later)

In Firebase, add an **iOS app** with bundle ID `com.divyrs.chance`, then
add `FIREBASE_IOS_APP_ID` and `GOOGLE_IOS_CLIENT_ID` (from the downloaded
`GoogleService-Info.plist`: `GOOGLE_APP_ID` and `CLIENT_ID`) to your build
settings. In Xcode, add a URL type whose scheme is the
`REVERSED_CLIENT_ID` value from the same file, as described in the
[google_sign_in iOS guide](https://pub.dev/packages/google_sign_in_ios#ios-integration).
