---
title: One Maestro flow per test case, deterministic waits, screenshot at every assertion
impact: HIGH
tags:
  - qa
  - mobile
  - maestro
  - flows
---

## Flow Authoring

One file per test case, named for the case id, written under the run's evidence dir. A
flow starts from a known state (`clearState` or an explicit launch), asserts an observable
outcome at every step it claims to verify, and screenshots each of those assertions.
Waiting is done with Maestro's condition commands, never with a fixed sleep.

**Incorrect (one mega-flow, sleeps, no evidence):**

```yaml
appId: com.example.app
---
- launchApp
- tapOn: "Get started"
- inputText: "learner@example.com"
- tapOn: "Continue"
- runFlow:
    commands:
      - swipe: { direction: UP }
- wait: 5000              # hope the list loaded
- tapOn: "Start practice"  # 12 more steps follow in the same file
```

- Error: A failure at step 9 reports "flow failed" with no screenshot and no isolation — the whole journey is one opaque unit, and the 5 s sleep is flaky on a cold emulator.
- Cause: The flow was written as a script to reach the end, not as a test that verifies and evidences each claim.

**Correct (scoped case, condition waits, evidence at each assertion):**

```yaml
appId: ${APP_ID}
name: TC-042 — learner can start a practice session
---
- clearState
- launchApp:
    clearKeychain: false
- assertVisible:
    id: "onboarding-cta"
- takeScreenshot: ${EVIDENCE}/screenshots/TC-042-01-onboarding
- tapOn:
    id: "onboarding-cta"
- extendedWaitUntil:
    visible:
      id: "practice-home-list"
    timeout: 20000
- takeScreenshot: ${EVIDENCE}/screenshots/TC-042-02-practice-home
- tapOn:
    id: "practice-start-button"
- extendedWaitUntil:
    visible:
      id: "practice-session-screen"
    timeout: 20000
- takeScreenshot: ${EVIDENCE}/screenshots/TC-042-03-session-started
```

- The case id, the intent, and each verification point are all legible from the file alone.
- `extendedWaitUntil` makes the flow slow-machine tolerant without inventing timing.
- Every assertion has a matching screenshot named for its step.

**Why it matters:**

A flow is a claim about the product. Claims that cannot be located (which step?), evidenced
(what did the screen look like?), or reproduced on a slower machine (why did it pass
yesterday?) get discounted by whoever reads the report — and rightly so.
