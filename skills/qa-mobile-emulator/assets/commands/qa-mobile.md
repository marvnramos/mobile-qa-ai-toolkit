---
description: Run an on-device mobile QA sweep with the qa-mobile-emulator prober
argument-hint: [scope — ticket id, flow name, or "smoke"] [ios|android]
allowed-tools: Bash, Read, Grep, Glob, Task
---

# /qa-mobile

Run a read-only, on-device QA sweep of the mobile app for: **$ARGUMENTS**

## What to do

1. **Resolve the run context before dispatching.** Read `.qa/config.yml` (the `mobile` and
   `api` blocks — including `framework` and `build`) and `.qa/test-plan.md`. Mint
   `RUN_ID=$(date -u +%Y-%m-%dT%H-%M-qa)` and create the absolute `.qa/findings/$RUN_ID/`
   and `.qa/reports/$RUN_ID/` dirs **in the main checkout**, even when the session is
   running inside a worktree.
2. **Report what the sweep will touch** before it starts: the device, the app id, the build
   under test (artifact path or bundler URL), and the flows in scope. A simulator, an
   emulator, and a bundler port are shared resources — say so rather than racing another
   agent for them.
3. **Dispatch `qa-mobile-emulator`** with a brief containing every field from the skill's
   Phase 0 table: `run_id`, absolute `findings_dir` and `evidence_dir`, `platform`,
   `framework`, `device`, `app`, `build`, `api`, and `scope`. Do not leave a field for the
   agent to guess.
4. **Collect the result** — read `.qa/findings/$RUN_ID/_manifest.json` and every
   `F-qa-mobile-emulator-*.json`, confirm the evidence paths of BLOCKER and HIGH findings
   exist on disk, then summarize: flows run, flows passed, findings by severity, and the
   evidence dir.

## Rules

- The prober is **read-only**. If a finding needs a fix, hand it to a fixer agent — never
  let the prober edit source.
- A missing device, missing tooling, or missing test data is a **BLOCKER finding and a
  stop**, reported as such. Never present a blocked run as a pass.
- Do not file issue-tracker tickets from this command unless the user asks; findings JSON
  is the deliverable.
