#!/usr/bin/env bash
# =============================================================================
# ModuNote — Create GitHub Issues from BUGS.md
# =============================================================================
# Usage:  bash modunote/bugs/github_issues.sh
# Prereq: gh auth login (GitHub CLI authenticated)
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Colour helpers (safe for non-tty)
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
if ! command -v gh &> /dev/null; then
    error "GitHub CLI (gh) is not installed."
    echo "  Install: https://cli.github.com/"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    error "GitHub CLI is not authenticated. Run 'gh auth login' first."
    exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || true)
if [[ -z "$REPO" ]]; then
    error "Could not detect repository. Run this from inside the ModuNote git repo."
    exit 1
fi

info "Creating issues in repository: $REPO"
echo ""

# ---------------------------------------------------------------------------
# Ensure labels exist (created idempotently)
# ---------------------------------------------------------------------------
declare -a LABELS=(
    "bug"
    "severity: med-high"
    "severity: medium"
    "severity: low"
    "area: audio"
    "area: editor"
    "area: data"
    "area: viewmodel"
    "area: view"
)

LABEL_COLORS=(
    "d73a4a"
    "e36209"
    "fbca04"
    "0e8a16"
    "5319e7"
    "006b75"
    "1d76db"
    "b60205"
    "c5def5"
)

info "Ensuring labels exist..."
for i in "${!LABELS[@]}"; do
    label="${LABELS[$i]}"
    color="${LABEL_COLORS[$i]}"
    gh label create "$label" --color "$color" --force 2>/dev/null || true
done
info "Labels ready."
echo ""

# ---------------------------------------------------------------------------
# Counter
# ---------------------------------------------------------------------------
CREATED=0
FAILED=0

create_issue() {
    local title="$1"
    local body="$2"
    shift 2
    local labels=("$@")

    # Build the label flags
    local label_args=()
    for lbl in "${labels[@]}"; do
        label_args+=(--label "$lbl")
    done

    info "Creating issue: $title"
    if gh issue create \
        --title "$title" \
        --body "$body" \
        "${label_args[@]}"; then
        ((CREATED++))
    else
        warn "Failed to create: $title"
        ((FAILED++))
    fi
    echo ""
}

# =============================================================================
# MED-HIGH — Bug #1
# =============================================================================

create_issue \
    "Bug #1: Audio session leaked on nearly every note view" \
    "## Severity: MED-HIGH

### Audio session leaked on nearly every note view

- **Where:** \`lib/presentation/views/note_editor/widgets/voice_panel.dart:56\` + \`lib/presentation/views/note_editor/note_editor_screen.dart:99\` · area: audio, editor
- **Problem:** \`VoicePanel.initState\` calls \`widget.audioService.init()\` (opens the native FlutterSound recorder+player), but the screen's \`dispose()\` closes the service only when \`_audioInitialized\` is true — and that flag is set **only** inside \`_onMicTap\`. \`VoicePanel\` never sets it.
- **Failure:** Open an existing note (VoicePanel renders when the keyboard is down), view/play, leave **without recording** → \`dispose()\` skips \`_audioService.dispose()\`. Native session leaks on essentially every note view; repeated opens can exhaust sessions (\"recorder busy\").
- **Fix:** \`AudioRecordingService.dispose()\` is idempotent — drop the \`if (_audioInitialized)\` guard and always \`await _audioService.dispose()\`. (Or set \`_audioInitialized = true\` when the panel initialises the shared service.)

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: med-high" "area: audio" "area: editor"

# =============================================================================
# MEDIUM — Bug #2
# =============================================================================

create_issue \
    "Bug #2: Deleting a tag orphans note_tags rows + stale note.tagIds" \
    "## Severity: MEDIUM

### Deleting a tag orphans note_tags rows + stale note.tagIds

- **Where:** \`lib/data/datasources/local/daos/tags_dao.dart:69\` (via \`local_tag_repository.dart:117\`) · area: data
- **Problem:** \`deleteTag(id)\` deletes only the \`tags\` row — not the \`note_tags\` join rows, and it doesn't refresh the denormalised \`note.tagIds\` JSON. No FK / \`ON DELETE CASCADE\`; \`foreign_keys\` PRAGMA off. Contract (\`i_tag_repository.dart\`) says delete \"removes all its note associations.\"
- **Failure:** Delete a tag still attached to notes → tag row gone, but \`tagIds\` + \`note_tags\` rows linger forever. \`findById\` returns null while \`watchByTag\`/\`countNotesPerTag\` still see the notes. Re-creating the tag mints a new UUID → dangling rows never reconnect. (UI degrades gracefully — unresolved ids are dropped from display.)
- **Fix:** In \`TagsDao.deleteTag\`, transaction: delete \`note_tags WHERE tag_id = id\`, re-sync \`tagIds\` for affected notes, then delete the tag row. **Design choice to confirm:** transactional cascade (matches codebase style) vs enabling SQLite FK cascade (bigger schema change, still needs the \`tagIds\` refresh) — recommend transactional.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: medium" "area: data"

# =============================================================================
# MEDIUM — Bug #3
# =============================================================================

create_issue \
    "Bug #3: NoteEditorViewModel.save() drops note value during write → concurrent edit lost" \
    "## Severity: MEDIUM

### NoteEditorViewModel.save() drops note value during write → concurrent edit lost

- **Where:** \`lib/presentation/viewmodels/note_editor_view_model.dart:23\` · area: viewmodel
- **Problem:** \`save()\` sets \`state = const AsyncLoading();\` (bare, no \`copyWithPrevious\`), so \`state.valueOrNull\` is \`null\` for the whole insert/update await window.
- **Failure:** \`addTag\`/\`removeTag\`/\`setCategory\`/\`togglePin\` each early-return when \`state.valueOrNull == null\`. If one fires while an autosave is in flight (tap a tag chip as the 800 ms debounce fires) → silent no-op, edit dropped.
- **Fix:** \`state = const AsyncLoading<Note?>().copyWithPrevious(state);\` or serialise edits against the in-flight save.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: medium" "area: viewmodel"

# =============================================================================
# MEDIUM — Bug #4
# =============================================================================

create_issue \
    "Bug #4: Mutation errors clobber stream-backed list state (whole list vanishes)" \
    "## Severity: MEDIUM

### Mutation errors clobber stream-backed list state (whole list vanishes)

- **Where:** \`note_list_view_model.dart\` (+ \`category_tree_view_model.dart\`, \`archived_notes_view_model.dart\`, \`audio_editor_view_model.dart\`) · area: viewmodel
- **Problem:** Mutation methods on Stream-backed notifiers set \`state = AsyncError(e, st)\` on failure, replacing the whole streamed list. The failed op made no DB change → no re-emission restores it.
- **Failure:** A failed \`togglePin\`/\`archive\`/\`delete\`/\`move\` makes the entire list vanish into a full-screen error until an unrelated DB change fires.
- **Fix:** Surface mutation errors via return value / toast (as \`TagListViewModel.insert\` rethrows), leaving list state intact.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: medium" "area: viewmodel"

# =============================================================================
# MEDIUM — Bug #5
# =============================================================================

create_issue \
    "Bug #5: Home long-press actions sheet occluded by floating nav (missing useRootNavigator)" \
    "## Severity: MEDIUM

### Home long-press actions sheet occluded by floating nav (missing useRootNavigator)

- **Where:** \`lib/presentation/views/note_list/widgets/swipeable_note_card.dart:26\` (\`_showActionsSheet\`) · area: view
- **Problem:** \`showModalBottomSheet\` omits \`useRootNavigator: true\`. On Home (ShellRoute nested navigator) the floating \`BottomBar\`/FAB is drawn outside that navigator, so the sheet is occluded. Sibling account sheet + RAG picker set it; this one was missed.
- **Failure:** Long-press a Home note → the sheet's bottom rows sit under the nav pill/FAB, partly unreachable. (Fine on the full-screen Archive route.)
- **Fix:** Add \`useRootNavigator: true\`.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: medium" "area: view"

# =============================================================================
# MEDIUM — Bug #6
# =============================================================================

create_issue \
    "Bug #6: setState after await without mounted guard in _onMicTap / _stopRecording" \
    "## Severity: MEDIUM

### setState after await without mounted guard in _onMicTap / _stopRecording

- **Where:** \`note_editor_screen.dart\` — \`_onMicTap\` (~:509-519), \`_stopRecording\` (~:537-545) · area: editor
- **Problem:** \`setState\` (and in \`_onMicTap\` the new \`_amplitudeSubscription\` + \`_recordTimer\`) run after multi-\`await\` chains with no \`mounted\` guard — inconsistent with the guarded \`setState\` later in \`_stopRecording\`.
- **Failure:** System-back during mic start/stop await → \`setState\` on an unmounted state (\"setState after dispose\"); a fresh amplitude subscription created post-dispose leaks.
- **Fix:** \`if (!mounted) { <cleanup>; return; }\` (or \`if (mounted) setState(...)\`).

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: medium" "area: editor"

# =============================================================================
# MEDIUM — Bug #7
# =============================================================================

create_issue \
    "Bug #7: addTag/removeTag/togglePin: no ref.mounted guard + findById null → AsyncData(null)" \
    "## Severity: MEDIUM

### addTag/removeTag/togglePin: no ref.mounted guard + findById null → AsyncData(null)

- **Where:** \`note_editor_view_model.dart:57,69,99\` · area: viewmodel
- **Problem:** After \`await ... .findById(...)\`, \`state = AsyncData(updated)\` runs with no \`ref.mounted\` check, and \`findById\` returns \`Note?\` (may be null).
- **Failure:** (a) Editor popped during await → writing \`state\` throws \`StateError\` (masked only by the screen's \`catch (_) {}\`). (b) A concurrently-deleted note → \`findById\` null → \`state = AsyncData(null)\` blanks the VM.
- **Fix:** \`if (!ref.mounted) return;\` before the write; handle the null result explicitly instead of storing \`AsyncData(null)\`.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: medium" "area: viewmodel"

# =============================================================================
# LOW — Bug #8
# =============================================================================

create_issue \
    "Bug #8: Category max nesting depth off-by-one (caps at 4, docs say 5)" \
    "## Severity: LOW

### Category max nesting depth off-by-one (caps at 4, docs say 5)

- **Where:** \`lib/data/repositories/local/local_category_repository.dart:215-227\` (\`_assertDepthAllowed\`) · area: data · **verified**
- **Problem:** \`depth\` starts at 1 and the loop also increments for \`parentId\`, so computed depth = actualParentDepth + 1; the \`depth >= 5\` guard fires one level early.
- **Failure:** Inserting a legitimate depth-5 node (child under a depth-4 category) throws. Effective usable nesting = 4.
- **Fix:** Start \`depth = 0\`, or guard on \`depth > _maxDepth\`. Add a depth-5-chain unit test.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: low" "area: data"

# =============================================================================
# LOW — Bug #9
# =============================================================================

create_issue \
    "Bug #9: SyncedNoteRepository.update doesn't set pending → skipped by syncAllPending" \
    "## Severity: LOW

### SyncedNoteRepository.update doesn't set pending → skipped by syncAllPending

- **Where:** \`synced_note_repository.dart:52\` + \`note_editor_view_model.dart:90\` · area: data
- **Problem:** \`update\` delegates to local without setting \`syncStatus = pending\`; the editor's save preserves the status. Editing a \`synced\` note leaves it \`synced\`, so \`syncAllPending()\` (filters \`!= synced\`) skips it.
- **Failure:** Edit a synced note, background the app without hitting back (the back path syncs explicitly) → edit never pushed to Firestore.
- **Fix:** \`SyncedNoteRepository.update\` persists with \`syncStatus: pending\`.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: low" "area: data"

# =============================================================================
# LOW — Bug #10
# =============================================================================

create_issue \
    "Bug #10: FTS search sanitiser misses ' ^ . → invalid MATCH → error instead of empty" \
    "## Severity: LOW

### FTS search sanitiser misses ' ^ . → invalid MATCH → error instead of empty

- **Where:** \`notes_dao.dart:106-110\` · area: data
- **Problem:** Strips \`\" ( ) - + * : ,\` but not \`'\`, \`^\`, \`.\`. A query of only those builds an invalid FTS5 MATCH.
- **Failure:** Searching \`.\` / \`^\` raises an FTS5 syntax error → re-wrapped as \`DatabaseException\` → error toast instead of \"no results\".
- **Fix:** Extend the strip regex (\`' ^ .\`), or return \`[]\` on a degenerate token set.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: low" "area: data"

# =============================================================================
# LOW — Bug #11
# =============================================================================

create_issue \
    "Bug #11: ViewModel catch clauses only catch AppException → non-AppException escapes" \
    "## Severity: LOW

### ViewModel catch clauses only catch AppException → non-AppException escapes

- **Where:** \`note_editor_view_model.dart:33,58,70,100\` and other VMs · area: viewmodel
- **Problem:** \`on AppException\` only — a raw \`StateError\` / un-wrapped platform/Drift/Firestore error escapes as an unhandled async error. Relies on every repo wrapping perfectly.
- **Fix:** Trailing \`catch (e, st) { state = AsyncError(e, st); }\` (or deliberate rethrow).

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: low" "area: viewmodel"

# =============================================================================
# LOW — Bug #12
# =============================================================================

create_issue \
    "Bug #12: _performAutoSave / _onBack: ref.read after await without mounted guard" \
    "## Severity: LOW

### _performAutoSave / _onBack: ref.read after await without mounted guard

- **Where:** \`note_editor_screen.dart\` — \`_performAutoSave\` (~:197-206), \`_onBack\` (~:692-707) · area: editor
- **Problem:** Post-await \`ref.read(...)\` (state check, \`_scheduleRagSync\`, \`pruneOrphans\`) with no \`mounted\` guard. Reading an auto-dispose provider after dispose re-initialises it; a disposed-ref read can throw \`StateError\`.
- **Failure:** System-back during a slow \`syncNote\` await → continuation \`ref.read\` on a disposed ref.
- **Fix:** \`if (!mounted) return;\` before the post-await block, or capture providers/services into locals before the await.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: low" "area: editor"

# =============================================================================
# LOW — Bug #13
# =============================================================================

create_issue \
    "Bug #13: Partial recording start leak: startListening throws after startRecording succeeds" \
    "## Severity: LOW

### Partial recording start leak: startListening throws after startRecording succeeds

- **Where:** \`note_editor_screen.dart:490-512\` (\`_onMicTap\`) · area: audio, editor
- **Problem:** \`startListening\`/amplitude-subscribe have no try/catch. If \`startRecording\` succeeds but \`startListening\` throws, the recorder is left running with no stop path (\`_isRecording\` never true → no overlay/stop button).
- **Failure:** Recognizer fails after the recorder started → orphaned recording; next mic tap overwrites \`_currentRecordingPath\` and starts a second recorder → error.
- **Fix:** Wrap \`startListening\`/subscribe in try/catch that calls \`_audioService.stopRecording()\` and resets \`_currentRecordingPath\` on failure.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: low" "area: audio" "area: editor"

# =============================================================================
# LOW — Bug #14
# =============================================================================

create_issue \
    "Bug #14: AudioRecordingService.onProgress subscription never cancelled" \
    "## Severity: LOW

### AudioRecordingService.onProgress subscription never cancelled

- **Where:** \`lib/services/audio/audio_recording_service.dart:71-77\` · area: audio
- **Problem:** \`_recorder.onProgress!.listen(...)\` is never stored/cancelled; a new listener is added on every \`startRecording\`.
- **Failure:** Record/stop cycles stack up listeners until service dispose (harmless output, growing leak).
- **Fix:** Store the \`StreamSubscription\`; cancel in \`stopRecording\` + \`dispose\`.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: low" "area: audio"

# =============================================================================
# LOW — Bug #15
# =============================================================================

create_issue \
    "Bug #15: RagIndexTags / audio_pref cold-start load race can clobber user edits" \
    "## Severity: LOW

### RagIndexTags / audio_pref cold-start load race can clobble user edits

- **Where:** \`rag_settings_view_model.dart:20-30\` (+ \`audio_pref_view_model.dart:14-24\`) · area: viewmodel
- **Problem:** \`build()\` returns the default synchronously and fires \`_load()\` async, which does an unconditional \`state = saved.toSet()\`. During the load window the value is the DEFAULT, not persisted; a late \`_load\` can overwrite an \`addTag\`/\`removeTag\` that raced it.
- **Failure:** Practically unreachable (\`keepAlive\` + ms prefs read vs seconds of user navigation) — latent correctness issue.
- **Fix:** Make the provider \`Future<Set<String>>\` (async build), or only apply the persisted value while \`state\` still equals the default.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: low" "area: viewmodel"

# =============================================================================
# LOW — Bug #16
# =============================================================================

create_issue \
    "Bug #16: Debounce not cancelled before archive → narrow un-archive window" \
    "## Severity: LOW

### Debounce not cancelled before archive → narrow un-archive window

- **Where:** \`note_editor_screen.dart\` — archive path (~:626-635) · area: editor
- **Problem:** \`onArchive\` doesn't cancel the pending 800 ms debounce, and \`_currentNote\` isn't updated to archived. If the timer fires during \`await archive(id)\` before \`context.pop()\` (whose dispose cancels it), \`_performAutoSave\` writes back \`isArchived: false\` → un-archives.
- **Failure:** Edit then archive within the debounce window, if the archive await outlasts the remaining debounce → note re-appears in the main list. (The delete \"resurrect\" is NOT reachable — update of a deleted row is a 0-row no-op.)
- **Fix:** \`_debounce?.cancel(); _isDirty = false;\` at the start of archive; refresh \`_currentNote\` from VM state after archiving.

---
_Source: BUGS.md · Origin: 2026-07-18 four-agent audit_" \
    "bug" "severity: low" "area: editor"

# =============================================================================
# Summary
# =============================================================================

echo "============================================="
info "Done! Created: $CREATED | Failed: $FAILED"
echo "============================================="

if [[ $FAILED -gt 0 ]]; then
    warn "Some issues failed to create. Check output above."
    exit 1
fi
