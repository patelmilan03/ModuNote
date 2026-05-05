# ModuNote — Manual Testing Guide
> Covers Phases 1–6 (all shipped code). Each check is a pass/fail statement.
> Run in order. Checks marked **🔴 CRITICAL** must pass before committing.
> Checks marked **⚠️ KNOWN STUB** are intentional placeholders for a future phase — verify the placeholder renders, then skip.

---

## Pre-Test Setup

Before running any tests, complete these steps every time:

```bash
# 1. Generate code (required after any Phase 6+ change)
dart run build_runner build --delete-conflicting-outputs

# 2. Verify zero static issues
flutter analyze

# 3. Launch on a physical Android device (or Pixel emulator API 33+)
flutter run
```

**Required device state:**
- App is freshly installed **OR** the existing install's DB has been wiped (`flutter clean` + reinstall) for the "first launch" checks
- Device language: English
- Microphone permission not yet granted (for permission-flow checks)

---

## 1 — App Bootstrap

| # | Check | Expected |
|---|---|---|
| 1.1 | App launches without crash | NoteListScreen appears |
| 1.2 | No red error banners or `Exception` text on screen | Screen renders cleanly |
| 1.3 | On first launch with empty DB: empty state is shown | Icon + "No notes yet" + "Tap + to capture your first idea." text visible |
| 1.4 | App bar shows today's weekday in uppercase (e.g. `TUESDAY`) | Correct day of week shown |
| 1.5 | App bar shows `"Your notes"` title in bold | Title uses Plus Jakarta Sans weight 800 |
| 1.6 | Avatar circle in top-right shows `"MA"` initials on a gradient | Indigo→amber gradient circle |
| 1.7 | Theme follows device OS setting (light or dark) by default | Background matches OS theme |

---

## 2 — Note List Screen

### 2A — Layout & Navigation Bar

| # | Check | Expected |
|---|---|---|
| 2.1 🔴 | Floating bottom nav visible at bottom of screen | Pill-shaped container, 4 icons, card background |
| 2.2 | Home tab icon is filled/active (article icon solid) | Home icon filled, highlighted with `primaryContainer` circle |
| 2.3 | Explore tab icon is outlined (unfilled) | Outlined icon, no background highlight |
| 2.4 | Tags tab icon is outlined | Outlined icon |
| 2.5 | Settings tab icon is outlined | Outlined icon |
| 2.6 | Bottom nav has rounded pill shape (br 32) and subtle border | Not a square; `outlineVariant` border |
| 2.7 | Tapping Explore navigates to Search screen | SearchScreen appears |
| 2.8 | Tapping Tags navigates to Tags screen | TagsScreen appears (stub) |
| 2.9 | Tapping Settings navigates to Settings screen | SettingsScreen appears (stub) |
| 2.10 | Tapping Home on any other tab returns to NoteListScreen | Home screen appears |

### 2B — Search Field

| # | Check | Expected |
|---|---|---|
| 2.11 🔴 | Search field visible below app bar | Rounded container with search icon and hint "Search notes…" |
| 2.12 | Tapping the search field navigates to SearchScreen | Does NOT open keyboard on home screen; routes to `/search` |

### 2C — FAB

| # | Check | Expected |
|---|---|---|
| 2.13 🔴 | Amber FAB visible above bottom nav, right side | Amber square with rounded corners (br 18), `+` icon |
| 2.14 | FAB has amber glow shadow | Subtle shadow under FAB |
| 2.15 🔴 | Tapping FAB opens NoteEditorScreen | Editor appears with empty title + empty body |

### 2D — Loading State

| # | Check | Expected |
|---|---|---|
| 2.16 | On a slow/cold DB open: skeleton placeholders pulse | 3 grey boxes pulsing in opacity (0.35→0.65 oscillation at 800 ms) |

### 2E — Error State

| # | Check | Expected |
|---|---|---|
| 2.17 | If DB load fails: error body visible | Error icon + "Could not load notes" + "Retry" button |
| 2.18 | Tapping Retry invalidates the provider and reloads | Screen transitions back to loading → then data |

---

## 3 — Note Creation & Auto-Save

| # | Check | Expected |
|---|---|---|
| 3.1 🔴 | Tap FAB → editor opens, cursor in body (auto-focused) | Keyboard appears in body area |
| 3.2 | Title field shows "Title…" placeholder | Muted placeholder text |
| 3.3 | Save badge shows neutral dot + "Saving…" after any keystroke | Badge changes within 1 second of first keystroke |
| 3.4 🔴 | 800 ms after last keystroke, save badge shows green dot + "Saved" | Badge changes to green "Saved" automatically |
| 3.5 🔴 | Press back → note appears in note list | Card shows title and content preview |
| 3.6 | Note with no title shows "Untitled" on the card | `Untitled` displayed in card header |
| 3.7 | Note with empty body shows no preview line on card | Card height is shorter with no preview text |
| 3.8 | Note card timestamp shows "Just now" immediately after creation | Timestamp reads "Just now" |
| 3.9 🔴 | Reopen the note → previously typed content is restored exactly | Title and body match what was typed |

---

## 4 — Note Editor Screen

### 4A — App Bar

| # | Check | Expected |
|---|---|---|
| 4.1 | Back arrow button (←) is present in top-left | Circle icon button |
| 4.2 | Title field is editable inline in the app bar row | Typing changes the title |
| 4.3 | Three-dot overflow menu button is present in top-right | Tapping it does nothing (stub, phase 5) |
| 4.4 | Save badge sits between title and overflow button | Shows "Saved" / "Saving…" state |

### 4B — Rich Text Toolbar (9 buttons)

| # | Check | Expected |
|---|---|---|
| 4.5 🔴 | Toolbar visible above the keyboard | 9 buttons in a row: B, I, U, H1, H2, •, 1., ☑, " |
| 4.6 🔴 | Selecting text and tapping B applies **bold**; text appears bold | Bold applied to selection |
| 4.7 | Tapping B again while bold is selected removes bold | Bold removed |
| 4.8 🔴 | Tapping I applies *italic* to selection | Italic applied |
| 4.9 | Tapping U applies underline to selection | Underline applied |
| 4.10 | Tapping H1 makes the current paragraph a heading 1 | Heading 1 font applied |
| 4.11 | Tapping H2 makes the current paragraph a heading 2 | Heading 2 font applied |
| 4.12 | Tapping H1 again while active removes the heading | Paragraph returns to normal |
| 4.13 | Tapping • creates a bullet list | Bullet point appears |
| 4.14 | Tapping 1. creates an ordered (numbered) list | Number `1.` appears |
| 4.15 | Tapping ☑ creates a checklist item | Checkbox appears unchecked |
| 4.16 | Tapping " creates a blockquote | Blockquote formatting applied |
| 4.17 🔴 | Active toolbar button shows `primaryContainer` background highlight | Active button visually differs from inactive |
| 4.18 | Toolbar button highlight updates when cursor moves into already-formatted text | Moving cursor into bold text highlights B button |
| 4.19 | Toolbar background is card-colored with top separator line | Distinct from editor body background |

### 4C — Tag Row

| # | Check | Expected |
|---|---|---|
| 4.20 🔴 | Tag row visible between editor body and toolbar | Row with "No category" chip, "+ tag" chip, mic button |
| 4.21 | "No category" chip is present and tappable | Shows folder icon + "No category" + chevron |
| 4.22 ⚠️ KNOWN STUB | Tapping "No category" opens bottom sheet | Sheet shows "Category picker — Phase 8" text |
| 4.23 | "+ tag" chip is outlined (no fill) | Dashed/outlined border style |
| 4.24 🔴 | Tapping "+ tag" → dialog appears for tag input | AlertDialog with text field and Add/Cancel buttons |
| 4.25 | Typing "photography" and tapping Add → tag chip appears in row | `#photography` chip appears in the tag row |
| 4.26 | Tag name is stored lowercase even if typed with uppercase | "Photography" stored as `#photography` |
| 4.27 | Tapping the × on a tag chip removes it from the note | Chip disappears from row |
| 4.28 | Removed tag no longer shows on the note card in the list | List card updated correctly |
| 4.29 | Adding a tag to a new (unsaved) note auto-saves first | Note is persisted before tag is attached |

### 4D — Note Card Preview on List

| # | Check | Expected |
|---|---|---|
| 4.30 | Note card shows up to 3 tag chips with `#name` format | Max 3 shown, prefixed with # |
| 4.31 | Note card shows content preview truncated to 1 line with ellipsis | Long preview text cut off at end of line |
| 4.32 | Note card uses Plus Jakarta Sans 700 for title | Heading font applied |

---

## 5 — Note List — Pinning & Sections

> To pin a note: open it in the editor. The `isPinned` field is not yet exposed in UI (Phase 5 stub). Manually insert a pinned note via a fresh install if needed, or test this by directly examining DB state. Skip 5.1–5.4 if no pin toggle is available in the current build.

| # | Check | Expected |
|---|---|---|
| 5.1 | Pinned notes appear in "PINNED" section above "RECENT" | PINNED section header with count badge |
| 5.2 | PINNED section header shows the count of pinned notes | e.g. `PINNED  ─────  2` |
| 5.3 | Pinned note card has amber/gold tint background (light mode) | Light gold `#FFF4D6` background |
| 5.4 | Pinned note card shows push-pin icon (amber) in top-left | `Icons.push_pin` in accent color |
| 5.5 | RECENT section shows only non-pinned notes | No pinned notes appear in Recent |
| 5.6 | Both sections sort by `updatedAt` descending | Most recently edited note at top |
| 5.7 | If only Recent notes exist, PINNED section header is hidden | No empty section header shown |
| 5.8 | If only Pinned notes exist, RECENT section header is hidden | Same |

---

## 6 — Search Screen

| # | Check | Expected |
|---|---|---|
| 6.1 🔴 | Bottom nav shows Explore tab as active | Filled explore icon with primaryContainer highlight |
| 6.2 🔴 | Keyboard auto-focuses search field on navigation | Keyboard appears without requiring a tap |
| 6.3 🔴 | Empty state shows search icon + "Search your notes" + hint text | Visible before any query is typed |
| 6.4 🔴 | Typing a word that matches a note title returns results | Note cards appear within 300 ms of typing |
| 6.5 | Typing a word that matches body content returns results | FTS5 searches both title and content |
| 6.6 | Typing a non-matching query shows "No results for…" state | Message includes the typed query |
| 6.7 | Tapping a result card opens that note in the editor | Editor appears with the note's content |
| 6.8 | Back button in search bar returns to previous screen | Note list or previous screen appears |
| 6.9 | Clear (×) button appears in search field when text is present | Tapping × clears the field and shows empty state |
| 6.10 | Search is debounced — no flickering on fast typing | Results appear smoothly, not on every keypress |
| 6.11 | Archived notes do NOT appear in search results | Only non-archived notes returned |

---

## 7 — Voice Recording (Phase 6)

### 7A — Permission Flow

| # | Check | Expected |
|---|---|---|
| 7.1 🔴 | **Fresh install, first mic tap**: OS dialog requesting microphone permission appears | Android permission dialog shown |
| 7.2 🔴 | Granting permission → recording starts immediately | No crash; recording overlay appears |
| 7.3 🔴 | **Repeat: deny permission on fresh install**: SnackBar shows | "Microphone permission denied" snackbar, no crash |
| 7.4 | After denying, tapping mic again → permission re-requested | OS dialog re-shown OR SnackBar again (depends on device settings) |

### 7B — Recording Start

| # | Check | Expected |
|---|---|---|
| 7.5 🔴 | Tapping mic button → recording overlay slides up above toolbar | Overlay appears with red border and red glow |
| 7.6 🔴 | Mic button in tag row changes to red square (stop icon) while recording | Red background, white square inside |
| 7.7 🔴 | Timer in overlay counts up: `00:00` → `00:01` → `00:02`… | Timer increments every second |
| 7.8 | "Recording" label in overlay is red | Uses `recordRed` color token |
| 7.9 🔴 | Waveform bars animate while speaking | Bars grow/shrink in response to voice amplitude |
| 7.10 | Waveform bars are red | Same `recordRed` color as label |
| 7.11 | Bars show only minimum height in silence | Small bars at rest height (~4 dp) |
| 7.12 | Stop button pulses (scales 0.95→1.05) continuously | Smooth pulsing animation at ~800 ms cycle |
| 7.13 | Overlay has card background with 1px red border | White/dark card color, `#E5484D` border |

### 7C — Live Transcription

| # | Check | Expected |
|---|---|---|
| 7.14 🔴 | Speaking while recording → live transcript text appears below timer | Partial words appear in overlay |
| 7.15 | Transcript preview is single-line with ellipsis if long | No wrapping; cuts with `…` |
| 7.16 | Transcript preview uses muted color (Inter 11.5/w400) | Lighter grey text |
| 7.17 | Transcript preview only shown when non-empty | No empty space when silent |

### 7D — Android STT Timeout Recovery

| # | Check | Expected |
|---|---|---|
| 7.18 | After 8+ seconds of silence, transcription resumes when you speak again | STT does not permanently stop; auto-restarts |
| 7.19 | Timer continues counting even during STT restart | Timer unaffected by STT internals |

### 7E — Stop Recording

| # | Check | Expected |
|---|---|---|
| 7.20 🔴 | Tapping the stop button → overlay disappears | Recording overlay hidden |
| 7.21 🔴 | Mic button returns to its default state (mic icon, primary color) | No longer red |
| 7.22 🔴 | Transcript text is inserted at the Quill cursor position | Text appears in body with newlines before and after |
| 7.23 | If no speech detected, nothing is inserted into the editor | Body unchanged |
| 7.24 🔴 | Audio clip chip appears above the tag row | Compact chip with play icon + duration (e.g. `0:08`) |
| 7.25 | Chip has rounded-pill shape (br 999), surfaceContainer background | Matches design spec |

### 7F — Audio Clip Chips

| # | Check | Expected |
|---|---|---|
| 7.26 🔴 | Tapping play icon on chip → audio plays back | Device speaker plays the recording |
| 7.27 | Play icon changes to pause icon while playing | Icon toggles |
| 7.28 | Tapping pause → playback stops | Silence; icon returns to play |
| 7.29 | Playback ends naturally → chip returns to play icon | Auto-reset after clip ends |
| 7.30 | Tapping × on chip → chip disappears | Removed from row immediately |
| 7.31 🔴 | Close and reopen the note → audio chip is still there | Persisted in Drift DB; reloaded on open |
| 7.32 | Recording twice → two chips appear side by side | Horizontal scroll row with both clips |
| 7.33 | Tapping play on a second chip while first is playing → first stops, second plays | Only one clip plays at a time |

### 7G — Recording Edge Cases

| # | Check | Expected |
|---|---|---|
| 7.34 | Recording on a new (unsaved) note: note is auto-saved first before recording starts | Recording does not fail with a null note ID |
| 7.35 | Navigating away mid-recording: no crash | Recording services disposed cleanly in `dispose()` |

---

## 8 — Data Persistence

| # | Check | Expected |
|---|---|---|
| 8.1 🔴 | Create a note, force-kill the app, relaunch → note still exists | Drift persists to SQLite on device |
| 8.2 🔴 | Edit a note's title, navigate away, return → new title shown in list and editor | Auto-save committed to DB |
| 8.3 🔴 | Add a tag to a note, force-kill, relaunch → tag still on note | Tag persisted in `note_tags` join table + `tagIds` denorm column |
| 8.4 🔴 | Record audio on a note, force-kill, relaunch → chip still visible | `AudioRecord` persisted in Drift |
| 8.5 | Delete an audio clip chip, force-kill, relaunch → chip still gone | File + DB row both deleted |
| 8.6 | Create many notes (10+) → list shows all of them | No DB pagination limit hit |

---

## 9 — Theme (Light / Dark)

| # | Check | Expected |
|---|---|---|
| 9.1 | With device in light mode: background is near-white `#FEFBFF` | Not pure white |
| 9.2 | With device in dark mode: background is `#1C1B2E` (dark navy) | Not pure black |
| 9.3 | Note card in light mode: white card with subtle border | `#FFFFFF` background |
| 9.4 | Note card in dark mode: dark card `#232238` | Slightly lighter than background |
| 9.5 | Primary accent (FAB, active nav) is `#5B4EFF` purple in light mode | Indigo-violet |
| 9.6 | Primary accent is `#B7AFFF` soft lavender in dark mode | Lighter variant |
| 9.7 | FAB is amber `#F59E0B` in both light and dark mode | Unchanged between themes |
| 9.8 | Recording red is `#E5484D` in light, `#FF6369` in dark | Slightly brighter in dark |
| 9.9 | Tag chips use `#EEEAFF` background + `#3F2FE0` text in light | Purple chip style |
| 9.10 | Tag chips use `#2F2A5E` background + `#B7AFFF` text in dark | Dark purple chip style |
| 9.11 | Switching device OS theme while app is running updates the app | Live theme follow — no restart needed |

---

## 10 — Navigation & Routing

| # | Check | Expected |
|---|---|---|
| 10.1 🔴 | App starts at `/` (NoteListScreen) | Home screen on launch |
| 10.2 🔴 | FAB → `/note/new` (editor, no ID) | New note editor |
| 10.3 🔴 | Tapping note card → `/note/:id` (editor, with ID) | Correct note loaded |
| 10.4 🔴 | Back from editor → returns to previous screen | No crash, note list updated |
| 10.5 | Tapping Explore tab → `/search` | Search screen |
| 10.6 | Tapping Tags tab → `/tags` | Tags screen (stub) |
| 10.7 | Tapping Settings tab → `/settings` | Settings screen (stub) |
| 10.8 | Device back button in editor → same as tapping ← | Flushes auto-save and pops |
| 10.9 | Navigating Home → Editor → back button → still on Home | No double-back to exit app unexpectedly |
| 10.10 | Deep-link to an existing note ID loads that note correctly | Editor populates with correct content |

---

## 11 — Stub Screens (Phase Placeholders)

These are intentionally incomplete. Verify they render without crashing.

| # | Check | Expected |
|---|---|---|
| 11.1 | TagsScreen loads without crash | Shows "🏷️ Tags" + "Phase 7 — coming soon" |
| 11.2 | SettingsScreen loads without crash | Shows "⚙️ Settings" + "Phase 9 — coming soon" |
| 11.3 ⚠️ KNOWN STUB | Category bottom sheet in editor shows placeholder | "Category picker — Phase 8" |
| 11.4 ⚠️ KNOWN STUB | Note editor overflow menu (⋮) does nothing | No crash on tap |

---

## 12 — Edge Cases & Error Handling

| # | Check | Expected |
|---|---|---|
| 12.1 | Type 200+ characters in a note title → title does not crash | Handles long strings (truncation in preview) |
| 12.2 | Create a note with only whitespace title → shows "Untitled" in list | Empty title handled gracefully |
| 12.3 | Search with only spaces → no results shown | Handles whitespace-only queries |
| 12.4 | Rapidly tap FAB multiple times → only one editor opens | No duplicate screens pushed |
| 12.5 | Add and remove the same tag twice in a row → no crash | Tag state consistent after round-trip |
| 12.6 | Open the editor and immediately press back (nothing typed) → no crash | No empty note saved (auto-save not triggered) |
| 12.7 | Open a note, make an edit, immediately press back before 800 ms → save fires on back | Back button flushes the debounce |
| 12.8 | Rotate device mid-recording → recording continues (or overlay dismissed gracefully) | No crash; services handle lifecycle |
| 12.9 | Record a 30-second clip → timer reads `00:30`, chip shows `0:30` | Timer and chip duration match |
| 12.10 | Record a clip longer than 1 minute → timer shows `01:xx`, chip shows `1:xx` | Minute overflow handled |

---

## 13 — Performance Checks

| # | Check | Expected |
|---|---|---|
| 13.1 | Note list with 50 notes scrolls without frame drops | List uses `ListView` with item-level widgets; no jank |
| 13.2 | Auto-save does not cause visible UI freeze | 800 ms debounce offloads DB write after typing stops |
| 13.3 | Opening the editor for an existing note feels instant (<300 ms) | Quill controller init is synchronous from cached data |
| 13.4 | Search results appear within ~300 ms of typing stopping | Debounced FTS5 query returns quickly |
| 13.5 | App cold start to usable home screen < 3 seconds | Drift opens lazily; no blocking I/O on main thread |

---

## 14 — `flutter analyze` Gate

| # | Check | Expected |
|---|---|---|
| 14.1 🔴 | `flutter analyze` returns **0 issues** | Zero errors, zero warnings, zero infos |

This gate must pass before every commit. If it fails, do not proceed.

---

## Known Limitations (Not Bugs)

The following are **intentional stubs** pending future phases. Do not report them as bugs:

| Item | Planned Phase |
|---|---|
| Tags screen is a placeholder | Phase 7 |
| Settings screen is a placeholder | Phase 9 |
| Category picker in editor is a placeholder | Phase 8 |
| Note editor overflow menu (⋮) does nothing | Phase 5+ (not spec'd yet) |
| Bottom nav tab highlight is hardcoded per screen (no shared state) | Phase 9 (GoRouter ShellRoute) |
| Theme preference resets on app restart | Phase 9 (SharedPreferences wiring) |
| `SyncStatus` field on notes is always `local` | Phase 10 |
| No note deletion UI | Not yet spec'd |
| No note archiving UI | Not yet spec'd |

---

## Test Session Checklist (Quick Run — ~15 min)

For a quick smoke-test after each commit, run only the 🔴 CRITICAL checks:

```
Section 1:  1.1, 1.2, 1.3
Section 2:  2.1, 2.2, 2.7, 2.13, 2.15
Section 3:  3.1, 3.4, 3.5, 3.9
Section 4:  4.5, 4.6, 4.17, 4.20, 4.24, 4.25
Section 6:  6.1, 6.2, 6.4
Section 7:  7.1, 7.2, 7.3, 7.5, 7.6, 7.7, 7.14, 7.20, 7.21, 7.22, 7.24, 7.26, 7.31
Section 8:  8.1, 8.2, 8.3, 8.4
Section 10: 10.1, 10.2, 10.3, 10.4, 10.8
Section 14: 14.1
Section 15: 15.1, 15.2, 15.3, 15.11, 15.12, 15.17, 15.18, 15.26, 15.39, 15.40, 15.41
```

**Total: ~46 checks ≈ 20 minutes on device.**

---

## Full Regression Checklist (~1.5 hr)

Run all numbered checks in all 15 sections before tagging a release or starting a new phase.

---

## 15 — Voice Recording & STT Deep Verification

> This section answers three questions:
> 1. **Where are the saved audio files?**
> 2. **Where is the transcribed text stored?**
> 3. **How do I confirm a recording succeeded at every level?**
>
> All ADB commands require a **debug build** (`flutter run`, not a release APK).
> The package name for this app is `com.modunote.app`.

---

### 15A — Where Audio Files Are Saved

ModuNote saves every recording as a `.aac` file under the app's private documents directory.

**On-device path:**
```
/data/user/0/com.modunote.app/app_flutter/audio_notes/
```

Each file is named with a UUID v4, e.g.:
```
/data/user/0/com.modunote.app/app_flutter/audio_notes/3f2a8b1c-9d4e-4f3a-8e2b-1c9d4e3f2a8b.aac
```

This path is constructed by `AudioFileStorage.generateFilePath()`:
- Root: `getApplicationDocumentsDirectory()` → resolves to `…/app_flutter/` on Android
- Sub-directory: `AppConstants.audioSubDir` = `"audio_notes"`
- Filename: `UuidGenerator.generate() + ".aac"`

**Expected file characteristics:**
| Property | Value |
|---|---|
| Format | AAC (ADTS container) |
| Bitrate | 32 kbps |
| Channels | Mono (1) |
| Sample rate | 16 kHz |
| Approximate size | ~0.24 MB per minute (~4 KB per second) |

---

### 15B — Where Transcribed Text Is Stored

Transcribed text is stored in **two places simultaneously** when a recording is stopped:

**1. SQLite database (persistent)**
- File: `/data/user/0/com.modunote.app/databases/modunote.db`
- Table: `audio_records`
- Column: `transcribed_text` (nullable TEXT)
- Also in the same row: `id`, `note_id`, `file_path`, `duration_ms`, `file_size_bytes`, `codec`, `created_at`

**2. Quill editor body (immediate UI)**
- Inserted at the cursor position when recording stops
- Inserted as `\n{transcript}\n` (newline-padded block)
- This is what the user sees immediately in the note body

If the user spoke nothing (or STT returned no text), `transcribed_text` is `NULL` in the DB and nothing is inserted into the editor.

---

### 15C — In-App Verification (No Tools Required)

These checks require only the running app on a device.

| # | Check | Expected |
|---|---|---|
| 15.1 🔴 | Record a voice note; speak clearly for 3–5 seconds then stop | Audio clip chip appears above the tag row in the editor |
| 15.2 🔴 | Chip shows a duration formatted as `M:SS` (e.g. `0:05`) | Duration is non-zero and matches approximate speaking time |
| 15.3 🔴 | Tap the play ▶ icon on the chip | Audio plays back through device speaker; icon changes to pause ⏸ |
| 15.4 🔴 | Tap pause ⏸ while audio is playing | Audio stops immediately |
| 15.5 🔴 | Tap ✕ dismiss button on chip | Chip disappears from the row |
| 15.6 | Speak a sentence; after stopping, check the note body | Spoken text (or close approximation) appears inserted at the cursor |
| 15.7 | Close and reopen the note | Audio chip is still present (DB persistence via `watchByNote` stream) |
| 15.8 | Record a second voice note in the same note | Two chips appear side by side in a horizontally scrollable row |
| 15.9 | Save the note (back button) then reopen | Both chips still present |
| 15.10 | Tap ✕ on one chip; close and reopen the note | Only the remaining chip is present (deletion is permanent) |

---

### 15D — ADB File System Verification

Confirms the `.aac` file was physically written to disk.

**Prerequisites:** USB debugging enabled, device connected, `adb` on PATH.

**Step 1 — List audio files:**
```bash
adb shell run-as com.modunote.app ls -lh app_flutter/audio_notes/
```

Expected output (one line per recording):
```
-rw------- 1 u0_a123 u0_a123   18K 2026-05-05 14:32 3f2a8b1c-9d4e-4f3a-8e2b-1c9d4e3f2a8b.aac
```

| Check | Expected |
|---|---|
| 15.11 🔴 | Directory `audio_notes/` exists | No `ls: cannot access` error |
| 15.12 🔴 | At least one `.aac` file present after recording | UUID-named file visible |
| 15.13 | File size is non-zero and proportional to duration | A 5-second clip ≈ 20–22 KB |
| 15.14 | After tapping ✕ dismiss, re-run the `ls` command | The deleted file is gone from the directory |

**Step 2 — Pull a file to your PC and play it:**
```bash
# Copy one file to current directory on PC
adb shell run-as com.modunote.app cat app_flutter/audio_notes/{uuid}.aac > test_recording.aac

# Play it (Windows — requires VLC or Windows Media Player to handle .aac)
# Or rename to .m4a — most media players accept that extension
```

| Check | Expected |
|---|---|
| 15.15 | Pulled file plays in VLC / Windows Media Player | Voice is audible and clear |
| 15.16 | Audio is mono (single channel), approx 16 kHz sample rate | Shown in VLC → Tools → Media Information → Codec |

**Step 3 — Check total audio directory size:**
```bash
adb shell run-as com.modunote.app du -sh app_flutter/audio_notes/
```
Expected: size grows after each recording, shrinks after deletions.

---

### 15E — ADB Database Verification

Confirms the `audio_records` row was written with correct metadata and transcription.

**Method A — sqlite3 on-device (requires sqlite3 binary):**
```bash
# Copy DB to a writable location, then query
adb shell run-as com.modunote.app cp databases/modunote.db /sdcard/modunote_debug.db
adb shell sqlite3 /sdcard/modunote_debug.db "SELECT id, note_id, substr(file_path,45), duration_ms, file_size_bytes, transcribed_text FROM audio_records;"
```

**Method B — Pull DB to PC then open in DB Browser for SQLite (recommended):**
```bash
# Pull the database file to current directory on PC
adb shell run-as com.modunote.app cat databases/modunote.db > modunote_debug.db
```

Then open `modunote_debug.db` in [DB Browser for SQLite](https://sqlitebrowser.org/):
1. File → Open Database → select `modunote_debug.db`
2. Browse Data tab → Table: `audio_records`

**What to verify in the `audio_records` table:**

| # | Column | Expected Value |
|---|---|---|
| 15.17 🔴 | `id` | A valid UUID v4 string (e.g. `3f2a8b1c-9d4e-4f3a-8e2b-...`) |
| 15.18 🔴 | `note_id` | Matches the `id` of the parent note in the `notes` table |
| 15.19 🔴 | `file_path` | Full absolute path ending in `.aac` under `audio_notes/` |
| 15.20 🔴 | `duration_ms` | Positive integer; approximately `seconds_spoken × 1000` |
| 15.21 🔴 | `file_size_bytes` | Positive integer; matches the on-disk file size from `ls -lh` |
| 15.22 | `codec` | `"aac"` (default value from Drift schema) |
| 15.23 | `transcribed_text` | The spoken text (or NULL if nothing was transcribed) |
| 15.24 | `created_at` | Unix timestamp in milliseconds for when recording stopped |
| 15.25 | After ✕ dismiss: re-pull DB and check | Row is no longer present in `audio_records` table |

**Verify file_path ↔ disk sync:**
```sql
-- Run in DB Browser (Execute SQL tab)
SELECT file_path FROM audio_records WHERE note_id = '{your-note-id}';
```
The returned path should match a file you can see with `adb shell run-as com.modunote.app ls app_flutter/audio_notes/`.

---

### 15F — STT Transcription Verification

Confirms that live speech-to-text output was captured, accumulated, and stored correctly.

**In-app transcript check:**

| # | Check | Expected |
|---|---|---|
| 15.26 🔴 | While recording overlay is open, speak a sentence | Live transcript preview appears below the timer text in the overlay |
| 15.27 | Transcript updates continuously as you speak | Text grows with each recognized phrase (partial + final results merged) |
| 15.28 | Stop recording; check editor body | Transcript text inserted at cursor position, preceded and followed by a newline |
| 15.29 | Transcript in editor matches what was shown in the overlay | Text is identical (accumulated from finalResults) |

**Pause / timeout recovery check (Android-specific):**

| # | Check | Expected |
|---|---|---|
| 15.30 | Start recording; speak a sentence; then stay silent for 8+ seconds; then speak again | STT resumes after the 8 s silence pause and continues transcribing (timeout recovery active) |
| 15.31 | After a silence-recovery, the transcript is continuous | Previously spoken text is preserved; new speech appended (not replaced) |

> **How this works**: `SpeechToTextService._onStatus('notListening')` detects the Android STT engine stopping silently. After a 200 ms delay, `_listen()` is restarted if `_active` is still true. The `_accumulated` string retains all text spoken before the timeout, so new speech appends correctly.

**DB transcription check:**

After recording and stopping, pull the DB (see Section 15E Method B) and verify:
```sql
SELECT transcribed_text FROM audio_records ORDER BY created_at DESC LIMIT 1;
```

| # | Check | Expected |
|---|---|---|
| 15.32 | `transcribed_text` is not NULL after speaking | Column contains recognized text |
| 15.33 | Content matches editor body insertion | Same string, minus leading/trailing newlines |
| 15.34 | Record with silence only (no speech); check DB | `transcribed_text` is NULL; nothing inserted into editor |

---

### 15G — Logcat Verification (Advanced)

Filter Android system logs to see real-time output from the recording and STT services.

**Flutter app logs (most useful):**
```bash
adb logcat -s flutter
```

Look for these log patterns during recording:
```
I/flutter: [AudioRecordingService] Recording started: /data/user/0/…/audio_notes/{uuid}.aac
I/flutter: [AudioRecordingService] Recording stopped. Duration: 5234ms
I/flutter: [SpeechToTextService] STT initialized successfully
I/flutter: [SpeechToTextService] Status: notListening — restarting (timeout recovery)
I/flutter: [SpeechToTextService] Result: "your spoken words here" (final: true)
```

**flutter_sound system logs:**
```bash
adb logcat -s "flutter_sound"
```

**speech_to_text system logs:**
```bash
adb logcat | grep -i "speech\|stt\|SpeechRecognition"
```

| # | Check | Expected |
|---|---|---|
| 15.35 | Recording start logged | Path of `.aac` file logged when mic button tapped |
| 15.36 | Recording stop logged | Duration in ms logged |
| 15.37 | `finalResult` events appear | `Result: "text" (final: true)` lines appear as you speak |
| 15.38 | Timeout recovery logged | `Status: notListening — restarting` appears after >7 s silence |

---

### 15H — Permission Edge Cases

| # | Check | Expected |
|---|---|---|
| 15.39 🔴 | Fresh install, tap mic icon → OS permission dialog | Android system permission dialog: "Allow ModuNote to record audio?" |
| 15.40 🔴 | Tap "Allow" → recording starts immediately | Overlay appears; timer runs; waveform animates |
| 15.41 🔴 | Fresh install, tap mic icon → tap "Deny" | SnackBar: "Microphone permission denied". No crash. No overlay. |
| 15.42 | After deny: tap mic again | Same SnackBar re-appears (no OS dialog on second tap — OS blocks repeated requests) |
| 15.43 | Revoke permission in device Settings → return to app → tap mic | SnackBar: "Microphone permission denied". App handles gracefully. |

---

### 15I — Quick Reference Summary

| Question | Answer |
|---|---|
| **Where are audio files?** | `adb shell run-as com.modunote.app ls app_flutter/audio_notes/` |
| **Where is transcribed text (DB)?** | `audio_records.transcribed_text` column in `modunote.db` |
| **Where is transcribed text (UI)?** | Inserted at Quill cursor in note body on recording stop |
| **How to pull the database?** | `adb shell run-as com.modunote.app cat databases/modunote.db > debug.db` |
| **How to pull an audio file?** | `adb shell run-as com.modunote.app cat app_flutter/audio_notes/{uuid}.aac > clip.aac` |
| **How to query the DB on PC?** | DB Browser for SQLite → open `debug.db` → Browse Data → `audio_records` |
| **Why does STT stop mid-recording?** | Android OS timeout (~7 s silence). App auto-recovers via `_onStatus` handler. |
| **Expected file size per minute?** | ~240 KB/min (32 kbps × 60 s ÷ 8 bits per byte) |
