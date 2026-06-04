#!/bin/bash
set -euo pipefail

# First Principles Thinking — Install Script
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/reshiner/first-principles-thinking/main/install.sh | bash
#   curl -fsSL ... | bash -s -- --codex        # also set up Codex CLI
#   curl -fsSL ... | bash -s -- --opencode     # also set up OpenCode
#   curl -fsSL ... | bash -s -- --all          # set up all detected platforms

REPO_URL="https://github.com/reshiner/first-principles-thinking.git"
INSTALL_DIR="${HOME}/.agents/skills/first-principles-thinking"

# ── Parse flags ──────────────────────────────────────────────
INSTALL_CODEX=false
INSTALL_OPENCODE=false

for arg in "$@"; do
  case "$arg" in
    --codex)    INSTALL_CODEX=true ;;
    --opencode) INSTALL_OPENCODE=true ;;
    --all)      INSTALL_CODEX=true; INSTALL_OPENCODE=true ;;
    --help|-h)
      echo "Usage: bash install.sh [--codex] [--opencode] [--all]"
      echo ""
      echo "  --codex      Also link into Codex CLI's skill directory"
      echo "  --opencode   Also link into OpenCode's skill directory"
      echo "  --all        Link into all supported platforms"
      exit 0 ;;
    *)
      echo "Unknown flag: $arg"
      echo "Usage: bash install.sh [--codex] [--opencode] [--all]"
      exit 1 ;;
  esac
done

# ── Install / update core skill ──────────────────────────────
echo "📦 Installing First Principles Thinking skill..."

if [ -d "$INSTALL_DIR/.git" ]; then
  echo "  → Updating existing installation..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "  → Cloning repository..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

echo ""
echo "✅ Core skill installed at ${INSTALL_DIR}"

# ── Platform: Claude Code (v2 Plugin Registration) ──────────
# Since Claude Code 2.x removed ~/.agents/skills/ auto-discovery,
# we register the skill as a plugin in installed_plugins.json v2.
echo "  → Registering in Claude Code v2 plugin system..."

PLUGIN_CACHE_DIR="${HOME}/.claude/plugins/cache/reshiner/first-principles-thinking/1.0.0"

# Create cache structure: .claude-plugin/plugin.json + skills/ + commands/
mkdir -p "$PLUGIN_CACHE_DIR/.claude-plugin"
mkdir -p "$PLUGIN_CACHE_DIR/skills/first-principles-thinking"
mkdir -p "$PLUGIN_CACHE_DIR/commands"

# Write plugin.json (idempotent)
cat > "$PLUGIN_CACHE_DIR/.claude-plugin/plugin.json" <<'PLUGINJSON'
{
  "name": "first-principles-thinking",
  "description": "First Principles Thinking — critically evaluate existing code design, design the ideal solution, then reconcile.",
  "version": "1.0.0",
  "author": {
    "name": "reshiner"
  }
}
PLUGINJSON

# Symlink SKILL.md so updates in the repo are reflected live
ln -sfn "${INSTALL_DIR}/SKILL.md" "$PLUGIN_CACHE_DIR/skills/first-principles-thinking/SKILL.md"

# Write command entry (delegates to skill)
cat > "$PLUGIN_CACHE_DIR/commands/fpt.md" <<'FPTCMD'
---
description: "First Principles Thinking — critically evaluate existing code design, design the ideal solution, then reconcile. / 第一性原理分析 — 批判性评估现有设计，设计理想方案，做出权衡推荐。Use when you want design-quality-first analysis before code changes."
argument-hint: "Describe the change or feature to analyze / 描述你想要分析的需求或改动"
allowed-tools: Read, Write, Edit, Bash, Glob
---

# First Principles Thinking

Load and follow the **first-principles-thinking** skill from this plugin: `skills/first-principles-thinking/SKILL.md`.

## Quick Start

$ARGUMENTS is the user's description of what they want to change. If provided, use it directly as the task. If empty, ask the user what feature or change they want to analyze.

Follow the three-phase process **in order**:
1. **Phase 1: Decompose** — surface intent, decompose existing code, diagnose design debt
2. **Phase 2: Design** — clean-sheet design from fundamentals, document the gap
3. **Phase 3: Reconcile** — compare Path A vs Path B, apply decision framework, produce recommendation

Output the structured `First Principles Analysis` document as specified in the skill.
FPTCMD

# Register in installed_plugins.json v2 (idempotent)
INSTALLED_JSON="${HOME}/.claude/plugins/installed_plugins.json"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
GIT_SHA=$(git -C "$INSTALL_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")

if [ -f "$INSTALLED_JSON" ]; then
  python3 -c "
import json, os

path = os.path.expanduser('$INSTALLED_JSON')
with open(path) as f:
    data = json.load(f)

key = 'first-principles-thinking@reshiner'
if key not in data.get('plugins', {}):
    data.setdefault('plugins', {})[key] = [{
        'scope': 'user',
        'installPath': '$PLUGIN_CACHE_DIR',
        'version': '1.0.0',
        'installedAt': '$TIMESTAMP',
        'lastUpdated': '$TIMESTAMP',
        'gitCommitSha': '$GIT_SHA'
    }]
    with open(path, 'w') as f:
        json.dump(data, f, indent=2)
        f.write('\n')
    print('   • Registered in installed_plugins.json')
  "
  echo "   • Claude Code v2: registered as plugin"
else
  echo "   ⚠ Cannot find ${INSTALLED_JSON}. Manual registration required:"
  echo "      Add an entry 'first-principles-thinking@reshiner' to your installed_plugins.json"
fi

# ── Platform: Codex CLI ──────────────────────────────────────
if [ "$INSTALL_CODEX" = true ]; then
  CODEX_DIR="${HOME}/.codex/skills/first-principles-thinking"
  echo "  → Linking Codex CLI skill..."
  mkdir -p "$(dirname "$CODEX_DIR")"
  if [ -L "$CODEX_DIR" ] || [ ! -e "$CODEX_DIR" ]; then
    ln -sfn "$INSTALL_DIR/adapters/codex" "$CODEX_DIR"
    echo "   • Codex CLI: linked → $CODEX_DIR"
  else
    echo "   ⚠ Codex CLI: $CODEX_DIR already exists and is not a symlink. Skipping."
  fi
fi

# ── Platform: OpenCode ───────────────────────────────────────
if [ "$INSTALL_OPENCODE" = true ]; then
  OPENCODE_DIR="${HOME}/.opencode/skills/first-principles-thinking"
  echo "  → Linking OpenCode skill..."
  mkdir -p "$(dirname "$OPENCODE_DIR")"
  if [ -L "$OPENCODE_DIR" ] || [ ! -e "$OPENCODE_DIR" ]; then
    ln -sfn "$INSTALL_DIR/adapters/opencode" "$OPENCODE_DIR"
    echo "   • OpenCode: linked → $OPENCODE_DIR"
  else
    echo "   ⚠ OpenCode: $OPENCODE_DIR already exists and is not a symlink. Skipping."
  fi
fi

# ── Summary ──────────────────────────────────────────────────
echo ""
echo "   • SKILL.md  —  Core methodology"
echo "   • commands/fpt.md  —  /fpt slash command (Claude Code v2 plugin system)"

if [ "$INSTALL_CODEX" = true ]; then
  echo "   • adapters/codex/  —  Codex CLI agent definition"
fi
if [ "$INSTALL_OPENCODE" = true ]; then
  echo "   • adapters/opencode/  —  OpenCode rules"
fi
echo ""
echo "   Automatic triggers include:"
echo "     - \"第一性原理\" / \"从根本分析\""
echo "     - \"challenge assumptions\" / \"question this design\""
echo "     - Non-trivial code modification requests"
echo ""
