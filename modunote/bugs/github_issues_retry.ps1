# =============================================================================
# ModuNote — Retry: Create the 4 GitHub issues that failed
# =============================================================================
# Bugs #1, #2, #6, #10 failed because PowerShell mangles embedded
# double-quotes when passing to native commands. This script uses
# --body-file with a temp file to avoid the issue.
# =============================================================================

$ErrorActionPreference = "Stop"

$ghCmd = Get-Command gh -ErrorAction SilentlyContinue
if ($ghCmd) { $gh = $ghCmd.Source }
elseif (Test-Path "C:\Program Files\GitHub CLI\gh.exe") { $gh = "C:\Program Files\GitHub CLI\gh.exe" }
else { Write-Host "[ERROR] gh not found" -ForegroundColor Red; exit 1 }

$script:created = 0
$script:failed  = 0
$tmpFile = Join-Path $env:TEMP "gh_issue_body.md"

function New-GHIssueFromFile {
    param(
        [string]$Title,
        [string]$Body,
        [string[]]$Labels
    )

    $labelArgs = @()
    foreach ($l in $Labels) {
        $labelArgs += "--label"
        $labelArgs += $l
    }

    # Write body to temp file to avoid quote-mangling
    [System.IO.File]::WriteAllText($tmpFile, $Body, [System.Text.Encoding]::UTF8)

    Write-Host "[INFO]  Creating issue: $Title" -ForegroundColor Green
    & $gh issue create --title $Title --body-file $tmpFile @labelArgs
    if ($LASTEXITCODE -eq 0) {
        $script:created++
    } else {
        Write-Host "[WARN]  Failed to create: $Title" -ForegroundColor Yellow
        $script:failed++
    }
    Write-Host ""
}

# =============================================================================
# MED-HIGH — Bug #1
# =============================================================================

$body1 = @"
## Severity: MED-HIGH

### Audio session leaked on nearly every note view

- **Where:** ``lib/presentation/views/note_editor/widgets/voice_panel.dart:56`` + ``lib/presentation/views/note_editor/note_editor_screen.dart:99`` · area: audio, editor
- **Problem:** ``VoicePanel.initState`` calls ``widget.audioService.init()`` (opens the native FlutterSound recorder+player), but the screen's ``dispose()`` closes the service only when ``_audioInitialized`` is true — and that flag is set **only** inside ``_onMicTap``. ``VoicePanel`` never sets it.
- **Failure:** Open an existing note (VoicePanel renders when the keyboard is down), view/play, leave **without recording** → ``dispose()`` skips ``_audioService.dispose()``. Native session leaks on essentially every note view; repeated opens can exhaust sessions ("recorder busy").
- **Fix:** ``AudioRecordingService.dispose()`` is idempotent — drop the ``if (_audioInitialized)`` guard and always ``await _audioService.dispose()``. (Or set ``_audioInitialized = true`` when the panel initialises the shared service.)

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_
"@

New-GHIssueFromFile -Title "Bug #1: Audio session leaked on nearly every note view" `
    -Labels @("bug", "severity: med-high", "area: audio", "area: editor") `
    -Body $body1

# =============================================================================
# MEDIUM — Bug #2
# =============================================================================

$body2 = @"
## Severity: MEDIUM

### Deleting a tag orphans note_tags rows + stale note.tagIds

- **Where:** ``lib/data/datasources/local/daos/tags_dao.dart:69`` (via ``local_tag_repository.dart:117``) · area: data
- **Problem:** ``deleteTag(id)`` deletes only the ``tags`` row — not the ``note_tags`` join rows, and it doesn't refresh the denormalised ``note.tagIds`` JSON. No FK / ``ON DELETE CASCADE``; ``foreign_keys`` PRAGMA off. Contract (``i_tag_repository.dart``) says delete "removes all its note associations."
- **Failure:** Delete a tag still attached to notes → tag row gone, but ``tagIds`` + ``note_tags`` rows linger forever. ``findById`` returns null while ``watchByTag``/``countNotesPerTag`` still see the notes. Re-creating the tag mints a new UUID → dangling rows never reconnect. (UI degrades gracefully — unresolved ids are dropped from display.)
- **Fix:** In ``TagsDao.deleteTag``, transaction: delete ``note_tags WHERE tag_id = id``, re-sync ``tagIds`` for affected notes, then delete the tag row. **Design choice to confirm:** transactional cascade (matches codebase style) vs enabling SQLite FK cascade (bigger schema change, still needs the ``tagIds`` refresh) — recommend transactional.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_
"@

New-GHIssueFromFile -Title "Bug #2: Deleting a tag orphans note_tags rows + stale note.tagIds" `
    -Labels @("bug", "severity: medium", "area: data") `
    -Body $body2

# =============================================================================
# MEDIUM — Bug #6
# =============================================================================

$body6 = @"
## Severity: MEDIUM

### setState after await without mounted guard in _onMicTap / _stopRecording

- **Where:** ``note_editor_screen.dart`` — ``_onMicTap`` (~:509-519), ``_stopRecording`` (~:537-545) · area: editor
- **Problem:** ``setState`` (and in ``_onMicTap`` the new ``_amplitudeSubscription`` + ``_recordTimer``) run after multi-``await`` chains with no ``mounted`` guard — inconsistent with the guarded ``setState`` later in ``_stopRecording``.
- **Failure:** System-back during mic start/stop await → ``setState`` on an unmounted state ("setState after dispose"); a fresh amplitude subscription created post-dispose leaks.
- **Fix:** ``if (!mounted) { <cleanup>; return; }`` (or ``if (mounted) setState(...)``).

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_
"@

New-GHIssueFromFile -Title "Bug #6: setState after await without mounted guard in _onMicTap / _stopRecording" `
    -Labels @("bug", "severity: medium", "area: editor") `
    -Body $body6

# =============================================================================
# LOW — Bug #10
# =============================================================================

$body10 = @"
## Severity: LOW

### FTS search sanitiser misses ' ^ . → invalid MATCH → error instead of empty

- **Where:** ``notes_dao.dart:106-110`` · area: data
- **Problem:** Strips ``" ( ) - + * : ,`` but not ``'``, ``^``, ``.``. A query of only those builds an invalid FTS5 MATCH.
- **Failure:** Searching ``.`` / ``^`` raises an FTS5 syntax error → re-wrapped as ``DatabaseException`` → error toast instead of "no results".
- **Fix:** Extend the strip regex (``' ^ .``), or return ``[]`` on a degenerate token set.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_
"@

New-GHIssueFromFile -Title "Bug #10: FTS search sanitiser misses chars that cause invalid MATCH" `
    -Labels @("bug", "severity: low", "area: data") `
    -Body $body10

# ---------------------------------------------------------------------------
# Cleanup & Summary
# ---------------------------------------------------------------------------
if (Test-Path $tmpFile) { Remove-Item $tmpFile -Force }

Write-Host "============================================="
Write-Host "[INFO]  Done! Created: $($script:created) | Failed: $($script:failed)" -ForegroundColor Green
Write-Host "============================================="

if ($script:failed -gt 0) {
    Write-Host "[WARN]  Some issues failed to create. Check output above." -ForegroundColor Yellow
    exit 1
}
