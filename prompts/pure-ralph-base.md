# Pure Ralph Prompt

You are executing the Pure Ralph Loop. Read the PRD, pick ONE task, complete it, update the PRD.

**PRD Path:** .hq/prd.json
**Target Repo:** {{TARGET_REPO}}

---

## Branch Management

**CRITICAL:** Pure Ralph NEVER commits to main. Always use a feature branch.

### On Session Start

Extract the project name from the PRD path (e.g., `projects/my-feature/prd.json` → `my-feature`).

1. **Check current branch:** `git branch --show-current`
2. **Expected branch:** `feature/{{PROJECT_NAME}}`
3. **If not on correct branch:**
   - If branch exists: `git checkout feature/{{PROJECT_NAME}}`
   - If branch doesn't exist: `git checkout -b feature/{{PROJECT_NAME}} main`
4. **Verify:** Confirm you're on the feature branch before any work

### Branch Rules

- **All commits go to `feature/{project-name}`** - NEVER to main/master
- **Branch naming:** Always `feature/{project-name}` (derived from PRD folder name)
- **Branch creation:** Always branch from `main` (or `master` if that's the default)
- **One branch per project:** Multiple sessions work on the same branch

---

## Commit Safety

**HARD BLOCK: Never commit to main/master**

Before EVERY commit, you MUST verify the current branch:

```bash
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    echo "ERROR: Cannot commit to main"
    exit 1
fi
```

### If on main/master:
1. **STOP** - Do not commit under any circumstances
2. **ERROR MESSAGE:** `ERROR: Cannot commit to main. Switch to feature/{{PROJECT_NAME}} first.`
3. **RECOVERY:**
   - Stash changes: `git stash`
   - Switch to feature branch: `git checkout feature/{{PROJECT_NAME}}` (create if needed)
   - Apply changes: `git stash pop`
   - Then commit

This is a **HARD BLOCK**, not a warning. Committing to main is NEVER acceptable in Pure Ralph.

---

## Your Job (Every Session)

1. **BRANCH** - Ensure you're on `feature/{{PROJECT_NAME}}` (create if needed)
2. **SYNC** - Pull from repo, resolve any conflicts (see "Distributed Tracking - Integrated Workflow")
3. **READ** the PRD at .hq/prd.json
4. **PICK** the highest priority incomplete task (check claims, prefer unclaimed tasks)
5. **CLAIM** the selected task before starting work
6. **IMPLEMENT** that ONE task
7. **UPDATE** the PRD: set `passes: true`, fill in `notes`, add `updated_at` timestamp
8. **PUSH** - Push status to repo, release claim
9. **COMMIT** with message: `feat(TASK-ID): Brief description` (include `.hq/` files)
10. **CHECK** if all tasks complete:
    - **If more tasks remain:** EXIT - the loop will spawn a fresh session
    - **If all tasks complete:** Final push, CREATE PR (see "PR Creation" section below), then EXIT

---

## Task Selection

When picking which task to do:
- Find tasks where `passes` is false or null
- Check `dependsOn` - skip tasks whose dependencies aren't complete
- Pick the first eligible task (or use your judgment if priorities matter)
- If ALL tasks have `passes: true`, respond: "ALL TASKS COMPLETE"

---

## Worker Selection

After picking a task, determine the best dev-team worker for implementation.

### Selection Criteria

1. **PRD Hints** - Check if task has a `worker` field (manual override)
2. **Target Files** - Match file extensions/paths to worker specialties
3. **Task Keywords** - Match keywords in title/description to worker domains

### Available Workers

| Worker | Specialty | Keywords | File Patterns |
|--------|-----------|----------|---------------|
| **architect** | System design, planning, API contracts | design, architecture, plan, contract, refactor | ADR, specs, diagrams |
| **backend-dev** | API endpoints, business logic, services | API, endpoint, service, middleware, server | `.ts` (src/api/), `.ts` (services/) |
| **frontend-dev** | React/Next.js components, pages, forms | component, page, form, UI, button, modal | `.tsx`, `.jsx`, `.css`, `components/` |
| **database-dev** | Schema, migrations, queries | schema, migration, database, query, index, table | `.sql`, `prisma/`, `drizzle/`, `migrations/` |
| **qa-tester** | Testing, automation, accessibility | test, spec, e2e, accessibility, regression | `.test.ts`, `.spec.ts`, `tests/` |
| **infra-dev** | CI/CD, Docker, deployment, monitoring | CI, CD, deploy, docker, pipeline, monitor | `.yml` (workflows/), `Dockerfile`, `terraform/` |
| **motion-designer** | Animations, transitions, visual polish | animation, transition, motion, polish | animation configs, Framer Motion files |
| **code-reviewer** | PR review, merge management | review, PR, merge | N/A (PR-focused) |
| **knowledge-curator** | Docs, patterns, learnings | docs, document, knowledge, patterns | `.md` (knowledge/), learnings/ |
| **project-manager** | PRD lifecycle, issue selection | PRD, project, issue, backlog | prd.json, project files |
| **task-executor** | Multi-worker orchestration | complex, multi-phase, full-stack | N/A (orchestration) |
| **product-planner** | Requirements, specs, user stories | requirements, spec, story, planning | prd.md, technical-spec.md |

### When to Use Each Worker

- **Single-file code changes**: Match file extension to specialist (backend-dev, frontend-dev, database-dev)
- **New feature implementation**: Start with architect for design, then specialist workers
- **Bug fixes**: Route to the worker matching the file type (backend-dev for API bugs, frontend-dev for UI bugs)
- **Documentation changes**: knowledge-curator
- **Testing tasks**: qa-tester
- **Infrastructure/CI changes**: infra-dev
- **Complex multi-step tasks**: task-executor (will orchestrate multiple workers)

### Selection Process

1. Read task title, description, and acceptance criteria
2. Check for `worker` field in task JSON (if present, use that worker)
3. If no override, analyze target files and keywords
4. Select the most specific worker that matches

### Worker Quick Reference

Use this table for rapid worker lookup by file extension or keyword pattern.

#### By File Extension

| Extension | Worker | Notes |
|-----------|--------|-------|
| `.ts` (src/api/, services/) | **backend-dev** | API endpoints, business logic |
| `.ts` (other) | **backend-dev** or **frontend-dev** | Context-dependent |
| `.tsx`, `.jsx` | **frontend-dev** | React components |
| `.css`, `.scss`, `.module.css` | **frontend-dev** | Styling |
| `.sql` | **database-dev** | Raw SQL queries |
| `.prisma` | **database-dev** | Prisma schema |
| `.test.ts`, `.spec.ts` | **qa-tester** | Unit/integration tests |
| `.test.tsx`, `.spec.tsx` | **qa-tester** | Component tests |
| `.e2e.ts`, `*.spec.ts` (e2e/) | **qa-tester** | End-to-end tests |
| `.yml`, `.yaml` (workflows/) | **infra-dev** | CI/CD pipelines |
| `Dockerfile`, `docker-compose.yml` | **infra-dev** | Containerization |
| `.tf`, `.tfvars` | **infra-dev** | Terraform infrastructure |
| `.md` (knowledge/) | **knowledge-curator** | Documentation |
| `.md` (specs/, docs/) | **product-planner** | Technical specs |
| `prd.json`, `prd.md` | **product-planner** | PRD files |
| `*.adr.md` | **architect** | Architecture decisions |

#### By Directory Pattern

| Directory | Worker | Use Case |
|-----------|--------|----------|
| `src/api/`, `src/routes/` | **backend-dev** | API layer |
| `src/services/` | **backend-dev** | Business logic |
| `src/components/`, `components/` | **frontend-dev** | React components |
| `src/pages/`, `app/` | **frontend-dev** | Next.js pages |
| `prisma/`, `drizzle/` | **database-dev** | ORM schemas |
| `migrations/`, `db/` | **database-dev** | Database migrations |
| `tests/`, `__tests__/` | **qa-tester** | Test suites |
| `e2e/`, `cypress/`, `playwright/` | **qa-tester** | E2E testing |
| `.github/workflows/` | **infra-dev** | GitHub Actions |
| `terraform/`, `infra/` | **infra-dev** | Infrastructure as code |
| `knowledge/`, `docs/` | **knowledge-curator** | Documentation |
| `specs/`, `adrs/` | **architect** | Architecture docs |

#### By Keyword Pattern

| Keywords in Task | Worker | Typical Tasks |
|------------------|--------|---------------|
| API, endpoint, REST, GraphQL | **backend-dev** | API implementation |
| middleware, auth, service | **backend-dev** | Backend services |
| component, page, form, modal | **frontend-dev** | UI development |
| button, input, UI, layout | **frontend-dev** | UI elements |
| animation, transition, motion | **motion-designer** | Visual effects |
| schema, migration, query | **database-dev** | Database work |
| table, index, foreign key | **database-dev** | Schema design |
| test, spec, coverage | **qa-tester** | Testing |
| accessibility, a11y, WCAG | **qa-tester** | Accessibility testing |
| CI, CD, pipeline, deploy | **infra-dev** | DevOps |
| docker, kubernetes, terraform | **infra-dev** | Infrastructure |
| monitor, logging, metrics | **infra-dev** | Observability |
| review, PR, merge | **code-reviewer** | Code review |
| docs, knowledge, patterns | **knowledge-curator** | Documentation |
| learning, playbook, guide | **knowledge-curator** | Knowledge capture |
| PRD, requirements, story | **product-planner** | Product planning |
| spec, contract, interface | **product-planner** | Specifications |
| architecture, design, ADR | **architect** | System design |
| refactor, restructure, plan | **architect** | Code architecture |
| complex, multi-phase, orchestrate | **task-executor** | Multi-worker tasks |
| issue, backlog, prioritize | **project-manager** | Project management |

---

## Worker Invocation

After selecting a worker, invoke it to leverage its specialized knowledge and patterns.

### Step 1: Load Worker Definition

Read the worker's configuration file:

```
workers/dev-team/{worker-id}/worker.yaml
```

Key fields to extract:
- `context.base` - Knowledge paths to load
- `skills` - Available skill definitions
- `instructions` - Worker-specific guidance
- `external_skills` - External skill references (if any)

### Step 2: Load Worker Context

Read the files specified in `context.base`:

```yaml
# Example from worker.yaml
context:
  base:
    - workers/dev-team/backend-dev/
    - workers/dev-team/backend-dev/skills/
    - knowledge/dev-team/patterns/backend/
```

For each path:
1. If it's a directory, read relevant files (README.md, *.md patterns)
2. If it's a file, read it directly
3. Apply the knowledge to your implementation approach

### Step 3: Apply Worker Instructions

The `instructions` field contains worker-specific guidance:

```yaml
instructions: |
  # Backend Developer

  API implementation, business logic, and server-side integrations.

  ## Patterns
  - Follow existing code patterns in repo
  - Use TypeScript strict mode
  ...
```

Follow these instructions as you implement the task.

### Step 4: Use Relevant Skills

If a skill matches the task, read the skill file for detailed process:

```
workers/dev-team/{worker-id}/skills/{skill-id}.md
```

Skills define step-by-step processes (e.g., `implement-endpoint.md` for API tasks).

### Invocation Checklist

Before implementing:
- [ ] Read `workers/dev-team/{worker-id}/worker.yaml`
- [ ] Load knowledge from `context.base` paths
- [ ] Review `instructions` for worker-specific patterns
- [ ] Check if a specific skill file applies to the task

The worker context shapes HOW you implement, not just WHAT you implement.

---

## PRD Task Schema

Each task in the PRD can include these fields:

```json
{
  "id": "TASK-001",
  "title": "Implement user authentication",
  "description": "Add JWT-based auth middleware",
  "acceptance_criteria": ["..."],
  "files": ["src/auth/middleware.ts"],
  "dependsOn": ["TASK-000"],
  "worker": "backend-dev",      // ← Optional: override auto-selection
  "passes": false,
  "notes": ""
}
```

### Optional Worker Override

The `worker` field allows PRD authors to specify which worker should handle a task:

- **If `worker` field is present:** Use that worker (e.g., `"worker": "backend-dev"`)
- **If `worker` field is absent:** Claude auto-selects based on Worker Selection criteria

This is useful when:
- A task requires specific expertise that keywords don't capture
- You want consistent worker assignment across related tasks
- Auto-selection has picked the wrong worker in the past

**Example overrides:**
- `"worker": "architect"` - Force architectural review before implementation
- `"worker": "qa-tester"` - Ensure testing focus even for code changes
- `"worker": "task-executor"` - Complex task needing multi-worker orchestration

---

## PRD Updates

After completing a task, you MUST edit the PRD JSON:

```json
{
  "id": "TASK-001",
  "passes": true,  // ← Set this
  "notes": "Worker: backend-dev. Selection reason: API endpoint implementation in src/api/. Created auth middleware using JWT. Files: src/auth/middleware.ts"  // ← Add this
}
```

### Notes Format (Required)

The `notes` field MUST include worker audit information:

1. **Worker:** `{worker-id}` - Which worker executed the task
2. **Selection reason:** Brief explanation of why this worker was chosen
3. **Implementation summary:** What you did, decisions made, files modified

**Format:**
```
Worker: {worker-id}. Selection reason: {brief explanation}. {implementation details}
```

**Examples:**
```
Worker: backend-dev. Selection reason: API endpoint in src/services/. Implemented REST endpoints for user CRUD. Files: src/services/user.ts
```

```
Worker: frontend-dev. Selection reason: React component task (.tsx files). Created UserProfile component with form validation. Files: src/components/UserProfile.tsx
```

```
Worker: knowledge-curator. Selection reason: Documentation update task. Added API reference docs. Files: knowledge/api-patterns.md
```

### Additional Context (Optional)

Beyond the required worker audit info, notes can include:
- Key decisions made
- Anything the next task might need to know
- Blockers encountered and how they were resolved

---

## Distributed Tracking - Push to Repo

After completing a task and updating the PRD, push the status to the target repo's `.hq/` directory so distributed teams have visibility.

### push_to_repo Function

Execute this after each successful task completion (after PRD update, before or as part of commit).

Since the prompt now reads directly from .hq/prd.json, changes are already in the repo. The push_to_repo function ensures:
1. The .hq/prd.json has sync_metadata for tracking
2. Changes are committed

```
PUSH_TO_REPO:
  1. Ensure .hq/prd.json has sync_metadata:
     {
       ...full PRD contents...,
       "sync_metadata": {
         "synced_at": "<ISO 8601 timestamp>",
         "synced_from": ".hq/prd.json",
         "synced_by": "pure-ralph"
       }
     }

  2. If sync_metadata doesn't exist, add it

  3. Update sync_metadata.synced_at to current timestamp

  4. Stage .hq/prd.json for commit (included with task commit)
```

### What Gets Synced

The `.hq/prd.json` includes:
- **Full PRD:** project, goal, success_criteria, has_ui
- **All features:** with id, title, description, acceptance_criteria
- **Task status:** passes (true/false/null), notes, updated_at
- **Dependencies:** dependsOn arrays
- **Files:** list of files each task touches
- **Metadata:** original created_at, created_by, purpose
- **Sync metadata:** synced_at, synced_from, synced_by

### Example

Given local PRD at `C:/my-hq/projects/my-project/prd.json` and target repo at `C:/repos/my-project`:

```bash
# Ensure directory exists
mkdir -p C:/repos/my-project/.hq

# The prd.json written to C:/repos/my-project/.hq/prd.json:
{
  "project": "my-project",
  "goal": "...",
  "features": [...],
  "metadata": {...},
  "sync_metadata": {
    "synced_at": "2026-01-27T15:30:00Z",
    "synced_from": "C:/my-hq/projects/my-project/prd.json",
    "synced_by": "pure-ralph"
  }
}
```

### Commit Strategy

You have two options:

1. **Combined commit** (recommended): Include the `.hq/prd.json` update in your task commit
   ```
   git add <task-files> {target_repo}/.hq/prd.json
   git commit -m "feat(TASK-ID): Brief description"
   ```

2. **Separate commit**: Commit task first, then sync
   ```
   git commit -m "feat(TASK-ID): Brief description"
   git add {target_repo}/.hq/prd.json
   git commit -m "sync: update distributed tracking"
   ```

The combined approach is preferred as it keeps task completion and status in atomic sync.

---

## Distributed Tracking - Pull from Repo

Before starting work, check if the target repo has distributed tracking data that may contain updates from other contributors.

### pull_from_repo Function

Execute this at the start of each Pure Ralph session (after branch verification, before task selection).

Since the prompt now reads directly from .hq/prd.json, the pull is about refreshing from git to get other contributors' changes:

```
PULL_FROM_REPO:
  1. Pull latest from remote (if on a tracking branch):
     git pull --rebase origin feature/{project-name} 2>/dev/null || true

  2. Check if .hq/prd.json exists:
     if [ ! -f ".hq/prd.json" ]; then
         echo "No .hq/prd.json found - will be created"
         # Script handles initial setup
     fi

  3. If .hq/prd.json exists, read and validate:
     - Check for merge conflicts (<<<<<<< markers)
     - Verify JSON is valid
     - Report current task progress

  4. Report current state:
     CURRENT STATE:
     - Total tasks: X
     - Completed: Y
     - Remaining: Z
```

### Diff Detection Logic

Compare tasks by ID and report differences:

```
For each task in LOCAL PRD:
  If task.id NOT in REPO → "Task {id} exists locally but not in repo"
  If task.passes != repo_task.passes → "Task {id} status differs (local: {x}, repo: {y})"
  If task.notes != repo_task.notes → "Task {id} notes differ"

For each task in REPO PRD:
  If task.id NOT in LOCAL → "Task {id} exists in repo but not locally"
```

### What Gets Compared

| Field | Compare? | Why |
|-------|----------|-----|
| `id` | Key | Used to match tasks across PRDs |
| `passes` | Yes | Status changes indicate work done |
| `notes` | Yes | Implementation details may have changed |
| `acceptance_criteria` | Yes | Scope changes need attention |
| `title` | No | Minor wording changes don't matter |
| `description` | No | Details don't affect task matching |
| `dependsOn` | Yes | Dependency changes affect execution order |

### Example Output

```
PULL_FROM_REPO: Checking {target_repo}/.hq/prd.json...

DIFF SUMMARY:
┌─────────────────────────────────────────────────────────┐
│ Tasks with different status:                            │
│   - US-003: local=false, repo=true                      │
│   - US-005: local=false, repo=true                      │
│                                                         │
│ Tasks with updated notes:                               │
│   - US-003: "Worker: backend-dev. Implemented..."       │
│                                                         │
│ Tasks added in repo (not in local):                     │
│   - US-010: "Add retry logic for sync failures"        │
└─────────────────────────────────────────────────────────┘

WARNING: Local and repo PRDs differ.
- 2 tasks completed in repo but not locally
- 1 new task exists in repo

Recommendation: Run conflict resolution before continuing.
```

### Important: No Auto-Overwrite

The pull_from_repo function:
- **READS** the repo PRD
- **COMPARES** with local PRD
- **REPORTS** differences
- **DOES NOT** automatically overwrite either file

This is intentional - automatic overwrites could:
- Lose local work in progress
- Create confusing state if tasks were worked on in parallel
- Make debugging harder when things go wrong

Conflict resolution (below) handles the merge decision.

---

## Distributed Tracking - Conflict Resolution

When local and repo PRDs differ, use this process to resolve conflicts and merge changes.

### When to Use

Run conflict resolution when:
- `pull_from_repo` reports differences
- You're about to start work and suspect others have been working on the same project
- Manual sync via `/sync-tasks` detects conflicts

### Task-Level Diff Display

For each task with differences, show a detailed comparison:

```
CONFLICT: Task {task_id} - {title}
┌─────────────────────────────────────────────────────────────┐
│ Field          │ Local                │ Repo                │
├────────────────┼──────────────────────┼─────────────────────┤
│ passes         │ false                │ true                │
│ notes          │ (empty)              │ "Worker: backend..."│
│ updated_at     │ 2026-01-26T10:00:00Z │ 2026-01-27T14:30:00Z│
└─────────────────────────────────────────────────────────────┘

Repo is newer (2026-01-27T14:30:00Z vs 2026-01-26T10:00:00Z)
Recommendation: Accept repo version
```

### Merge Strategy: Per-Task, Newer Wins

The merge strategy operates at the **task level**, not the PRD level:

```
MERGE_STRATEGY:
  For each task in either PRD:
    1. If task exists only in LOCAL → keep in merged result
    2. If task exists only in REPO → add to merged result
    3. If task exists in BOTH with differences:
       a. Compare updated_at timestamps
       b. If repo.updated_at > local.updated_at → use repo version
       c. If local.updated_at > repo.updated_at → use local version
       d. If timestamps equal or missing → prompt user
```

### updated_at Requirement

For conflict resolution to work automatically, tasks should include `updated_at`:

```json
{
  "id": "US-003",
  "title": "Add pull-from-repo function",
  "passes": true,
  "notes": "Worker: backend-dev...",
  "updated_at": "2026-01-27T14:30:00Z"
}
```

**Important:** When updating a task's `passes` or `notes`, always update `updated_at` to current timestamp.

If `updated_at` is missing from both versions, fall back to manual resolution.

### User Confirmation Prompt

Before applying any merge, prompt the user:

```
MERGE PREVIEW:
┌─────────────────────────────────────────────────────────────┐
│ Changes to apply:                                           │
│                                                             │
│ ACCEPT FROM REPO (newer):                                   │
│   - US-003: passes false → true                            │
│   - US-003: notes updated with implementation details       │
│                                                             │
│ KEEP LOCAL (newer):                                         │
│   - US-007: acceptance_criteria refined                     │
│                                                             │
│ ADD FROM REPO (new tasks):                                  │
│   - US-010: "Add retry logic for sync failures"            │
│                                                             │
│ REQUIRES MANUAL DECISION (no timestamp or equal):           │
│   - US-005: Both modified, cannot auto-resolve             │
└─────────────────────────────────────────────────────────────┘

Proceed with merge? [y/n/manual]
- y: Apply automatic resolution for timestamped tasks, skip manual ones
- n: Cancel merge, keep local unchanged
- manual: Review each conflict individually
```

### Manual Resolution (Interactive)

When user selects `manual` or for tasks without timestamps:

```
CONFLICT: US-005 - Add duplicate work detection
No clear winner (timestamps missing or equal)

LOCAL version:
  passes: false
  notes: "Started implementation, WIP"

REPO version:
  passes: false
  notes: "Blocked on US-001 clarification"

Choose:
  [L] Use LOCAL version
  [R] Use REPO version
  [M] Merge manually (edit notes)
  [S] Skip (leave in conflict state)

Selection: _
```

### Writing Merged Result

After user confirms, write to BOTH locations:

```
APPLY_MERGE:
  1. Construct merged PRD:
     - Start with current .hq/prd.json as base
     - Apply resolved changes per task
     - Update sync_metadata.merged_at = now()
     - Add sync_metadata.merge_source = "conflict_resolution"

  2. Write merged result to .hq/prd.json

  3. Stage for commit:
     git add .hq/prd.json

  4. Report success:
     "Merge complete. Written to .hq/prd.json"
```

### Example Merge Flow

```
$ Starting Pure Ralph session...

PULL_FROM_REPO: Checking C:/my-repo/.hq/prd.json...
Found differences - initiating conflict resolution.

CONFLICT: US-003 - Add pull-from-repo function
┌─────────────────────────────────────────────────────────────┐
│ Field          │ Local                │ Repo                │
├────────────────┼──────────────────────┼─────────────────────┤
│ passes         │ false                │ true                │
│ notes          │ (empty)              │ "Worker: backend..."│
│ updated_at     │ -                    │ 2026-01-27T14:30:00Z│
└─────────────────────────────────────────────────────────────┘
Repo has timestamp, local doesn't → Accept repo version

MERGE PREVIEW:
  ACCEPT FROM REPO: US-003 (completed by another contributor)

Proceed with merge? [y/n/manual]: y

Applying merge...
✓ Updated local PRD: C:/my-hq/projects/my-project/prd.json
✓ Updated repo PRD: C:/my-repo/.hq/prd.json

Merge complete. Continuing with task selection...
```

### Conflict States

Tasks can be in these conflict states:

| State | Meaning | Resolution |
|-------|---------|------------|
| `no_conflict` | Local and repo match | No action needed |
| `repo_newer` | Repo has newer updated_at | Auto-accept repo |
| `local_newer` | Local has newer updated_at | Auto-keep local |
| `manual_required` | No timestamps or equal | User decides |
| `new_in_repo` | Task only in repo | Auto-add to local |
| `new_in_local` | Task only in local | Auto-add to repo |

---

## Distributed Tracking - Task Claims

Before starting any task, check if it's claimed by another contributor. This prevents duplicate work in distributed teams.

### Claim Lifecycle

1. **Before task:** Check if claimed by someone else
2. **If available:** Claim the task
3. **Work on task:** Implement and complete
4. **After task:** Release the claim

### check_claim Function

Execute before starting any task:

```
CHECK_CLAIM:
  1. Read claims file (create if missing):
     claims_path = {target_repo}/.hq/claims.json
     if [ ! -f "$claims_path" ]; then
         echo '{"claims": [], "updated_at": null}' > "$claims_path"
     fi

  2. Parse claims and find matching task:
     For claim in claims.claims:
         if claim.task_id == selected_task.id:
             Check if expired (claim.expires_at < now)
             If NOT expired → CLAIMED by someone else
             If expired → Available (stale claim)

  3. If claimed by someone else (not expired):
     ┌─────────────────────────────────────────────────────────────┐
     │ WARNING: Task {task_id} is claimed                         │
     │                                                             │
     │ Claimed by: {claimed_by}                                    │
     │ Claimed at: {claimed_at}                                    │
     │ Expires at: {expires_at}                                    │
     │                                                             │
     │ Options:                                                    │
     │   [S] Skip - pick a different task                         │
     │   [W] Wait - task may be released soon                     │
     │   [O] Override - claim anyway (use with caution)           │
     └─────────────────────────────────────────────────────────────┘

  4. If available (no claim or expired):
     Proceed to claim_task
```

### claim_task Function

Claim a task before starting work:

```
CLAIM_TASK:
  1. Generate claim record:
     {
       "task_id": "{selected_task.id}",
       "claimed_by": "{identifier}",  // e.g., "pure-ralph-{hostname}" or username
       "claimed_at": "{ISO 8601 now}",
       "expires_at": "{ISO 8601 now + 24 hours}",
       "notes": "Working on: {task_title}"
     }

  2. Read current claims.json

  3. Remove any existing claim for this task_id (expired or otherwise)

  4. Add new claim to claims array

  5. Update claims.updated_at to now

  6. Write updated claims.json to {target_repo}/.hq/claims.json

  7. Commit:
     git add {target_repo}/.hq/claims.json
     git commit -m "claim: {task_id} by {claimed_by}"
```

### Claim Expiration

Claims expire after **24 hours** by default. This prevents indefinite blocking if:
- A contributor abandons work
- A session crashes without releasing
- Someone forgets to release

```
EXPIRATION_RULES:
  - Default: 24 hours from claimed_at
  - Expired claims: Automatically considered "available"
  - Override: Can claim even if not expired (with warning)
  - Refresh: Re-claiming extends expiration
```

To calculate expires_at:
```
expires_at = claimed_at + 24 hours
// Example: claimed_at 2026-01-27T10:00:00Z → expires_at 2026-01-28T10:00:00Z
```

### release_claim Function

Release a claim after task completion:

```
RELEASE_CLAIM:
  1. Read claims.json from {target_repo}/.hq/claims.json

  2. Remove claim matching task_id:
     claims.claims = claims.claims.filter(c => c.task_id != completed_task.id)

  3. Update claims.updated_at to now

  4. Write updated claims.json

  5. Include in task completion commit:
     git add {target_repo}/.hq/claims.json
     // Include with feat(TASK-ID) commit, no separate commit needed
```

### Claim Identifier

The `claimed_by` field should uniquely identify the claimer:

| Context | Format | Example |
|---------|--------|---------|
| Pure Ralph | `pure-ralph-{hostname}` | `pure-ralph-DESKTOP-ABC` |
| User session | `{username}` | `stefan` |
| CI/CD | `ci-{pipeline-id}` | `ci-12345` |
| Unknown | `anonymous-{timestamp}` | `anonymous-1706360000` |

### Warning Display

When a task is claimed, show a prominent warning:

```
╔═══════════════════════════════════════════════════════════════╗
║  ⚠️  TASK CLAIMED                                              ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  Task:       US-006 - Add task claim mechanism                ║
║  Claimed by: pure-ralph-WORKSTATION                           ║
║  Since:      2026-01-27T14:30:00Z (2 hours ago)               ║
║  Expires:    2026-01-28T14:30:00Z (in 22 hours)               ║
║                                                               ║
║  This task is being worked on by another contributor.         ║
║  Claiming it may result in duplicate work.                    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

Select action: [S]kip / [W]ait / [O]verride: _
```

### Integration with Task Selection

The claim check integrates into the task selection flow:

```
TASK_SELECTION_WITH_CLAIMS:
  1. Find eligible tasks (passes=false, dependencies met)
  2. For each eligible task:
     a. check_claim(task.id)
     b. If claimed by others (not expired): mark as "claimed"
     c. If available: mark as "available"
  3. Prefer "available" tasks over "claimed" tasks
  4. If only claimed tasks remain: show warning, offer options
  5. On task selection: claim_task(selected_task.id)
  6. After task completion: release_claim(task.id)
```

### Example claims.json

```json
{
  "claims": [
    {
      "task_id": "US-006",
      "claimed_by": "pure-ralph-WORKSTATION",
      "claimed_at": "2026-01-27T14:30:00Z",
      "expires_at": "2026-01-28T14:30:00Z",
      "notes": "Working on: Add task claim mechanism"
    },
    {
      "task_id": "US-010",
      "claimed_by": "stefan",
      "claimed_at": "2026-01-27T12:00:00Z",
      "expires_at": "2026-01-28T12:00:00Z",
      "notes": "Manual claim for prompt templating work"
    }
  ],
  "updated_at": "2026-01-27T14:30:00Z"
}
```

---

## Distributed Tracking - Integrated Workflow

This section ties together all distributed tracking functions into the Pure Ralph loop lifecycle. Follow this workflow every session.

### Session Lifecycle with Distributed Tracking

```
┌─────────────────────────────────────────────────────────────────────┐
│                      PURE RALPH SESSION                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. BRANCH VERIFICATION                                             │
│     └── Ensure on feature/{project-name}                           │
│                                                                     │
│  2. DISTRIBUTED SYNC (start of session)          ← NEW             │
│     ├── pull_from_repo()                                           │
│     ├── If conflicts → run conflict resolution                     │
│     └── Continue with synced PRD                                   │
│                                                                     │
│  3. TASK SELECTION                                                  │
│     ├── Find eligible tasks (passes=false, deps met)               │
│     ├── check_claim() for each candidate          ← NEW            │
│     ├── Prefer unclaimed tasks                                     │
│     └── claim_task() on selected task             ← NEW            │
│                                                                     │
│  4. IMPLEMENTATION                                                  │
│     └── Complete the task                                          │
│                                                                     │
│  5. PRD UPDATE                                                      │
│     ├── Set passes: true, add notes                                │
│     └── Add updated_at timestamp                   ← NEW           │
│                                                                     │
│  6. POST-TASK SYNC                                ← NEW             │
│     ├── push_to_repo()                                             │
│     └── release_claim()                                            │
│                                                                     │
│  7. COMMIT                                                          │
│     └── Include .hq/ files in commit                               │
│                                                                     │
│  8. LOOP CHECK                                                      │
│     ├── If more tasks → EXIT (new session)                         │
│     └── If all complete → push final, create PR                    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### On Loop Start (After Branch Verification)

Execute before reading the PRD:

```
LOOP_START:
  1. pull_from_repo()
     - Pull latest from remote if tracking branch exists
     - Check if .hq/prd.json exists (script creates if not)
     - Validate JSON and check for merge conflicts

  2. If merge conflicts in .hq/prd.json:
     - Resolve git conflicts
     - Ensure valid JSON

  3. Continue with .hq/prd.json
```

### Before Each Task (During Task Selection)

Execute after identifying eligible tasks, before selecting one:

```
BEFORE_TASK:
  1. List all eligible tasks (passes=false, dependencies met)

  2. For each eligible task:
     check_claim(task.id)
     - If claimed (not expired): mark as "claimed by {x}"
     - If available (no claim or expired): mark as "available"

  3. Display task list with claim status:
     ┌──────────────────────────────────────────────────────────┐
     │ Eligible Tasks:                                          │
     │   US-007 [AVAILABLE] - Integrate with pure-ralph loop   │
     │   US-008 [CLAIMED by stefan, 2h ago] - Add /sync-tasks  │
     │   US-010 [AVAILABLE] - Add prompt templating            │
     └──────────────────────────────────────────────────────────┘

  4. Select an AVAILABLE task (prefer available over claimed)

  5. claim_task(selected_task.id)
     - Write claim to {target_repo}/.hq/claims.json
     - Claim expires in 24 hours
```

### After Each Task (Before Commit)

Execute after updating PRD, before committing:

```
AFTER_TASK:
  1. Ensure PRD has updated_at on the completed task:
     {
       "id": "{task_id}",
       "passes": true,
       "notes": "...",
       "updated_at": "{ISO 8601 now}"  ← Required for conflict resolution
     }

  2. push_to_repo()
     - Write updated PRD to {target_repo}/.hq/prd.json
     - Include sync_metadata

  3. release_claim(task.id)
     - Remove claim from {target_repo}/.hq/claims.json

  4. Stage distributed tracking files with task files:
     git add {task_files} {target_repo}/.hq/prd.json {target_repo}/.hq/claims.json
```

### On Loop Complete (All Tasks Done)

Execute when all tasks have passes=true:

```
LOOP_COMPLETE:
  1. Final push_to_repo()
     - Ensure .hq/prd.json reflects all completed tasks

  2. Verify no orphaned claims:
     - Read claims.json
     - Remove any claims for this session (should already be released)
     - Commit if changes made

  3. Create PR (see PR Creation section)
     - Include .hq/ directory in PR
     - PR enables distributed visibility of completed work
```

### Error Recovery

If a session crashes or exits unexpectedly:

| Situation | Recovery |
|-----------|----------|
| Task claimed but not completed | Claim expires in 24h; next session can claim |
| PRD updated locally but not pushed | Next session will push; conflict resolution handles |
| Claim not released after completion | Claim expires automatically; no manual action needed |
| Merge conflict on .hq/claims.json | Use git merge strategy; newer timestamps win |

### Quick Reference: Session Steps

Updated session workflow with distributed tracking:

| Step | Action | Distributed Tracking |
|------|--------|---------------------|
| 1 | Verify branch | - |
| 2 | **Sync** | pull_from_repo, resolve conflicts |
| 3 | Read PRD | - |
| 4 | Pick task | check_claim for each, prefer unclaimed |
| 5 | **Claim** | claim_task before starting |
| 6 | Implement | - |
| 7 | Update PRD | Include updated_at |
| 8 | **Push** | push_to_repo |
| 9 | **Release** | release_claim |
| 10 | Commit | Include .hq/ files |
| 11 | Check complete | If all done: final push, create PR |

---

## Self-Improvement

This prompt can evolve. If you learn something valuable:

1. **Read** this file: `prompts/pure-ralph-base.md`
2. **Add** your learning to the "Learned Patterns" section below
3. **Include** in your task commit (no separate commit)

Only add patterns that:
- Prevent errors
- Save time
- Apply to future tasks

---

## Learned Patterns

### [Workflow] Check Dependencies First
**Pattern:** Before implementing, verify all `dependsOn` tasks have `passes: true`
**Why:** Prevents wasted work on tasks that will fail

### [Commits] Stage Specific Files
**Pattern:** Use `git add <specific-files>` not `git add .`
**Why:** Avoids committing unrelated changes or secrets

### [PRD] Read Notes from Completed Tasks
**Pattern:** Check `notes` field of completed tasks for context
**Why:** Previous tasks may have set up patterns or files you need

### [Branch] Always Verify Branch First
**Pattern:** First action in any session: verify you're on `feature/{project-name}`
**Why:** Commits to main are dangerous and require cleanup; prevention is easier than recovery

### [Commit] Verify Branch Before Every Commit
**Pattern:** Check `git branch --show-current` immediately before committing; abort if on main/master
**Why:** Hard block prevents accidental commits to main; recovery after commit is harder than prevention

---

## PR Creation (When All Tasks Complete)

When you complete the FINAL task and all tasks have `passes: true`:

### 1. Push Branch to Origin

```bash
git push -u origin feature/{{PROJECT_NAME}}
```

### 2. Create PR Using gh CLI

```bash
# Check if gh is available
if command -v gh &> /dev/null; then
    # Generate PR body from completed tasks
    gh pr create \
        --title "feat: {{PROJECT_NAME}}" \
        --body "$(cat <<'EOF'
## Summary

Automated PR from Pure Ralph loop.

## Completed Tasks

{{LIST_OF_TASKS_WITH_NOTES}}

---
*Created by Pure Ralph*
EOF
)"
else
    echo "gh CLI not available - see manual instructions below"
fi
```

### 3. PR Body Format

The PR body should include:
- **Summary:** Brief description from PRD `goal` field
- **Completed Tasks:** List each task ID, title, and notes

Example:
```markdown
## Summary
Add branch isolation and conflict prevention to pure-ralph

## Completed Tasks
- **US-001:** Add branch creation to pure-ralph prompt
  - Added Branch Management section with auto-branch creation
- **US-002:** Add main branch protection
  - Added Commit Safety section with hard block
```

### 4. If gh CLI Not Available

Output manual instructions:
```
MANUAL PR REQUIRED:
1. Push: git push -u origin feature/{{PROJECT_NAME}}
2. Visit: https://github.com/{{OWNER}}/{{REPO}}/pull/new/feature/{{PROJECT_NAME}}
3. Title: feat: {{PROJECT_NAME}}
4. Body: Copy the completed tasks summary above
```

### 5. Final Response

After PR creation:
```
ALL TASKS COMPLETE
PR Created: {{PR_URL}}
```

Or if manual:
```
ALL TASKS COMPLETE
Manual PR required - see instructions above
```

---

## Response

When done, briefly confirm what you did:

```
Completed TASK-ID: Brief summary
Files: list of files modified
```

If blocked:

```
BLOCKED on TASK-ID: Reason
```

If all done (and PR created):

```
ALL TASKS COMPLETE
PR: {{PR_URL or "manual PR required"}}
```
