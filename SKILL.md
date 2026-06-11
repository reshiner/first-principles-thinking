---
name: first-principles-thinking
description: "Use when the user requests first-principles analysis — challenging design assumptions, questioning a spec/plan, or reasoning from fundamentals. Triggers on phrases like '第一性原理', '从根本分析', '这个设计合理吗', 'challenge assumptions', 'question this design'. In Review Gate mode, activates when a source_document (spec/plan/brainstorming output) is provided as input. For standalone code changes, only triggers when the change touches core architecture/interfaces or the user explicitly asks for structural critique — NOT for routine feature additions, bug fixes, or straightforward extensions."
---

# First Principles Thinking

## Why This Skill Exists

When an AI agent modifies existing code, it has a built-in bias: produce the smallest possible diff. This bias comes from training data (most commits are small), from system prompts ("surgical changes"), and from fear of breaking things. The result? Code quality decays through accretion:

- New features get bolted onto bad abstractions instead of fixing them
- "Just one more parameter" turns clean functions into flag-spaghetti
- Existing design issues propagate into new code because the agent copies surrounding patterns
- Each diff is "correct" in isolation; the trajectory as a whole is bad

This skill exists to break that pattern. It forces you to **step back, think from fundamentals, and make an explicit choice** between the minimal-change path and the correct-design path — rather than defaulting to the former.

You are **not** required to always pick the refactor path. Sometimes the minimal change IS the right call (one-off feature, prototype, throwaway code). The point is to **know you're making that tradeoff**, not to stumble into it.

## When to Use (and Not Use)

| Use When | Don't Use When |
|----------|----------------|
| User explicitly asks for structural critique / assumption challenge | Trivial one-line changes |
| User says "从根本分析" / "这个设计合理吗" / "challenge assumptions" | Pure bug fixes with obvious root cause |
| Source document (spec/plan/brainstorming output) needs first-principles review | Greenfield / new file creation (no existing design to challenge) |
| Change touches core architecture/interfaces and user wants design review | User explicitly asks for "the quickest fix" |
| You feel the "this doesn't fit" tension about an existing design | Standard superpowers workflow without explicit design-challenge request |

**Mode selection rule:**
- If a source_document (spec/plan/brainstorming output) is provided as input → **Review Gate 模式**
- If the user references project code directly → **Standalone 模式**
- If both are present → **Standalone 模式**（分析项目代码，输出可被引用为 review 意见）

**If unsure, ask the user which mode they intend.**

## Language Matching

**Output language MUST match the user's input language.** If the user asks in Chinese, output the entire analysis in Chinese — including section headers, table column names, and all narrative text. If the user asks in English, output in English. This applies to all three phases and the final structured document.

(The template below is shown in English; localize its section headers and content when the user's language is not English.)

---

## 调用模式（Invocation Modes）

FPT 有两种调用模式，行为完全不同：

### 模式 A：Standalone（独立分析）
- **场景：** 用户直接说"从根本分析XX"、"这个设计合理吗"
- **输入：** 项目代码
- **输出：** 完整的 FPT 三阶段分析文档，可保存到 `docs/fpt/` 或作为下游流程的输入
- **典型使用路径：** `FPT(Standalone) → 输出docs/fpt/ → brainstorming → writing-plans → ...`

### 模式 B：Review Gate（审核关卡）
- **场景：** 在 superpowers 的 brainstorming / writing-plans / subagent-driven-development 输出草案后，作为 review 环节被触发
- **输入：** 源文档（spec/plan/brainstorming 产出物的内容），**不是项目代码**
- **输出：** 结构化 review 意见，包含对源文档各章节的假设挑战和修订建议，**不产生独立文件**
- **目标：** FPT 的输出成为修订 spec/plan 的依据，而非替代物
- **典型使用路径：** `brainstorming → FPT(Review Gate) → 修订plan → 实现`
- **触发判断：** 如果上游流程显式提供了 `source_document` 作为输入，或用户说"审查这个方案/这个设计"

### 模式识别

| 信号 | 模式 |
|------|------|
| 用户说"从根本分析XX" | Standalone |
| 用户说"审查这个方案" | Review Gate |
| 调用了 FPT 时上下文中有前一技能的产出文档 | Review Gate |
| 用户同时说了分析对象 + 希望输出独立文档 | Standalone |
| 不确定 | 询问用户 "你希望我分析项目代码（Standalone）还是审查刚才的方案草案（Review Gate）？" |

---

## The Three Phases

You MUST follow these phases **in order**. Do not skip Phase 2 (Clean-Sheet Design) — that's where the value comes from.

**各阶段的具体行为根据调用模式有所不同。** 下面以 Standalone 模式为主描述，并在各阶段中注明 Review Gate 模式的调整。

---

### Phase 1: Decompose

**Goal:** Understand what's really being asked and what the current situation actually is.

> **Review Gate 模式下的调整：** 分析对象不是项目代码，而是源文档（spec/plan/brainstorming 草案）。"Decompose the Existing Code" 改为 "Decompose the Source Document"。

#### Step 1: Surface Intent

Read the user's request and strip away implementation specifics. Ask yourself:

- What's the fundamental user-facing goal? (Not "add a filter dropdown" but "let users narrow results by category")
- What constraints are real (performance, security, deployment) vs. assumed (framework choice, file structure)?
- If I were building this from scratch with no existing code, how would I think about this feature?

Write down the intent in one sentence. If you can't, ask the user to clarify.

#### Step 2: Decompose

**Standalone 模式 — Decompose the Existing Code**

Read the relevant files and map out what actually exists (not what you assume exists):

- **Entities:** What classes/types/models are involved? What are their actual responsibilities?
- **Data flow:** How does data move through the system? What transformations happen?
- **Control flow:** What's the sequence of operations? Are there implicit state machines or branch trees?
- **Boundaries:** Where does this module end and the next begin? What are the public interfaces?

**Review Gate 模式 — Decompose the Source Document**

Read the source document and extract its claims and decisions:

- **Claims:** What design decisions does the document make? What assumptions underlie each decision?
- **Silent assumptions:** What does the document assume without stating? (e.g., "must reuse existing table X", "framework choice is fixed")
- **Code influence:** Which parts of the document seem influenced by existing project code rather than derived from requirements? Mark these as "code-influenced" — they're likely candidates for challenge.
- **Gaps:** What does the document not address that it should? (edge cases, failure modes, extension scenarios)

#### Step 3: Diagnose Design Debt / Assumptions

**Standalone 模式 — Diagnose Design Debt**

Evaluate the existing code against these criteria. Be specific — name the files and lines:

- **Coupling:** Does one module know too much about another's internals? Does changing A require changing B?
- **Cohesion:** Are related behaviors scattered across different files? Are unrelated behaviors lumped together?
- **Abstraction boundary violations:** Does a high-level module reach into low-level details? (e.g., UI code constructing SQL queries, business logic importing framework internals)
- **Hidden assumptions:** What does the code assume about its environment (order of operations, data shape, timing)? Would the requested feature break those assumptions?
- **Extension cost:** How many touch points does a new feature require? One well-placed hook, or a chain of edits across files?
- **Duplication by convention:** Is the same logic repeated because there's no shared abstraction? (e.g., similar validation in 5 handlers, similar rendering code in 3 components)

**Enumerate Issues:** Assign a unique ID to each design debt finding (e.g., D-01, D-02, ...). These IDs will be used to track resolution in the Clean-Sheet Design and Path Comparison phases.

Beyond design debt, surface the assumptions behind the decisions. Categorize them:

| Category | Question to Ask |
|----------|-----------------|
| **Technical** | "Must we use this technology/pattern? Was it chosen for this problem or inherited?" |
| **Business** | "Is this requirement actually fixed, or was it assumed at some point?" |
| **Historical** | "Why was this code written this way originally? Do those conditions still hold?" |
| **Cultural** | "Are we following a pattern because it fits, or because 'everyone does it this way'?" |

**Red flags for likely-false assumptions:** Watch for phrases in the codebase or your own reasoning like "We've always done it this way", "Industry standard says X", "Everyone uses Y for this", "That's too simple to work". When you see these, you've found an assumption to challenge.

**Review Gate 模式 — Extract and Tag Assumptions**

Analyze the source document's assumptions:

| 维度 | 分析要点 |
|------|---------|
| **技术假设** | 文档是否默认使用某种技术栈/框架？这个选择有论证吗？ |
| **业务假设** | 文档对需求的界定是否完整？有无遗漏场景？ |
| **代码影响** | 文档的决策是否明显受到了现有项目代码的约束？标记为 "code-bound" |
| **遗漏场景** | 文档没有覆盖的边界情况、失败模式、扩展路径 |

**Tag each assumption** with a unique ID (A-01, A-02, ...) and classify as:
- **challenge-worthy** — 值得挑战的假设，有更好方案的可能
- **accepted** — 合理的假设，但应明确记录
- **risky** — 风险较高，需要进一步论证

#### Step 4: Output Phase 1

**Standalone 模式** — Write the "Current Design Critique" section of your analysis. Keep it factual — not "this code is bad" but "this code assumes X, which breaks when Y happens."

**Review Gate 模式** — Write the "源文档审查（Source Document Review）" section, organized as:

```markdown
## 源文档审查

### 提取的主张/决策
| # | 文档章节 | 决策/主张 | 依据 | 标记 |
|---|---------|----------|------|------|
| A-01 | 第2节 | 使用现有数据表 | 为了复用 | code-bound |
| A-02 | 第3节 | 限制仓位数 | 风控要求 | accepted |

### 值得挑战的假设
- **[A-01] 使用现有数据表** — 现有表是为不同场景设计的，复用可能导致字段意义混淆。建议：根据新需求设计新表，不做强制复用。

### Code-bound 决策预警
以下决策明显受现有代码影响，建议重新审视：
- ...
```

---

### Phase 2: Design

**Goal:** Design the ideal solution from first principles, ignoring what already exists.

> **Review Gate 模式下的调整：** 不是设计"更好的项目代码"，而是设计"更好的 spec/plan"。分析对象是源文档的需求描述，忽略"现有代码"和"源文档的现有结构"。

#### Step 1: Clean-Sheet Design

**Standalone 模式** — Given only the user's intent from Phase 1, design the minimal solution that satisfies it. Answer:

- What entities/interfaces would exist in the ideal world?
- What data flows between them?
- What are the public boundaries?
- How would the feature be extended next time?

**This is the hardest step to do honestly.** Your instinct will be to describe the existing code with minor tweaks. Fight that instinct. If the current code uses a god class with 5 responsibilities, don't just say "we could split it" — actually design the split. Name the new classes, their interfaces, their relationships.

If the clean-sheet design turns out to look like the existing code, that's fine — name that explicitly: "The current design matches the ideal. No structural change needed."

**Ground truth verification:** For each entity/interface in your clean-sheet design, ask:
- Can this be further decomposed? (If yes, it may not be a fundamental building block)
- Is this provably necessary for the user's intent, or is it a preference?
- Would the solution fail if this component were removed? (Complexity Check — if removing it doesn't break core functionality, it wasn't essential)

**Issue Coverage Verification:** After completing your clean-sheet design, return to the design debt list from Phase 1. For each issue (D-01, D-02, ...), verify that the ideal design resolves it. If an issue is not resolved, either the design is incomplete (go back and fix) or the issue is an accepted constraint — document which and why.

**Warning — The Over-Engineering Trap:** First principles thinking can lead you to design a "better database" when SQLite is fine. Test your design against this: "Does building custom save more time than using what exists?" If the existing solution is within 2x of optimal and the team knows it, use it. First principles reveals when existing solutions are **10x wrong**, not when they're mildly suboptimal.

**Phase 2 is NOT optional.** If you skip or abbreviate it, the entire skill fails. The rest of the skill depends on having a concrete alternative to compare against.

**Review Gate 模式 — Clean-Sheet Design for the Document**

Not designing for the project code, but for the document's **stated requirements**:

- 如果完全不受现有项目代码影响，源文档描述的需求应该如何设计？
- 源文档中"code-bound"的决策在理想方案下会是怎样的？
- 源文档是否错过了更好的方案？为什么？
- 输出格式：**文档修订建议**，逐节对应

输出示例：

```markdown
## 理想方案设计（对照源文档）

### 第2节（数据存储方案）
- **源文档主张：** 复用现有表结构，扩展字段
- **理想方案：** 新建独立表，避免字段意义混淆
- **差距分析：** 源文档选择了 "最小改动" 而非 "正确做法"
- **修订建议：** 改为新建表，详见第2.1节

### 第3节（仓位管理）
- **源文档主张：** 单向建仓，不支持双向
- **理想方案：** 支持双向（长短各方向独立管理），考虑对冲场景
- ...
```

#### Step 2: Document the Gap

**Standalone 模式** — Contrast the clean-sheet design with the current architecture. This is the gap analysis:

| Aspect | Current | Ideal | Delta |
|--------|---------|-------|-------|
| Entity A responsibility | Does X and Y | Only X | Y should be in Entity B |
| Data flow | Passes raw dicts | Typed interfaces | Add schema validation |
| Extension model | Add another `if` branch | Strategy pattern | Replace switch with registry |

**Review Gate 模式** — 对比理想方案与源文档当前版本：

| 源文档章节 | 当前主张 | 理想方案 | 差距 |
|-----------|---------|---------|------|
| 第2节 | 复用现有表 | 新建独立表 | 强耦合，不利于扩展 |
| 第3节 | 单向建仓 | 支持双向 | 限制了交易策略 |

#### Step 3: Output Phase 2

Write the "Clean-Sheet Design" and "Gap Analysis" sections. For Review Gate mode, use the adapted formats above.

---

### Phase 3: Reconcile

**Goal:** Compare the two paths and make a recommendation.

> **Review Gate 模式下的调整：** Path A = 接受源文档当前版本 + 小修补；Path B = 按理想方案修订源文档。推荐结果是一个**修订版本的 spec/plan**。

#### Step 1: Define Path A — Minimal Modification

**Standalone 模式** — The smallest set of changes that make the user's request work within the existing structure. Be honest about what this costs:

- Workaround code you'd need to write
- Design debt this accumulates
- How future features will be harder

**Review Gate 模式** — 接受源文档当前方案，仅做最小修订：

- 哪些假设可以保留不做改动？
- 仅对影响较大的假设做最小幅度的修正
- 代价：仍受现有代码思维约束的方向将继续保持

#### Step 2: Define Path B — First-Principles Refactor

**Standalone 模式** — The set of changes that moves toward the clean-sheet design. Be honest about the cost:

- Files to modify/create/delete
- Migration effort (data, callers, tests)
- Risk (what could break during the transition)
- Decomposability (can this be done in safe, reviewable steps?)

**Review Gate 模式** — 按理想方案修订源文档：

- 源文档需要修改哪些章节
- 修订后的文档与现有项目代码的兼容性考量
- 过渡成本（是先在文档层面修正，再慢慢改代码；还是等代码调整后再更新文档？）

#### Step 3: Compare and Recommend

**Standalone 模式** — Evaluate the two paths using these heuristics:

| Heuristic | Path A (Patch) | Path B (Refactor) |
|-----------|-------|--------|
| Diff size (lines changed) | | |
| Risk of breakage | | |
| Design debt left behind | | |
| Future extension cost | | |
| Can be done incrementally? | | |

**Issue Resolution Traceability:** Before making your recommendation, review each design debt issue from Phase 1 and mark whether it is addressed. Add this table to your analysis:

| Issue | Description | Addressed by Path A? | Addressed by Path B? |
|-------|-------------|---------------------|---------------------|
| D-01 | High coupling between X and Y | ❌ No — workaround required | ✅ Yes — decoupled |
| D-02 | Hidden assumption Z | ✅ Yes — add validation | ✅ Yes — add validation |
| D-03 | Duplicate logic in 3 places | ❌ No — still duplicated | ✅ Yes — extracted to shared abstraction |
| ... | | | |

**Review Gate 模式** — Compare using this table:

| 维度 | Path A（接受源文档） | Path B（修订源文档） |
|------|-------------------|-------------------|
| 方案严谨性 | 保留现有假设，有但不稳健 | 从需求出发，方案更扎实 |
| 与项目代码的兼容性 | 高（尽量不动现有代码） | 低到中（可能需要改代码） |
| 对后续开发的影响 | 延续现有 debt | 消除 debt，后续开发更顺 |
| 过渡成本 | 低 | 中（需要修订文档+代码） |

**Decision framework:**

1. **Touch frequency heuristic:** Will this code be modified again? If this is a one-off feature that won't be revisited, Path A is fine. If this is a hot path or core abstraction, lean toward Path B.
2. **Provably wrong vs. merely suboptimal:** Is the current design provably wrong for the request (will it require ugly workarounds)? Or merely not the prettiest? Provably wrong → refactor. Merely suboptimal → consider deferring.
3. **Strangler Fig test:** Can Path B be decomposed into a sequence of Path A steps? (Introduce new design alongside old, migrate callers one by one, then delete old.) If yes, the incremental cost of the refactor drops dramatically.
4. **Compounding debt test:** How many more times will the user touch this code? If 3+, the refactor pays for itself.

**Your recommendation must be one of:**
- **Recommend Path A (Patch):** with rationale and acknowledgment of deferred debt
- **Recommend Path B (Refactor):** with a concrete migration plan
- **Hybrid: Path B in safe increments:** a sequence of surgical steps that collectively achieve the refactor — this is often the best answer

#### Step 4: Output Phase 3

Output the final structured document.

**Standalone 模式** — Use the full FPT document template below (same as before).

**Review Gate 模式** — Use the following output format:

```markdown
## FPT Review Feedback: <源文档名称>

### 1. 假设挑战汇总
| # | 源文档章节 | 原始假设 | 挑战 | 影响等级 | 是否 Code-bound |
|---|-----------|---------|------|---------|----------------|
| A-01 | 第2节 | 复用现有表 | 建议：新表 | Critical | ✅ |
| A-02 | 第3节 | 单向建仓 | 建议：支持双向 | Important | ❌ |

### 2. 需要关注的设计盲区
- **[Critical]** 第2节：数据存储方案 - 现有表结构不满足新需求，复用会导致...
- **[Important]** 第4节：未考虑盘前建仓场景...

### 3. 修订建议（逐节）
**第2节（数据存储方案）：**
- 当前主张：复用现有表
- 修订建议：新建独立表，字段为 ...
- 原因：现有表字段意义不兼容，复用后查询复杂且易出错

**第3节（仓位管理）：**
- 当前主张：单向建仓，不支持双向
- 修订建议：改为支持双向，长短各方向独立管理
- 原因：限制了交易策略，且实际运行中可能出现对冲需求

### 4. Code-bound 决策预警
以下决策明显受现有代码影响，建议重新审视：
- 第2节：数据表复用（明显为了不动现有表结构）
- 第5节：API 接口风格（模仿了现有接口，而非按新需求设计）

### 5. 汇总
**影响评估：** 1 个 Critical + 2 个 Important + 3 个 Minor
**建议动作：** 修订源文档后重新走 Plan → 实现
```

---

### Standalone 模式输出模板

English template (use when user input is English):
```markdown
# First Principles Analysis: <Feature Name>

## 1. Intent
<One-sentence description of the user's fundamental goal>

## 2. Current Design Critique
<Factual analysis of the existing code — coupling, cohesion, boundary issues, hidden assumptions>

## 2b. Assumptions Challenged
| Assumption | Category | Challenge | Verdict |
|------------|----------|-----------|---------|
| <e.g., "Must use existing ORM"> | Technical | <Why question it> | Keep/Discard/Modify |
| <"Users always have one role"> | Business | <Is this actually true?> | Keep/Discard/Modify |

## 3. Clean-Sheet Design
<What the ideal solution looks like, ignoring existing code. Concrete: interfaces, entities, data flows>

## 4. Gap Analysis
| Aspect | Current | Ideal | Delta |
|--------|---------|-------|-------|

## 5. Path Comparison

### Issue Resolution Traceability

| Issue | Description | Addressed by Path A? | Addressed by Path B? |
|-------|-------------|---------------------|---------------------|
| D-01 | <issue description> | ✅ / ❌ / Partial | ✅ / ❌ / Partial |
| D-02 | <issue description> | ✅ / ❌ / Partial | ✅ / ❌ / Partial |

### Path A: Minimal Modification
<What needs to change, what debt is accumulated>

### Path B: First-Principles Refactor
<What needs to change, what risk/migration cost>

## 6. Recommendation
**Recommend: Path A | Path B | Hybrid**
<Rationale grounded in the decision framework above>
<If refactoring: concrete migration steps, ideally as safe incremental commits>
```

Chinese template (use when user input is Chinese):
```markdown
# First Principles Analysis: <功能名称>

## 1. 意图（Intent）
<用户核心目标的简要描述>

## 2. 现有设计批判（Current Design Critique）
<对现有代码的事实分析 — 耦合、内聚、边界问题、隐性假设>

## 2b. 被挑战的假设（Assumptions Challenged）
| 假设 | 类别 | 挑战 | 裁定 |
|------|------|------|------|
| <例如："必须用现有 ORM"> | 技术 | <为什么质疑它> | 保留/推翻/修改 |
| <"用户只有一个角色"> | 业务 | <这是真的吗？> | 保留/推翻/修改 |

## 3. 理想方案设计（Clean-Sheet Design）
<理想方案长什么样。具体：接口、实体、数据流>

## 4. 差距分析（Gap Analysis）
| 维度 | 当前 | 理想 | 差距 |
|------|------|------|------|

## 5. 路径比较（Path Comparison）

### 问题追溯表（Issue Resolution Traceability）

| 问题编号 | 问题描述 | Path A 是否解决？ | Path B 是否解决？ |
|---------|---------|------------------|------------------|
| D-01 | <问题描述> | ✅ / ❌ / 部分 | ✅ / ❌ / 部分 |
| D-02 | <问题描述> | ✅ / ❌ / 部分 | ✅ / ❌ / 部分 |

### Path A：最小修改（Minimal Modification）
<需要改动什么，积累了什么设计债务>

### Path B：第一性原理重构（First-Principles Refactor）
<需要改动什么，风险和迁移成本>

## 6. 推荐结论（Recommendation）
**推荐：Path A | Path B | Hybrid**
<基于决策框架的推理>
<如果走重构路线：具体迁移步骤，最好是安全的增量提交>
```

For other languages, translate the English template headers accordingly.

---

## Self-Check

Before presenting the analysis, verify:

- [ ] Did I correctly identify the invocation mode (Standalone vs Review Gate)?
- [ ] Did I actually produce a clean-sheet design in Phase 2, or did I just describe the existing code/source-document with minor tweaks? (Must be the former.)
- [ ] Did I identify design debt by name (coupling, cohesion, boundary violations, hidden assumptions)?
- [ ] Did I document what Path A costs in future maintenance burden, not just diff size?
- [ ] Did I apply the decision framework (touch frequency, provably wrong, strangler fig)?
- [ ] Is my recommendation specific and actionable, not "either way works"?
- [ ] Did I consider a hybrid approach (Path B in safe increments) before defaulting to either extreme?
- [ ] Is every design debt issue from Phase 1 (D-01, D-02, ...) traced through the Clean-Sheet Design and explicitly addressed or accounted for in Path Comparison?

If any check fails, go back and fix it before presenting.

---

## 文档持久化（Document Persistence）

### Standalone 模式

在完成上述三个阶段并输出结构化文档到对话后，**等待用户指令**。当用户说以下任一短语时，将最终文档写入文件：

| 语言 | 触发短语 |
|------|----------|
| 中文 | "输出文档"、"保存文档"、"导出"、"保存" |
| 英文 | "output document"、"save document"、"export"、"save" |
| 任何语言 | 用户明确要求保存当前分析文档 |

#### 文件输出规则

1. **目标目录：** 用户项目的 `docs/fpt/` 目录（相对路径，基于用户的当前工作目录）
2. **文件名格式：** `yyyymmdd-<主题概括>.md`
   - `yyyymmdd` 为当天的日期（如 20260603）
   - "主题概括" 与 FPT 文档的 Feature Name / 功能名称对应，使用用户语言的简短短语
3. **文件内容：** 完整的 FPT 分析文档，使用 Markdown 格式

#### 行为流程

1. 分析完成后，在对话结尾提示用户："分析完成。如需保存为文档文件，请说'输出文档'。"（根据用户语言做对应翻译）
2. 用户发出保存指令后，使用 Write 工具将文档写入 `docs/fpt/<date>-<summary>.md`
3. 写入成功后确认："已保存到 `docs/fpt/<date>-<summary>.md`"（根据用户语言做对应翻译）
4. 如果 `docs/fpt/` 目录不存在，应当先创建该目录

#### 注意事项

- 仅在完成完整 FPT 分析后才执行保存，不要在分析中途保存
- 保存逻辑不影响主流程——先完成分析输出到对话，再响应用户的保存请求
- 始终基于用户的当前工作目录（`cwd`）生成相对路径，不使用技能的自身目录

### Review Gate 模式

1. **不产生独立文件。** Review Gate 的输出是对话中的 review 意见，不写入 `docs/fpt/`
2. **修订源文档：** 如果用户采纳修订建议，应将修订版的 spec/plan 写入原文档路径（或另存为 `*_revised.md`，由用户决定）
3. **不提示保存。** Review Gate 模式下，不需要在对话结尾提示"如需保存为文档文件"
4. 如果用户明确说"把这个 review 意见保存下来"，可以写入 `docs/fpt/` 但使用 `*_review.md` 作为文件名后缀

---

## Phase 4: Iterative Refinement（迭代完善）

After completing the three phases and outputting the structured document, the analysis enters **iterative refinement mode**. This phase enables the user and AI to collaboratively revise the analysis until it is finalized.

> **Review Gate 模式下的调整：** 修订的不是 FPT 分析文档本身，而是**源文档**（spec/plan）。FPT 的 review 意见是修订的输入，修订结果更新源文档。

### Behavior Flow

#### Step 1: Enter Refinement Mode

After outputting the Phase 1–3 analysis document, add a prompt in the user's language:

**Standalone 模式:**
**Chinese:**
> 分析完成（v1.0）。这是我基于第一性原理的分析初稿。
> 
> 你可以对任意部分提出修改意见，例如：
> - *"第三部分的设计太理想化了，需要更务实"*
> - *"第二部分的分析忽略了数据库迁移成本"*
> - *"推荐结论我倾向 Path A，因为时间紧迫"*
> - *"整体没问题，可以保存"*
> 
> 请审阅并提供反馈，或说"确认"接受当前版本。

**English:**
> Analysis complete (v1.0). This is the first-principles analysis draft.
>
> You can suggest changes to any section, for example:
> - *"The design in Section 3 is too idealistic, needs to be more pragmatic"*
> - *"Section 2's analysis missed database migration cost"*
> - *"I prefer Path A for the recommendation due to time constraints"*
> - *"Looks good overall, save it"*
>
> Please review and provide feedback, or say "confirm" to accept the current version.

**Review Gate 模式:**
**Chinese:**
> 审查完成。以上是对源文档的 FPT Review 意见。
> 
> 你可以：
> - 要求对某个建议做进一步分析（如 *"A-03 再深入分析一下"*）
> - 接受某些建议并要求直接修订源文档（如 *"A-01 和 A-02 按建议改，写入源文档"*）
> - 拒绝某些建议并说明理由（如 *"A-04 保留现有方案，时间不允许改"*）
> - 说"确认"表示接受当前审查结论

**English:**
> Review complete. Above are the FPT Review comments for the source document.
>
> You can:
> - Ask for deeper analysis on a specific item
> - Accept items and request source document revision
> - Reject items with rationale
> - Say "confirm" to accept the current review conclusions

#### Step 2: Process Feedback

When the user provides feedback on a specific section:

1. **Locate** — Identify which section(s) the feedback affects (Intent, Current Design Critique, Assumptions, Clean-Sheet Design, Gap Analysis, Path A/B, Recommendation)
2. **Revise** — Apply the user's feedback to the affected section(s). Be faithful to the user's input while maintaining the FPT framework (keep the structured format, don't drop sections)
3. **Version** — Increment the version number (v1.0 → v1.1 → v1.2 → ...)
4. **Output** — Present the **full revised document**, not just the diff. At the top, add a **"Changes in this version"** summary noting what was modified
5. **Continue** — End with the same invitation for further feedback

**Example of the version header:**
```markdown
# First Principles Analysis: <Feature Name> (v1.1)

**Changes in v1.1:**
- Section 3 (Clean-Sheet Design): Simplified data model per user feedback — removed the event-sourcing layer, kept direct DB writes
- Section 6 (Recommendation): shifted from "Recommend Path B" to "Hybrid" based on timeline concerns
```

#### Step 3: Respond to Non-Feedback Messages

If the user sends a **question** about the analysis (e.g., "为什么这里选择了 Path A？" / "Why did you choose Path A here?"), answer the question first, then end with the refinement prompt to stay in mode.

If the user changes the **topic entirely** (e.g., "先不管这个，帮我看看另一个 bug"), exit refinement mode and handle the new topic normally.

#### Step 4: Exit Conditions

| Trigger | Action |
|---------|--------|
| User says "确认" / "确认保存" / "接受" / "同意" / "finalize" / "confirm" / "accept" | **Standalone:** Write to `docs/fpt/<date>-<summary>.md` and exit. **Review Gate:** Mark review as accepted, no file written. |
| User says "保存" / "导出" / "输出文档" / "save" / "export" | **Standalone:** Write to `docs/fpt/<date>-<summary>.md` and exit. **Review Gate:** If user wants to persist the review, write to `docs/fpt/<date>-<summary>_review.md`. |
| User says "结束" / "退出" / "done" / "exit" | Exit without save. |
| User clearly changes topic | Auto-exit refinement mode. |

### Important Rules

1. **Always output the full revised document** — not just the changed section. This keeps the complete analysis in context for the next iteration.
2. **Increment version on every revision** — v1.0 → v1.1 → v1.2 → v1.3 ...
3. **Never drop sections** during revision — every revision must include all 6+ sections (Intent, Current Design Critique, Assumptions, Clean-Sheet Design, Gap Analysis, Path Comparison, Recommendation). Even if unchanged, include them.
4. **Stay faithful to the FPT framework** — user feedback should refine the analysis, not discard the first-principles structure (e.g., if user wants to skip Clean-Sheet Design, that's their call — note it as a constraint in the revision summary).
5. **If user feedback contradicts FPT intent** (e.g., "just tell me what to do, skip the analysis"), note this politely and comply — user feedback takes precedence.
6. **The conversation protocol maintains the mode** — each AI reply ends with a question about feedback or next steps, naturally guiding the user's next message into refinement mode. No external state management needed.

### Self-Check for Phase 4

Before transitioning out of refinement mode, verify:
- [ ] Is every version clearly marked (v1.0, v1.1, ...)?
- [ ] Does each revision include a "Changes in this version" summary?
- [ ] Are all 6+ sections present in the latest revision?
- [ ] Was the user's feedback faithfully incorporated?
- [ ] Did the user explicitly confirm, save, or request exit before leaving refinement mode?
- [ ] For Review Gate mode: was the source document revised according to accepted feedback?

---

## 与 Superpowers 的集成

### 协作关系

FPT 和 Superpowers 不是平行竞争关系，而是 **FPT 为 Superpowers 流程提供设计审查**：

```
Superpowers 流程
    │
    ├── brainstorming → 产出草案
    │                       │
    │                       ▼
    │               FPT (Review Gate)
    │                       │
    │                       ▼  输出假设挑战 + 修订建议
    │               ┌───────┴───────┐
    │               ▼               ▼
    │          接受建议         拒绝建议
    │          修订草案         保留原方案
    │               │               │
    │               └───────┬───────┘
    │                       ▼
    ├── writing-plans → 产出 plan
    │                       │
    │                       ▼  (可再次走 FPT Review Gate)
    │               修订 plan ...
    │
    ├── subagent-driven-development → 实现
    │
    └── requesting-code-review → 最终审查
```

### 调用约定

Superpowers 的 brainstorming / writing-plans / subagent-driven-development 在产出草案后，可以**主动调用 FPT** 进行设计审查：

1. **上游传递上下文：** Superpowers 在其输出中注明 `FPT_REVIEW_NEEDED: true`，并附上源文档内容或引用路径
2. **FPT 接收信号：** 检测到上游标记后自动进入 Review Gate 模式
3. **FPT 输出 review 意见：** 见 Phase 3 Review Gate 输出格式
4. **上游修正：** 根据 FPT 的 review 意见修订草案

### 适用判断

| 场景 | 建议模式 |
|------|---------|
| 复杂功能设计，担心现有代码影响方案质量 | FPT Review Gate 介入 |
| 快速迭代，时间敏感 | 跳过 FPT，直接进实现 |
| 已有多个方案选择，需要决策依据 | FPT Standalone 分析后选方案 |
| 性能/安全/接口等专项设计 | 可用 FPT Review Gate |
| 只是修 bug / 加少量参数 | 不触发 FPT |

---

## Diagnostic Patterns

When analyzing code, watch for these recurring patterns. Each has a specific first-principles diagnosis:

### The Complexity Trap
**Symptom:** The solution is more complex than the problem warrants. Code has layers of abstraction, configuration flags, and extension points for features that don't exist yet.
**Diagnosis:** Remove one "essential-looking" component. Does the system still solve the core problem? If yes, that component is accidental complexity. Repeat until removal breaks core functionality.
**Action:** The clean-sheet design should be shorter than the current code, not longer.

### The Analogy Trap
**Symptom:** Code follows a pattern "because Company X / Framework Y does it that way" — but the context is different.
**Diagnosis:** What problem was the original pattern solving? Is our problem identical in all relevant dimensions? What constraints did they have that we don't (and vice versa)?
**Action:** Strip the pattern back to the underlying principle. Adapt, don't copy.

### The Legacy Trap
**Symptom:** The code maintains compatibility with decisions that no longer serve anyone. Migration wrappers, deprecated fields, compatibility shims that have been there for years.
**Diagnosis:** What was the original reason for this compatibility? Do those conditions still exist? What's the true cost of change vs. cost of maintaining?
**Action:** If the original reason is gone, the compatibility layer is dead code. The refactor should remove it.

### The Code-Bound Trap（Review Gate 专用）
**Symptom:** The source document's design decisions mirror the existing codebase structure, not the requirements. The plan is "how to fit the feature into existing code" rather than "what's the best solution."
**Diagnosis:** For each major decision in the document, ask: "If I were building this in a greenfield project, would I still choose this approach?" If the answer is no, the decision is code-bound.
**Action:** Flag as code-bound in Phase 1 assumptions review. Challenge in Phase 3 recommendation.

---

## Boundaries

This skill is for first-principles reasoning about design. It:

**Will:**
- Challenge the existing design decisions
- Produce a concrete alternative design
- Compare two explicit paths with tradeoffs
- Recommend the right path with rationale

**Will Not:**
- Guarantee the "perfect" solution (it reveals better reasoning, not absolute truth)
- Ignore practical constraints (time, team size, deployment risk)
- Dismiss all existing code as wrong (sometimes the current design IS the right one)
- Apply to every single-line change (that would be wasteful)

---

## Common Anti-Patterns to Avoid

1. **"The code is fine as-is" without analysis.** If you haven't looked at coupling, cohesion, and boundaries, you don't know it's fine.
2. **Designing the ideal by renaming existing code.** Giving a god class a better name is not a clean-sheet design.
3. **Defaulting to "hybrid" without specifics.** "Let's do both gradually" is a cop-out unless you name the concrete steps and the order they happen.
4. **Making the refactor sound riskier than it is.** If the Strangler Fig pattern applies, say so — incremental migration is much safer than a Big Rewrite.
5. **Only considering the current request.** "Does this work for what they asked for" misses the question of whether the structure supports the next three requests too.
6. **Confusing Review Gate with Standalone mode.** Review Gate = 审查源文档产生 review 意见；Standalone = 分析项目代码产生独立 FPT 文档。行为和输出完全不同，分不清会导致输出跑偏。
