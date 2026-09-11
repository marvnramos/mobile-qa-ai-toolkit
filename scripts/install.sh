#!/usr/bin/env bash
# Thin wrapper: the installer lives with the skill so that a skills-CLI install
# (which ships only skills/) still carries it.
#   bash scripts/install.sh [TARGET_DIR]
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "$HERE/skills/qa-mobile-emulator/assets/install.sh" "$@"
