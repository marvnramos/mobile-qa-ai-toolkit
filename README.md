# mobile-qa-ai-toolkit

An independent AI toolkit for **on-device mobile QA**. It ships one read-only prober that
drives a mobile app through its real user journeys on an **iOS Simulator or Android
emulator** with [Maestro](https://maestro.mobile.dev), screenshots every verification
point, and emits structured findings JSON that an orchestrator, a bug fixer, or a human
can act on.

**Framework-neutral**: native iOS (Swift/ObjC), native Android (Kotlin/Java), React
Native, Expo, and Flutter. Maestro drives the rendered UI, so the flow layer is identical
everywhere; what changes is where the code under test lives and how elements are
identified — both selected by the `framework` key in the project's config.

| Framework | Code under test | Selector source | Freshness check |
|---|---|---|---|
| Native iOS | The installed `.app` / `.ipa` | `accessibilityIdentifier` | Reinstall, verify `CFBundleVersion` |
| Native Android | The installed APK | `android:id` → `resource-id` | Reinstall, verify `versionCode` |
| React Native / Expo | Metro bundle, or a release binary | `testID` | Bundler origin + forced reload |
| Flutter | The installed build | `Semantics` / `ValueKey` | Reinstall, verify the build id |

It is stack-aware but **project-agnostic** — framework, device, bundle id, artifact path,
bundler URL, backend readiness path, and test data all come from the target project's
`.qa/config.yml`, never from anything baked into the skill.

## What's inside

```text
agents/qa-mobile-emulator.md          spawnable subagent — read-only toolset (Bash Read Grep Glob)
commands/qa-mobile.md                 /qa-mobile — mint a run, dispatch the prober, collect findings
skills/qa-mobile-emulator/
  SKILL.md                            the contract: persona, 5-phase workflow, 3 modes
  rules/                              8 enforced rules (preflight, freshness, flows, evidence, findings, safety)
  references/                         Maestro, xcrun simctl, adb, native builds, Expo dev client
  assets/templates/                   Maestro flow template + .qa/config.yml mobile block
  assets/install.sh                   wire the toolkit into a target repo (bundled with the skill)
  assets/agents|commands/             mirrors of the two files above, for skills-only installs
scripts/install.sh                    wrapper around the bundled installer
scripts/audit.rb                      structural gate (CI runs it), incl. mirror-drift check
```

## Install

**As a Claude Code plugin** (recommended — brings the agent, skill, and command together):

```bash
/plugin marketplace add marvnramos/mobile-qa-ai-toolkit
/plugin install mobile-qa@mobile-qa-ai-toolkit
```

**As a standalone skill** (skills CLI):

```bash
npx skills add marvnramos/mobile-qa-ai-toolkit -s qa-mobile-emulator
```

The plugin path brings the agent, the skill, and the `/qa-mobile` command together. The
skills-CLI path ships the **skill only** — the agent and command come from the installer
below, which is bundled inside the skill for exactly that reason.

**Then wire it into the project under test** (either path):

```bash
# from a clone of this repo
bash scripts/install.sh /path/to/your/repo

# or from the installed skill, with no clone
bash .claude/skills/qa-mobile-emulator/assets/install.sh .
```

That creates `.claude/agents/qa-mobile-emulator.md`, `.claude/commands/qa-mobile.md`, a
`.qa/config.yml` with a `mobile` block to fill in, a `.qa/test-plan.md` stub with a Mobile
Flows section, and a Maestro flow template — then reports the local Maestro / xcrun / adb
situation. Nothing existing is overwritten, and plugin users simply see the agent and
command steps skipped.

## Use

```text
/qa-mobile TAL-1234 ios
/qa-mobile smoke android
@agent-qa-mobile-emulator run the mobile emulator QA for the onboarding flow
```

A run produces, in the **main checkout**:

```text
.qa/reports/<run-id>/maestro/TC-042.yaml          one flow per test case
.qa/reports/<run-id>/screenshots/TC-042-01-*.png  one per verification point
.qa/reports/<run-id>/recordings/ .../logs/        video + Maestro output
.qa/findings/<run-id>/F-qa-mobile-emulator-001.json
.qa/findings/<run-id>/_manifest.json              always written, even on a clean run
```

## The rules it enforces

| Rule | Impact | What it prevents |
|---|---|---|
| `pre-brief-contract` | HIGH | Guessed bundle ids and devices — evidence with no provenance |
| `pre-preflight-gates` | CRITICAL | Environment failures reported as product bugs |
| `pre-build-freshness` | CRITICAL | A green re-run against a stale binary or bundle closing a live defect |
| `flow-maestro-authoring` | HIGH | Opaque mega-flows, fixed sleeps, assertions with no screenshot |
| `flow-selector-strategy` | HIGH | Text and coordinate selectors that break on copy or layout |
| `out-evidence-capture` | HIGH | Evidence written into a worktree that later gets pruned |
| `out-findings-schema` | CRITICAL | Prose results that triage cannot count or dispatch |
| `safe-read-only` | CRITICAL | A prober editing the code it is judging |

## Requirements

- [Maestro](https://maestro.mobile.dev) 1.39+ (`curl -fsSL https://get.maestro.mobile.dev | bash`)
- Xcode command line tools for iOS Simulator flows, Android platform tools (`adb`) for emulator flows
- Nothing else: no test runner, no app-side instrumentation, no source changes
- A project with a `.qa/` directory — `scripts/install.sh` creates one

## Development

```bash
ruby scripts/audit.rb     # structural gate: skills, rules, agents, manifest sync
```

CI runs the audit on every push and pull request. Two kinds of drift fail it: a skill's
`metadata.version` out of sync with its `marketplace.json` entry, and `agents/` or
`commands/` out of sync with their mirrors under `skills/qa-mobile-emulator/assets/`
(edit the root copy, then copy it across).

### Adding another prober

1. `skills/<name>/SKILL.md` with `## Workflow`, `## Examples`, `## Troubleshooting`, and
   `Use when …` trigger language in the description.
2. `skills/<name>/rules/` with `_sections.md` plus rules carrying `title`, `impact`,
   `tags`, an **Incorrect** example, a **Correct** example, and **Why it matters**.
3. `agents/<name>.md` if it needs to be spawnable, with a read-only toolset for probers.
4. An entry in `marketplace.json`, then `ruby scripts/audit.rb`.
