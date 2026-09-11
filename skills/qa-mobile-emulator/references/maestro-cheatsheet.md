# Maestro Cheatsheet

Verified against Maestro 1.3x–2.x. `maestro --version` first; syntax below is the YAML
flow format (`appId` header, `---`, then commands).

## CLI

```bash
maestro test flow.yaml                     # run one flow
maestro test flows/ --include-tags smoke   # run a dir, filtered by tag
maestro test flow.yaml --env APP_ID=com.example.app --env EVIDENCE=/abs/path
maestro test flow.yaml --format junit --output report.xml
maestro test flow.yaml --device UDID_OR_EMULATOR_NAME
maestro studio                             # interactive inspector — selector discovery
maestro hierarchy                          # dump the current view hierarchy (find test ids)
```

Exit code 0 = every assertion passed. Non-zero = failure; Maestro writes a failure
screenshot and a debug bundle (path printed at the end of the run, usually
`~/.maestro/tests/<timestamp>/`) — copy anything you cite into the run's evidence dir.

## Flow header

```yaml
appId: ${APP_ID}
name: TC-042 — human readable case name
tags:
  - smoke
env:
  EVIDENCE: /abs/path/.qa/reports/RUN_ID
---
```

## Commands used most

| Command | Notes |
|---|---|
| `launchApp` | `clearState: true`, `clearKeychain: true`, `stopApp: true` sub-keys |
| `tapOn` | `id:`, `text:`, `point:`, plus `index:`, `childOf:`, `enabled:`, `retryTapIfNoChange:` |
| `assertVisible` / `assertNotVisible` | Same selector shape as `tapOn` |
| `extendedWaitUntil` | `visible:`/`notVisible:` + `timeout:` — the condition-based wait; prefer over `wait` |
| `scrollUntilVisible` | `element:`, `direction:`, `timeout:`, `speed:` |
| `inputText` / `eraseText` / `hideKeyboard` | `inputRandomEmail` for throwaway accounts |
| `takeScreenshot` | Path without extension; Maestro appends `.png` |
| `openLink` | Deep links and custom schemes — fastest way to a screen under test |
| `runFlow` | `file:` to reuse a subflow, `when:` for conditionals |
| `back` / `pressKey` | `pressKey: Enter`, `Home`, `Back`, `Lock` |
| `swipe` | `direction:` or explicit `start:`/`end:` percentages |
| `repeat` | `times:` or `while:` with a condition |
| `evalScript` | JS escape hatch — use sparingly, it hides intent |

## Selector precedence

`id` (testID / resource-id) → `id` on a stable parent + `index`/`childOf` → accessibility
label → visible text. See `../rules/flow-selector-strategy.md`.

## Gotchas

- `wait` does not exist as a top-level command in current versions — use `extendedWaitUntil`.
- `takeScreenshot` paths are relative to the working directory unless absolute; always pass an absolute evidence path.
- iOS `clearState` does not clear the keychain unless asked — a stale auth token survives.
- Text matching is a regex substring match, and it matches the *rendered* string, so locale and truncation both break it.
