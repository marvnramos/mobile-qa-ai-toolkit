# Expo Dev Client, Metro, and Deep Links

## Which binary is on the device

Three shapes, and they fail differently:

| Build | JS source | Symptom when wrong |
|---|---|---|
| Dev client | Metro, live | Loads the wrong branch if Metro runs from another checkout |
| Preview / release (internal) | Bundled at build time | Silently tests yesterday's code; no Metro connection at all |
| Expo Go | Metro, live | Any custom native module is simply absent |

Confirm the installed bundle id before anything else — a dev client is often a *different*
bundle id from production (`com.example.app.dev`), and testing the wrong one is
indistinguishable from a passing run.

## Metro

```bash
curl -sf http://localhost:8081/status                 # expect: packager-status:running
npx expo start --dev-client --clear                   # --clear drops a poisoned cache
npx expo start --dev-client --port 8082               # second Metro when the default is taken
```

Point the app at a specific Metro instance with a deep link rather than by guessing:

```bash
xcrun simctl openurl UDID "myapp://expo-development-client/?url=http%3A%2F%2Flocalhost%3A8082"
adb shell am start -a android.intent.action.VIEW \
  -d "myapp://expo-development-client/?url=http%3A%2F%2F10.0.2.2%3A8082" PACKAGE
```

## Environment baked into the bundle

`EXPO_PUBLIC_*` values are inlined at bundle time, and a worktree-local `.env` beats an
exported shell variable. A flow that fails with "offline" or hits the wrong API is
usually a baked env var, not a device network problem — check `.env`/`.env.local` in the
checkout Metro is serving, then restart Metro with `--clear`.

## Stale native module

A redbox reading `Cannot find native module 'X'` means the JS bundle imports a native
module the installed binary does not contain. That is an **environment blocker against the
dev client** — it needs a native rebuild — not a defect in the feature under test. Report
it as such and stop; do not attempt a workaround.

## Expo Router note

Anything under the router directory (`app/`) is shipped as a route. Never write a test
file, fixture, or scratch screen there — it becomes part of the app.
