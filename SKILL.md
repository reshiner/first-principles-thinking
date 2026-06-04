---
name: first-principles-thinking
description: "Use when the user requests code changes to existing code — adding features, extending functionality, changing behavior, or fixing bugs. Also triggers on phrases like '第一性原理', '从根本分析', '从零开始思考', '这个设计合理吗', 'challenge assumptions', 'question this design', 'is this the right approach'. Forces first-principles thinking: critically evaluate the existing design, design the ideal solution, then reconcile. Do NOT use for: trivial one-line changes, pure read/search tasks, or obvious-root-cause bug fixes."
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
| User asks to add a feature to existing code | Trivial one-line changes |
| User asks to extend/modify behavior | Pure bug fixes with obvious root cause |
| Changes will touch >2 files | Codebase exploration / read-only questions |
| Request implies a structural mismatch | The user explicitly asks for "the quickest fix" |
| You feel the "this doesn't fit" tension | Greenfield / new file creation |

**If unsure, use it.** The cost is one round of structured thinking; the cost of not using it is another layer of technical debt.

## Language Matching

**Output language MUST match the user's input language.** If the user asks in Chinese, output the entire analysis in Chinese — including section headers, table column names, and all narrative text. If the user asks in English, output in English. This applies to all three phases and the final structured document.

(The template below is shown in English; localize its section headers and content when the user's language is not English.)

## The Three Phases

You MUST follow these phases **in order**. Do not skip Phase 2 (Clean-Sheet Design) — that's where the value comes from.

---

### Phase 1: Decompose

**Goal:** Understand what's really being asked and what the current code actually is.

#### Step 1: Surface Intent

Read the user's request and strip away implementation specifics. Ask yourself:

- What's the fundamental user-facing goal? (Not "add a filter dropdown" but "let users narrow results by category")
- What constraints are real (performance, security, deployment) vs. assumed (framework choice, file structure)?
- If I were building this from scratch with no existing code, how would I think about this feature?

Write down the intent in one sentence. If you can't, ask the user to clarify.

#### Step 2: Decompose the Existing Code

Read the relevant files and map out what actually exists (not what you assume exists):

- **Entities:** What classes/types/models are involved? What are their actual responsibilities?
- **Data flow:** How does data move through the system? What transformations happen?
- **Control flow:** What's the sequence of operations? Are there implicit state machines or branch trees?
- **Boundaries:** Where does this module end and the next begin? What are the public interfaces?

#### Step 3: Diagnose Design Debt

Evaluate the existing code against these criteria. Be specific — name the files and lines:

- **Coupling:** Does one module know too much about another's internals? Does changing A require changing B?
- **Cohesion:** Are related behaviors scattered across different files? Are unrelated behaviors lumped together?
- **Abstraction boundary violations:** Does a high-level module reach into low-level details? (e.g., UI code constructing SQL queries, business logic importing framework internals)
- **Hidden assumptions:** What does the code assume about its environment (order of operations, data shape, timing)? Would the requested feature break those assumptions?
- **Extension cost:** How many touch points does a new feature require? One well-placed hook, or a chain of edits across files?
- **Duplication by convention:** Is the same logic repeated because there's no shared abstraction? (e.g., similar validation in 5 handlers, similar rendering code in 3 components)

Beyond design debt, surface the assumptions behind the decisions. Categorize them:

| Category | Question to Ask |
|----------|-----------------|
| **Technical** | "Must we use this technology/pattern? Was it chosen for this problem or inherited?" |
| **Business** | "Is this requirement actually fixed, or was it assumed at some point?" |
| **Historical** | "Why was this code written this way originally? Do those conditions still hold?" |
| **Cultural** | "Are we following a pattern because it fits, or because 'everyone does it this way'?" |

**Red flags for likely-false assumptions:** Watch for phrases in the codebase or your own reasoning like "We've always done it this way", "Industry standard says X", "Everyone uses Y for this", "That's too simple to work". When you see these, you've found an assumption to challenge.

#### Step 4: Output Phase 1

Write the "Current Design Critique" section of your analysis. Keep it factual — not "this code is bad" but "this code assumes X, which breaks when Y happens."

---

### Phase 2: Design

**Goal:** Design the ideal solution from first principles, ignoring what already exists.

#### Step 1: Clean-Sheet Design

Given only the user's intent from Phase 1, design the minimal solution that satisfies it. Answer:

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

**Warning — The Over-Engineering Trap:** First principles thinking can lead you to design a "better database" when SQLite is fine. Test your design against this: "Does building custom save more time than using what exists?" If the existing solution is within 2x of optimal and the team knows it, use it. First principles reveals when existing solutions are **10x wrong**, not when they're mildly suboptimal.

**Phase 2 is NOT optional.** If you skip or abbreviate it, the entire skill fails. The rest of the skill depends on having a concrete alternative to compare against.

#### Step 2: Document the Gap

Contrast the clean-sheet design with the current architecture. This is the gap analysis:

| Aspect | Current | Ideal | Delta |
|--------|---------|-------|-------|
| Entity A responsibility | Does X and Y | Only X | Y should be in Entity B |
| Data flow | Passes raw dicts | Typed interfaces | Add schema validation |
| Extension model | Add another `if` branch | Strategy pattern | Replace switch with registry |

#### Step 3: Output Phase 2

Write the "Clean-Sheet Design" and "Gap Analysis" sections.

---

### Phase 3: Reconcile

**Goal:** Compare the two paths and make a recommendation.

#### Step 1: Define Path A — Minimal Modification

The smallest set of changes that make the user's request work within the existing structure. Be honest about what this costs:

- Workaround code you'd need to write
- Design debt this accumulates
- How future features will be harder

#### Step 2: Define Path B — First-Principles Refactor

The set of changes that moves toward the clean-sheet design. Be honest about the cost:

- Files to modify/create/delete
- Migration effort (data, callers, tests)
- Risk (what could break during the transition)
- Decomposability (can this be done in safe, reviewable steps?)

#### Step 3: Compare and Recommend

Evaluate the two paths using these heuristics:

| Heuristic | Path A (Patch) | Path B (Refactor) |
|-----------|-------|--------|
| Diff size (lines changed) | | |
| Risk of breakage | | |
| Design debt left behind | | |
| Future extension cost | | |
| Can be done incrementally? | | |

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

Write the final output as a structured document. **Use the template below but localize all headers, table columns, and labels to match the user's language** (see Language Matching section above).

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

- [ ] Did I actually produce a clean-sheet design in Phase 2, or did I just describe the existing code with minor tweaks? (Must be the former.)
- [ ] Did I identify design debt by name (coupling, cohesion, boundary violations, hidden assumptions)?
- [ ] Did I document what Path A costs in future maintenance burden, not just diff size?
- [ ] Did I apply the decision framework (touch frequency, provably wrong, strangler fig)?
- [ ] Is my recommendation specific and actionable, not "either way works"?
- [ ] Did I consider a hybrid approach (Path B in safe increments) before defaulting to either extreme?

If any check fails, go back and fix it before presenting.

---

## 文档持久化（Document Persistence）

在完成上述三个阶段并输出结构化文档到对话后，**等待用户指令**。当用户说以下任一短语时，将最终文档写入文件：

| 语言 | 触发短语 |
|------|----------|
| 中文 | "输出文档"、"保存文档"、"导出"、"保存" |
| 英文 | "output document"、"save document"、"export"、"save" |
| 任何语言 | 用户明确要求保存当前分析文档 |

### 文件输出规则

1. **目标目录：** 用户项目的 `doc/fpt/` 目录（相对路径，基于用户的当前工作目录）
2. **文件名格式：** `yyyymmdd-<主题概括>.md`
   - `yyyymmdd` 为当天的日期（如 20260603）
   - "主题概括" 与 FPT 文档的 Feature Name / 功能名称对应，使用用户语言的简短短语
3. **文件内容：** 完整的 FPT 分析文档，使用 Markdown 格式

### 行为流程

1. 分析完成后，在对话结尾提示用户："分析完成。如需保存为文档文件，请说'输出文档'。"（根据用户语言做对应翻译）
2. 用户发出保存指令后，使用 Write 工具将文档写入 `doc/fpt/<date>-<summary>.md`
3. 写入成功后确认："已保存到 `doc/fpt/<date>-<summary>.md`"（根据用户语言做对应翻译）
4. 如果 `doc/fpt/` 目录不存在，应当先创建该目录

### 注意事项

- 仅在完成完整 FPT 分析后才执行保存，不要在分析中途保存
- 保存逻辑不影响主流程——先完成分析输出到对话，再响应用户的保存请求
- 始终基于用户的当前工作目录（`cwd`）生成相对路径，不使用技能的自身目录

---

## Phase 4: Iterative Refinement（迭代完善）

After completing the three phases and outputting the structured document, the analysis enters **iterative refinement mode**. This phase enables the user and AI to collaboratively revise the analysis until it is finalized.

### Behavior Flow

#### Step 1: Enter Refinement Mode

After outputting the Phase 1–3 analysis document, add a prompt in the user's language:

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
| User says "确认" / "确认保存" / "接受" / "同意" / "finalize" / "confirm" / "accept" | **Confirm + Save + Exit:** Mark the current version as final, write to `doc/fpt/<date>-<summary>.md` using the Document Persistence rules, confirm success, and exit refinement mode. |
| User says "保存" / "导出" / "输出文档" / "save" / "export" | **Save + Exit:** Same as confirm — write to `doc/fpt/<date>-<summary>.md`, confirm success, and exit. (Saving implies finalization.) |
| User says "结束" / "退出" / "done" / "exit" | **Exit without save:** Exit refinement mode. The analysis is still in conversation history. |
| User clearly changes topic | Auto-exit refinement mode. |

### Important Rules

1. **Always output the full revised document** — not just the changed section. This keeps the complete analysis in context for the next iteration.
2. **Increment version on every revision** — v1.0 → v1.1 → v1.2 → v1.3 ...
3. **Never drop sections** during revision — every revision must include all 6+ sections (Intent, Current Design Critique, Assumptions, Clean-Sheet Design, Gap Analysis, Path Comparison, Recommendation). Even if unchanged, include them.
4. **Stay faithful to the FPT framework** — user feedback should refine the analysis, not discard the first-principles structure (e.g., if user wants to skip Clean-Sheet Design, that's their call — note it as a constraint in the revision summary).
5. **If user feedback contradicts FPT intent** (e.g., "just tell me what to change, skip the analysis"), note this politely and comply — user feedback takes precedence.
6. **The conversation protocol maintains the mode** — each AI reply ends with a question about feedback or next steps, naturally guiding the user's next message into refinement mode. No external state management needed.

### Self-Check for Phase 4

Before transitioning out of refinement mode, verify:
- [ ] Is every version clearly marked (v1.0, v1.1, ...)?
- [ ] Does each revision include a "Changes in this version" summary?
- [ ] Are all 6+ sections present in the latest revision?
- [ ] Was the user's feedback faithfully incorporated?
- [ ] Did the user explicitly confirm, save, or request exit before leaving refinement mode?

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

---

## Boundaries

This skill is for code modification planning. It:

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