---
title: Select by test id first — visible text is a last resort, not a default
impact: HIGH
tags:
  - qa
  - mobile
  - selectors
  - testid
  - accessibility
---

## Selector Strategy

Resolution order for every `tapOn` / `assertVisible`:

1. `id:` — the React Native `testID` (surfaces as the accessibility identifier on iOS and
   the resource id on Android).
2. `id:` on a stable parent plus `childOf` / `index` for repeated rows.
3. Accessibility label, when the product guarantees it.
4. Visible text — only for copy that is asserted **because** it is the thing under test.

When no stable id exists, report the gap in the run notes. Do not add a `testID` to product
source: this personality is read-only.

**Incorrect (text selectors as the default):**

```yaml
- tapOn: "Continue"          # three "Continue" buttons on this screen
- assertVisible: "Welcome back, Marvin!"   # breaks on any copy or locale change
- tapOn:
    point: "50%,72%"          # coordinate tap — meaningless the moment layout shifts
```

- Error: `Element not found: Continue` on a localized build, or a tap that lands on the wrong control when a banner shifts the layout by 40 px.
- Cause: The selector encodes presentation (copy, position) rather than identity.

**Correct (identity-based, text only where text is the assertion):**

```yaml
- tapOn:
    id: "signup-continue"
- assertVisible:
    id: "home-greeting"
- assertVisible: "Welcome back"        # the copy IS the acceptance criterion here
- tapOn:
    id: "phrase-row"
    index: 0
```

- Survives copy edits, locale switches, and layout changes.
- Text assertions remain where the test plan actually specifies the wording.

**Why it matters:**

Text- and coordinate-based selectors generate failures that look like product bugs and
cost a triage cycle each. Worse, they generate passes on the wrong element. Identity
selectors make a red flow mean exactly one thing: the behavior changed.
