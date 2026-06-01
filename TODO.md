# TODO

## 📋 迁移后待办事项

### 1. 验证 Codex CLI 适配器格式
- [x] 检查 Codex CLI 的 `.agent.md` frontmatter 规范（运行 `codex --list-agents` 或查阅文档）
- [x] 确认 `adapters/codex/fpp.agent.md` 的 frontmatter 字段正确（name、description 等）
- [x] 确认 `~/.codex/skills/` 是 Codex CLI 的正确发现路径
- [x] 测试：运行 `bash install.sh --codex`，验证 Codex CLI 能加载该 skill

### 2. 验证 OpenCode 适配器格式
- [x] 查阅 OpenCode 的 `.opencode/rules/` 文档，确认 `.rule.md` 格式兼容
- [x] 确认 `adapters/opencode/fpp.rule.md` 的 frontmatter 字段正确
- [x] 确认 `~/.opencode/skills/` 是 OpenCode 的正确发现路径
- [x] 测试：运行 `bash install.sh --opencode`，验证 OpenCode 能加载该规则

### 3. 测试向后兼容性
- [x] 确认 Claude Code 仍能自动发现 `~/.agents/skills/first-principles-plan/` 下的 SKILL.md
- [x] 确认 `/fpp` 斜杠命令仍能正常触发（通过 `commands` 符号链接）
- [x] 确认 `.claude-plugin/plugin.json` 仍能被 Claude Code 识别（通过 `.claude-plugin` 符号链接）

### 4. 完善文档
- [ ] README.md 中的平台安装说明是否足够清晰？
- [ ] 是否需要为 `adapters/codex/` 和 `adapters/opencode/` 添加内嵌的格式说明注释？
- [ ] 考虑为适配器目录添加 `README.md` 说明文件

### 5. 功能性检查
- [x] 运行 `bash install.sh --all`，测试安装完整流程
- [x] 确认 `git clone` 到新目录后，符号链接依然有效（符号链接在 git 中是相对路径）
- [x] 确认 SKILL.md 的简化 frontmatter 不影响 Claude Code 的自动触发