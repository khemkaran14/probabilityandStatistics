# Turning on sign-in, profiles and cloud sync

The app's accounts use **Firebase** (Google's backend). Until you do the
steps below, builds have **no sign-in at all** and work as before. Once the
5 GitHub variables in step 7 are set, every new build **requires** users to:

1. sign in with Google (name, email and photo come from their Google account),
2. verify their mobile number with an SMS code (OTP),
3. optionally change their photo and tick "Send me offers and updates".

Their profile and progress are saved in Firebase, where you can see them
(step 10). Setup takes about 45 minutes.

**First do the signing-key step in [REMAINING.md](REMAINING.md) (step 4).**
Google only lets sign-in and SMS verification work from apps signed with a
key you've registered.

## 1. Create the Firebase project (5 min)

1. Go to <https://console.firebase.google.com> and sign in with the Google
   account you want to own the data (use your Divyrs account, not a
   personal one).
2. **Create a project** → name it `chance` → turn **off** Google Analytics
   (the app doesn't use it) → **Create project**.

## 2. Switch to the Blaze plan (5 min)

SMS codes and photo uploads need Firebase's pay-as-you-go **Blaze** plan.
Small apps mostly stay inside the free allowance; **you pay for SMS**
(roughly ₹1 per code in India, see Firebase pricing) and for storage only
beyond the free limits.

1. Bottom-left **Spark plan → Upgrade** → **Blaze** → add a billing account
   (card).
2. Set a **budget alert**: Google Cloud console → **Billing → Budgets &
   alerts** → e.g. ₹500/month, so you get an email before costs grow.

## 3. Turn on Google and phone sign-in (5 min)

1. Left menu → **Build → Authentication** → **Get started**.
2. **Sign-in method** tab → **Google** → **Enable** → pick your **support
   email** (this email is shown on Google's sign-in screen, so use your
   Divyrs email) → **Save**.
3. Open **Google** again → expand **Web SDK configuration** → copy the
   **Web client ID** (ends in `.apps.googleusercontent.com`). Keep it for
   step 7.
4. **Add new provider → Phone → Enable → Save**.
5. Still on **Phone**, open **Phone numbers for testing** and add a test
   number, e.g. `+91 99999 00000` with code `123456`. It never sends a real
   SMS. You'll give it to Google's app reviewers (step 9) and can use it
   yourself while testing.
6. **Settings** tab → **SMS region policy** → **Allow** only the countries
   you serve (e.g. India). This blocks SMS fraud to expensive countries.

## 4. Create the database (3 min)

1. **Build → Firestore Database → Create database**.
2. Location: **asia-south1 (Mumbai)** (can't be changed later) → **Start in
   production mode** → **Create**.
3. **Rules** tab → replace everything with
   [`firestore.rules`](../firestore.rules) from this repository →
   **Publish**. Each user can only read and write their own record, and a
   phone number can only be saved after it was verified.

## 5. Create photo storage (3 min)

1. **Build → Storage → Get started** → same location (asia-south1) →
   **production mode** → **Done**.
2. **Rules** tab → replace everything with
   [`storage.rules`](../storage.rules) → **Publish**. Each user can only
   upload their own photo (images under 2 MB).
3. At the top of the **Files** tab you'll see the bucket name, e.g.
   `gs://chance-12345.firebasestorage.app`. Copy the part after `gs://` for
   step 7.

## 6. Register the Android app (10 min)

1. ⚙ **Project settings → Your apps → Android** icon.
2. **Package name:** `com.divyrs.chance` (exactly). Nickname: `Chance`.
3. **SHA-1 and SHA-256** of your upload key. On your Mac run:
   ```
   keytool -list -v -keystore ~/upload-keystore.jks -alias upload
   ```
   Add the `SHA1:` value, then after registering use **Add fingerprint** to
   add the `SHA256:` value too. (SMS verification needs SHA-256.)
4. **Register app** → download `google-services.json` (don't add it to the
   project, you only need values from it) → skip the rest of the wizard.
5. **Play's app signing key:** Play Console → **Test and release → Setup →
   App signing** → copy the **SHA-1** and **SHA-256** of the *App signing
   key certificate* → add both in Firebase (**Add fingerprint**). Without
   these, sign-in and SMS fail in the version downloaded from Play.
6. Google Cloud console (<https://console.cloud.google.com>, same project)
   → **APIs & Services → Library** → enable **Play Integrity API** (Firebase
   uses it to stop fake SMS requests).

## 7. Give the values to GitHub (5 min)

Open `google-services.json` in a text editor. In GitHub → repository →
**Settings → Secrets and variables → Actions → Variables** tab → **New
repository variable**, add:

| Variable name | Where to find it |
|---|---|
| `FIREBASE_API_KEY` | `"current_key"` (starts with `AIza`) |
| `FIREBASE_PROJECT_ID` | `"project_id"` |
| `FIREBASE_SENDER_ID` | `"project_number"` |
| `FIREBASE_ANDROID_APP_ID` | `"mobilesdk_app_id"` (`1:1234…:android:…`) |
| `GOOGLE_WEB_CLIENT_ID` | the Web client ID from step 3.3 |
| `FIREBASE_STORAGE_BUCKET` | the bucket from step 5.3 (e.g. `chance-12345.firebasestorage.app`) |

These identify your project; they aren't passwords (the rules in steps 4–5
keep the data safe), so variables are fine.

Then **Actions → latest run → Re-run all jobs**. The new APK and app bundle
require sign-in.

## 8. Check it works (on your phone)

1. Install the new `chance-apk` from the CI run.
2. After the welcome pages: **Continue with Google** → pick your account.
3. **Complete your profile**: enter your mobile → **Send code** → type the
   SMS code → **Verify** → optionally **Add a photo** and tick the offers
   box → **Start learning**.
4. Firebase → **Authentication → Users** shows you with email and phone;
   **Firestore Database → Data → users** shows your profile and progress;
   **Storage** shows your photo.
5. Uninstall, reinstall, sign in again: you go straight in with your
   progress.

**Problems?**

| What you see | Fix |
|---|---|
| "Sign-in cancelled" right after picking an account | SHA-1 missing/wrong (step 6.3/6.5) or wrong Web client ID (step 3.3) |
| "Couldn't verify the number (app-not-authorized / missing-client-identifier)" | SHA-256 missing (step 6.3/6.5) or Play Integrity API off (step 6.6) |
| "Couldn't verify the number (billing-not-enabled)" | Blaze plan not active (step 2) |
| "Couldn't save your profile (permission-denied)" | Rules not published (step 4.3) |
| "Couldn't upload the photo" | Storage not created, rules not published (step 5), or wrong `FIREBASE_STORAGE_BUCKET` |

## 9. Update Play Console before publishing this build

Sign-in is now required, so Google needs to know:

1. **App content → App access** → **All or some functionality is
   restricted** → **Add instructions**:
   - Name: `Reviewer login`
   - Instructions: "Tap Continue with Google and use any Google account.
     On 'Complete your profile' enter the mobile number 9999900000 and the
     code 123456 (a Firebase test number; no SMS is sent)."
   (Use your own test number from step 3.5.)
2. **App content → Data safety** → **Yes**, the app collects data:

   | Data type | Collected | Shared | Optional? | Purposes |
   |---|---|---|---|---|
   | Personal info → **Name** | Yes | No | Required | App functionality, Account management |
   | Personal info → **Email address** | Yes | No | Required | App functionality, Account management, Developer communications (only if opted in) |
   | Personal info → **Phone number** | Yes | No | Required | App functionality, Account management, Developer communications (only if opted in) |
   | Photos and videos → **Photos** | Yes | No | Optional | App functionality |
   | App activity → **App interactions** | Yes | No | Required | App functionality |

   - Encrypted in transit: **Yes**
   - Users can request deletion: **Yes**
   - Account creation: **"My app allows users to create an account"** →
     method **OAuth (Google)** and **phone number**.
   - **Delete account URL:** `https://divyrs.com/chance/privacy#delete-account`
3. **Privacy policy:** publish the updated text from
   [`docs/store/privacy-policy.md`](store/privacy-policy.md) on your site
   first (it now covers accounts, phone, photo and offers).
4. **Store listing:** mention that a free account is needed (see
   `docs/store/listing.md`).

## 10. Seeing your users (admin)

- **Quick look:** Firebase console → **Authentication → Users** (email,
  phone, sign-up date) and **Firestore Database → Data → users → (user)**
  → `profile` (name, phone, photo, offers consent) and `progress`.
- **Spreadsheet export:** run [`tool/export_users.py`](../tool/export_users.py)
  on your Mac (instructions at the top of the file). By default it exports
  **only users who ticked "Send me offers"**, with the time they agreed.

**Use the contact details responsibly:** only send offers to users who
opted in (India's DPDP Act and Google Play policy require consent), include
a way to stop messages, and honour deletion requests within 30 days.

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
enable Push Notifications + Background Modes for phone auth, and add
"Sign in with Apple" (Apple requires it when Google sign-in is offered).
