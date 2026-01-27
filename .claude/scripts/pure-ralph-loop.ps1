<#
.SYNOPSIS
    Pure Ralph Loop - Canonical external orchestrator

.DESCRIPTION
    Runs the SAME prompt in a loop. Claude picks the task.
    Fresh context per iteration. Loop until all tasks pass.

.PARAMETER PrdPath
    Full path to the PRD JSON file

.PARAMETER TargetRepo
    Full path to the target repository

.PARAMETER Manual
    Run in manual mode (interactive TUI, manually close windows)
    Default is auto mode (uses -p flag, auto-exits)

.EXAMPLE
    # Auto mode (default) - fully autonomous
    .\pure-ralph-loop.ps1 -PrdPath "C:/my-hq/projects/my-project/prd.json" -TargetRepo "C:/my-hq"

    # Manual mode - see chain of thought, close windows manually
    .\pure-ralph-loop.ps1 -PrdPath "C:/my-hq/projects/my-project/prd.json" -TargetRepo "C:/my-hq" -Manual
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$PrdPath,

    [Parameter(Mandatory=$true)]
    [string]$TargetRepo,

    [string]$HqPath = "C:/my-hq",

    [switch]$Manual
)

# ============================================================================
# Configuration
# ============================================================================

$HqBasePromptPath = Join-Path $HqPath "prompts/pure-ralph-base.md"
$ProjectName = (Split-Path (Split-Path $PrdPath -Parent) -Leaf)
$LogDir = Join-Path $HqPath "workspace/orchestrator/$ProjectName"
$LogFile = Join-Path $LogDir "pure-ralph.log"

# .hq/ directory paths in target repo
$HqDir = Join-Path $TargetRepo ".hq"
$RepoPromptPath = Join-Path $HqDir "prompt.md"
$RepoPrdPath = Join-Path $HqDir "prd.json"

# Create log directory
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

# ============================================================================
# Functions
# ============================================================================

function Initialize-HqDirectory {
    # Create .hq directory if missing
    if (-not (Test-Path $HqDir)) {
        Write-Log "Creating .hq directory in target repo"
        New-Item -ItemType Directory -Path $HqDir -Force | Out-Null
    }

    # Copy prompt.md if missing
    if (-not (Test-Path $RepoPromptPath)) {
        Write-Log "Copying prompt template to $RepoPromptPath"
        if (Test-Path $HqBasePromptPath) {
            # Read the base prompt and substitute TARGET_REPO
            $promptContent = Get-Content $HqBasePromptPath -Raw
            $promptContent = $promptContent -replace '\{\{TARGET_REPO\}\}', $TargetRepo
            $promptContent | Out-File -FilePath $RepoPromptPath -Encoding utf8
            Write-Log "Prompt template created at $RepoPromptPath" "SUCCESS"
        } else {
            Write-Log "Base prompt not found at $HqBasePromptPath" "ERROR"
            exit 1
        }
    } else {
        Write-Log "Using existing prompt at $RepoPromptPath"
    }

    # Copy prd.json if missing
    if (-not (Test-Path $RepoPrdPath)) {
        Write-Log "Copying PRD to $RepoPrdPath"
        if (Test-Path $PrdPath) {
            # Read the HQ PRD and add sync_metadata
            $prdContent = Get-Content $PrdPath -Raw | ConvertFrom-Json
            $prdContent | Add-Member -NotePropertyName "sync_metadata" -NotePropertyValue @{
                synced_at = (Get-Date -Format "o")
                synced_from = $PrdPath
                synced_by = "pure-ralph-init"
            } -Force
            $prdContent | ConvertTo-Json -Depth 10 | Out-File -FilePath $RepoPrdPath -Encoding utf8
            Write-Log "PRD copied to $RepoPrdPath" "SUCCESS"
        } else {
            Write-Log "HQ PRD not found at $PrdPath" "ERROR"
            exit 1
        }
    } else {
        Write-Log "Using existing PRD at $RepoPrdPath"
    }
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $entry

    switch ($Level) {
        "ERROR"   { Write-Host $entry -ForegroundColor Red }
        "WARN"    { Write-Host $entry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $entry -ForegroundColor Green }
        default   { Write-Host $entry }
    }
}

function Get-TaskProgress {
    # Read from repo's .hq/prd.json
    $prd = Get-Content $RepoPrdPath -Raw | ConvertFrom-Json
    $total = $prd.features.Count
    $complete = ($prd.features | Where-Object { $_.passes -eq $true }).Count
    return @{ Total = $total; Complete = $complete; Remaining = $total - $complete }
}

function Build-Prompt {
    param([bool]$IsManual)

    # Read prompt from repo's .hq/prompt.md (already has TARGET_REPO substituted)
    # No PRD_PATH substitution needed - prompt references .hq/prd.json directly
    $prompt = Get-Content $RepoPromptPath -Raw

    # In manual mode, add instruction for user to close window
    if ($IsManual) {
        $prompt += @"


---

## IMPORTANT: Manual Mode

When you have completed the task and updated the PRD, output this message:

```
TASK COMPLETE - Please close this window to continue to the next task.
```

Do NOT exit automatically. Wait for the user to close the window.
"@
    }

    return $prompt
}

# ============================================================================
# Main Loop
# ============================================================================

$modeLabel = if ($Manual) { "MANUAL (interactive)" } else { "AUTO (autonomous)" }

Write-Host ""
Write-Host "=== Pure Ralph Loop ===" -ForegroundColor Cyan
Write-Host "PRD: $PrdPath" -ForegroundColor Gray
Write-Host "Target: $TargetRepo" -ForegroundColor Gray
Write-Host "Log: $LogFile" -ForegroundColor Gray
Write-Host "Mode: $modeLabel" -ForegroundColor $(if ($Manual) { "Yellow" } else { "Green" })
Write-Host ""
Write-Host "Same prompt every iteration. Claude picks the task." -ForegroundColor Yellow
Write-Host ""

Write-Log "Pure Ralph Loop started"
Write-Log "PRD: $PrdPath"
Write-Log "Target: $TargetRepo"
Write-Log "Mode: $modeLabel"

# Initialize .hq directory (copy prompt.md and prd.json if missing)
Initialize-HqDirectory

# Build the prompt from .hq/prompt.md (no PRD_PATH substitution needed)
$prompt = Build-Prompt -IsManual $Manual
$promptFile = Join-Path $LogDir "current-prompt.md"
$prompt | Out-File -FilePath $promptFile -Encoding utf8

Write-Log "Prompt built and saved to $promptFile"

$iteration = 0
$maxIterations = 50

while ($iteration -lt $maxIterations) {
    $iteration++

    $progress = Get-TaskProgress

    Write-Host ""
    Write-Host "--- Iteration $iteration ---" -ForegroundColor Cyan
    Write-Log "Iteration $iteration - Progress: $($progress.Complete)/$($progress.Total)"

    # Check if all done
    if ($progress.Remaining -eq 0) {
        Write-Host ""
        Write-Host "=== ALL TASKS COMPLETE ===" -ForegroundColor Green
        Write-Log "All tasks complete!" "SUCCESS"
        break
    }

    Write-Host "Tasks remaining: $($progress.Remaining)" -ForegroundColor Yellow
    Write-Host ""

    if ($Manual) {
        Write-Host "Opening Claude in new window (MANUAL MODE)..." -ForegroundColor Cyan
        Write-Host ">>> Close the window when task completes to continue <<<" -ForegroundColor Yellow
    } else {
        Write-Host "Opening Claude in new window (AUTO MODE)..." -ForegroundColor Cyan
        Write-Host ">>> Window will close automatically when done <<<" -ForegroundColor Green
    }
    Write-Host ""

    Write-Log "Spawning Claude session"

    # Build the Claude command based on mode
    if ($Manual) {
        # Manual mode: interactive TUI, user closes window
        $claudeCmd = @"
cd '$TargetRepo'
Write-Host '=== Pure Ralph Session (MANUAL MODE) ===' -ForegroundColor Cyan
Write-Host 'Reading PRD, picking task, implementing...' -ForegroundColor Gray
Write-Host 'Close this window when done to continue the loop.' -ForegroundColor Yellow
Write-Host ''
claude --permission-mode bypassPermissions (Get-Content '$promptFile' -Raw)
"@
    } else {
        # Auto mode: -p flag, auto-exits
        $claudeCmd = @"
cd '$TargetRepo'
Write-Host '=== Pure Ralph Session (AUTO MODE) ===' -ForegroundColor Cyan
Write-Host 'Reading PRD, picking task, implementing...' -ForegroundColor Gray
Write-Host ''
claude -p --permission-mode bypassPermissions (Get-Content '$promptFile' -Raw)
Write-Host ''
Write-Host 'Session complete. Window closing in 3 seconds...' -ForegroundColor Green
Start-Sleep -Seconds 3
exit
"@
    }

    # Start new window and WAIT for it to close
    $proc = Start-Process powershell -ArgumentList "-Command", $claudeCmd -PassThru

    Write-Host "Waiting for Claude session (PID: $($proc.Id))..." -ForegroundColor Gray
    $proc.WaitForExit()

    Write-Log "Claude session ended"

    # Brief pause before next iteration
    Start-Sleep -Seconds 2
}

if ($iteration -ge $maxIterations) {
    Write-Log "Safety limit reached ($maxIterations iterations)" "WARN"
}

# Final summary
$progress = Get-TaskProgress
Write-Host ""
Write-Host "=== Final Summary ===" -ForegroundColor Cyan
Write-Host "Completed: $($progress.Complete)/$($progress.Total) tasks" -ForegroundColor $(if ($progress.Remaining -eq 0) { "Green" } else { "Yellow" })
Write-Host "Log: $LogFile" -ForegroundColor Gray

Write-Log "Loop ended. Final: $($progress.Complete)/$($progress.Total) complete"
