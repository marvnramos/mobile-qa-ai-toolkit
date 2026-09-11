---
title: Prove the device is running the build under test before trusting any result
impact: CRITICAL
tags:
  - qa
  - mobile
  - metro
  - stale-build
---

## Bundle Freshness

A simulator happily keeps serving the last bundle it loaded. Before the first flow, and
again after every code change or re-run, confirm three things: Metro is serving from the
**checkout under test**, the app **reloaded** since the change, and an observable marker
from that build is on screen or in the log.

**Incorrect (re-running straight after a fix):**

```bash
# fix lands in the worktree
maestro test "$EVIDENCE_DIR/maestro/TC-042.yaml"   # green
# reported: "verified fixed"
```

- Error: The flow asserted against the bundle loaded before the fix, so the pass says nothing about the fix.
- Cause: Metro was started from a different checkout, or the app never reloaded — neither was checked.

**Correct (verify origin, force the reload, check a marker):**

```bash
# 1. Metro is serving the checkout under test
curl -sf "$METRO_URL/status"                       # expect: packager-status:running
grep -m1 "$WORKTREE_PATH" "$EVIDENCE_DIR/logs/metro.log" \
  || { echo "Metro is serving a DIFFERENT checkout"; exit 1; }

# 2. force a fresh bundle onto the device
xcrun simctl terminate "$DEVICE" "$APP_ID"
xcrun simctl launch "$DEVICE" "$APP_ID"

# 3. prove the build under test is what loaded
grep -m1 "Running application" "$EVIDENCE_DIR/logs/metro.log"
maestro test "$EVIDENCE_DIR/maestro/TC-042.yaml"
```

- The result now describes the build the ticket changed.
- A cross-checkout mismatch is caught before it becomes a false verification.

**Why it matters:**

A false pass from a stale bundle is worse than a failure: it closes a real defect, ships
it, and the next person to find it starts from "but QA verified this". The same trap
catches release builds — a binary installed yesterday does not contain today's fix.
