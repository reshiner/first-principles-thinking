# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

A multi-platform AI coding **skill** that forces first-principles thinking before code changes. It breaks the default "minimal diff" bias in LLM-assisted development by requiring structured analysis: decompose the existing design, design the ideal solution from fundamentals, then make an explicit tradeoff recommendation.

Works with Claude Code, Codex CLI, and OpenCode.

## High-Level Architecture

```
~/.agents/skills/first-principles-thinking/
├── SKILL.md                    # Core methodology (single source of truth)
├── adapters/                   # Platform-specific entry points
│   ├── claude/                 #   Claude Code: plugin.json + commands/fpt.md
│   ├── codex/                  #   Codex CLI: fpt.agent.md
│   └── opencode/               #   OpenCode: fpt.rule.md
├── install.sh                  # Install/update script
├── examples/                   # Real FPT analysis documents (for reference/demo)
└── doc/fpt/                    # Output directory for saved analysis documents
```

**SKILL.md** is the canonical methodology (~450 lines). All adapters delegate to it via a `Load and follow` instruction. Platform adapters are thin wrappers that supply YAML frontmatter for discovery and point back to SKILL.md.

**Adapters** are the only platform-specific code. Each subdirectory contains an entry point file and a README. The `install.sh` script clones the repo and optionally symlinks adapters into platform skill directories:
- Claude Code: auto-discovered from `~/.agents/skills/`
- Codex CLI: `install.sh --codex` → symlink to `~/.codex/skills/`
- OpenCode: `install.sh --opencode` → symlink to `~/.opencode/skills/`

## Core Methodology (SKILL.md)

The skill defines three required phases:

1. **Decompose** — Surface user intent, map existing code (entities, data/control flow, boundaries), diagnose design debt (coupling, cohesion, hidden assumptions)
2. **Design** — Clean-sheet design from first principles ignoring existing code; document the gap between current and ideal
3. **Reconcile** — Compare Path A (minimal patch) vs Path B (refactor) using a 4-heuristic decision framework (touch frequency, provably wrong, Strangler Fig, compounding debt); recommend one with rationale

Plus Phase 4 (iterative refinement): post-analysis revision via conversation protocol with versioning (v1.0 → v1.1 → ...).

Output format is a structured Markdown document with 6 sections (Intent, Current Design Critique, Assumptions Challenged, Clean-Sheet Design, Gap Analysis, Path Comparison, Recommendation). Language matches the user's input language (i18n via template localization).

## Document Persistence

Analysis documents are saved to `doc/fpt/yyyymmdd-<topic>.md` on user request ("output document" / "保存"). The memory directory at `memory/` stores cross-session context (adapter architecture, output path conventions, iterative refinement behavior).

## Common Commands

| Purpose | Command |
|---------|---------|
| Install/update core skill | `curl -fsSL https://raw.githubusercontent.com/reshiner/first-principles-thinking/main/install.sh \| bash` |
| Install with Codex CLI support | `bash install.sh --codex` |
| Install with OpenCode support | `bash install.sh --opencode` |
| Install all platforms | `bash install.sh --all` |
| See install help | `bash install.sh --help` |

There are no build, test, or lint commands — this is a content/configuration repository.

## Key Design Decisions

- **SKILL.md is the single source of truth** — adapters are thin; all methodology lives in one file
- **Platform adapters delegate by reference** — they say "load and follow SKILL.md" rather than duplicating content
- **Bidirectional language support** — English and Chinese templates in SKILL.md; output language matches user input
- **Phase 4 is conversation-driven** — no external state; the version counter and refinement mode are maintained via chat protocol
- **No runtime code** — the skill is 100% markdown configuration files; there is no code to compile, test, or lint