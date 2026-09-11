---
title: The emulator prober never writes to product source
impact: CRITICAL
tags:
  - qa
  - safety
  - read-only
---

## Read-Only Boundary

Allowed writes: Maestro flows, screenshots, recordings, logs, and findings JSON — all
under the run's evidence and findings dirs. Everything else is read-only, including test
sources, fixtures, snapshots, app config, and native projects. Tooling is limited to
`Bash Read Grep Glob` for exactly this reason.

**Incorrect (making the app testable mid-run):**

```bash
# assertVisible keeps failing, so "just add the identifier" — same sin in every stack:
# .accessibilityIdentifier("practice-start") in Swift, android:id in a layout,
# testID on an RN component, Semantics(identifier:) in Flutter.
sed -i '' 's/Button("Start")/Button("Start").accessibilityIdentifier("practice-start")/' \
  Sources/Practice/PracticeStartView.swift
git stash pop && maestro test flows/TC-042.yaml   # now green
```

- Error: The run reports a pass for a build that does not exist in the repo, and an uncommitted diff pollutes the branch under test.
- Cause: The prober treated a testability gap as its own problem to fix.

**Correct (report the gap, test what shipped):**

```yaml
# flow falls back to the most stable available selector
- tapOn:
    id: "practice-home-list"
    childOf:
      id: "practice-root"
```

```text
Run note: the Start control exposes no accessibility identifier; TC-042 selects via its
parent. Filed as a LOW finding ("missing test id blocks stable selection"), not fixed here.
```

- The product is tested exactly as it exists.
- The testability gap becomes a tracked finding instead of an invisible local patch.

**Why it matters:**

A QA agent that edits the code it is testing destroys the independence that makes its
verdict worth anything, and leaves working-tree changes that the next agent inherits
without knowing. Separation of powers: probers observe, fixers change.
