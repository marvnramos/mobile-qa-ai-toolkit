# iOS Simulator CLI

```bash
xcrun simctl list devices                       # all devices, grouped by runtime
xcrun simctl list devices booted                # what is actually running
xcrun simctl boot UDID                          # boot (idempotent-ish; errors if already booted)
open -a Simulator                               # show the window
xcrun simctl bootstatus UDID -b                 # block until boot completes
```

## App lifecycle

```bash
xcrun simctl install  UDID /path/App.app
xcrun simctl launch   UDID BUNDLE_ID            # add --console to stream stdout
xcrun simctl terminate UDID BUNDLE_ID
xcrun simctl uninstall UDID BUNDLE_ID
xcrun simctl get_app_container UDID BUNDLE_ID data   # sandbox path, for inspecting storage
xcrun simctl openurl UDID "myapp://practice/42"      # deep link straight to a screen
```

## Evidence

```bash
xcrun simctl io UDID screenshot /abs/evidence/screenshots/name.png
xcrun simctl io UDID recordVideo /abs/evidence/recordings/name.mp4 &
kill -INT $!                                    # SIGINT finalizes the file; SIGKILL corrupts it
xcrun simctl spawn UDID log stream --level debug --predicate 'processImagePath CONTAINS "MyApp"'
```

## Permissions and state

```bash
xcrun simctl privacy UDID grant  notifications BUNDLE_ID   # also: photos, camera, microphone, location
xcrun simctl privacy UDID reset  all BUNDLE_ID
xcrun simctl push UDID BUNDLE_ID payload.apns              # simulated remote notification
xcrun simctl erase UDID                                    # factory reset — device must be shut down
xcrun simctl status_bar UDID override --time 9:41 --batteryLevel 100   # clean screenshots
```

## Driving the UI outside Maestro

`idb` covers the gaps Maestro does not reach (notification taps, hardware buttons):
`idb ui tap X Y`, `idb ui text "..."`, `idb ui button HOME`. Install with
`pipx install fb-idb` (the Python version matters — a pinned virtualenv is often needed).

## Gotchas

- The simulator has **no APNs device token** — push registration always fails there; use `simctl push` for payload-shaped tests and a physical device for the registration chain.
- A simulator app built for a different architecture launches but crashes instantly with no redbox; check the build log, not the screen.
- `xcrun simctl launch` returns the pid immediately — the app may still be splash-screening; wait on a UI condition, not on the command returning.
