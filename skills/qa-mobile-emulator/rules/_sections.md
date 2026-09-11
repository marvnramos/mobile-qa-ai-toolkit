# QA Mobile Emulator — Section Definitions

## Sections

### pre — Preflight and Inputs
Impact: CRITICAL
Order: 1
Everything that must be true before a flow runs: the brief contract, the device and
tooling gates, and proof that the bundle on the device is the build under test.

### flow — Flow Authoring
Impact: HIGH
Order: 2
How Maestro flows are written so a failure means the app is wrong, not the flow.

### out — Outputs
Impact: CRITICAL
Order: 3
Evidence capture and the machine-readable findings contract the orchestrator consumes.

### safe — Safety Boundary
Impact: CRITICAL
Order: 4
The read-only boundary this personality never crosses.

## Rule Index

- `pre-brief-contract.md`
- `pre-preflight-gates.md`
- `pre-bundle-freshness.md`
- `flow-maestro-authoring.md`
- `flow-selector-strategy.md`
- `out-evidence-capture.md`
- `out-findings-schema.md`
- `safe-read-only.md`
