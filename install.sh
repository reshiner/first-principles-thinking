#!/bin/bash
set -euo pipefail

# First Principles Plan — Install Script
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/reshiner/first-principles-plan/main/install.sh | bash
#   curl -fsSL ... | bash -s -- --codex        # also set up Codex CLI
#   curl -fsSL ... | bash -s -- --opencode     # also set up OpenCode
#   curl -fsSL ... | bash -s -- --all          # set up all detected platforms

REPO_URL="https://github.com/reshiner/first-principles-plan.git"
INSTALL_DIR="${HOME}/.agents/skills/first-principles-plan"

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

# ── Detect which platform is running ─────────────────────────
detect_platform() {
  # No auto-detection for now — each platform links differently.
  # The caller explicitly passes --codex or --opencode.
  echo "agents"
}

# ── Install / update core skill ──────────────────────────────
echo "📦 Installing First Principles Plan..."

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

# ── Platform: Claude Code ────────────────────────────────────
# Auto-discovered via ~/.agents/skills/ scanning. No extra setup needed.
echo "   • Claude Code: auto-discovered (via ~/.agents/skills/)"

# ── Platform: Codex CLI ──────────────────────────────────────
if [ "$INSTALL_CODEX" = true ]; then
  CODEX_DIR="${HOME}/.codex/skills/first-principles-plan"
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
  OPENCODE_DIR="${HOME}/.opencode/skills/first-principles-plan"
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
echo "   • SKILL.md  —  Core methodology (auto-loaded by agents scanning ~/.agents/skills/)"
echo "   • commands/fpp.md  —  /fpp slash command (Claude Code, via adapters/claude/)"

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