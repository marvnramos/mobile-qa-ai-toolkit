# Changelog

## 0.2.0

Generalized beyond React Native — the toolkit now covers native iOS, native Android,
Flutter, React Native, and Expo.

- `framework` and `build` are first-class brief and config inputs; `js_source` is gone
- `pre-bundle-freshness` → `pre-build-freshness`: reinstall-and-read-back identity for
  compiled apps (`CFBundleVersion`, `versionCode`), bundler-origin checks for JS dev builds
- Selector strategy maps `id` to `accessibilityIdentifier`, `resource-id`, `testID`, and
  Flutter Semantics, with `maestro hierarchy` as the discovery tool
- Preflight gate 4 is now "build under test identified and verified"
- New `references/native-builds.md`: artifact per target, build discovery, identity
  read-back, Flutter notes
- Framework matrix in the skill and the README

## 0.1.0

Initial release, extracted from the TalkBox `qa-mobile-emulator` personality and made
project-agnostic.

- `qa-mobile-emulator` skill — 5-phase workflow, execute / verify-fix / cross-platform modes
- 8 rules: brief contract, preflight gates, bundle freshness, flow authoring, selector
  strategy, evidence capture, findings schema, read-only boundary
- References for Maestro, iOS Simulator, Android emulator, and the Expo dev client
- `qa-mobile-emulator` agent and `/qa-mobile` command
- `scripts/install.sh` project installer and `scripts/audit.rb` structural gate
