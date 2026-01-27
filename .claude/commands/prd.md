---
description: Generate a Product Requirements Document for project execution
allowed-tools: Task, Read, Glob, Grep, Write, Bash, AskUserQuestion
argument-hint: [project/feature description]
---

# /prd - Project Planning

Create PRDs with full HQ context awareness.

**User's input:** $ARGUMENTS

## The Job

1. Scan HQ context (workers, knowledge, existing projects)
2. Discovery interview (batched questions)
3. Generate structured PRD
4. Save to `projects/{name}/`

**Important:** Do NOT implement. Just create the PRD.

## Step 1: Scan HQ Context

Before asking questions, explore HQ:

```bash
# Workers available
cat workers/registry.yaml

# Existing projects (check for overlap)
ls projects/

# Knowledge bases
ls knowledge/
ls companies/*/knowledge/
```

Present findings:
```
Scanned HQ:
- Workers: frontend-dev, backend-dev, database-dev...
- Existing projects: {list or "none"}
- Relevant knowledge: {if any match keywords}

This appears to be: [company-specific | personal | HQ infrastructure]
```

## Step 2: Get Project Name

Ask for project slug. Check if `projects/{name}` exists:
- If exists: "Project exists. Continue editing or choose different name?"
- If new: proceed

## Step 2.5: Check for Duplicate Work (Distributed Tracking)

Before starting discovery, check if work already exists in the target repo:

```bash
# Check if distributed tracking exists in target repo
TARGET_REPO="${TARGET_REPO:-$(pwd)}"
if [ -f "$TARGET_REPO/.hq/prd.json" ]; then
    cat "$TARGET_REPO/.hq/prd.json"
fi
```

**If `.hq/prd.json` exists:**

1. Parse and show existing tasks:
   ```
   Found existing distributed work in this repo:

   | ID | Title | Status |
   |----|-------|--------|
   | US-001 | Example task | ✓ complete |
   | US-002 | Another task | pending |
   ```

2. Fuzzy match user's description against existing task titles:
   - Normalize: lowercase, remove punctuation
   - Check for: exact match, contains match, word overlap > 50%
   - If match found:
     ```
     ⚠️ Potential duplicate detected:
     Your request: "add user authentication"
     Existing task: "US-003: Add user auth flow" (pending)

     Similarity: 78% word overlap
     ```

3. Ask user before proceeding:
   ```
   Options:
   A. Add to existing project (extend .hq/prd.json)
   B. Create separate project (new projects/{name}/)
   C. Cancel and review existing work first
   ```

**If no `.hq/prd.json` exists:** Proceed to Step 3.

## Step 3: Discovery Interview

Ask questions in batches. Format:

```
1. What's the core problem or goal?
   A. Option one
   B. Option two
   C. Other: [specify]

2. What does success look like?
   A. Measurable outcome 1
   B. Measurable outcome 2
```

Users respond: "1A, 2C"

**Batch 1: Problem & Success**
- Core problem/goal?
- What does success look like? (measurable)
- Who benefits?

**Batch 2: Scope & Constraints**
- What's in scope for MVP?
- Hard constraints (time, tech)?
- Dependencies on other projects?

**Batch 3: Quality Gates** (required)
```
What quality commands must pass for each user story?
   A. pnpm typecheck && pnpm lint
   B. npm run typecheck && npm run lint
   C. None (no automated checks)
   D. Other: [specify]
```

## Step 4: Generate PRD

Create `projects/{name}/` folder with:

**projects/{name}/README.md:**
```markdown
# {Project Name}

**Goal:** {1-sentence goal}
**Success:** {measurable outcome}

## Overview
{Brief description}

## Quality Gates
- `{command}` - {description}

## User Stories

### US-001: [Title]
**Description:** As a [user], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] Specific verifiable criterion

### US-002: [Title]
...

## Non-Goals
{What's out of scope}

## Technical Considerations
{Constraints, dependencies}

## Open Questions
{Remaining questions}
```

## Story Guidelines

- Each story completable in one AI session
- Acceptance criteria must be verifiable (not "works correctly")
- Order: schema → backend → UI → integration
- Keep stories atomic (one deliverable each)

## Step 5: Complete

Tell user:
```
Project **{name}** created with {N} user stories.
Location: projects/{name}/README.md

Next: Run /execute to create tasks and assign workers.
```

## Rules

- Scan HQ first, ask questions second
- Batch questions (don't overwhelm)
- **Do NOT use EnterPlanMode** - this skill IS planning
- **Do NOT use TodoWrite** - PRD stories track tasks
