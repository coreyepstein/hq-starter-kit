# Distributed Tracking Workflow Guide

Comprehensive guide for contributors using distributed tracking to collaborate on projects via git.

## Overview

Distributed tracking enables multiple contributors (human or AI) to work on the same project without duplicating work. It uses the `.hq/` directory in target repos to share:
- **PRD status** - Which tasks are done, in progress, or available
- **Claims** - Who is working on what
- **Sync history** - Audit trail of all sync operations

## Full Sync Lifecycle

### Session Start

```
1. BRANCH VERIFICATION
   ├── Check current branch: git branch --show-current
   ├── Expected: feature/{project-name}
   └── If wrong: checkout or create feature branch

2. PULL FROM REPO
   ├── Check if {target_repo}/.hq/prd.json exists
   ├── Compare with local projects/{project}/prd.json
   ├── Generate diff summary
   └── If conflicts → resolve before continuing

3. READ PRD
   └── Load local PRD (now synced with repo)
```

### Task Selection

```
4. FIND ELIGIBLE TASKS
   ├── Filter: passes=false or null
   ├── Filter: all dependsOn tasks have passes=true
   └── Result: list of tasks ready for work

5. CHECK CLAIMS
   ├── For each eligible task:
   │   └── Read {target_repo}/.hq/claims.json
   │       ├── If claimed (not expired) → mark "claimed by X"
   │       └── If available → mark "available"
   └── Display task list with claim status

6. SELECT AND CLAIM
   ├── Prefer unclaimed tasks
   ├── Select one task
   └── Write claim to claims.json (expires in 24h)
```

### Implementation

```
7. DO THE WORK
   ├── Implement the task
   ├── Follow acceptance criteria
   └── Test your changes

8. UPDATE PRD
   ├── Set passes: true
   ├── Add notes with worker info and summary
   └── Add updated_at timestamp (ISO 8601)
```

### Session End

```
9. PUSH TO REPO
   ├── Write updated PRD to {target_repo}/.hq/prd.json
   └── Include sync_metadata

10. RELEASE CLAIM
    └── Remove your claim from claims.json

11. COMMIT
    ├── Stage task files
    ├── Stage .hq/prd.json and .hq/claims.json
    └── Commit: "feat({task-id}): Brief description"

12. CHECK COMPLETION
    ├── If more tasks remain → EXIT (loop continues)
    └── If all complete → final push, create PR
```

## Quick Reference: Commands

| Phase | Action | Command/File |
|-------|--------|--------------|
| Start | Check branch | `git branch --show-current` |
| Start | Pull status | `/sync-tasks {project}` |
| Select | View claims | Check `.hq/claims.json` |
| Select | Claim task | `/sync-tasks {project} --claim {id}` |
| End | Push status | `/sync-tasks {project} --push` |
| End | Release claim | `/sync-tasks {project} --release {id}` |

## Claim/Release Flow

### Claiming a Task

Before starting any task, claim it to prevent others from working on it simultaneously.

**Step 1: Check if task is claimed**
```
Read {target_repo}/.hq/claims.json
Find claim where task_id matches your selected task
Check if expires_at > now (still valid)
```

**Step 2: If claimed by someone else**
```
WARNING: Task US-006 is claimed

Claimed by: pure-ralph-WORKSTATION
Claimed at: 2026-01-27T14:30:00Z (2 hours ago)
Expires at: 2026-01-28T14:30:00Z (in 22 hours)

Options:
  [S] Skip - pick a different task
  [W] Wait - task may be released soon
  [O] Override - claim anyway (use with caution)
```

**Step 3: If available, create claim**
```json
{
  "task_id": "US-006",
  "claimed_by": "pure-ralph-LAPTOP-ABC",
  "claimed_at": "2026-01-27T16:00:00Z",
  "expires_at": "2026-01-28T16:00:00Z",
  "notes": "Working on: Add task claim mechanism"
}
```

**Step 4: Write claim and commit**
```bash
# Write updated claims.json
# Then commit:
git add {target_repo}/.hq/claims.json
git commit -m "claim: US-006 by pure-ralph-LAPTOP-ABC"
```

### Releasing a Claim

After completing a task, release your claim so others know the task is done.

**Step 1: Remove claim from array**
```
Read claims.json
Remove entry where task_id matches completed task
Update claims.updated_at to now
```

**Step 2: Include in task commit**
```bash
# Stage with your task changes:
git add {task_files} {target_repo}/.hq/prd.json {target_repo}/.hq/claims.json
git commit -m "feat(US-006): Add task claim mechanism"
```

### Claim Expiration

Claims automatically expire after 24 hours. This prevents indefinite blocking if:
- A contributor abandons work
- A session crashes
- Someone forgets to release

**Expired claims are treated as "available"** - no manual cleanup needed.

### Example: Full Claim Lifecycle

```
SESSION START
├── Check claims.json
│   └── US-006: claimed by stefan (expires in 2h)
│   └── US-007: no claim (available)
│
├── Select US-007 (available)
│
├── Claim US-007:
│   {
│     "task_id": "US-007",
│     "claimed_by": "pure-ralph-DESKTOP",
│     "claimed_at": "2026-01-27T18:00:00Z",
│     "expires_at": "2026-01-28T18:00:00Z"
│   }
│
├── WORK ON TASK
│   └── Implement, test, update PRD
│
├── Release claim:
│   └── Remove US-007 from claims array
│
└── Commit:
    git add src/feature.ts .hq/prd.json .hq/claims.json
    git commit -m "feat(US-007): Integrate with pure-ralph loop"
```

## Troubleshooting Common Conflicts

### Conflict: Task Status Differs

**Symptom:** Local shows `passes: false`, repo shows `passes: true`

**Cause:** Another contributor completed the task while you were working.

**Resolution:**
1. Check `updated_at` timestamps on both versions
2. If repo is newer → Accept repo version (task is done)
3. If local is newer → Your work may overwrite; verify the task isn't actually done
4. If timestamps equal or missing → Manual review required

```
CONFLICT: US-003 - Add pull-from-repo function
┌──────────────┬─────────────────┬─────────────────┐
│ Field        │ Local           │ Repo            │
├──────────────┼─────────────────┼─────────────────┤
│ passes       │ false           │ true            │
│ notes        │ (empty)         │ "Worker: ..."   │
│ updated_at   │ -               │ 2026-01-27T14:30│
└──────────────┴─────────────────┴─────────────────┘

Repo has timestamp, local doesn't → Accept repo version
```

### Conflict: Notes Differ

**Symptom:** Both local and repo have different `notes` content.

**Cause:** Two contributors worked on the same task or updated notes independently.

**Resolution:**
1. Compare `updated_at` - newer wins
2. If both have valuable info, manually merge the notes
3. Write merged result to both locations

### Conflict: New Tasks in Repo

**Symptom:** Repo has task IDs that don't exist locally.

**Cause:** Someone added tasks to the repo PRD (scope expansion).

**Resolution:**
1. Review new tasks - do they make sense for the project?
2. Add to local PRD if valid
3. Or ignore if they're out of scope for your work

```
Tasks added in repo (not in local):
  - US-011: "Add retry logic for sync failures"
  - US-012: "Improve error messages"

Action: Add to local? [y/n/review]
```

### Conflict: Claimed Task You Need

**Symptom:** The task you want to work on is claimed by someone else.

**Cause:** Another contributor is actively working on it.

**Resolution Options:**
1. **Skip** - Pick a different unclaimed task
2. **Wait** - Check back later (claim may be released)
3. **Override** - Claim anyway if you're sure they're not working on it

**When to Override:**
- Claim is about to expire (< 1 hour remaining)
- You've communicated with the claimer and they agreed
- The claimer is known to be unavailable

**When NOT to Override:**
- Claim was made recently (< 12 hours ago)
- You haven't tried to contact the claimer
- Multiple tasks are available - pick another

### Conflict: Git Merge Conflict on .hq/ Files

**Symptom:** Git merge conflict in `.hq/prd.json` or `.hq/claims.json`

**Cause:** Two contributors pushed changes to the same file simultaneously.

**Resolution for prd.json:**
1. Open the file with conflict markers
2. For each conflicted task, compare `updated_at`
3. Keep the newer version of each task
4. Resolve and commit

**Resolution for claims.json:**
1. Combine both claim arrays (remove duplicates by task_id)
2. For duplicate task_ids, keep the newer claim
3. Remove any expired claims
4. Resolve and commit

```bash
# After resolving:
git add .hq/prd.json .hq/claims.json
git commit -m "merge: resolve distributed tracking conflicts"
```

### Conflict: Stale Local PRD

**Symptom:** Your local PRD is significantly behind the repo version.

**Cause:** You haven't synced in a while; others have completed many tasks.

**Resolution:**
1. Run `/sync-tasks {project}` to see the full diff
2. If many tasks differ, consider accepting repo state wholesale
3. Apply merge: repo version for completed tasks, keep local for your in-progress work

### Session Crashed: Claim Not Released

**Symptom:** You claimed a task but your session crashed before releasing.

**Impact:** The claim will expire in 24 hours automatically.

**If you need to work on it sooner:**
1. Manually edit `{target_repo}/.hq/claims.json`
2. Remove your stale claim
3. Re-claim if continuing work

```bash
# Edit claims.json, remove your stale claim, then:
git add .hq/claims.json
git commit -m "fix: release stale claim from crashed session"
```

### Session Crashed: PRD Not Pushed

**Symptom:** You completed work but the session crashed before pushing to repo.

**Impact:** Your local PRD has the update, but repo doesn't.

**Resolution:**
1. Your work is still in local PRD
2. Next session will run `/sync-tasks --push`
3. Conflict resolution will merge if someone else also worked

## Best Practices

### Before Starting Work

1. Always sync first: `/sync-tasks {project}`
2. Review the diff - understand what's changed
3. Pick unclaimed tasks when possible
4. Claim your task before coding

### During Work

1. Work on ONE task at a time
2. Don't hold claims longer than needed
3. If blocked, release claim and pick another task

### After Completing Work

1. Update PRD with notes AND `updated_at`
2. Push to repo immediately
3. Release your claim
4. Include `.hq/` files in your commit

### For Distributed Teams

1. Communicate about large refactors
2. Check sync status before long sessions
3. Don't override claims without good reason
4. Keep sessions short - claim, work, release

## File Reference

| File | Purpose | Location |
|------|---------|----------|
| Local PRD | Source of truth for project | `projects/{project}/prd.json` |
| Repo PRD | Shared status for team | `{target_repo}/.hq/prd.json` |
| Claims | Who's working on what | `{target_repo}/.hq/claims.json` |
| Sync Log | Audit trail | `{target_repo}/.hq/sync-log.json` |

## See Also

- [Directory Structure](structure.md) - File schemas and directory layout
- `/sync-tasks` command - Manual sync operations
- `prompts/pure-ralph-base.md` - Automated workflow integration
