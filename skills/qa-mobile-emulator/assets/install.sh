#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# qa-mobile-emulator — project installer
#
#   bash install.sh [TARGET_DIR]
#
# Installs the three things a project must supply around the skill:
#   1. .claude/agents/qa-mobile-emulator.md   (spawnable subagent definition)
#   2. .claude/commands/qa-mobile.md           (/qa-mobile sweep command)
#   3. .qa/config.yml                          (device / app / readiness config)
#   4. .qa/ run dirs + a mobile test-plan stub
#
# Plugin users already have 1 and 2 from the plugin — the script skips whatever exists.
#
# Existing files are never overwritten — anything present is reported and skipped.
# The skill itself is installed separately:
#   /plugin marketplace add marvnramos/mobile-qa-ai-toolkit  (Claude Code)
#   npx skills add marvnramos/mobile-qa-ai-toolkit -s qa-mobile-emulator
# ============================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # the skill's assets dir
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
TEMPLATES="$HERE/templates"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${CYAN}[info]${NC}  $*"; }
ok()   { echo -e "${GREEN}[ok]${NC}    $*"; }
warn() { echo -e "${YELLOW}[warn]${NC}  $*"; }

echo ""
info "Installing qa-mobile-emulator into: $TARGET_DIR"

# ── 1. Subagent definition ────────────────────────────────────
mkdir -p "$TARGET_DIR/.claude/agents"
AGENT="$TARGET_DIR/.claude/agents/qa-mobile-emulator.md"
if [ -f "$AGENT" ]; then
  warn "Skipping .claude/agents/qa-mobile-emulator.md (exists)"
else
  cp "$HERE/agents/qa-mobile-emulator.md" "$AGENT"
  ok ".claude/agents/qa-mobile-emulator.md — fill in the Project overlay section"
fi

# ── 2. Slash command ──────────────────────────────────────────
mkdir -p "$TARGET_DIR/.claude/commands"
CMD="$TARGET_DIR/.claude/commands/qa-mobile.md"
if [ -f "$CMD" ]; then
  warn "Skipping .claude/commands/qa-mobile.md (exists)"
else
  cp "$HERE/commands/qa-mobile.md" "$CMD"
  ok ".claude/commands/qa-mobile.md — run it with /qa-mobile"
fi

# ── 3. QA config ──────────────────────────────────────────────
mkdir -p "$TARGET_DIR/.qa"
CONFIG="$TARGET_DIR/.qa/config.yml"
if [ -f "$CONFIG" ]; then
  if grep -q "qa-mobile-emulator" "$CONFIG"; then
    ok ".qa/config.yml already registers qa-mobile-emulator"
  else
    cp "$TEMPLATES/qa-config-mobile.yml" "$TARGET_DIR/.qa/config.mobile.yml"
    warn ".qa/config.yml exists — wrote .qa/config.mobile.yml to merge by hand"
  fi
else
  cp "$TEMPLATES/qa-config-mobile.yml" "$CONFIG"
  ok ".qa/config.yml — replace every REPLACE- value"
fi

# ── 4. Run dirs, flow template, test-plan stub ────────────────
mkdir -p "$TARGET_DIR/.qa/findings" "$TARGET_DIR/.qa/reports" "$TARGET_DIR/.qa/maestro"
cp -n "$TEMPLATES/flow.yaml" "$TARGET_DIR/.qa/maestro/_template.yaml" 2>/dev/null \
  && ok ".qa/maestro/_template.yaml" || warn "Skipping flow template (exists)"

PLAN="$TARGET_DIR/.qa/test-plan.md"
if [ -f "$PLAN" ]; then
  if grep -qi "^##\+ *Mobile Flows" "$PLAN"; then
    ok "test plan already has a Mobile Flows section"
  else
    cat >> "$PLAN" <<'PLAN_MD'

## Mobile Flows (for qa-mobile-emulator)

### TC-001 — [Flow name]
- **Platform**: ios | android | both
- **Precondition**: [seeded account, entitlement, data the flow needs]
- **Steps**:
  1. [Action]
  2. [Action]
- **Expected**: [Observable outcome on screen]
PLAN_MD
    ok "Appended a Mobile Flows section to .qa/test-plan.md"
  fi
else
  cat > "$PLAN" <<'PLAN_MD'
# QA Test Plan

## Mobile Flows (for qa-mobile-emulator)

### TC-001 — [Flow name]
- **Platform**: ios | android | both
- **Precondition**: [seeded account, entitlement, data the flow needs]
- **Steps**:
  1. [Action]
  2. [Action]
- **Expected**: [Observable outcome on screen]
PLAN_MD
  ok ".qa/test-plan.md"
fi

# ── 5. gitignore evidence, keep findings ──────────────────────
GITIGNORE="$TARGET_DIR/.gitignore"
if [ -f "$GITIGNORE" ] && ! grep -q "^\.env\.qa$" "$GITIGNORE" 2>/dev/null; then
  printf '\n# QA agent credentials\n.env.qa\n' >> "$GITIGNORE"
  ok "Added .env.qa to .gitignore"
fi

# ── 6. Environment check ──────────────────────────────────────
echo ""
info "Environment check"
command -v maestro >/dev/null && ok "maestro $(maestro --version 2>/dev/null | head -1)" \
  || warn "maestro not found — curl -fsSL https://get.maestro.mobile.dev | bash"
command -v xcrun >/dev/null && ok "xcrun (iOS Simulator) available" \
  || warn "xcrun not found — iOS Simulator flows unavailable on this machine"
command -v adb >/dev/null && ok "adb (Android) available" \
  || warn "adb not found — Android emulator flows unavailable on this machine"

echo ""
echo "Next steps:"
echo "  1. Toolkit installed (plugin or skill) — this script wired the project side"
echo "  2. Fill in .qa/config.yml (device, app id, Metro URL, readiness path)"
echo "  3. Fill in the Project overlay in .claude/agents/qa-mobile-emulator.md"
echo "  4. Write mobile flows in .qa/test-plan.md"
echo "  5. Run:  @agent-qa-mobile-emulator run the mobile emulator QA for <scope>"
echo ""
