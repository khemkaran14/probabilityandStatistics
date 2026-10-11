# 5. Release & Deployment

## Every push

CI builds a web bundle and an APK and attaches both to the workflow run
(Actions tab → run → Artifacts). The APK is signed with debug keys unless a
keystore is configured, so it installs on a phone for testing but cannot go
to the Play Store.

## Google Play (Android)

1. **App id.** Change `applicationId` / `namespace` in
   `android/app/build.gradle.kts` (currently `com.chance.chance`) to one you
   own, e.g. `com.yourname.chance`. It can never change after the first upload.
2. **Upload key** (once, keep it safe and backed up):
   ```
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Create `android/key.properties` (git-ignored):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/home/you/upload-keystore.jks
   ```
3. **Icon.** Replace the default Flutter icons in `android/app/src/main/res/mipmap-*`
   (or use `flutter_launcher_icons`).
4. **Build:** `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.
5. **Play Console:** create the app, upload the `.aab` to *Internal testing*
   first. Data safety form: no data collected or shared.
6. **In-app product:** Monetize → Products → In-app products → create a
   one-time product with id **`chance_premium_unlock`** and activate it. Add
   your Google account as a licence tester to buy without being charged.
7. Promote internal → closed → production once the manual checklist in
   [04-testing.md](04-testing.md) passes.

## App Store (iOS)

Needs a Mac with Xcode (or a cloud builder such as Codemagic) and an Apple
Developer account.

1. Set the bundle id in Xcode (`ios/Runner.xcworkspace`) and add the
   *In-App Purchase* capability.
2. App Store Connect: create the app and a **Non-Consumable** in-app
   purchase with id **`chance_premium_unlock`**.
3. `flutter build ipa --release`, upload with Xcode or Transporter, test in
   TestFlight with a sandbox account (buy and restore).

## Web

`flutter build web --release` → host `build/web` on any static host
(GitHub Pages, Netlify, Firebase Hosting). In-app purchases are not
available on web, so it works as a free preview of chapters 1–3 and the
preview lessons.

## DartPad preview

`python3 tool/make_dartpad.py` writes `dartpad_preview.dart`, a single-file
version (progress in memory, purchases always succeed) to paste into
dartpad.dev. CI fails if it is out of date.

## Versioning

`version:` in `pubspec.yaml` is `name+build`. Bump the build number on every
store upload, the name on user-visible releases, and keep `kAppVersion` in
`lib/screens/settings_screen.dart` and `CHANGELOG.md` in step.
