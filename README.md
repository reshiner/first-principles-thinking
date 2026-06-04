# First Principles Thinking

**English** | [中文](README.zh-CN.md)

A multi-platform AI coding skill that breaks the "minimal change" bias in LLM-assisted development.  
**Works with:** Claude Code · Codex CLI · OpenCode

When AI agents modify existing code, they default to producing the smallest possible diff — which leads to accreted complexity, patched-over abstractions, and design debt. This skill forces a structured process:

1. **Decompose** — understand the user's true intent, critically evaluate existing code for design debt
2. **Design** — imagine the ideal solution from first principles, ignoring existing code
3. **Reconcile** — compare the minimal-change path vs. the ideal design, and make a reasoned recommendation

The skill does **not** always recommend refactoring. It makes the tradeoff **explicit** so you know what you're accepting.

## Features

- **`/fpt` slash command** (Claude Code) or equivalent trigger on other platforms
- **Automatic trigger** — activates on phrases like "第一性原理", "challenge assumptions", "从根本分析", and non-trivial code modification requests
- **Structured output** — produces a `First Principles Analysis` document with intent, critique, clean-sheet design, path comparison, and recommendation
- **Decision framework** — 4 heuristics (touch frequency, provably wrong, Strangler Fig, compounding debt) to guide the recommendation

## Installation

### Core (all platforms)

```bash
curl -fsSL https://raw.githubusercontent.com/reshiner/first-principles-thinking/main/install.sh | bash
```

Or clone manually:

```bash
git clone https://github.com/reshiner/first-principles-thinking.git ~/.agents/skills/first-principles-thinking
```

### Platform-specific setup

After installing the core, set up your specific platform:

**Claude Code:** Auto-discovered — no extra steps needed. The skill is loaded from `~/.agents/skills/` automatically. `/fpt` slash command is available via `adapters/claude/commands/fpt.md`.

**Codex CLI:**
```bash
curl -fsSL https://raw.githubusercontent.com/reshiner/first-principles-thinking/main/install.sh | bash -s -- --codex
```
This creates a symlink at `~/.codex/skills/first-principles-thinking/` pointing to `adapters/codex/`.

**OpenCode:**
```bash
curl -fsSL https://raw.githubusercontent.com/reshiner/first-principles-thinking/main/install.sh | bash -s -- --opencode
```
This creates a symlink at `~/.opencode/skills/first-principles-thinking/` pointing to `adapters/opencode/`.

**All at once:**
```bash
curl -fsSL https://raw.githubusercontent.com/reshiner/first-principles-thinking/main/install.sh | bash -s -- --all
```

## Usage

### Triggering an analysis

```
# Manual trigger (Claude Code):
/fpt We need to add webhook support to the notification system

# Or trigger via natural language (any platform):
用第一性原理分析一下这个现有的设计
Think from first principles about adding this feature
challenge assumptions in this codebase
```

The skill produces:

```markdown
# First Principles Analysis: <Feature Name>

## 1. Intent
## 2. Current Design Critique
## 2b. Assumptions Challenged
## 3. Clean-Sheet Design
## 4. Gap Analysis
## 5. Path Comparison (A: Minimal Modification vs B: Refactor)
## 6. Recommendation
```

### Saving the analysis to a file

After the analysis is presented, the agent will prompt you to save it as a local file. Simply say:

```
输出文档     # (Chinese — "output document")
save         # (English)
```

The document is saved to `doc/fpt/<date>-<topic>.md` in your project directory. Example:

```
doc/fpt/20260603-authentication-module-analysis.md
```

## Structure

```
~/.agents/skills/first-principles-thinking/     # Skill directory
├── SKILL.md                                 # Core methodology (platform-agnostic)
├── CLAUDE.md                                # Project instructions for AI agents
├── adapters/                                # Platform-specific entry points
│   ├── README.md                            # Adapter overview
│   ├── claude/
│   │   ├── .claude-plugin/plugin.json       # Claude Code plugin manifest
│   │   └── commands/fpt.md                  # /fpt slash command
│   ├── codex/                               # Codex CLI agent definition
│   │   └── fpt.agent.md
│   └── opencode/                            # OpenCode rules
│       └── fpt.rule.md
├── examples/                                # FPT analysis example documents
│   ├── notification-system-fpt.md
│   └── payment-checkout-fpt.md
├── doc/fpt/                                 # Saved FPT analysis documents
├── commands -> adapters/claude/commands     # Backward-compat symlink
├── .claude-plugin -> adapters/claude/.claude-plugin
├── README.md                                # This file (English)
├── README.zh-CN.md                          # Introduction (中文)
├── LICENSE                                  # MIT License
├── TODO.md                                  # Development todo list
└── install.sh                               # Install script
```

## Examples

Real-world FPT analysis documents demonstrating the skill in action:

| Example | Language | Scenario | Key Takeaway |
|---------|----------|----------|--------------|
| [Notification System — Webhook Support](examples/notification-system-fpt.md) | 中文 | Adding a new notification channel to an `if-elif` based sender | Shows how FPT catches design debt before adding the N+1th branch; recommends **Hybrid** (Strangler Fig for safe incremental refactor) |
| [Payment Checkout — Buy Now](examples/payment-checkout-fpt.md) | English | Adding one-click purchase to a multi-step checkout flow | Shows when FPT **recommends the minimal patch** — because the debt hasn't compounded enough yet. Includes a documented refactoring trigger for when it should be revisited |

Each example walks through all six sections of the FPT output format. They are self-contained demonstrations — the code snippets are illustrative, not from real repositories.

## Design Philosophy

This skill addresses a specific problem in AI-assisted development: **LLMs naturally default to minimal-change paths**. Training data (most commits are small), system prompts ("surgical changes"), and risk-aversion all bias toward patching rather than fixing. The result is code quality decay through accretion.

The skill doesn't override the "surgical changes" principle — it adds a decision gate: *before* you decide to make a minimal change, you must explicitly consider whether the design itself is correct. If it is, the minimal change is the right answer. If it isn't, you should know that and make a conscious tradeoff.

## License

MIT