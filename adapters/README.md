# Platform Adapters / 平台适配器

Each subdirectory provides the platform-specific entry point for the core `SKILL.md` methodology.
每个子目录为 `SKILL.md` 核心方法论提供平台特定的入口。

| Directory | Platform | Format | Install flag |
|-----------|----------|--------|-------------|
| `claude/` | Claude Code | `.claude-plugin/plugin.json` + `commands/fpt.md` | auto-discovered / 自动发现 |
| `codex/` | Codex CLI | `.agent.md` | `--codex` |
| `opencode/` | OpenCode | `.rule.md` | `--opencode` |

All adapters delegate to `../SKILL.md` as the single source of truth for the methodology.
所有适配器均委托 `../SKILL.md` 作为方法论的唯一权威来源。