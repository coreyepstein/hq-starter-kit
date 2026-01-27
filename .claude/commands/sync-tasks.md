# /sync-tasks - Manual Distributed Tracking Sync

Manual sync command for checking task status, pushing updates, and claiming tasks in distributed projects.

## Usage

```
/sync-tasks {project}              # Pull and show status diff
/sync-tasks {project} --push       # Push local PRD to repo
/sync-tasks {project} --claim {id} # Claim a specific task
/sync-tasks {project} --release {id} # Release a claim
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `{project}` | Yes | Project name (folder name in `projects/`) |
| `--push` | No | Push local PRD to target repo's `.hq/` |
| `--claim {id}` | No | Claim a specific task ID |
| `--release {id}` | No | Release a claim on a task ID |

## Steps

### Default: Pull and Show Status Diff

1. **Read local PRD:**
   ```
   projects/{project}/prd.json
   ```

2. **Get target repo from PRD:**
   Extract `target_repo` field from the PRD.

3. **Check for distributed tracking:**
   ```bash
   if [ -f "{target_repo}/.hq/prd.json" ]; then
       echo "Distributed tracking found"
   else
       echo "No distributed tracking in target repo"
       echo "Use --push to initialize"
       exit 0
   fi
   ```

4. **Compare PRDs and show diff:**
   ```
   SYNC STATUS: {project}
   ┌─────────────────────────────────────────────────────────────┐
   │ Local PRD:  projects/{project}/prd.json                     │
   │ Repo PRD:   {target_repo}/.hq/prd.json                      │
   │ Last sync:  {sync_metadata.synced_at}                       │
   ├─────────────────────────────────────────────────────────────┤
   │ TASK STATUS COMPARISON                                      │
   │                                                             │
   │ ID      │ Title                    │ Local  │ Repo   │      │
   │ ────────┼──────────────────────────┼────────┼────────┼───── │
   │ US-001  │ Define .hq/ structure    │ PASS   │ PASS   │ =    │
   │ US-002  │ Add push-to-repo         │ PASS   │ PASS   │ =    │
   │ US-003  │ Add pull-from-repo       │ FAIL   │ PASS   │ ←    │
   │ US-008  │ Add /sync-tasks          │ -      │ FAIL   │ NEW  │
   │                                                             │
   │ Legend: = same, ← repo newer, → local newer, NEW = only one │
   ├─────────────────────────────────────────────────────────────┤
   │ CLAIMS                                                      │
   │                                                             │
   │ US-006: claimed by pure-ralph-WORK (expires in 22h)         │
   │ US-010: claimed by stefan (expires in 2h)                   │
   ├─────────────────────────────────────────────────────────────┤
   │ SUMMARY                                                     │
   │   Local: 5/10 tasks complete                                │
   │   Repo:  7/10 tasks complete                                │
   │   Diff:  2 tasks differ, 0 conflicts                        │
   └─────────────────────────────────────────────────────────────┘
   ```

5. **If differences found, suggest actions:**
   ```
   Suggested actions:
   - /sync-tasks {project} --push    # Push local changes to repo
   - /sync-tasks {project} --claim US-008  # Claim a task before starting
   ```

### With `--push`: Push Local to Repo

1. **Read local PRD** from `projects/{project}/prd.json`

2. **Create .hq/ directory if missing:**
   ```bash
   mkdir -p {target_repo}/.hq
   ```

3. **Add sync metadata:**
   ```json
   {
     ...full PRD...,
     "sync_metadata": {
       "synced_at": "{ISO 8601 now}",
       "synced_from": "projects/{project}/prd.json",
       "synced_by": "sync-tasks-command"
     }
   }
   ```

4. **Write to repo:**
   ```
   {target_repo}/.hq/prd.json
   ```

5. **Report result:**
   ```
   PUSH COMPLETE
   ┌─────────────────────────────────────────────────────────────┐
   │ Pushed: projects/{project}/prd.json                         │
   │ To:     {target_repo}/.hq/prd.json                          │
   │ At:     {synced_at}                                         │
   │                                                             │
   │ Tasks synced: 10                                            │
   │ Complete: 7, Remaining: 3                                   │
   └─────────────────────────────────────────────────────────────┘

   Note: Changes not committed. Run:
     git add {target_repo}/.hq/prd.json
     git commit -m "sync: update distributed tracking"
   ```

### With `--claim {task-id}`: Claim a Task

1. **Verify task exists** in local PRD

2. **Read or create claims.json:**
   ```bash
   claims_path="{target_repo}/.hq/claims.json"
   if [ ! -f "$claims_path" ]; then
       echo '{"claims": [], "updated_at": null}' > "$claims_path"
   fi
   ```

3. **Check if already claimed:**
   - If claimed by someone else (not expired): show warning, ask to proceed
   - If expired or unclaimed: proceed

4. **Add claim:**
   ```json
   {
     "task_id": "{task-id}",
     "claimed_by": "{username or identifier}",
     "claimed_at": "{ISO 8601 now}",
     "expires_at": "{ISO 8601 now + 24 hours}",
     "notes": "Claimed via /sync-tasks command"
   }
   ```

5. **Write updated claims.json**

6. **Report result:**
   ```
   CLAIM RECORDED
   ┌─────────────────────────────────────────────────────────────┐
   │ Task:     {task-id} - {task title}                          │
   │ Claimed:  {claimed_at}                                      │
   │ Expires:  {expires_at}                                      │
   │ By:       {claimed_by}                                      │
   └─────────────────────────────────────────────────────────────┘

   Note: Commit the claim:
     git add {target_repo}/.hq/claims.json
     git commit -m "claim: {task-id}"
   ```

### With `--release {task-id}`: Release a Claim

1. **Read claims.json**

2. **Find and remove the claim** for the specified task ID

3. **Write updated claims.json**

4. **Report result:**
   ```
   CLAIM RELEASED
   ┌─────────────────────────────────────────────────────────────┐
   │ Task:     {task-id} - {task title}                          │
   │ Released: {ISO 8601 now}                                    │
   └─────────────────────────────────────────────────────────────┘
   ```

## Comparison Logic

When comparing local and repo PRDs:

| Field | Compare? | Notes |
|-------|----------|-------|
| `id` | Key | Match tasks by ID |
| `passes` | Yes | Status changes are important |
| `notes` | Yes | Implementation details |
| `updated_at` | Yes | Determines which is newer |
| `title` | No | Minor wording doesn't matter |
| `description` | No | Details don't affect matching |

### Diff Symbols

| Symbol | Meaning |
|--------|---------|
| `=` | Same in both |
| `←` | Repo is newer (has updates) |
| `→` | Local is newer |
| `NEW` | Only exists in one |
| `!` | Conflict (both modified) |

## Error Handling

| Error | Response |
|-------|----------|
| Project not found | "Project '{project}' not found in projects/" |
| No target_repo in PRD | "PRD missing target_repo field" |
| Task ID not found | "Task '{id}' not found in PRD" |
| Already claimed | Show claim info, ask to override |

## Examples

**Check sync status:**
```
> /sync-tasks distributed-tracking

SYNC STATUS: distributed-tracking
...shows diff table...
```

**Push local changes:**
```
> /sync-tasks distributed-tracking --push

PUSH COMPLETE
Pushed 10 tasks to C:/my-hq/.hq/prd.json
```

**Claim a task:**
```
> /sync-tasks distributed-tracking --claim US-008

CLAIM RECORDED
Task: US-008 - Add /sync-tasks slash command
Claimed by: stefan
Expires: 2026-01-28T15:30:00Z
```

**Release a claim:**
```
> /sync-tasks distributed-tracking --release US-008

CLAIM RELEASED
Task: US-008 - Add /sync-tasks slash command
```
