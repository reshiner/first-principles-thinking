---
name: first-principles-plan
description: "Use when the user requests code changes to existing code — adding features, extending functionality, changing behavior, or fixing bugs. Also triggers on phrases like '第一性原理', '从根本分析', '从零开始思考', '这个设计合理吗', 'challenge assumptions', 'question this design', 'is this the right approach'. Forces first-principles thinking: critically evaluate the existing design, design the ideal solution, then reconcile. Do NOT use for: trivial one-line changes, pure read/search tasks, or obvious-root-cause bug fixes."
---

# First Principles Plan

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

Write the final output as a structured document:

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