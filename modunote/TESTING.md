# ModuNote — Complete Device Testing Guide
> **Covers Phases 1–9** (all shipped code as of Phase 9 Navigation + Theming completion).
> Every check is a pass/fail statement. Run on a **physical Android device**.
> 🔴 = must pass before any commit. ⚠️ STUB = intentional placeholder for a future phase.

---

## Pre-Test Setup

Run these commands every time before starting a test session:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze        # must report: No issues found!
flutter run            # connect physical Android device first
```

**Device state required:**
- USB debugging on, device trusted
- App freshly installed **or** existing install's DB wiped (`adb shell pm clear com.modunote.app`) for first-launch checks
- Device language: English
- Microphone permission **not yet granted** for permission-flow sections (use a fresh install or revoke in Settings → Apps → ModuNote → Permissions)
- Both light and dark OS themes available for theme checks

---

## Section 1 — App Bootstrap

| # | Check | Expected |
|---|---|---|
| 1.1 🔴 | App launches without crash | `NoteListScreen` appears; no red error banners |
| 1.2 🔴 | No `Exception` text, no red overlay, no Flutter error widget anywhere on screen | Clean render |
| 1.3 🔴 | First launch with empty DB → empty state visible | Centred icon + "No notes yet" + subtitle text |
| 1.4 | App bar shows today's weekday in ALL CAPS (e.g. `WEDNESDAY`) | Correct day of week; Inter 12/500/onSurfaceMuted/+0.4 |
| 1.5 | App bar shows `"Your notes"` heading | Plus Jakarta Sans 26 sp / weight 800 / letterSpacing −0.6 |
| 1.6 | Avatar circle in top-right shows `"MA"` initials | 42×42 circle; 135° gradient (primary → accent); white PJS 14/800 text |
| 1.7 | App theme matches the OS theme (light or dark) on cold start | Background matches system setting without restarting app |
| 1.8 | Switching OS theme while app is running updates all screens instantly | No app restart required |

---

## Section 2 — Note List Screen: App Bar & Search Field

### 2A — App Bar

| # | Check | Expected |
|---|---|---|
| 2.1 | Day-of-week label is UPPERCASE | `MONDAY`, not `Monday` |
| 2.2 | Day label uses Inter weight 500, muted colour | Lighter grey, not the primary text colour |
| 2.3 | `"Your notes"` heading is visibly larger and bolder than all other text on screen | Largest text on the screen |
| 2.4 | Avatar gradient goes from indigo-violet (left/top) to amber (right/bottom) | Diagonal gradient; `"MA"` readable in white |
| 2.5 | Avatar is a perfect circle, 42 dp diameter | Circular mask; no square corners |

### 2B — Search Field

| # | Check | Expected |
|---|---|---|
| 2.6 🔴 | Search field visible below app bar with left margin 20 dp | Rounded container, not full-bleed |
| 2.7 | Search field height is 48 dp; border-radius 16 | Noticeably rounded, not pill |
| 2.8 | Search field background is `surfaceContainer` (light: `#F4F0FA` / dark: `#2A2942`) | Slightly different from screen background |
| 2.9 | Search field has a 0.5 px `outline`-coloured border | Very subtle border around the field |
| 2.10 | Search icon (20 dp) is left of placeholder, in `onSurfaceMuted` colour | Muted grey magnifier icon |
| 2.11 | Placeholder text reads `"Search notes, tags…"` | Exact string; Inter 14.5/400/onSurfaceMuted |
| 2.12 🔴 | Tapping search field navigates to Explore/Search screen | Does NOT open keyboard on home; pushes route |
| 2.13 | Search field is NOT editable on Home | Tapping it never shows a cursor or keyboard in-place |

---

## Section 3 — Note List Screen: Floating Bottom Nav

| # | Check | Expected |
|---|---|---|
| 3.1 🔴 | Bottom nav pill is visible, floating above the screen bottom edge | Does not sit flush against the bottom; left 16, right 16, bottom 14 |
| 3.2 | Nav pill height is 64 dp | Taller than a typical icon button |
| 3.3 | Nav pill has fully rounded ends (border-radius 32) | Pill shape, not a rectangle |
| 3.4 | Nav pill background is `card` colour (light: `#FFFFFF` / dark: `#232238`) | White in light, dark card in dark |
| 3.5 | Nav pill has a 0.5 px `outlineStrong`-coloured border | Visible thin border around entire pill |
| 3.6 | Nav pill casts a subtle shadow (very faint in light, stronger in dark) | Slightly elevated appearance |
| 3.7 | Four tabs visible left-to-right: Home, Explore, Tags, Settings | Correct icons in correct order |
| 3.8 🔴 | **Home tab** is active on Note List screen | `primaryContainer` background pill behind the icon + label |
| 3.9 | Active tab shows icon (20 dp) in `onPrimaryContainer` colour | Darker on the light purple pill |
| 3.10 | Active tab shows its label text to the right of the icon | "Home" text visible, Inter 13/600/onPrimaryContainer/+0.1 |
| 3.11 | Inactive tabs show no label text, no background pill | Icon only, `onSurfaceVariant` colour |
| 3.12 | Inactive tab icons are 20 dp, `onSurfaceVariant` colour | Lighter grey than active icon |
| 3.13 🔴 | Tapping **Explore** tab navigates to Search screen | Explore/Search screen loads |
| 3.14 🔴 | Tapping **Tags** tab navigates to Tags screen | Tags screen loads (Phase 7 full UI) |
| 3.15 | Tapping **Settings** tab navigates to Settings screen | Settings stub screen loads |
| 3.16 | Tapping **Home** tab from any other tab returns to Note List | Home screen appears |
| 3.17 | Nav pill does not overlap note cards when scrolling | Cards visible up to the nav pill's top edge |

---

## Section 4 — Note List Screen: Floating Action Button (FAB)

| # | Check | Expected |
|---|---|---|
| 4.1 🔴 | Amber FAB visible in the lower-right corner of the screen | Above bottom nav, right-aligned |
| 4.2 | FAB position: bottom 96 dp from screen bottom, right 20 dp from edge | Floats above nav pill |
| 4.3 | FAB is 56×56 dp, border-radius 18 | Square-ish rounded corners, not a circle |
| 4.4 | FAB background is amber `#F59E0B` in both light and dark mode | Does not change with theme |
| 4.5 | FAB icon is `+` (add), 26 dp, `accentOn` colour (`#1C1B2E`) | Dark icon on amber background |
| 4.6 | FAB casts an amber-tinted shadow | Warm glow underneath the button |
| 4.7 🔴 | Tapping FAB opens Note Editor screen with empty title and body | New note editor; no previous content |
| 4.8 | Tapping FAB from Explore or Tags screen routes to `/note/new` | Editor works from any tab |

---

## Section 5 — Note List Screen: Note Cards

### 5A — Visual Anatomy

| # | Check | Expected |
|---|---|---|
| 5.1 | Note card border-radius is 20 dp | Noticeably rounded corners |
| 5.2 | Note card padding: 16 dp top/bottom, 18 dp left/right | Inner content not flush with edges |
| 5.3 | Unpinned card: `card` colour background, 0.5 px `outline`-coloured border | White (light) / `#232238` (dark) |
| 5.4 | Pinned card (light mode): `#FFF4D6` background | Warm gold tint, noticeably different from white |
| 5.5 | Pinned card (dark mode): same `card` colour background as unpinned | Only border changes in dark mode |
| 5.6 | Pinned card border: 0.5 px `rgba(245,158,11,0.35)` | Amber-tinted border |
| 5.7 | Pinned card shows push-pin icon (14 dp) in amber (`accent`) colour | Pin icon visible in header row, left of title |
| 5.8 | Unpinned card shows no pin icon | No empty space where pin would be |
| 5.9 | Gap between pin icon and title is 8 dp | Tight but readable |

### 5B — Content

| # | Check | Expected |
|---|---|---|
| 5.10 🔴 | Card title uses Plus Jakarta Sans 16.5 sp / weight 700 / `onSurface` | Heading font, noticeably bolder than preview text |
| 5.11 | Note with no title shows `"Untitled"` on the card | Not blank or empty |
| 5.12 | Card timestamp (e.g. "Just now", "5m ago") is Inter 11.5/500/`onSurfaceMuted` | Smallest, lightest text on the card |
| 5.13 | Timestamp is right-aligned in the header row | Opposite side from the title |
| 5.14 🔴 | Body preview text shows a single line with ellipsis if content is long | One line; `…` at end; Inter 13.5/400/`onSurfaceVariant` |
| 5.15 | Note with no body content shows no preview line | Card height shorter with no preview |
| 5.16 | Preview is extracted from Quill Delta content (plain text, no markdown symbols) | No `**bold**` characters; just the words |
| 5.17 | Internal gap between header and preview is 10 dp | Consistent spacing |

### 5C — Tag Chips on Cards

| # | Check | Expected |
|---|---|---|
| 5.18 🔴 | Note with tags shows tag chips below the preview | Chip row visible when note has ≥1 tag |
| 5.19 | Up to 3 tag chips shown; 4th+ tags are not shown (no overflow indicator) | Maximum 3 chips rendered |
| 5.20 | Each chip shows `#tagname` with hash prefix | e.g. `#photography` |
| 5.21 | Tag chips are `sm` size: height 24 dp, chipBg background, chipText colour | Small filled pill chips |
| 5.22 | Note with no tags shows no chip row | No empty row at bottom of card |
| 5.23 | Adding a tag to a note → card in list immediately updates to show that chip | Reactive stream update |

### 5D — Tap Interaction

| # | Check | Expected |
|---|---|---|
| 5.24 🔴 | Tapping a note card opens the Note Editor with that note's content | Title, body, and tags loaded correctly |
| 5.25 | Long-pressing a note card does nothing (no action yet) | No menu, no crash |

---

## Section 6 — Note List Screen: Sections & States

### 6A — PINNED / RECENT Sections

| # | Check | Expected |
|---|---|---|
| 6.1 | Notes with `isPinned == true` appear under "PINNED" header | Above the Recent section |
| 6.2 | PINNED section header shows: label + hairline divider + count badge | `PINNED ─── 2` layout |
| 6.3 | Section label is "PINNED": Inter 12/600/`onSurfaceMuted`/UPPERCASE/+0.6 | All caps, small, muted |
| 6.4 | Hairline divider is 0.5 px `outline` colour, flex-expands between label and badge | Very thin line |
| 6.5 | Count badge: Inter 11/500/`onSurfaceMuted` | e.g. `2` |
| 6.6 | Notes with `isPinned == false` appear under "RECENT" header | Below pinned section |
| 6.7 | RECENT section header shows: label + hairline divider (no count badge) | `RECENT ───────` |
| 6.8 | Each section sorted by `updatedAt` descending | Most recently edited note at top of each section |
| 6.9 | If no pinned notes: PINNED section header is hidden | No empty header |
| 6.10 | If no recent notes: RECENT section header is hidden | No empty header |
| 6.11 | Archived notes are NOT shown on the home screen | No archived note appears |

### 6B — Loading State

| # | Check | Expected |
|---|---|---|
| 6.12 | While DB is loading: 3 skeleton placeholder cards pulsing | Grey boxes matching card shape |
| 6.13 | Skeleton boxes oscillate in opacity (dim ↔ brighter, ~800 ms cycle) | Smooth, not flickering |
| 6.14 | Skeleton layout mirrors a real card shape | Same border radius and padding as MNNoteCard |

### 6C — Error State

| # | Check | Expected |
|---|---|---|
| 6.15 | If DB load fails: error icon + "Could not load notes" message + "Retry" button | Centred on screen |
| 6.16 | Tapping Retry calls `ref.invalidate(noteListViewModelProvider)` | Screen transitions back to loading → data |

### 6D — Empty State

| # | Check | Expected |
|---|---|---|
| 6.17 🔴 | Empty DB: centred empty state UI visible | No crash; "No notes yet" visible |
| 6.18 | FAB is still visible on empty state | User can create a note |
| 6.19 | Bottom nav is still visible on empty state | Navigation accessible |

---

## Section 7 — Note Creation & Auto-Save

| # | Check | Expected |
|---|---|---|
| 7.1 🔴 | Tap FAB → editor opens; cursor placed in body (auto-focused) | Keyboard appears without a manual tap |
| 7.2 | Title field shows `"Title…"` placeholder in muted colour | Disappears when typing starts |
| 7.3 | Typing in title → save badge changes to neutral dot + `"Saving…"` | Within ~1 second of first keystroke |
| 7.4 🔴 | 800 ms after last keystroke → save badge shows green dot + `"Saved"` | Auto-save debounce fires |
| 7.5 | Editing title and body in quick succession → save fires once, not twice | Debounce resets on each keystroke |
| 7.6 | Typing only in title with blank body → note still saves | Title-only notes are valid |
| 7.7 | Typing only in body with blank title → note saves with empty title | Stored as empty string; shown as "Untitled" in list |
| 7.8 🔴 | Press back → note appears in Note List immediately | Card shows title + preview; no manual refresh needed |
| 7.9 | Pressing back before 800 ms debounce fires → save fires immediately on back | Back button flushes debounce synchronously |
| 7.10 🔴 | Re-open the note → content is exactly as typed | Title and body match; no data loss |
| 7.11 | Creating a note and immediately pressing back (nothing typed) → no empty note in list | Auto-save only fires if content changed |
| 7.12 | Timestamp on card reads `"Just now"` immediately after creation | Relative time string |
| 7.13 | After 1 minute: timestamp reads `"1m ago"` | Relative time updates |

---

## Section 8 — Note Editor Screen: App Bar

| # | Check | Expected |
|---|---|---|
| 8.1 | Back arrow button (←) is a 40×40 circular tap target | Circle touch area; `←` icon 22 dp |
| 8.2 | Tapping back arrow flushes auto-save and navigates to previous screen | No data loss on back |
| 8.3 | Device hardware back button behaves identically to the ← button | Auto-save fires; screen pops |
| 8.4 | Title `TextField` fills the space between ← and save badge | Flex-expands; no fixed width |
| 8.5 | Title field uses Plus Jakarta Sans 17 sp / weight 700 / letterSpacing −0.2 | Slightly smaller than list heading |
| 8.6 | Title field has no visible border or underline decoration | Inline style (collapsed decoration) |
| 8.7 | Save badge sits between title and `⋮` button | Correct horizontal order: ← title badge ⋮ |
| 8.8 | Save badge: surfaceContainer background, border-radius 100 (pill), padding 4×10 | Small rounded pill |
| 8.9 | Save badge "Saving…" state: 6×6 neutral dot (matches `onSurfaceMuted`) + text | Dot colour is same muted grey |
| 8.10 | Save badge "Saved" state: 6×6 green dot (`#22c55e`) + text | Green dot; text reads "Saved" |
| 8.11 | `⋮` overflow menu button is a 40×40 circular tap target | Does nothing (stub) |
| 8.12 | Tapping `⋮` does not crash | Empty tap; no menu or exception |
| 8.13 | App bar top padding is 4 dp; bottom padding 8 dp | Slightly tighter than standard AppBar |

---

## Section 9 — Note Editor Screen: Quill Rich Text Body

| # | Check | Expected |
|---|---|---|
| 9.1 | Editor body placeholder text: `"Start writing…"` | Visible when body is empty |
| 9.2 | Editor body is scrollable vertically | Long notes scroll independently from toolbar |
| 9.3 | Editor body has horizontal padding of 20 dp each side | Content not flush with screen edges |
| 9.4 | Typing produces visible text in the editor | Basic text input works |
| 9.5 | Multi-line text wraps correctly | No horizontal overflow |
| 9.6 | Tapping different parts of the text moves cursor there | Cursor responds to taps |
| 9.7 | Keyboard pushes editor up (not hidden behind keyboard) | `resizeToAvoidBottomInset: true` |
| 9.8 🔴 | Bold, italic, underline text renders visibly different from normal text | Formatting applied and visible |
| 9.9 | H1 text is larger than H2; both larger than body | Heading hierarchy visible |
| 9.10 | Bullet list item has a `•` prefix | Standard bullet character |
| 9.11 | Numbered list items are numbered sequentially `1.`, `2.`, `3.` | Number increments with new items |
| 9.12 | Checklist items show a checkbox shape | Unchecked: outlined box; Checked: filled with check mark |
| 9.13 | Blockquote has a vertical left border in amber (`accent` colour) | Left accent stripe, `surfaceContainer` background |
| 9.14 | Formatting is preserved after closing and reopening the note | Delta JSON round-trips correctly |

---

## Section 10 — Note Editor Screen: Formatting Toolbar

| # | Check | Expected |
|---|---|---|
| 10.1 🔴 | Toolbar visible between tag row and keyboard (pinned above keyboard) | 9 buttons in a horizontal row |
| 10.2 | Toolbar background is `card` colour with a 0.5 px top border | Separated from editor body |
| 10.3 | Toolbar padding: 10 dp vertical, 12 dp horizontal | Comfortable spacing |
| 10.4 | Each button slot is 34×34 dp, border-radius 10 | Consistent square-rounded buttons |
| 10.5 | Inactive button: transparent background, icon `onSurfaceVariant` | Muted icon |
| 10.6 | Active button: `primaryContainer` background, icon `onPrimaryContainer` | Highlighted button |
| 10.7 🔴 | Tapping **B** with text selected applies bold | Text appears bold immediately |
| 10.8 | Tapping **B** again while bold is selected removes bold | Toggle off works |
| 10.9 🔴 | Tapping **I** with text selected applies italic | Italicised text visible |
| 10.10 | Tapping **U** with text selected applies underline | Underline visible |
| 10.11 | Tapping **H1** applies heading level 1 to current line | Large heading |
| 10.12 | Tapping **H2** applies heading level 2 to current line | Slightly smaller heading |
| 10.13 | Tapping **H1** again (while active) removes heading — paragraph returns to body | Toggle off works |
| 10.14 | Tapping **•** starts a bullet list | Bullet character appears on current line |
| 10.15 | Tapping **1.** starts a numbered list | `1.` appears; next line becomes `2.` |
| 10.16 | Tapping **☑** creates a checklist item | Checkbox appears |
| 10.17 | Tapping a checklist checkbox toggles its checked state | Visual check/uncheck |
| 10.18 | Tapping **"** creates a blockquote | Block with left amber border |
| 10.19 🔴 | Moving cursor into already-bold text highlights the B button | Active state updates on cursor move |
| 10.20 | Moving cursor into a heading updates H1 or H2 button highlight | Correct format button activates |
| 10.21 | Moving cursor into a bullet list highlights the • button | List format reflected in toolbar |
| 10.22 | Moving cursor between formatted and unformatted text toggles button state | Real-time active state |

---

## Section 11 — Note Editor Screen: Tag Row

| # | Check | Expected |
|---|---|---|
| 11.1 🔴 | Tag row visible between editor body and formatting toolbar | Horizontal strip with chips and mic button |
| 11.2 | Tag row background is `surface` colour with a 0.5 px top border | Separated from editor |
| 11.3 | Tag row vertical padding is 12 dp; horizontal padding 16 dp | Content has breathing room |
| 11.4 | Category chip is on the left, always visible | Folder icon + label + chevron |
| 11.5 | Category chip: height 30 dp, border-radius 10, `surfaceContainer` background, 0.5 px `outline` border | Slightly rounded rect |
| 11.6 | Category chip shows folder icon (14 dp, `onSurfaceVariant`) + label + chevron-down (12 dp, `onSurfaceMuted`) | All three elements side by side |
| 11.7 | Category chip label reads `"No category"` when note has no category | Default label |
| 11.8 ⚠️ STUB | Tapping category chip → bottom sheet shows `"Category picker — Phase 8"` | Placeholder renders; no crash |
| 11.9 | Tag chips (if any) appear to the right of the category chip in a horizontally scrollable row | Scrollable when many tags |
| 11.10 🔴 | `"+ tag"` chip is always visible to the right of existing tag chips | Outlined chip at end of row |
| 11.11 | `"+ tag"` chip: height 24 dp, border-radius 999 (pill), 1 px outlined `outlineStrong` border | Pill outline chip |
| 11.12 | `"+ tag"` chip text is Inter 11/600/`onSurfaceVariant` | Small, muted, weight 600 |
| 11.13 | Mic button is on the far right of the tag row | Right-aligned, not scrollable |
| 11.14 | Mic button (idle): 40×40 dp, border-radius 14, `primaryContainer` background | Square-rounded, light purple |
| 11.15 | Mic button (idle): mic icon 20 dp, `onPrimaryContainer` colour | Dark icon on light background |
| 11.16 | Mic button (recording): `recordRed` background, white square stop icon | Completely red |
| 11.17 | Mic button (recording): glow effect (spread 4 dp, `recordRed` at 15% opacity) | Subtle red halo |
| 11.18 | Tag chips in row: `sm` size (height 24), chipBg background, chipText colour, pill | Small filled purple chips |
| 11.19 | Each tag chip shows `#tagname` format | Hash prefix always present |
| 11.20 🔴 | Tag chip has a dismiss `×` button on the right | Tappable close button |
| 11.21 | Dismiss button: 16×16 circle, `rgba(0,0,0,0.08)` background, 10 dp `×` icon | Small circle dismiss |
| 11.22 🔴 | Tapping `×` removes the tag from the note | Chip disappears; ViewModel updated |
| 11.23 | Removing tag from note does NOT delete the tag from the tags database | Tag still appears in Tags screen |
| 11.24 | Tag row chips scroll horizontally when many tags present | No line wrap; horizontal scroll |
| 11.25 | Gap between chips is 6 dp | Consistent spacing |

---

## Section 12 — Tag Input Sheet (Phase 7)

> The tag input sheet opens when tapping `"+ tag"` in the note editor tag row.
> It is a modal bottom sheet (`ConsumerStatefulWidget`) that returns the selected/created `Tag`.

### 12A — Sheet Appearance

| # | Check | Expected |
|---|---|---|
| 12.1 🔴 | Tapping `"+ tag"` opens a bottom sheet sliding up from below | Smooth slide-up animation |
| 12.2 | Sheet has card-coloured background | Light: `#FFFFFF`; Dark: `#232238` |
| 12.3 | Sheet top corners are rounded (border-radius 28) | Curved top; flat at sides and bottom |
| 12.4 | Grabber bar centred at top of sheet: 36×4 dp, border-radius 2, `outlineStrong` colour | Drag handle indicator |
| 12.5 | `"Add tag"` heading below grabber: Plus Jakarta Sans 19 sp / weight 800 / letterSpacing −0.3 | Bold heading |
| 12.6 | Input container: height 48 dp, border-radius 16, `surfaceContainer` background, 0.5 px `outline` border | Rounded field |
| 12.7 | Tag icon (18 dp, `onSurfaceMuted`) is left of the text field inside the container | Small icon prefix |
| 12.8 | Placeholder text `"e.g. photography"` in muted colour | Disappears when typing starts |
| 12.9 🔴 | Keyboard opens automatically when sheet appears (autofocus) | No manual tap needed |
| 12.10 | Sheet expands above the keyboard (not hidden behind it) | `isScrollControlled: true` + `viewInsets` padding |

### 12B — Autocomplete Suggestions

| # | Check | Expected |
|---|---|---|
| 12.11 🔴 | Typing a prefix (e.g. `"ph"`) → suggestions appear below the input within ~200 ms | `#photography` chip + "Use existing tag" label |
| 12.12 | Each suggestion row shows: a `#tagname` filled chip (chipBg/chipText) + "Use existing tag" text | Two elements per suggestion row |
| 12.13 | Suggestion tap target is the full row (InkWell, border-radius 12) | Easy to tap |
| 12.14 | Suggestions only show tags NOT already on this note | Already-added tags filtered out |
| 12.15 | Clearing the input field → suggestions list disappears | No stale results shown |
| 12.16 | Typing a prefix that matches no tags → no suggestion rows shown | Empty list; only Create tile may appear |
| 12.17 | Typing a name with an exact match in suggestions → "Create" tile does NOT appear | Exact match means no need to create |
| 12.18 | Typing a name with no exact match → "Create `#name`" tile appears below suggestions | Create option visible |
| 12.19 | "Create" tile has a dashed `outlineStrong` border, border-radius 12 | Visually distinct from suggestions |
| 12.20 | "Create" tile shows `+` icon (16 dp) + `"Create '#name'"` text | Descriptive create label |

### 12C — Selecting an Existing Tag

| # | Check | Expected |
|---|---|---|
| 12.21 🔴 | Tapping a suggestion row → sheet closes and that tag is added to the note | Tag chip appears in note's tag row |
| 12.22 | The existing tag's ID is used (no duplicate tag created) | Tags screen count increments; no new tag in list |
| 12.23 | Submitting (Enter) a name that exactly matches an existing tag → uses existing tag | No duplicate; same as tapping suggestion |
| 12.24 | Submitted name normalised to lowercase before `findByName` | `"Photography"` finds `#photography` tag |

### 12D — Creating a New Tag

| # | Check | Expected |
|---|---|---|
| 12.25 🔴 | Tapping "Create `#name`" tile → sheet closes, new tag created, added to note | New chip appears; Tags screen shows new tag |
| 12.26 | Pressing Enter/submit with a name that matches no existing tag → creates new tag | Same result as tapping Create tile |
| 12.27 | New tag name is normalised: `"TRAVEL"` stored as `#travel` | Always lowercase in chip and Tags screen |
| 12.28 | New tag appears in Tags screen with count 1 (the note just tagged) | Count badge shows 1 |
| 12.29 | Creating a tag that already exists (typed from scratch, no suggestion) → uses existing, no duplicate | `findByName` check prevents duplicate |

### 12E — Tag Already Added

| # | Check | Expected |
|---|---|---|
| 12.30 🔴 | Typing the name of a tag already on the note → it does NOT appear in suggestions | Filtered out of autocomplete list |
| 12.31 | Submitting the exact name of a tag already on the note → `"Tag already added"` SnackBar | Sheet stays open; no tag added again |

### 12C — Cancellation

| # | Check | Expected |
|---|---|---|
| 12.32 | Submitting an empty input → sheet closes with no change | No tag added; no crash |
| 12.33 | Tapping outside the sheet (backdrop) → sheet closes with no change | Dismiss gesture works |
| 12.34 | Pressing the device back button while sheet is open → sheet closes with no change | No double-pop |

---

## Section 13 — Tags Screen (Phase 7)

> Navigate to this screen via the **Tags** tab (index 2) in the bottom nav.

### 13A — App Bar

| # | Check | Expected |
|---|---|---|
| 13.1 🔴 | Navigating to Tags tab → Tags screen loads without crash | No red error banner |
| 13.2 | `"Tags"` heading: Plus Jakarta Sans 24 sp / weight 800 / letterSpacing −0.5 | Bold, slightly smaller than Home's "Your notes" |
| 13.3 | Subtitle below heading shows `"N tags"` (e.g. `"3 tags"`, `"1 tag"`) | Updates when tags added/deleted |
| 13.4 | Subtitle: Inter 12.5 sp / weight 400 / `onSurfaceMuted` | Small, muted |
| 13.5 | Subtitle reads `"1 tag"` (singular) when exactly 1 tag exists | Correct singular/plural |
| 13.6 | Add button is 40×40 dp, border-radius 14, `primaryContainer` background | Square-rounded button |
| 13.7 | Add button icon is `+` (20 dp, `onPrimaryContainer`) | Dark icon on light purple |
| 13.8 | Add button is right-aligned in the app bar | Top-right area |
| 13.9 | Bottom nav shows Tags tab (index 2) as active | `primaryContainer` pill behind Tags icon + "Tags" label |

### 13B — Empty State

| # | Check | Expected |
|---|---|---|
| 13.10 🔴 | With no tags: empty state shows "No tags yet" heading | Centred on screen |
| 13.11 | Empty state shows hint text below heading | e.g. "Tap + to create your first tag" |
| 13.12 | Empty state does NOT show the outer card | No card with empty rows |

### 13C — Tags List

| # | Check | Expected |
|---|---|---|
| 13.13 🔴 | Tags list wrapped in an outer card: `card` background, 0.5 px `outline` border, border-radius 20, padding 6 | Single card containing all rows |
| 13.14 | Tags are listed in alphabetical order (A → Z) | Sorted by name ascending |
| 13.15 | Each tag row has internal padding: 12 dp vertical, 14 dp horizontal | Comfortable row height |
| 13.16 | Rows separated by a 0.5 px `outline`-coloured horizontal divider | Very thin line between rows |
| 13.17 | **Last row has no bottom divider** | No line after the final tag |

### 13D — Tag Row Anatomy

| # | Check | Expected |
|---|---|---|
| 13.18 | Hash icon container: 36×36 dp, border-radius 12, `chipBg` background | Small square-rounded box |
| 13.19 | Hash `#` icon inside container: 18 dp, `chipText` colour | Purple `#` symbol |
| 13.20 | Tag name: Plus Jakarta Sans 15 sp / weight 700 / `onSurface` / letterSpacing −0.1 | Bold, slightly smaller than card titles |
| 13.21 | Density bar is below the tag name, with 6 dp margin-top | Thin bar, not inline with text |
| 13.22 | Density bar track: height 3 dp, full available width, `surfaceContainer` background, border-radius 2 | Very thin background track |
| 13.23 🔴 | Density bar fill: `primary` colour at 55% opacity | Semi-transparent purple fill |
| 13.24 | Density bar fill width = `(tagNoteCount / maxTagNoteCount) × availableWidth` | Proportional to note count |
| 13.25 | Tag with most notes: density bar fills 100% of track width | Full-width bar |
| 13.26 | Tag with 0 notes: density bar shows no fill (empty track only) | Track visible, no fill |
| 13.27 | If only one tag exists with notes, its bar is 100% wide | Single-tag case |
| 13.28 | If all tags have 0 notes: all bars show empty track | No division-by-zero crash |
| 13.29 | Count badge: Inter 12 sp / weight 600 / `onSurfaceMuted` / padding 4×10 / border-radius 100 / `surfaceContainer` bg | Small pill badge |
| 13.30 | Count badge shows integer count (e.g. `3`) | No decimals |
| 13.31 | Count badge shows `0` for tags not assigned to any note | Zero shown, not blank |
| 13.32 | Chevron icon: 16 dp, `onSurfaceMuted` colour | Right-pointing arrow at end of row |
| 13.33 | Row layout order: [hash container] [name + density bar column, Expanded] [count badge] [chevron] | Correct horizontal arrangement |

### 13E — Density Bar Proportionality

| # | Check | Expected |
|---|---|---|
| 13.34 🔴 | Add note, tag it with `#work` → check Tags screen: `#work` has count 1, bar width at 100% (only tag with notes) | Single-use tag is 100% |
| 13.35 | Add second note, tag it with `#work` and `#travel` → check Tags screen | `#work` count = 2, `#travel` count = 1; `#work` bar wider |
| 13.36 | `#work` bar is exactly 2× the width of `#travel` bar | Strict proportionality |
| 13.37 | Add another note, tag it with `#travel` only → counts: work=2, travel=2 | Both bars are equal width (100%) |
| 13.38 | `#photography` with 0 notes shows count `0` and empty bar while other tags have notes | Zero-count tag handled correctly |
| 13.39 | Density values recalculate when navigating away and back to Tags screen | Stale data not shown |

### 13F — Add Tag Action

| # | Check | Expected |
|---|---|---|
| 13.40 🔴 | Tapping `+` Add button → `"New tag"` AlertDialog appears | Modal dialog with text field |
| 13.41 | Dialog title reads `"New tag"` | Exact string |
| 13.42 | Dialog has a text field with focus | Keyboard opens |
| 13.43 | Submitting (Enter or "Create" button) with non-empty name → dialog closes, tag appears in list | New row added; count 0; empty density bar |
| 13.44 | Submitting an empty name → dialog closes, no tag added | Graceful no-op |
| 13.45 | Tapping Cancel → dialog closes, no tag added | Cancel works |
| 13.46 | New tag name normalised to lowercase | `"FOOD"` stored as `#food` |
| 13.47 | New tag appears with `0` count badge and empty density bar (not yet assigned to any note) | Correct initial state |
| 13.48 | New tag is sorted into the correct alphabetical position in the list | Not appended to bottom |

### 13G — Delete Tag Action

| # | Check | Expected |
|---|---|---|
| 13.49 🔴 | Long-pressing a tag row → confirmation dialog appears | `"Delete '#tagname'?"` title |
| 13.50 | Dialog body text explains the consequence: `"This tag will be removed from all notes."` | Exact or equivalent warning |
| 13.51 | Tapping Cancel → dialog closes, tag unchanged | Safe cancel |
| 13.52 | Tapping Delete (red text) → dialog closes, tag removed from Tags screen list | Row disappears from the list |
| 13.53 🔴 | After deleting a tag → open a note that had that tag; the chip is gone from its tag row | Cascade delete to note |
| 13.54 | After deleting a tag → note card in Note List no longer shows that tag chip | Cascade to card rendering |
| 13.55 | After deleting a tag → Tags screen subtitle count decrements | e.g. "4 tags" → "3 tags" |
| 13.56 | Deleting all tags → Tags screen shows empty state | "No tags yet" returns |

### 13H — Loading & Error States

| # | Check | Expected |
|---|---|---|
| 13.57 | Tags screen loading state: `CircularProgressIndicator` centred | Visible while stream loads |
| 13.58 | Tags screen error state: error message + Retry button | `ref.invalidate(tagListViewModelProvider)` on tap |

---

## Section 14 — Tags: maxTagsPerNote Enforcement (Phase 7)

| # | Check | Expected |
|---|---|---|
| 14.1 🔴 | Note with 19 tags: `"+ tag"` chip is fully opaque and tappable | Normal appearance; sheet opens |
| 14.2 🔴 | Add the 20th tag → `"+ tag"` chip fades to ~40% opacity | Visibly dimmed |
| 14.3 🔴 | Tapping `"+ tag"` at 20 tags → SnackBar: `"Maximum 20 tags per note"` | Sheet does NOT open |
| 14.4 | The SnackBar does not stack if tapped multiple times in quick succession | One SnackBar at a time |
| 14.5 | Removing one tag from a 20-tag note → `"+ tag"` chip returns to full opacity | Chip re-enabled |
| 14.6 | After removing a tag from 20, tapping `"+ tag"` → sheet opens normally | Full functionality restored |
| 14.7 | Note card in list still shows maximum 3 chips even if note has 20 tags | Card chip display unaffected |

---

## Section 15 — Tags: Persistence & Cross-Screen Reactivity (Phase 7)

| # | Check | Expected |
|---|---|---|
| 15.1 🔴 | Add tag to note, force-kill app (`adb shell am force-stop com.modunote.app`), relaunch → tag still on note | Drift `note_tags` join table + `tagIds` column persisted |
| 15.2 🔴 | Create tag via Tags screen, force-kill, relaunch → tag still in Tags screen | `tags` table persisted |
| 15.3 🔴 | Delete tag via Tags screen long-press, force-kill, relaunch → tag gone | Delete committed to DB before app closed |
| 15.4 | Remove tag from note via `×` chip, force-kill, relaunch → tag gone from note but still in Tags screen | Row in `note_tags` deleted; tag row in `tags` table intact |
| 15.5 | Add `#travel` to Note A and Note B → Tags screen shows `#travel` with count 2 | Cross-note count aggregated correctly |
| 15.6 | Remove `#travel` from Note A → Tags screen shows `#travel` with count 1 | Count decrements in real time |
| 15.7 | Open Note Editor, add a tag → immediately switch to Tags screen → new count visible | Stream reactive update without force-refresh |
| 15.8 | Tags screen open, another screen adds a tag → navigate back to Tags screen → count updated | Count recalculated on screen re-mount |
| 15.9 | Tag name is always stored in lowercase; searching by uppercase prefix finds it | `findByName("TRAVEL")` → returns `#travel` |
| 15.10 | Adding the same tag name twice from different notes → only one row in Tags screen | UNIQUE constraint on `tags.name`; same tag shared |

---

## Section 16 — Explore / Search Screen

| # | Check | Expected |
|---|---|---|
| 16.1 🔴 | Navigating to Explore tab → Search screen loads | `"Explore"` heading visible |
| 16.2 | `"Explore"` heading: Plus Jakarta Sans 24/800/`onSurface`/−0.5 | Same style as Tags screen heading |
| 16.3 🔴 | Explore tab active (index 1) in bottom nav | `primaryContainer` pill behind Explore icon + label |
| 16.4 🔴 | Search field on Explore is editable; keyboard auto-focuses | Cursor visible; keyboard appears immediately |
| 16.5 | Empty state before any search: search icon + descriptive text | No results shown yet |
| 16.6 🔴 | Typing a word matching a note title → results appear within ~300 ms | Note cards appear; debounce fires |
| 16.7 🔴 | Typing a word matching note body content → results appear (FTS5 searches both fields) | Body content is searchable |
| 16.8 | Typing a tag name → notes with that tag appear if title/body also contain that word | FTS5 searches title + content only, not tags |
| 16.9 | Typing a non-matching query → `"No notes found"` empty state | Message includes typed query |
| 16.10 | Search is debounced: results appear after typing stops, not on every keystroke | No mid-word result flicker |
| 16.11 | Tapping a result card opens that note in the editor | Correct note loaded |
| 16.12 | Back button on search screen returns to previous tab | Navigation stack correct |
| 16.13 | Archived notes do NOT appear in search results | Only non-archived notes returned |
| 16.14 | `×` clear button appears in search field when text is entered | Tapping × clears field and shows empty state |

---

## Section 17 — Voice Recording: Permission Flow

| # | Check | Expected |
|---|---|---|
| 17.1 🔴 | **Fresh install**: tapping mic button → OS dialog: `"Allow ModuNote to record audio?"` | Android system permission dialog |
| 17.2 🔴 | Tapping `"Allow"` on OS dialog → recording starts immediately | No second tap needed; overlay appears |
| 17.3 🔴 | **Fresh install, deny permission**: tapping `"Deny"` → SnackBar: `"Microphone permission denied"` | No crash; no overlay |
| 17.4 | After denying: tapping mic again → OS dialog may not reappear; SnackBar reappears | OS behaviour; app handles gracefully |
| 17.5 | Revoke permission in device Settings → return to app → tap mic → SnackBar | App gracefully handles revoked permission |
| 17.6 | Grant permission → revoke in Settings → re-grant → mic works again | Permission state re-evaluated on each tap |

---

## Section 18 — Voice Recording: Recording Session

### 18A — Start

| # | Check | Expected |
|---|---|---|
| 18.1 🔴 | Tapping mic on new (unsaved) note: note is auto-saved first | Note ID exists before recording starts |
| 18.2 🔴 | Tapping mic → recording overlay slides up (absolute positioned, left 16, right 16, bottom 8) | Overlay appears above toolbar |
| 18.3 | Overlay background: `card` colour, 1 px `recordRed` border, border-radius 20 | Red-bordered card |
| 18.4 | Overlay casts a red-tinted shadow below it | `rgba(229,72,77,0.35)` glow |
| 18.5 | Overlay padding: 14 dp vertical, 16 dp horizontal | Content has spacing |
| 18.6 🔴 | Mic button in tag row changes to `recordRed` background with white stop square | Red button visible in tag row |
| 18.7 | Mic button red glow effect active during recording | Spread shadow around button |

### 18B — Timer

| # | Check | Expected |
|---|---|---|
| 18.8 🔴 | Timer in overlay starts at `00:00` and counts up every second | `00:01`, `00:02`… |
| 18.9 | Timer format: `MM:SS` with zero-padding | `01:05` not `1:5` |
| 18.10 | Timer continues past 1 minute: `01:00`, `01:01`… | Minute overflow handled |
| 18.11 | Timer: Inter 12/500/`onSurfaceMuted` | Smaller, muted text |
| 18.12 | `"Recording"` label: Plus Jakarta Sans 13/700/`recordRed` | Red bold label left of timer |

### 18C — Waveform Bars

| # | Check | Expected |
|---|---|---|
| 18.13 🔴 | 12 bars visible in the overlay while recording | Distinct vertical bars in a row |
| 18.14 | Bars animate height in response to microphone amplitude | Bars grow when speaking, shrink in silence |
| 18.15 | Bars use `recordRed` colour | Same red as border and label |
| 18.16 | Each bar has 3 dp width, 2 dp gap between bars, border-radius 2 | Consistent appearance |
| 18.17 | In silence: all bars are at minimum height (~4 dp) | Not zero height; always visible |
| 18.18 | While speaking loudly: bars approach maximum height (~24 dp) | Clear visual response |
| 18.19 | Height animation uses 80 ms `AnimatedContainer` — smooth, not jerky | No sudden jumps |

### 18D — Stop Button

| # | Check | Expected |
|---|---|---|
| 18.20 | Stop button: 36×36 dp circle, `recordRed` background | Red circle |
| 18.21 | Stop button: inner 10×10 dp white square, border-radius 2 | Stop icon |
| 18.22 | Stop button pulsing: scales 0.95→1.05 over ~800 ms, repeating | Smooth continuous pulse |
| 18.23 | Stop button glow: 4 dp spread, `recordRed` at 20% opacity | Red halo around button |

---

## Section 19 — Voice Recording: Live Transcription

| # | Check | Expected |
|---|---|---|
| 19.1 🔴 | Speaking while recording → live transcript text appears below the timer row | Partial words appear, update in real time |
| 19.2 | Transcript preview: Inter 11.5/400/`onSurfaceMuted` | Smaller, muted text |
| 19.3 | Transcript preview is single line with ellipsis if text overflows | No multi-line expansion |
| 19.4 | Transcript preview only visible when non-empty | No empty space in silent recording |
| 19.5 | Transcript accumulates across words and phrases as you speak | Text grows; previous words not lost |
| 19.6 🔴 | After 8+ seconds of silence: STT auto-recovers; speaking again continues accumulating | Transcript resumes; no reset to empty |
| 19.7 | Transcript recovery is transparent: timer keeps running during silence | No gap or reset in the overlay |

---

## Section 20 — Voice Recording: Stop & Result

| # | Check | Expected |
|---|---|---|
| 20.1 🔴 | Tapping stop button → recording overlay disappears | Overlay slides away or hides |
| 20.2 🔴 | Mic button returns to idle state (`primaryContainer` background, mic icon) | No longer red |
| 20.3 🔴 | If speech was detected: transcript inserted at Quill cursor position | Words appear in body |
| 20.4 | Inserted transcript is preceded and followed by a newline (`\n`) | Transcript in its own paragraph block |
| 20.5 | If no speech detected: nothing inserted into the editor | Body unchanged |
| 20.6 🔴 | Audio clip chip appears above the tag row | Compact chip row visible |
| 20.7 | Audio clip chip: height 28 dp, pill shape (border-radius 999), `surfaceContainer` background, 0.5 px `outline` border | Consistent with design |
| 20.8 | Chip shows play icon (16 dp) + duration (e.g. `0:08`) + `×` dismiss button | Three elements |
| 20.9 | Duration format: `M:SS` — `0:08`, `1:23` | Correct format |
| 20.10 | Duration is non-zero and approximately matches the speaking time | Stopwatch tracks actual elapsed time |
| 20.11 | Auto-save fires after recording inserts transcript into Quill | Save badge shows "Saving…" then "Saved" |

---

## Section 21 — Voice Recording: Playback & Clip Management

| # | Check | Expected |
|---|---|---|
| 21.1 🔴 | Tapping play icon on clip → audio plays through device speaker | Voice is audible |
| 21.2 | Play icon changes to pause icon while playing | `▶` → `⏸` |
| 21.3 | Tapping pause → playback stops immediately | Silence; icon reverts to `▶` |
| 21.4 | Playback reaches end of clip naturally → icon resets to `▶` | Auto-reset; no manual tap needed |
| 21.5 | Two clips present: tapping play on second while first is playing → first stops, second starts | Only one clip plays at a time |
| 21.6 🔴 | Tapping `×` on clip → chip disappears from row | Removed immediately |
| 21.7 | After `×` dismiss: audio file deleted from device storage | ADB check: file gone from `audio_notes/` |
| 21.8 🔴 | Close and reopen note → clip chips still present | Persisted in `audio_records` Drift table |
| 21.9 | Record multiple clips in one note → all chips appear in horizontal scrollable row | Scroll if too wide to fit |
| 21.10 | Close and reopen note → all multiple clips still present | All persisted |
| 21.11 | Delete one chip from a multi-chip note → remaining chips still present | Only targeted record deleted |
| 21.12 | Audio clips row is hidden when note has no recordings | `SizedBox.shrink()` — no empty row |
| 21.13 | Gap between chips in the row is 6 dp | Consistent spacing |

---

## Section 22 — Voice Recording: Edge Cases

| # | Check | Expected |
|---|---|---|
| 22.1 | Record on a new (never-saved) note → no crash | Note auto-saved before recording starts |
| 22.2 | Start recording, rotate device → no crash | Services survive rotation |
| 22.3 | Start recording, navigate back mid-recording → no crash | `dispose()` called cleanly |
| 22.4 | Record a clip > 1 minute → timer shows `01:xx`, chip shows `1:xx` | Minute overflow handled in both places |
| 22.5 | Record 30-second clip → chip duration reads `0:30` | Timer and chip duration consistent |
| 22.6 | Silent recording (no speech) → chip appears with correct duration, `transcribed_text` is NULL | Audio file saved even without transcript |
| 22.7 | Multiple quick stop/starts: no platform channel error or crash | Each recording session independent |

---

## Section 23 — Data Persistence

| # | Check | Expected |
|---|---|---|
| 23.1 🔴 | Create note, force-kill app, relaunch → note in list | Drift SQLite write committed |
| 23.2 🔴 | Edit note title, back, force-kill, relaunch → updated title shown | Auto-save committed |
| 23.3 🔴 | Add tag to note, force-kill, relaunch → tag chip on note | `note_tags` + `tagIds` column persisted |
| 23.4 🔴 | Record audio, force-kill, relaunch → chip still visible | `audio_records` row persisted |
| 23.5 | Delete audio chip, force-kill, relaunch → chip still gone | DB row + file deleted before kill |
| 23.6 | Create tag via Tags screen, force-kill, relaunch → tag in Tags screen | `tags` row persisted |
| 23.7 | Delete tag, force-kill, relaunch → tag gone | Delete committed |
| 23.8 | Apply bold formatting, back, force-kill, relaunch → bold still applied | Quill Delta JSON persisted in `notes.content` |
| 23.9 | Create 10+ notes → all appear in list after relaunch | No page size limit |

---

## Section 24 — Theme: Light and Dark Mode

| # | Check | Expected |
|---|---|---|
| 24.1 🔴 | Light mode background: `#FEFBFF` | Off-white, not pure white |
| 24.2 🔴 | Dark mode background: `#1C1B2E` | Dark navy, not pure black |
| 24.3 | Light mode card: `#FFFFFF` | Pure white |
| 24.4 | Dark mode card: `#232238` | Slightly lighter than background |
| 24.5 | Light mode `surfaceContainer`: `#F4F0FA` | Used in search field, tag row bg |
| 24.6 | Dark mode `surfaceContainer`: `#2A2942` | Used in search field, tag row bg |
| 24.7 | Light mode primary: `#5B4EFF` | Active tab icon, density bar fill |
| 24.8 | Dark mode primary: `#B7AFFF` | Softer lavender |
| 24.9 | FAB amber `#F59E0B` in both light and dark | Unchanged across themes |
| 24.10 | Light mode recordRed: `#E5484D` | Mic button, recording overlay |
| 24.11 | Dark mode recordRed: `#FF6369` | Slightly brighter |
| 24.12 | Light mode tag chipBg: `#EEEBFF`; chipText: `#3F2FE0` | Light purple chip |
| 24.13 | Dark mode tag chipBg: `#2F2A5E`; chipText: `#B7AFFF` | Dark purple chip |
| 24.14 | Light mode pinTint: `#FFF4D6` (pinned card background) | Warm gold tint |
| 24.15 | Dark mode pinTint: `#3A3320` (pinned card background in dark) | Darker gold |
| 24.16 | Switching OS to dark while app is open → entire app updates instantly | Live theme follow |
| 24.17 | Switching back to light → app reverts immediately | No app restart required |
| 24.18 | Recording overlay adapts to theme (card colour changes) | Red border stays; bg matches theme |

---

## Section 25 — Navigation & Routing

| # | Check | Expected |
|---|---|---|
| 25.1 🔴 | App launches at `/` (NoteListScreen) | Home screen on cold start |
| 25.2 🔴 | FAB → `/note/new` | New note editor (no pre-loaded content) |
| 25.3 🔴 | Tapping a note card → `/note/:id` | Correct note loaded by ID |
| 25.4 🔴 | Back from editor → returns to the screen that launched the editor | No wrong destination |
| 25.5 🔴 | Back button (hardware or ←) in editor → auto-save flushes before pop | No data loss |
| 25.6 | Explore tab → `/search` | Search screen with editable field |
| 25.7 | Tags tab → `/tags` | Tags screen |
| 25.8 | Settings tab → `/settings` | Settings stub screen |
| 25.9 | Device back button on NoteListScreen → app exits (or asks to exit) | No back to a blank state |
| 25.10 | Navigating Home → Editor → back → still on Home | Correct stack |
| 25.11 | Navigating from Explore to a note → back → returns to Explore | Correct origin screen |
| 25.12 | Opening the category picker bottom sheet and pressing back dismisses it | No route pushed; modal dismissed |

---

## Section 26 — Stub Screens (Expected Placeholders)

| # | Check | Expected |
|---|---|---|
| 26.1 ⚠️ STUB | Settings screen loads without crash | Some placeholder content visible |
| 26.2 ~~⚠️ STUB~~ | ~~Tapping category chip → bottom sheet shows `"Category picker — Phase 8"`~~ | ✅ Full picker implemented in Phase 8 — see Section 33 |
| 26.3 ⚠️ STUB | Note editor `⋮` overflow button → tapping does nothing | No crash; no menu |
| 26.4 | Note editor `⋮` does not navigate or pop the screen | Screen stays open |

---

## Section 27 — Edge Cases & Error Handling

| # | Check | Expected |
|---|---|---|
| 27.1 | Note title exactly 200 characters → saves without crash | Limit not enforced in UI; DB stores value |
| 27.2 | Note title with only spaces → stored as empty; shown as "Untitled" in list | Whitespace trimmed or treated as empty |
| 27.3 | Note with emojis in title and body → saves and reloads correctly | UTF-8 handled |
| 27.4 | Note with only rich-text (e.g. bold words, no plain text) → preview shows plain text | Delta stripped of formatting for preview |
| 27.5 | Search query with only spaces → no results, no crash | Empty/whitespace query handled |
| 27.6 | Tap FAB multiple times rapidly → only one editor screen pushed | No duplicate `/note/new` screens |
| 27.7 | Add and remove the same tag to a note twice → no crash; state consistent | Round-trip idempotent |
| 27.8 | Add a tag with only spaces → normalised to empty; should not be added | Blank tag name rejected |
| 27.9 | Add a tag, remove it, add it again → chip reappears, Tags screen count correct | State fully restored |
| 27.10 | Create a tag, add it to 5 notes, delete it from Tags screen → all 5 notes lose the chip | Cascade delete across multiple notes |
| 27.11 | Note with 20 tags: open Tags screen, delete one of those tags → note now has 19 tags (+ tag chip re-enabled) | Cascade + limit re-enabled |
| 27.12 | Open editor, start recording, press back before stopping → no crash or zombie audio process | `dispose()` cleans up services |
| 27.13 | Type in title, switch to body, switch back to title → cursor position preserved | Focus management works |
| 27.14 | Open Tags screen with many tags (20+) → list scrolls smoothly | No jank |
| 27.15 | Create a note, never type anything, go back → no empty note in list | Content-empty note not auto-saved |

---

## Section 28 — Performance

| # | Check | Expected |
|---|---|---|
| 28.1 | Note list with 50+ notes → scrolls without visible frame drops | `ListView` rendering; no jank |
| 28.2 | Typing fast in note editor → no UI freeze; auto-save is delayed | 800 ms debounce prevents blocking |
| 28.3 | Opening a large note (3000+ words) → editor loads in < 2 seconds | Quill loads Delta JSON synchronously |
| 28.4 | App cold start to visible Home screen < 3 seconds | Drift opens lazily on background thread |
| 28.5 | Search results appear within ~300 ms of typing stopping | FTS5 + 300 ms debounce |
| 28.6 | Tags screen with 50 tags → scrolls without frame drops | ListView in outer card |
| 28.7 | Tag autocomplete suggestions appear within ~200 ms of typing | Debounce + prefix search |
| 28.8 | Waveform bars animate at ~12 fps or better without dropping other UI frames | AnimatedContainer 80 ms; amplitude stream |

---

## Section 29 — ADB: Audio File Verification

> Requires USB debugging enabled. App package: `com.modunote.app`.

### 29A — List Audio Files

```bash
adb shell run-as com.modunote.app ls -lh app_flutter/audio_notes/
```

| # | Check | Expected |
|---|---|---|
| 29.1 🔴 | Directory `audio_notes/` exists | No `ls: cannot access` error |
| 29.2 🔴 | At least one `.aac` file present after recording | UUID-named file, e.g. `3f2a8b1c-…-8b.aac` |
| 29.3 | File size is non-zero and proportional to duration | ~20–25 KB for a 5-second clip (32 kbps) |
| 29.4 | After tapping `×` dismiss on a chip: re-run `ls` → file is gone | Physical file deleted |
| 29.5 | File has `.aac` extension | Correct codec container |

### 29B — Pull and Play Audio File

```bash
# Pull one file to PC (replace UUID with actual filename from ls)
adb shell run-as com.modunote.app cat app_flutter/audio_notes/{uuid}.aac > test_clip.aac
```

| # | Check | Expected |
|---|---|---|
| 29.6 | Pulled `.aac` file opens in VLC, Windows Media Player, or macOS QuickTime | Audio is audible and clear |
| 29.7 | Audio is mono, ~16 kHz (check VLC → Tools → Media Information → Codec) | Single channel; 16000 Hz sample rate |
| 29.8 | Audio bitrate ~32 kbps | Low bitrate voice quality; acceptable for notes |

### 29C — Check Total Storage

```bash
adb shell run-as com.modunote.app du -sh app_flutter/audio_notes/
```

| # | Check | Expected |
|---|---|---|
| 29.9 | Size grows after each recording | Accumulates as expected |
| 29.10 | Size shrinks after deleting a clip chip | File removed from count |

---

## Section 30 — ADB: Database Verification

### 30A — Pull the Database

```bash
adb shell run-as com.modunote.app cat databases/modunote.db > modunote_debug.db
```

Open `modunote_debug.db` in [DB Browser for SQLite](https://sqlitebrowser.org/):
File → Open Database → Browse Data tab.

### 30B — `audio_records` Table

| # | Column | Check | Expected |
|---|---|---|---|
| 30.1 🔴 | `id` | UUID v4 format | e.g. `3f2a8b1c-9d4e-4f3a-8e2b-1c9d4e3f2a8b` |
| 30.2 🔴 | `note_id` | Matches `id` in `notes` table | Foreign key valid |
| 30.3 🔴 | `file_path` | Full path ending `.aac` under `audio_notes/` | Absolute path |
| 30.4 🔴 | `duration_ms` | Positive integer; ~seconds × 1000 | 5 s clip → ~5000 |
| 30.5 🔴 | `file_size_bytes` | Positive integer; matches `ls -lh` size | Within ±5% |
| 30.6 | `codec` | `"aac"` | Default value |
| 30.7 | `transcribed_text` | Spoken text (or NULL if silent) | Text or NULL |
| 30.8 | `created_at` | Unix ms timestamp | Large integer; ~now |
| 30.9 | After `×` dismiss: re-pull DB → row absent from `audio_records` | Row deleted |

### 30C — `notes` Table

| # | Column | Check | Expected |
|---|---|---|---|
| 30.10 | `id` | UUID v4 | Valid UUID |
| 30.11 | `title` | Typed title (or empty string) | Exact text |
| 30.12 | `content` | JSON string with `"ops"` key | Valid Quill Delta JSON |
| 30.13 | `tag_ids` | JSON array of tag ID strings | e.g. `["uuid1","uuid2"]` |
| 30.14 | `sync_status` | `"local"` | Default until Phase 10 |
| 30.15 | `is_pinned` | `0` or `1` | Integer boolean |
| 30.16 | `is_archived` | `0` | Not archived by default |
| 30.17 | `updated_at` | Integer timestamp in ms; updates on edit | Increases after each save |

### 30D — `tags` Table

| # | Column | Check | Expected |
|---|---|---|---|
| 30.18 🔴 | `id` | UUID v4 | Valid UUID |
| 30.19 🔴 | `name` | Lowercase; no spaces; no duplicates | e.g. `photography`, `travel` |
| 30.20 | `created_at` | Unix ms timestamp | Valid timestamp |
| 30.21 | After deleting tag from Tags screen: re-pull DB → row absent | Row deleted |

### 30E — `note_tags` Join Table

| # | Column | Check | Expected |
|---|---|---|---|
| 30.22 🔴 | `note_id` | Valid note UUID | References `notes.id` |
| 30.23 🔴 | `tag_id` | Valid tag UUID | References `tags.id` |
| 30.24 | Adding same tag twice to same note → only one row | `InsertMode.insertOrIgnore` applied |
| 30.25 | Removing tag from note via `×` → that `(note_id, tag_id)` row deleted | Cascade remove |
| 30.26 | Deleting tag from Tags screen → all `note_tags` rows with that `tag_id` deleted | Cascade delete |

### 30F — FTS5 Full-Text Search Table

```sql
-- Run in Execute SQL tab
SELECT * FROM notes_fts LIMIT 10;
```

| # | Check | Expected |
|---|---|---|
| 30.27 | `notes_fts` table exists | No error |
| 30.28 | Rows mirror `notes.title` and `notes.content` | Same text content |
| 30.29 | After editing a note: re-pull DB → `notes_fts` row updated | Trigger fired on UPDATE |

---

## Section 31 — ADB: Tag Database Verification (Phase 7)

```sql
-- In DB Browser Execute SQL tab — count notes per tag
SELECT t.name, COUNT(nt.note_id) as note_count
FROM tags t
LEFT JOIN note_tags nt ON t.id = nt.tag_id
GROUP BY t.id
ORDER BY t.name;
```

| # | Check | Expected |
|---|---|---|
| 31.1 🔴 | Query returns one row per tag | All tags in `tags` table represented |
| 31.2 | `note_count` matches the count badge shown in Tags screen | Exact match |
| 31.3 | Tags with no notes show `note_count = 0` | LEFT JOIN returns 0 not NULL |
| 31.4 | After adding tag to a note → re-pull DB → count increments in query | Transactional update confirmed |
| 31.5 | After deleting tag from Tags screen → tag row absent from `tags` | Hard delete confirmed |

```sql
-- Verify denormalised tagIds column on notes table
SELECT id, tag_ids FROM notes WHERE tag_ids != '[]';
```

| # | Check | Expected |
|---|---|---|
| 31.6 🔴 | `tag_ids` column is a valid JSON array | e.g. `["uuid-a","uuid-b"]` |
| 31.7 | IDs in `tag_ids` match rows in `note_tags` for that note | Denormalised and join table in sync |
| 31.8 | After removing a tag from a note via `×`: `tag_ids` array updated | ID removed from array; join row removed |
| 31.9 | After deleting a tag via Tags screen: `tag_ids` on all affected notes updated | ID purged from all note arrays |

---

## Section 32 — STT Transcription Verification

| # | Check | Expected |
|---|---|---|
| 32.1 🔴 | Speak a sentence while recording → transcript appears in overlay | Partial + final results shown |
| 32.2 | Transcript updates word-by-word during speaking | Accumulates in real time |
| 32.3 | Stop recording → transcript inserted at Quill cursor | Preceded and followed by `\n` |
| 32.4 | Transcript in editor matches final overlay text | Identical text |
| 32.5 | Record silence only → nothing inserted into editor | NULL transcript; no text inserted |
| 32.6 | `transcribed_text` in DB (Section 30B check 30.7) matches editor insertion | DB and UI consistent |
| 32.7 🔴 | After 8+ seconds of silence: speak again → transcript continues accumulating | STT timeout recovery (D6.7) active |
| 32.8 | After recovery: previously spoken words still present in transcript | `_accumulated` preserved across restart |

### Logcat Filter (Advanced)

```bash
adb logcat -s flutter
```

| # | Check | Expected |
|---|---|---|
| 32.9 | Recording start logged | Path of `.aac` file in log when mic tapped |
| 32.10 | Recording stop logged with duration | `Duration: NNNNms` in log |
| 32.11 | STT timeout recovery logged | `Status: notListening — restarting` after ~7 s silence |
| 32.12 | Final result events logged | `Result: "spoken text" (final: true)` lines appear |

---

## Section 33 — Category Picker: Sheet UI (Phase 8)

> Access by opening any note in the editor then tapping the **category chip** in the tag row.

### 33A — Sheet Open

| # | Check | Expected |
|---|---|---|
| 33.1 🔴 | Tapping category chip → `MNCategoryPickerSheet` slides up | Bottom sheet opens; no crash |
| 33.2 | Sheet has a grabber (36×4 dp, `outlineStrong` colour, border-radius 2) | Visible at top of sheet |
| 33.3 | Sheet corner radius: 28 dp top-left and top-right | Rounded top corners |
| 33.4 | Sheet header reads `"Move to category"` (PJS 19/800/−0.3) | Bold heading visible |
| 33.5 | Header subtitle reads `"Organise this note in your folder tree"` (Inter 12.5/400/muted) | Smaller muted text |
| 33.6 | Close × button: 34×34 circle, `surfaceContainer` bg, 18 dp icon | Top-right of header |
| 33.7 | Tapping × → sheet dismisses, no category change | Null result; note unchanged |
| 33.8 | Swiping sheet down → sheet dismisses, no category change | Same null result |

### 33B — "None" Row

| # | Check | Expected |
|---|---|---|
| 33.9 🔴 | "None" row is the first item in the list | Above all category rows |
| 33.10 | "None" row has `folder_off_outlined` icon | Folder-with-x icon |
| 33.11 | Tapping "None" → sheet closes | Returns `""` (empty string = unassign) |
| 33.12 🔴 | After tapping "None": category chip in editor shows default/unassigned state | `categoryName == null` |
| 33.13 | When note has no category assigned: "None" row shows a checkmark `✓` | Pre-selected state |
| 33.14 | When note has a category assigned: "None" row has no checkmark | Unselected |

### 33C — Category Tree Rows

| # | Check | Expected |
|---|---|---|
| 33.15 🔴 | Root-level categories appear with no indentation (or base 10 dp left padding) | Not indented |
| 33.16 🔴 | Child categories indented by `10 + depth × 20` dp from left | e.g. depth 1 = 30 dp, depth 2 = 50 dp |
| 33.17 | Category with children shows expand chevron (right-pointing) | `keyboard_arrow_right` icon visible |
| 33.18 | Category without children shows no chevron (spacer instead) | No icon; row still aligns |
| 33.19 🔴 | Tapping expand chevron → children appear below parent | Tree expands inline |
| 33.20 | Tapping chevron again → children collapse | Tree collapses |
| 33.21 | Tapping chevron does NOT select the category | Only the row tap selects |
| 33.22 | Tapping a category row → sheet closes | Returns that category's id |
| 33.23 🔴 | After tapping a category: category chip in editor shows that category's name | `categoryName == category.name` |
| 33.24 | Selected row: `primaryContainer` background + check ✓ icon + bold name + `folder` (filled) icon | Highlighted selection |
| 33.25 | Unselected rows: transparent background + `folder_outlined` icon | Normal appearance |
| 33.26 | When opening sheet for a note with an assigned category: that category row shows checkmark | Pre-selected |
| 33.27 | When opening sheet for a note with an assigned category AND it's nested: ancestor rows are pre-expanded | Selection visible without manual expansion |

### 33D — "New Category" Row

| # | Check | Expected |
|---|---|---|
| 33.28 🔴 | "New category" row is last in the list | Below all category rows |
| 33.29 | Row has a border (1 dp `outlineStrong`), border-radius 14 | Distinct from tree rows |
| 33.30 | Row has amber add button: 26×26 dp, border-radius 8, `accent` background, `+` icon | Small amber square-rounded button |
| 33.31 | When a category is selected in the tree: row shows `"Under · <name>"` hint text | Context hint visible on right |
| 33.32 | When no category is selected: no hint text shown | Right side empty |
| 33.33 🔴 | Tapping "New category" → AlertDialog opens with text field | "New category" dialog title |
| 33.34 | Dialog hint text shows parent context: `"Name (under <parent>)"` if a category is selected; `"Name (at root)"` otherwise | Contextual placeholder |
| 33.35 🔴 | Submitting a name → new category created, tree updates | Category appears in tree |
| 33.36 | New category created under the currently-selected parent (if one is selected) | Adjacency-list parent set correctly |
| 33.37 | New category created at root if no category is selected (or "None" is selected) | `parentId = null` |
| 33.38 | Submitting empty name → dialog closes, nothing created | Graceful no-op |
| 33.39 | Tapping Cancel in dialog → no category created | Cancel works |

### 33E — Sheet Scrolling & Constraints

| # | Check | Expected |
|---|---|---|
| 33.40 | Sheet content area is scrollable when tree has many categories | `ListView` scrolls within `ConstrainedBox(maxHeight: 55% of screen)` |
| 33.41 | Sheet does not exceed 55% of screen height | Content clips cleanly |
| 33.42 | Keyboard safe area respected at bottom | Content not hidden by nav gestures |

---

## Section 34 — Category Picker: Assignment & Persistence (Phase 8)

| # | Check | Expected |
|---|---|---|
| 34.1 🔴 | Assign a category to a note via picker → force-kill app, relaunch, open note → category chip still shows assigned category | `categoryId` committed to `notes` table |
| 34.2 🔴 | Unassign a category ("None") → force-kill, relaunch → category chip shows default | `categoryId = null` persisted |
| 34.3 | Assign category A, then re-open picker and assign category B → note shows B | Category replaced, not appended |
| 34.4 | Note List screen: note card shows no category indication until Phase 9 decides card layout | No card regression |

---

## Section 35 — Category Deletion: Re-Parent Policy (Phase 8)

> Create a small tree to test: Root → A → B (B is child of A). Add notes assigned to A.

| # | Check | Expected |
|---|---|---|
| 35.1 🔴 | Delete category A (which has child B and assigned notes) — child B should now be at root | B appears with no parent (root level) |
| 35.2 🔴 | Notes previously assigned to A → after delete, `categoryId = null` | Notes become Uncategorised |
| 35.3 | Category B's sub-children (if any at depth 2) stay as children of B after A is deleted | Only direct children re-parented; deeper descendants unaffected |
| 35.4 | Force-kill app after deletion, relaunch → re-parent state persisted | DB committed before kill |

### 35A — DB Verification for Category Operations

```sql
-- In DB Browser Execute SQL tab
SELECT id, name, parent_id, sort_order FROM categories ORDER BY parent_id NULLS FIRST, name;
```

| # | Check | Expected |
|---|---|---|
| 35.5 🔴 | After assigning a category to a note: `categories` row exists; `notes.category_id` matches | FK valid |
| 35.6 | After unassigning: `notes.category_id` is NULL | Column nulled |
| 35.7 | After deleting A (which had child B): A row absent; B row has `parent_id = NULL` (was A's parent) | Re-parent committed |
| 35.8 | Notes that had `category_id = A.id` now have `category_id = NULL` | `clearCategoryFromNotes` ran |

---

## Section 36 — Persistent Bottom Nav (Phase 9)

> The shell `_AppShell` renders `MNBottomNav` across all 4 tab routes. Note Editor is outside the shell.

### 36A — Visual Appearance

| # | Check | Expected |
|---|---|---|
| 36.1 🔴 | Bottom nav visible on NoteListScreen without tapping anything | Floating pill persistent at bottom |
| 36.2 🔴 | Bottom nav visible on SearchScreen (Explore tab) | Still present after tab switch |
| 36.3 🔴 | Bottom nav visible on TagsScreen | Still present |
| 36.4 🔴 | Bottom nav visible on SettingsScreen | Still present |
| 36.5 | Bottom nav height: 64 dp | Visible pill height |
| 36.6 | Bottom nav positioned 14 dp above bottom edge of SafeArea | Gap between pill and edge |
| 36.7 | Bottom nav left/right margin: 16 dp | Pill floats, not full-bleed |
| 36.8 | Bottom nav background: `card` colour | `#FFFFFF` light / `#232238` dark |
| 36.9 | Bottom nav border-radius: 32 dp | Fully-rounded pill ends |
| 36.10 | Bottom nav border: 0.5 px `outlineStrong` | Very thin visible border |
| 36.11 | Bottom nav shadow: 6 dp blur | Slight elevation shadow |

### 36B — Active Tab Indicator

| # | Check | Expected |
|---|---|---|
| 36.12 🔴 | Home tab active on launch: `primaryContainer` pill behind home icon + "Home" label | Purple pill, label visible |
| 36.13 🔴 | Active tab label visible (Inter 13/600/+0.1) | Text appears below icon in active tab only |
| 36.14 | Active tab pill: `primaryContainer` bg, border-radius 26 | Rounded pill within the nav bar |
| 36.15 | Active tab icon: `onPrimaryContainer` colour | Dark icon on light-purple pill |
| 36.16 | Inactive tab icons: `onSurfaceVariant` colour | Greyed out icons, no label |
| 36.17 | Exactly one tab is active at a time | No double-highlight edge case |

### 36C — Tab Switching

| # | Check | Expected |
|---|---|---|
| 36.18 🔴 | Tap Explore tab → SearchScreen loads; Explore pill highlights | Nav switches; active indicator moves |
| 36.19 🔴 | Tap Tags tab → TagsScreen loads; Tags pill highlights | Same |
| 36.20 🔴 | Tap Settings tab → SettingsScreen loads; Settings pill highlights | Same |
| 36.21 🔴 | Tap Home tab from any tab → NoteListScreen; Home pill highlights | Same |
| 36.22 | Tapping the already-active tab → no crash or re-navigation | Safe no-op |
| 36.23 | Switching tabs quickly (rapid taps) → no crash | Debounce not required; GoRouter handles it |
| 36.24 | After switching tabs, scroll position in previous tab is NOT preserved | Shell rebuilds child on each tab switch |

### 36D — Shell vs. Push Behaviour

| # | Check | Expected |
|---|---|---|
| 36.25 🔴 | Tap FAB on Home → Note Editor opens full-screen; bottom nav NOT visible | Editor is outside the shell |
| 36.26 🔴 | Press back from Note Editor → returns to Home; bottom nav reappears | Shell resumes |
| 36.27 | Open note from Search results → Note Editor opens; bottom nav NOT visible | Same: editor is outside shell |
| 36.28 | Press back from note opened from Search → returns to Search (Explore tab active) | Correct origin screen |
| 36.29 | Category picker bottom sheet opens over Settings/Home → nav still behind sheet | Sheet is modal overlay, not shell child |

---

## Section 37 — Settings Screen & Theme Tiles (Phase 9)

> Access via the **Settings** tab (rightmost in bottom nav).

### 37A — Screen Layout

| # | Check | Expected |
|---|---|---|
| 37.1 🔴 | Settings tab loads without crash | No red error banner |
| 37.2 🔴 | Settings tab active (index 3) in bottom nav | `primaryContainer` pill behind Settings icon + "Settings" label |
| 37.3 | Screen has no inner Scaffold — shell's Scaffold is the only one | No nested-Scaffold warning in logcat |
| 37.4 | "Settings" heading: Plus Jakarta Sans 24/800/−0.5 | Bold, same size as Tags heading |
| 37.5 | Screen scrollable via ListView | Content scrolls if screen is small |
| 37.6 | ListView bottom padding 150 dp | Content not hidden behind bottom nav |

### 37B — Appearance Card

| # | Check | Expected |
|---|---|---|
| 37.7 🔴 | Appearance card visible below heading | Card with rounded corners |
| 37.8 | Card background: `card` colour (`#FFFFFF` light / `#232238` dark) | Distinct from screen background |
| 37.9 | Card border: 0.5 px `outline` | Very thin border |
| 37.10 | Card border-radius: 22 dp | Noticeably rounded |
| 37.11 | Card padding: 16 dp | Internal spacing |
| 37.12 | Card title: "Appearance" (PJS 15/700/`onSurface`) | Bold section title |
| 37.13 | Card subtitle: "Choose how ModuNote looks on your device." (Inter 12.5/400/`onSurfaceMuted`) | Smaller muted subtitle |

### 37C — Theme Tiles

| # | Check | Expected |
|---|---|---|
| 37.14 🔴 | Two tiles visible side-by-side: "Light" (left) and "Dark" (right) | Equal-width tiles in a Row |
| 37.15 | Tile gap: 10 dp | Small gap between tiles |
| 37.16 | Each tile: border-radius 16 dp | Moderately rounded |
| 37.17 | Each tile: padding `fromLTRB(14, 14, 14, 12)` | Balanced internal spacing |
| 37.18 | **Selected tile**: 2 px `primary` border + `primaryContainer` background | Clear selection indicator |
| 37.19 | **Unselected tile**: 0.5 px `outlineStrong` border + `surfaceContainer` background | Subtler appearance |

### 37D — Mini Preview

| # | Check | Expected |
|---|---|---|
| 37.20 | Each tile has a mini preview at top: height 56 dp, border-radius 10 | Small card preview |
| 37.21 | Light tile mini preview always uses **light card colour** (`#FFFFFF`) as background | Regardless of current app theme |
| 37.22 | Dark tile mini preview always uses **dark card colour** (`#232238`) as background | Always dark background in preview |
| 37.23 | Mini preview has simulated title line + two body lines + amber accent dot | 3 skeleton lines visible |
| 37.24 | Accent dot: 7×7 dp circle, `#F59E0B` amber | Small amber circle in top-right of preview |
| 37.25 | Second body line is shorter than first (60 dp fixed width) | Simulates real note card text wrapping |

### 37E — Tile Row (Icon + Label + Radio Dot)

| # | Check | Expected |
|---|---|---|
| 37.26 | Tile row has: icon (16 dp) + label (PJS 14/700, Expanded) + radio dot (18×18) | Three items in row |
| 37.27 | Light tile icon: `light_mode_outlined` | Sun outline icon |
| 37.28 | Dark tile icon: `dark_mode_outlined` | Moon outline icon |
| 37.29 | **Selected tile**: icon and label use `onPrimaryContainer` colour | Dark colour on light-purple background |
| 37.30 | **Unselected tile**: icon = `onSurfaceVariant`, label = `onSurface` | Standard grey colours |
| 37.31 | **Selected radio dot**: `primary` fill + white 8 dp `Icons.circle` inside | Filled purple circle with white dot |
| 37.32 | **Unselected radio dot**: `outlineStrong` border 1.5 px, transparent fill | Empty circle border |

### 37F — Tile Selection Interaction

| # | Check | Expected |
|---|---|---|
| 37.33 🔴 | Tapping Light tile → Light tile becomes selected (2px border + primaryContainer bg) | Instant visual change |
| 37.34 🔴 | Tapping Dark tile → Dark tile becomes selected | Instant visual change |
| 37.35 🔴 | Tapping Light → entire app theme switches to light mode | All screens update immediately |
| 37.36 🔴 | Tapping Dark → entire app theme switches to dark mode | All screens update immediately |
| 37.37 | When app is in `ThemeMode.system` (default on first launch): **neither tile is selected** | No border highlight on either tile |
| 37.38 | After tapping Light: switching OS to dark mode → app stays light (user override) | Explicit choice overrides system |

---

## Section 38 — Theme Persistence (Phase 9)

| # | Check | Expected |
|---|---|---|
| 38.1 🔴 | Tap Light tile → force-kill app (`adb shell am force-stop com.modunote.app`) → relaunch → Light tile is still selected; app is in light mode | SharedPreferences write confirmed |
| 38.2 🔴 | Tap Dark tile → force-kill → relaunch → Dark tile selected; app is in dark mode | Same for dark mode |
| 38.3 | Fresh install (first launch): neither tile highlighted; app follows OS theme | Default `ThemeMode.system` |
| 38.4 🔴 | Select Dark → relaunch → entire app (Note List, Editor, Tags, Search) renders in dark colours | Theme applied globally on startup |
| 38.5 | Select Light → navigate to Note Editor → editor is in light mode | Theme consistent across all screens |
| 38.6 | Select Dark → open Note Editor → editor in dark mode → go back → Settings tab still shows Dark selected | State persists within session |
| 38.7 | Uninstall app → reinstall → Settings shows neither tile selected (system default) | SharedPreferences cleared on uninstall |

---

## Section 39 — `flutter analyze` Gate

| # | Check | Expected |
|---|---|---|
| 39.1 🔴 | `flutter analyze` returns **`No issues found!`** | Zero errors, zero warnings, zero infos |

Run this before every commit. Do not commit if any issues are reported.

---

## Known Intentional Stubs (Not Bugs)

The following are placeholder implementations for future phases. Do not report as bugs:

| Item | Planned Phase |
|---|---|
| ~~Settings screen is a placeholder~~ | ✅ Full Settings screen shipped in Phase 9 |
| ~~Category picker bottom sheet shows stub text~~ | ✅ Full picker implemented in Phase 8 |
| ~~Bottom nav active-tab highlight is hardcoded per screen~~ | ✅ Persistent `ShellRoute` nav shipped in Phase 9 |
| ~~Theme preference resets on app restart~~ | ✅ SharedPreferences persistence shipped in Phase 9 |
| Note editor `⋮` overflow does nothing | Future |
| `SyncStatus` on notes is always `"local"` | Phase 10 |
| No note deletion or archiving UI | Not yet spec'd |
| Note pin/unpin not exposed in UI | Not yet spec'd |
| Chevron on Tags screen row taps do nothing | Future |

---

## Quick Smoke Test — ~25 min (~65 critical checks)

Run only 🔴 CRITICAL checks after each commit:

```
Section 1:   1.1, 1.2, 1.3
Section 2:   2.6, 2.12
Section 3:   3.1, 3.8, 3.13, 3.14
Section 4:   4.1, 4.7
Section 5:   5.10, 5.14, 5.18, 5.24
Section 6:   6.17
Section 7:   7.4, 7.8, 7.10
Section 8:   8.2
Section 9:   9.8
Section 10:  10.1, 10.7, 10.19
Section 11:  11.1, 11.10, 11.22
Section 12:  12.1, 12.9, 12.11, 12.21, 12.25, 12.30
Section 13:  13.1, 13.13, 13.23, 13.24, 13.49, 13.52, 13.53
Section 14:  14.2, 14.3
Section 15:  15.1, 15.2, 15.4
Section 17:  17.1, 17.2, 17.3
Section 18:  18.2, 18.6, 18.8
Section 19:  19.1, 19.6
Section 20:  20.1, 20.2, 20.3, 20.6
Section 21:  21.1, 21.6, 21.8
Section 23:  23.1, 23.2, 23.3, 23.4
Section 25:  25.1, 25.2, 25.3, 25.5
Section 36:  36.1, 36.12, 36.18, 36.19, 36.20, 36.21, 36.25, 36.26
Section 37:  37.1, 37.2, 37.7, 37.14, 37.33, 37.34, 37.35, 37.36
Section 38:  38.1, 38.2, 38.4
Section 39:  39.1
```

---

## Full Regression — ~2.5 hr

Run all numbered checks in all 39 sections before tagging a release or beginning a new phase.
Pay special attention to Sections 36–38 (Phase 9 Navigation + Theming) and Sections 29–32 (ADB verification).
