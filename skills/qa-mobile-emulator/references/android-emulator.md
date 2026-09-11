# Android Emulator CLI

```bash
emulator -list-avds
emulator -avd NAME -no-snapshot-load &          # cold boot, avoids stale snapshot state
adb devices                                     # confirm it attached
adb wait-for-device shell getprop sys.boot_completed   # returns 1 when usable
adb -s emulator-5554 ...                        # target a specific device when several run
```

## App lifecycle

```bash
adb install -r app-debug.apk
adb shell am start -n PACKAGE/.MainActivity
adb shell am force-stop PACKAGE
adb shell pm clear PACKAGE                      # wipe app data — the Android "clearState"
adb shell am start -a android.intent.action.VIEW -d "myapp://practice/42" PACKAGE
adb uninstall PACKAGE
```

## Evidence

```bash
adb exec-out screencap -p > /abs/evidence/screenshots/name.png
adb shell screenrecord --time-limit 180 /sdcard/name.mp4      # 3 min cap per file
adb pull /sdcard/name.mp4 /abs/evidence/recordings/name.mp4
adb logcat -c && adb logcat -v time > /abs/evidence/logs/logcat.txt &
adb logcat ReactNativeJS:V '*:S'                # JS console only
```

## Permissions and state

```bash
adb shell pm grant  PACKAGE android.permission.POST_NOTIFICATIONS
adb shell pm revoke PACKAGE android.permission.ACCESS_FINE_LOCATION
adb shell settings put global window_animation_scale 0     # also transition_ and animator_
adb shell input keyevent KEYCODE_BACK
adb shell svc wifi disable                      # offline-state testing
```

## Metro reachability

`localhost` inside the emulator is the emulator itself. The host is `10.0.2.2` on the
standard AVD emulator; alternatively `adb reverse tcp:8081 tcp:8081` (and the same for the
API port) makes host ports reachable as `localhost`.

## Gotchas

- Animation scales left at 1 make `assertVisible` flaky; zero them on the QA AVD.
- `pm clear` also clears granted permissions — re-grant after it if the flow depends on them.
- `screenrecord` stops silently at the time limit; long journeys need chunked recordings.
- An emulator without Play Services fails Google-sign-in flows in a way that looks like an app bug.
