# Native Builds — iOS, Android, Flutter

For apps whose code under test is **compiled into the installed artifact**: native iOS and
Android, Flutter, and React Native release builds. The rule that governs this is
`../rules/pre-build-freshness.md`; this is the command surface.

## Which artifact goes on which device

| Target | Artifact | Install |
|---|---|---|
| iOS Simulator | `.app` (simulator slice — an `.ipa` will not install) | `xcrun simctl install UDID App.app` |
| iOS device | `.ipa`, signed | `xcrun devicectl device install app --device UDID App.ipa` |
| Android emulator / device | `.apk` (an `.aab` must be converted first) | `adb install -r app.apk` |

A simulator build is compiled for the host architecture; a device build is not. Installing
the wrong one fails at install time on Android and crashes instantly on iOS — check the
artifact before blaming the app.

## Finding the artifact

```bash
# iOS — ask Xcode where the build products went, rather than guessing DerivedData paths
xcodebuild -showBuildSettings -scheme "$SCHEME" -configuration Debug \
  | awk -F' = ' '/ BUILT_PRODUCTS_DIR|  FULL_PRODUCT_NAME/{print $2}'

# Android — Gradle's conventional output
ls app/build/outputs/apk/debug/*.apk

# Flutter
flutter build ios --simulator     # build/ios/iphonesimulator/Runner.app
flutter build apk --debug         # build/app/outputs/flutter-apk/app-debug.apk
```

## Reading back the installed identity

This is the part that makes a freshness claim verifiable — always read it from the
**device**, never from the build script's output.

```bash
# iOS
CONTAINER=$(xcrun simctl get_app_container UDID BUNDLE_ID app)
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$CONTAINER/Info.plist"
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$CONTAINER/Info.plist"

# Android
adb shell dumpsys package PACKAGE | grep -E "versionCode|versionName|lastUpdateTime"
adb shell pm path PACKAGE                      # where the APK actually landed
```

Teams that stamp a git SHA into the build (`CFBundleVersion`, `versionName`, or a
`BuildConfig` field) make this exact — ask for that stamp if a run keeps needing manual
correlation.

## Discovering identifiers from the repo

```bash
# iOS bundle id
xcodebuild -showBuildSettings -scheme "$SCHEME" | awk -F' = ' '/PRODUCT_BUNDLE_IDENTIFIER/{print $2}'
plutil -extract CFBundleIdentifier raw ios/App/Info.plist 2>/dev/null

# Android package + URL scheme
awk -F'"' '/applicationId/{print $2}' app/build.gradle*
grep -A3 "android.intent.action.VIEW" app/src/main/AndroidManifest.xml
```

## Flutter specifics

- Maestro drives Flutter through the Semantics tree. Elements need `Semantics(identifier:)`
  or a `ValueKey` to be selectable by `id`; without them you are down to visible text.
- `maestro hierarchy` shows exactly what Semantics exposes — run it on the screen under
  test before writing selectors.
- Debug builds ship the Flutter inspector overlay's debug banner; it is not a defect, and
  it does shift layout slightly in screenshots.

## Gotchas

- `adb install -r` keeps app data; `pm clear` after it when the flow needs a clean state.
- iOS `simctl install` over an existing app keeps the sandbox too — `simctl uninstall` first for a true fresh install.
- A crash on launch with no redbox usually means an architecture or signing mismatch, not app code.
- An `.aab` cannot be installed directly — `bundletool build-apks --local-testing` produces something the emulator accepts.
