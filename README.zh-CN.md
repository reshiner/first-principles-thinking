# 第一性原理思考（First Principles Thinking）

[English](README.md) | **中文**

一个跨平台的 AI 编程技能，用于打破 LLM 辅助开发中的"最小改动"偏见。
**支持平台：** Claude Code · Codex CLI · OpenCode

当 AI 代理修改现有代码时，它们天然倾向于产生最小的 diff——这导致复杂度累积、抽象层补丁叠加、设计债务不断增长。这个技能通过结构化的流程强制你做出有意识的决策：

1. **分解** — 理解用户的真实意图，批判性地评估现有代码的设计债务
2. **设计** — 从第一性原理出发设计理想方案，不考虑现有代码
3. **调和** — 比较最小改动路径与理想设计，给出有理有据的推荐

技能**并不总是推荐重构**。它的价值在于让权衡**显式化**——让你清楚地知道自己正在接受什么。

## 特性

- **`/fpt` 斜杠命令**（Claude Code）或其它平台的等效触发方式
- **自动触发** — 在 "第一性原理"、"challenge assumptions"、"从根本分析" 等短语以及重要的代码修改请求时自动激活
- **结构化输出** — 生成 `First Principles Analysis` 文档，包含意图分析、设计批判、理想方案、路径比较和推荐结论
- **决策框架** — 4 条启发式规则（触碰频率、是否明显错误、Strangler Fig 模式、债务复利效应）指导推荐结论

## 安装

### Claude Code（推荐）

有两种方式：

**方式 A：Marketplace 安装（最简单，Claude Code v2.24+）**

在 Claude Code 中执行以下命令：

```
/plugin marketplace add https://github.com/reshiner/first-principles-thinking
/plugin install first-principles-thinking@reshiner
```

这会注册 `reshiner` 市场源并安装插件 — Claude Code 自动发现 `/fpt` 斜杠命令和自动触发技能。

**方式 B：安装脚本（所有 Claude Code 版本）**

```bash
curl -fsSL https://raw.githubusercontent.com/reshiner/first-principles-thinking/main/install.sh | bash
```

或手动克隆和运行：

```bash
git clone https://github.com/reshiner/first-principles-thinking.git
./first-principles-thinking/install.sh
```

安装脚本会在 `~/.claude/plugins/cache/reshiner/first-principles-thinking/1.0.0/` 创建插件缓存结构，并注册 `/fpt` 斜杠命令。

### Codex CLI

```bash
curl -fsSL https://raw.githubusercontent.com/reshiner/first-principles-thinking/main/install.sh | bash -s -- --codex
```

在 `~/.codex/skills/first-principles-thinking/` 创建指向 `adapters/codex/` 的符号链接。

### OpenCode

```bash
curl -fsSL https://raw.githubusercontent.com/reshiner/first-principles-thinking/main/install.sh | bash -s -- --opencode
```

在 `~/.opencode/skills/first-principles-thinking/` 创建指向 `adapters/opencode/` 的符号链接。

### 一键安装全部

```bash
curl -fsSL https://raw.githubusercontent.com/reshiner/first-principles-thinking/main/install.sh | bash -s -- --all
```

## 使用方式

### 触发分析

```
# 手动触发（Claude Code）：
/fpt 我们需要给通知系统添加 Webhook 支持

# 或通过自然语言触发（任何平台）：
用第一性原理分析一下这个现有的设计
Think from first principles about adding this feature
challenge assumptions in this codebase
```

技能将生成：

```markdown
# First Principles Analysis: <功能名称>

## 1. Intent（意图）
## 2. Current Design Critique（现有设计批判）
## 2b. Assumptions Challenged（被挑战的假设）
## 3. Clean-Sheet Design（理想方案设计）
## 4. Gap Analysis（差距分析）
## 5. Path Comparison（路径比较：A 最小修改 vs B 重构）
## 6. Recommendation（推荐结论）
```

输出文档的标题会随用户语言自动切换为中/英文。

### 保存分析文档到本地文件

分析输出到对话后，工具会提示你保存为本地文件。只需说：

```
输出文档     # 或 "保存文档"、"导出"、"保存"
```

文档将被保存到项目目录下的 `doc/fpt/<日期>-<主题概括>.md`。例如：

```
doc/fpt/20260603-用户认证模块分析.md
```

## 目录结构

```
~/.agents/skills/first-principles-thinking/     # 技能目录
├── SKILL.md                                 # 核心方法论（平台无关）
├── CLAUDE.md                                # AI 代理项目指令
├── adapters/                                # 平台特定入口
│   ├── README.md                            # 适配器概览
│   ├── claude/
│   │   ├── .claude-plugin/plugin.json       # Claude Code 插件清单
│   │   └── commands/fpt.md                  # /fpt 斜杠命令
│   ├── codex/                               # Codex CLI 代理定义
│   │   └── fpt.agent.md
│   └── opencode/                            # OpenCode 规则
│       └── fpt.rule.md
├── examples/                                # FPT 分析示例文档
│   ├── notification-system-fpt.md           # 示例（中文）：通知系统添加 Webhook
│   └── payment-checkout-fpt.md              # 示例（English）：支付系统添加 Buy Now
├── doc/fpt/                                 # 保存的 FPT 分析文档
├── commands -> adapters/claude/commands     # 向后兼容符号链接
├── .claude-plugin -> adapters/claude/.claude-plugin
├── README.md                                # 项目介绍（英文）
├── README.zh-CN.md                          # 项目介绍（中文）
├── LICENSE                                  # MIT 许可证
├── TODO.md                                  # 开发待办列表
└── install.sh                               # 安装脚本
```

## 示例

包含两份完整的 FPT 分析文档，展示技能的实际应用：

| 示例 | 语言 | 场景 | 关键要点 |
|------|------|------|----------|
| [通知系统 — Webhook 支持](examples/notification-system-fpt.md) | 中文 | 为基于 if-elif 的通知系统添加新渠道 | 展示 FPT 如何在添加第 N+1 个分支前发现设计债务；推荐 **Hybrid 方案**（Strangler Fig 渐进重构） |
| [支付系统 — Buy Now](examples/payment-checkout-fpt.md) | English | 为多步骤结账流程添加一键购买 | 展示 FPT **推荐最小修补**的场景——因为债务尚未积累到需要重构的程度。包含一个"重构触发器"文档 |

每个示例都完整遍历 FPT 输出格式的六个章节。代码片段仅为示意，非真实项目代码。

## 设计哲学

这个技能解决的是 AI 辅助开发中的特定问题：**LLM 天然倾向于最小改动路径**。训练数据（大多数 commit 是小改动）、系统提示（"外科手术式修改"）以及风险规避倾向共同导致了对修补而非修复的偏向。结果是代码质量通过累积不断衰减。

这个技能并没有推翻"外科手术式修改"原则——它增加了一道决策门：*在* 你决定做最小修改之前，必须显式考虑当前设计是否正确。如果是，最小修改就是正确答案。如果不是，你应当知道这个事实并做出有意识的选择。

## 许可证

MIT