# Distributed Tracking Directory Structure

The `.hq/` directory enables distributed teams to share PRD and task status via git.

## Directory Location

```
{target_repo}/
├── .hq/
│   ├── prd.json        # Project requirements and task status
│   ├── claims.json     # Active task claims
│   ├── sync-log.json   # Sync history
│   └── prompt.md       # Pure Ralph prompt (copied from HQ, can evolve with project)
├── src/
└── ...
```

## File Schemas

### prd.json

Synced copy of project PRD with tracking metadata.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["project", "goal", "features", "sync_metadata"],
  "properties": {
    "project": {
      "type": "string",
      "description": "Project identifier"
    },
    "goal": {
      "type": "string",
      "description": "High-level project goal"
    },
    "success_criteria": {
      "type": "string",
      "description": "How success is measured"
    },
    "has_ui": {
      "type": "boolean",
      "description": "Whether project has UI components requiring Playwright testing"
    },
    "features": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "title", "passes"],
        "properties": {
          "id": {
            "type": "string",
            "description": "Unique task identifier (e.g., US-001)"
          },
          "title": {
            "type": "string",
            "description": "Task title"
          },
          "description": {
            "type": "string",
            "description": "Detailed task description"
          },
          "acceptance_criteria": {
            "type": "array",
            "items": { "type": "string" },
            "description": "Verifiable completion criteria"
          },
          "files": {
            "type": "array",
            "items": { "type": "string" },
            "description": "Files to create or modify"
          },
          "dependsOn": {
            "type": "array",
            "items": { "type": "string" },
            "description": "Task IDs that must complete first"
          },
          "passes": {
            "type": ["boolean", "null"],
            "description": "Task completion status"
          },
          "notes": {
            "type": "string",
            "description": "Implementation notes, failure details"
          },
          "updated_at": {
            "type": "string",
            "format": "date-time",
            "description": "Last modification timestamp"
          }
        }
      }
    },
    "sync_metadata": {
      "type": "object",
      "required": ["synced_at", "synced_from"],
      "properties": {
        "synced_at": {
          "type": "string",
          "format": "date-time",
          "description": "When this sync occurred"
        },
        "synced_from": {
          "type": "string",
          "description": "Source HQ path (e.g., C:/my-hq/projects/distributed-tracking)"
        },
        "synced_by": {
          "type": "string",
          "description": "User or agent who performed sync"
        }
      }
    },
    "metadata": {
      "type": "object",
      "properties": {
        "created_at": { "type": "string", "format": "date-time" },
        "created_by": { "type": "string" },
        "purpose": { "type": "string" }
      }
    }
  }
}
```

### claims.json

Tracks which tasks are claimed by which contributor to prevent duplicate work.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["claims"],
  "properties": {
    "claims": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["task_id", "claimed_by", "claimed_at", "expires_at"],
        "properties": {
          "task_id": {
            "type": "string",
            "description": "Task ID being claimed (e.g., US-001)"
          },
          "claimed_by": {
            "type": "string",
            "description": "Identifier of claimer (user, agent, or machine)"
          },
          "claimed_at": {
            "type": "string",
            "format": "date-time",
            "description": "When claim was made"
          },
          "expires_at": {
            "type": "string",
            "format": "date-time",
            "description": "When claim expires (default: 24h from claimed_at)"
          },
          "notes": {
            "type": "string",
            "description": "Optional context about the claim"
          }
        }
      }
    },
    "updated_at": {
      "type": "string",
      "format": "date-time",
      "description": "Last modification to claims file"
    }
  }
}
```

### sync-log.json

Audit trail of all sync operations for debugging and history.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["entries"],
  "properties": {
    "entries": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["timestamp", "action", "source"],
        "properties": {
          "timestamp": {
            "type": "string",
            "format": "date-time",
            "description": "When operation occurred"
          },
          "action": {
            "type": "string",
            "enum": ["push", "pull", "claim", "release", "merge"],
            "description": "Type of sync operation"
          },
          "source": {
            "type": "string",
            "description": "Origin of the operation"
          },
          "target": {
            "type": "string",
            "description": "Destination of the operation"
          },
          "tasks_affected": {
            "type": "array",
            "items": { "type": "string" },
            "description": "Task IDs involved in this operation"
          },
          "details": {
            "type": "string",
            "description": "Additional context or error info"
          },
          "actor": {
            "type": "string",
            "description": "User or agent who performed operation"
          }
        }
      }
    }
  }
}
```

### prompt.md

The Pure Ralph prompt file, copied from HQ and customizable per project.

```markdown
# Pure Ralph Prompt

You are executing the Pure Ralph Loop...

**PRD Path:** .hq/prd.json
**Target Repo:** {{TARGET_REPO}}

---

[Full prompt content - see prompts/pure-ralph-base.md]
```

**Key Characteristics:**
- **Initial source:** Copied from `HQ/prompts/pure-ralph-base.md` on first run
- **References PRD locally:** Uses `.hq/prd.json` (not an HQ path)
- **Project-specific evolution:** Can be edited to add project-specific patterns
- **Version controlled:** Part of the repo, evolves with the project

**Why prompt.md lives in .hq/:**
1. **Portability:** Project can run Ralph loop without HQ access
2. **Customization:** Project teams can tune the prompt for their needs
3. **Version tracking:** Prompt changes are committed with the project
4. **Self-contained:** Everything needed for distributed work is in one directory

## .gitignore Recommendations

Add to the target repository's `.gitignore`:

```gitignore
# Distributed tracking - DO NOT ignore
# .hq/

# Local-only files (if needed)
.hq/*.local.json
.hq/scratch/
```

**Important:** The `.hq/` directory should be committed to git. This is intentional - the whole point is sharing status via git. Only ignore:

- `*.local.json` - Local overrides not meant for sharing
- `scratch/` - Temporary working files

## Usage

1. **First sync:** Creates `.hq/` directory with initial prd.json
2. **Subsequent syncs:** Updates prd.json, manages claims
3. **Contributors:** Pull repo, check `.hq/prd.json` for available tasks
4. **Claim before work:** Update claims.json to prevent conflicts
5. **After completion:** Push updated status, release claim
