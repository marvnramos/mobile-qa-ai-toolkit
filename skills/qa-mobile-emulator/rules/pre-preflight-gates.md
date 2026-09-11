---
title: Run every preflight gate and fail closed on the first one that fails
impact: CRITICAL
tags:
  - qa
  - mobile
  - preflight
  - blocker
---

## Preflight Gates

Six gates, in order, before the first flow runs:

1. **Maestro present** — `maestro --version`.
2. **Device booted** — `xcrun simctl list devices booted` / `adb devices`; boot the device
   named in the brief if none is up.
3. **App installed and launchable** on that device, at the resolved bundle id / package.
4. **Build under test identified and verified** — for a compiled app (native iOS/Android,
   Flutter, an RN release build), the installed build identity is read back from the
   device and matches; for a bundler-backed dev build, the bundler answers and serves the
   checkout under test. See `pre-build-freshness.md`.
5. **Backend readiness** — the readiness path from the project QA config returns 2xx.
6. **Test data present** for the flows in scope.

A failed gate is a **BLOCKER finding with `stopped_early: true`, and the run stops.**

**Incorrect (routing around a failed gate):**

```bash
curl -sf "$API_URL/health" || true      # wrong path, failure swallowed
maestro test flows/                      # runs anyway, against an unready backend
# → 3 flows fail on empty lists; reported as 3 product bugs
```

- Error: Three fabricated product findings that disappear the moment the backend is seeded.
- Cause: The gate was advisory instead of blocking, and the health path was assumed rather than read from config.

**Correct (explicit gates, one blocker, stop):**

```bash
HEALTH_PATH=$(grep -A3 '^api:' .qa/config.yml | grep health_path | awk '{print $2}')
if ! curl -sf "${QA_API_URL}${HEALTH_PATH}" >/dev/null; then
  cat > "$FINDINGS_DIR/F-qa-mobile-emulator-001.json" <<JSON
{"id":"F-qa-mobile-emulator-001","run_id":"$RUN_ID","agent":"qa-mobile-emulator",
 "severity":"BLOCKER","status":"open","title":"Backend not ready — QA run halted",
 "flow":"preflight","repro":["curl ${QA_API_URL}${HEALTH_PATH}"],
 "expected":"2xx from the readiness endpoint","actual":"connection refused",
 "evidence_paths":["$EVIDENCE_DIR/logs/preflight.log"],"stopped_early":true,
 "issue_url":null,"duplicate_of":null,"fix_ref":null}
JSON
  exit 0
fi
```

- One honest blocker instead of a pile of phantom product bugs.
- `curl -f` exits 22 on a 404, so a wrong health path fails the gate for the wrong reason — read the path from config rather than hardcoding `/health`.

**Why it matters:**

Every downstream consumer — triage, the bug fixer, the report — treats a finding as a
statement about the product. Environment failures dressed as product failures waste a fix
cycle and erode trust in the whole QA run.
