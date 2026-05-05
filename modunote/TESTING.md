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
```

**Total: ~35 checks ≈ 15 minutes on device.**

---

## Full Regression Checklist (~1 hr)

Run all numbered checks in all 14 sections before tagging a release or starting a new phase.
