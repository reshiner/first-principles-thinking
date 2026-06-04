# Claude Code Adapter / Claude Code 适配器

Entry point for Claude Code's skill discovery system.
Claude Code 技能发现系统的入口。

## Files / 文件

- `.claude-plugin/plugin.json` — Plugin manifest (name, description, author) / 插件清单
- `commands/fpt.md` — `/fpt` slash command definition / 斜杠命令定义

## Discovery / 发现机制

Claude Code discovers this skill automatically via `~/.agents/skills/` scanning.
Claude Code 通过扫描 `~/.agents/skills/` 自动发现此技能。

Root-level symlinks (`commands` → `adapters/claude/commands`, `.claude-plugin` → `adapters/claude/.claude-plugin`) ensure backward compatibility for existing installations.
根目录的符号链接（见上）确保已安装用户的向后兼容性。