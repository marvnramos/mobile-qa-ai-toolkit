---
title: Findings JSON is the contract — one file per defect, manifest line always
impact: CRITICAL
tags:
  - qa
  - findings
  - schema
  - contract
---

## Findings Contract

One JSON file per defect at `FINDINGS_DIR/F-qa-mobile-emulator-NNN.json` (zero-padded
counter), plus exactly one manifest line per run. The markdown report is the human
artifact; this JSON is what triage, the bug fixer, and the retrospective actually read.

| Field | Rule |
|---|---|
| `id` | `F-qa-mobile-emulator-NNN`, matching the filename |
| `run_id` | The run id from the brief, unchanged |
| `agent` | `qa-mobile-emulator` |
| `severity` | Exactly one of BLOCKER, HIGH, MEDIUM, LOW — from the project severity map, no custom levels |
| `status` | Always `open` from a prober; only the orchestrator or fixer transitions it |
| `flow` | Must name a real test-plan section and heading; a missing heading means the plan is stale — report that, do not invent a flow |
| `repro` | Ordered strings, one action each, max 10 — the flow reference carries the setup |
| `expected` / `actual` | Observable outcomes only, never a guess at the cause in code |
| `evidence_paths` | At least one for BLOCKER/HIGH, each existing on disk under the run's evidence dir |
| `stopped_early` | `true` only when this finding halted the run |
| `issue_url` / `duplicate_of` / `fix_ref` | Always `null` from a prober |

**Incorrect (prose result, invented severity, no evidence):**

```text
Ran 8 flows, 6 passed. The session screen is broken — looks like the query
returns null because the resolver probably doesn't handle an empty booster.
Severity: CRITICAL. Screenshots are in /tmp.
```

- Error: Nothing machine-readable — the orchestrator regexes prose, miscounts the run, and cannot dispatch a fix; `CRITICAL` is not in the severity map and `/tmp` evidence is gone by the next run.
- Cause: The prober reported a narrative and a root-cause theory instead of the contract.

**Correct (one file per defect, then the manifest):**

```bash
cat > "$FINDINGS_DIR/F-qa-mobile-emulator-001.json" <<JSON
{
  "id": "F-qa-mobile-emulator-001",
  "run_id": "$RUN_ID",
  "agent": "qa-mobile-emulator",
  "ticket": "$TICKET",
  "severity": "HIGH",
  "status": "open",
  "title": "Practice session screen renders empty after tapping Start",
  "flow": "test-plan.md ## Mobile Flows > Start a practice session",
  "repro": ["Launch the app as the seeded learner", "Open Practice", "Tap Start practice"],
  "expected": "The first phrase card is visible within 20s",
  "actual": "Session screen stays empty; no error is shown",
  "evidence_paths": [".qa/reports/$RUN_ID/screenshots/TC-042-03-session-started.png"],
  "stopped_early": false,
  "issue_url": null,
  "duplicate_of": null,
  "fix_ref": null
}
JSON

printf '%s\n' "{\"agent\":\"qa-mobile-emulator\",\"flows_run\":8,\"flows_passed\":7,\"findings\":1,\"stopped_early\":false,\"completed_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" \
  >> "$FINDINGS_DIR/_manifest.json"
```

- Counts come from the manifest, never from parsing prose.
- A zero-finding run still writes the manifest line — absence of the manifest means the run did not complete, which is a different fact from "nothing was wrong".

**Why it matters:**

Every automated step after the run assumes this shape. A finding that breaks it is not
"slightly messy" — it is invisible to triage, uncounted in the report, and unfixable
without a human re-reading the transcript.
