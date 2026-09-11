---
title: Screenshot every verification point and write all evidence to the main checkout
impact: HIGH
tags:
  - qa
  - mobile
  - evidence
  - screenshots
  - worktree
---

## Evidence Capture

Every verification point produces a screenshot. Multi-step journeys additionally get a
screen recording. All of it — flows, screenshots, recordings, logs — lands under the run's
evidence dir in the **main checkout**, given to you as an absolute path. Never inside a
git worktree.

**Incorrect (relative paths from inside a worktree):**

```bash
cd /repo/.worktrees/feature-x
maestro test flows/TC-042.yaml
xcrun simctl io booted screenshot ./shot.png     # lands in the worktree
# worktree pruned after merge → every evidence path in the findings is dead
```

- Error: `evidence_paths` in the findings point at files that no longer exist; BLOCKER findings fail validation at collection.
- Cause: Evidence was written relative to a disposable checkout.

**Correct (absolute main-checkout paths, recording around the journey):**

```bash
EVIDENCE_DIR=/Users/me/repo/.qa/reports/$RUN_ID          # main checkout, absolute
mkdir -p "$EVIDENCE_DIR"/{screenshots,recordings,logs}

xcrun simctl io "$DEVICE" recordVideo "$EVIDENCE_DIR/recordings/TC-042.mp4" &
REC=$!
maestro test "$EVIDENCE_DIR/maestro/TC-042.yaml" 2>&1 | tee "$EVIDENCE_DIR/logs/TC-042.log"
kill -INT $REC && wait $REC 2>/dev/null            # stop cleanly, or the file is unplayable

ls -la "$EVIDENCE_DIR/screenshots" | tee -a "$EVIDENCE_DIR/logs/TC-042.log"
```

- Evidence outlives the branch, the worktree, and the run.
- The recording is finalized before reporting; an un-terminated `recordVideo` leaves a corrupt file.
- Listing the files proves the paths referenced in findings exist on disk.

**Why it matters:**

Worktrees get merged, pruned, and abandoned; evidence has to survive all three. A finding
whose screenshot is missing is, to a reviewer, indistinguishable from a finding that was
never observed.
