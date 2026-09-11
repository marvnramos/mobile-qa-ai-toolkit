# Changelog

## 0.1.0

Initial release, extracted from the TalkBox `qa-mobile-emulator` personality and made
project-agnostic.

- `qa-mobile-emulator` skill — 5-phase workflow, execute / verify-fix / cross-platform modes
- 8 rules: brief contract, preflight gates, bundle freshness, flow authoring, selector
  strategy, evidence capture, findings schema, read-only boundary
- References for Maestro, iOS Simulator, Android emulator, and the Expo dev client
- `qa-mobile-emulator` agent and `/qa-mobile` command
- `scripts/install.sh` project installer and `scripts/audit.rb` structural gate
