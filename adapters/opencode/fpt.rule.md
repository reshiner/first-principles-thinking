---
# OpenCode rules format
# Fields: name (required), description (required)
name: first-principles-thinking
description: "Forces first-principles thinking for code changes — critically evaluate existing design, design the ideal solution, then reconcile. / 第一性原理思考 — 批判性评估现有设计，设计理想方案，做出权衡推荐。"
---

# First Principles Thinking

> **OpenCode adapter** — This file provides the entry point for OpenCode (`~/.opencode/skills/first-principles-thinking/`).
> It delegates to the canonical methodology at `~/.agents/skills/first-principles-thinking/SKILL.md`.
> Format: `.rule.md` with YAML frontmatter (name, description).

Load and follow the full instructions from `~/.agents/skills/first-principles-thinking/SKILL.md`.

This adapter is installed via: `bash install.sh --opencode`

This rule implements a structured three-phase process for code modification planning:

## Phase 1: Decompose
1. **Surface Intent** — What is the user's fundamental goal? Strip away implementation specifics.
2. **Decompose Existing Code** — Map entities, data flow, control flow, boundaries.
3. **Diagnose Design Debt** — Evaluate coupling, cohesion, abstraction boundaries, hidden assumptions, extension cost, duplication.

## Phase 2: Design
1. **Clean-Sheet Design** — Ignore existing code. Design the ideal solution from fundamentals. Name interfaces, entities, relationships.
2. **Document the Gap** — Table comparing Current vs Ideal vs Delta.

## Phase 3: Reconcile
1. **Path A (Minimal Modification)** — Smallest change that works. Document debt accumulated.
2. **Path B (First-Principles Refactor)** — Move toward ideal design. Document risk and migration cost.
3. **Compare and Recommend** — Use 4 heuristics: touch frequency, provably wrong vs suboptimal, Strangler Fig decomposability, compounding debt.

Output a structured document: Intent, Current Design Critique, Assumptions Challenged, Clean-Sheet Design, Gap Analysis, Path Comparison, Recommendation.

## Trigger Conditions
- User asks to modify existing code (not trivial one-line changes)
- Phrases like "第一性原理", "从根本分析", "从零开始思考"
- Phrases like "challenge assumptions", "question this design"
- Non-trivial code modification requests
- Request implies a structural mismatch

## Core Principle
Do NOT always recommend refactoring. Make the tradeoff explicit between patching and redesigning. The goal is conscious decision-making, not maximum change.