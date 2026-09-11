---
title: Resolve every brief input before testing — discover, then ask, never guess
impact: HIGH
tags:
  - qa
  - mobile
  - brief
  - configuration
---

## Brief Contract

A run is defined by nine inputs: `run_id`, `findings_dir`, `evidence_dir`, `platform`,
`device`, `app`, `js_source`, `api`, `scope`. When an input is absent from the brief,
resolve it in this order: **project QA config → project app config → ask the user.**
Guessing a bundle id or a device silently tests the wrong thing.

**Incorrect (guessing the app identity):**

```bash
# Brief said "test onboarding on iOS" and nothing else.
xcrun simctl launch booted com.example.app     # invented bundle id
maestro test onboarding.yaml                    # device, run-id, evidence dir all implicit
```

- Error: `Application com.example.app is not installed`, or worse, a stale build of a different app launches and the flow "passes".
- Cause: Identity was assumed instead of discovered, so nothing ties the evidence to a known build.

**Correct (discover, then pin the values for the whole run):**

```bash
RUN_ID="${RUN_ID:-$(date -u +%Y-%m-%dT%H-%M-qa)}"
EVIDENCE_DIR="$REPO_ROOT/.qa/reports/$RUN_ID"
FINDINGS_DIR="$REPO_ROOT/.qa/findings/$RUN_ID"
mkdir -p "$EVIDENCE_DIR"/{maestro,screenshots,recordings,logs} "$FINDINGS_DIR"

# app id from the project's own config, not from memory
APP_ID=$(grep -A2 '"ios"' app.json | grep bundleIdentifier | sed -E 's/.*: *"(.*)".*/\1/')
DEVICE=$(xcrun simctl list devices booted -j | python3 -c 'import json,sys;d=json.load(sys.stdin)["devices"];print(next(x["udid"] for v in d.values() for x in v))')
echo "run=$RUN_ID app=$APP_ID device=$DEVICE" | tee "$EVIDENCE_DIR/logs/run-context.log"
```

- Every artifact is traceable to a known app id, device, and run id.
- The run context is itself evidence — a reviewer can tell what was tested.

**Why it matters:**

Mobile QA evidence is only worth what its provenance is worth. A screenshot with no record
of which build, device, and bundle produced it cannot support or refute a bug report, and
an invented bundle id turns a whole run into confident noise.
