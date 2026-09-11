---
title: Prove the device is running the build under test before trusting any result
impact: CRITICAL
tags:
  - qa
  - mobile
  - freshness
  - stale-build
  - native
  - metro
---

## Build Freshness

A device happily keeps running whatever it loaded last — an installed binary from three
days ago, or the JS bundle from before the fix. Before the first flow, and again after
every code change, prove that what is running **contains the change under test**. The
check differs by framework; skipping it is never an option.

### Compiled builds — native iOS, native Android, Flutter, RN release builds

Reinstall, then verify build identity from the device itself:

```bash
# iOS — reinstall and read back the build identity that is actually installed
xcrun simctl install "$DEVICE" "$APP_PATH"
PLIST=$(xcrun simctl get_app_container "$DEVICE" "$APP_ID" app)/Info.plist
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST"        # expect the CI build number
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST"

# Android — same idea, read it from the package manager
adb install -r "$APK_PATH"
adb shell dumpsys package "$PACKAGE" | grep -E "versionCode|versionName"
```

Compare against the build you were told to test. Equal is a pass; anything else means the
device is running something else, and the run stops until it is corrected.

### Bundler-backed builds — React Native dev builds, Expo dev client

The binary can be right while the JS is stale. Three checks:

```bash
curl -sf "$BUNDLER_URL/status"                      # the bundler is up
grep -m1 "$CHECKOUT_PATH" "$EVIDENCE_DIR/logs/metro.log" \
  || { echo "Bundler is serving a DIFFERENT checkout"; exit 1; }
xcrun simctl terminate "$DEVICE" "$APP_ID" && xcrun simctl launch "$DEVICE" "$APP_ID"
```

**Incorrect (re-running straight after a fix):**

```bash
# fix lands in the working tree
maestro test "$EVIDENCE_DIR/maestro/TC-042.yaml"   # green
# reported: "verified fixed"
```

- Error: The flow ran against a binary compiled before the fix, or a bundle loaded before it — the pass says nothing about the change.
- Cause: No reinstall, no reload, and no read-back of what is actually on the device.

**Correct (reinstall or reload, then read the identity back):**

```bash
case "$FRAMEWORK" in
  native-ios|flutter)
    xcrun simctl install "$DEVICE" "$APP_PATH"
    INSTALLED=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" \
      "$(xcrun simctl get_app_container "$DEVICE" "$APP_ID" app)/Info.plist") ;;
  native-android)
    adb install -r "$APK_PATH"
    INSTALLED=$(adb shell dumpsys package "$PACKAGE" | awk -F= '/versionCode/{print $2; exit}') ;;
  react-native|expo)
    curl -sf "$BUNDLER_URL/status" >/dev/null && xcrun simctl terminate "$DEVICE" "$APP_ID"
    xcrun simctl launch "$DEVICE" "$APP_ID"
    INSTALLED="bundler:$BUNDLER_URL" ;;
esac
echo "build under test: $EXPECTED_BUILD / running: $INSTALLED" | tee -a "$EVIDENCE_DIR/logs/run-context.log"
[ "$INSTALLED" = "$EXPECTED_BUILD" ] || echo "MISMATCH — stop and report"
```

- The evidence log records what was actually running, so a reviewer can check the claim.
- A mismatch is caught before it becomes a false verification.

**Why it matters:**

A false pass from stale code is worse than a failure: it closes a live defect, ships it,
and the next person to hit it starts from "but QA verified this". Compiled apps make the
trap quieter than JS ones — there is no bundler log to betray it, only a binary that looks
identical from the outside.
