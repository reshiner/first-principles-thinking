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
