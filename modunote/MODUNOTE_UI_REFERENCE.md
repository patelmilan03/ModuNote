# MODUNOTE UI Reference

> Derived from `design/components/tokens.jsx`, `frame.jsx`, `screens-a.jsx`, `screens-b.jsx`.
> All values are pixel values from the design source; map to logical pixels / `double` in Flutter.
> Device frame: 412 × 892 logical px (Android).

---

## 1. Design Tokens

### 1.1 Colour — Light Theme

| Token | Hex | Usage |
|---|---|---|
| `bg` / `surface` | `#FEFBFF` | Screen background |
| `card` | `#FFFFFF` | Card, bottom nav, toolbar |
| `surfaceContainer` | `#F4F0FA` | Search field bg, chip pressed state, mini previews |
| `surfaceContainerHigh` | `#EDE8F5` | Elevated containers |
| `primary` | `#5B4EFF` | Active icon, filter chip active bg |
| `primaryContainer` | `#E4E0FF` | Active nav pill, FAB mic idle bg, active chip bg |
| `onPrimaryContainer` | `#1A0F8A` | Text/icon on primaryContainer |
| `accent` | `#F59E0B` | FAB background, pin icon, blockquote left border |
| `accentOn` | `#1C1B2E` | FAB icon/label colour |
| `onSurface` | `#1C1B2E` | Primary text, active icons |
| `onSurfaceVariant` | `#4A4858` | Secondary text, inactive icons |
| `onSurfaceMuted` | `#6F6C7D` | Timestamps, labels, metadata |
| `outline` | `rgba(28,27,46,0.12)` | Card borders, dividers (0.5 px) |
| `outlineStrong` | `rgba(28,27,46,0.22)` | Bottom nav border, outlined chips |
| `pinTint` | `#FFF4D6` | Pinned card background (light) |
| `recordRed` | `#E5484D` | Recording button active, danger actions |
| `chipBg` | `#EEEBFF` | Filled chip background |
| `chipText` | `#3F2FE0` | Filled chip text |
| `frameBorder` | `#CBC9D6` | Device frame stroke |

### 1.2 Colour — Dark Theme

| Token | Hex |
|---|---|
| `bg` / `surface` | `#1C1B2E` |
| `card` | `#232238` |
| `surfaceContainer` | `#2A2942` |
| `surfaceContainerHigh` | `#33324E` |
| `primary` | `#B7AFFF` |
| `primaryContainer` | `#3D33C7` |
| `onPrimaryContainer` | `#E4E0FF` |
| `accent` | `#F59E0B` |
| `accentOn` | `#1C1B2E` |
| `onSurface` | `#EDECF5` |
| `onSurfaceVariant` | `#BDBAD0` |
| `onSurfaceMuted` | `#8A8799` |
| `outline` | `rgba(237,236,245,0.12)` |
| `outlineStrong` | `rgba(237,236,245,0.22)` |
| `pinTint` | `#3A3320` |
| `recordRed` | `#FF6369` |
| `chipBg` | `#2F2A5E` |
| `chipText` | `#B7AFFF` |
| `frameBorder` | `#0F0E1C` |

> Flutter mapping: tokens are already defined as `AppColors` constants in `lib/core/theme/app_colors.dart`. Confirm names match before adding new constants.

### 1.3 Typography

| Role | Font | Size | Weight | Letter spacing |
|---|---|---|---|---|
| Display heading (Home "Your notes") | Plus Jakarta Sans | 26 sp | 800 | −0.6 |
| Screen title (Explore, Tags, Settings) | Plus Jakarta Sans | 24 sp | 800 | −0.5 |
| Editor title in app bar | Plus Jakarta Sans | 17 sp | 700 | −0.2 |
| Card title | Plus Jakarta Sans | 16.5 sp | 700 | −0.2 |
| Section label (PINNED / RECENT) | Inter | 12 sp | 600 | +0.6, UPPERCASE |
| Day-of-week label ("Sunday") | Inter | 12 sp | 500 | +0.4, UPPERCASE |
| Body preview text | Inter | 13.5 sp | 400 | 0 |
| Timestamp / metadata | Inter | 11.5 sp | 500 | 0 |
| Chip label (sm) | Inter | 11 sp | 600 | +0.1 |
| Chip label (md) | Inter | 12.5 sp | 600 | +0.1 |
| Bottom nav label (active only) | Inter | 13 sp | 600 | +0.1 |
| FAB label | Plus Jakarta Sans | 15 sp | 700 | 0 |

---

## 2. Shared Components

### 2.1 MNChip

Pill-shaped label. Two sizes, three variants.

**Sizes**

| Size | Height | Font size |
|---|---|---|
| `sm` | 24 | 11 sp |
| `md` | 30 | 12.5 sp |

**Variants**

| Variant | Background | Border | Text colour |
|---|---|---|---|
| `filled` | `chipBg` | none | `chipText` |
| `outlined` | transparent | 1 px dashed `outlineStrong` | `onSurfaceVariant` |
| `ghost` | transparent | 1 px dashed `outlineStrong` | `onSurfaceVariant` |

**Padding**: `0 12px` (no leading/dismiss); `0 6px` trailing when dismiss present, `8px` leading when icon present.  
**Border radius**: 999 (pill).  
**Dismiss button**: 16×16, circle, `rgba(0,0,0,0.08)` bg, 10 px close icon at strokeWidth 2.5.  
**Leading icon**: 13 px, colour matches text colour at strokeWidth 2.

---

### 2.2 MNSearchField

Tappable affordance on Home; editable on Explore.

| Property | Value |
|---|---|
| Height | 48 |
| Background | `surfaceContainer` |
| Border | 0.5 px `outline` |
| Border radius | 16 |
| Horizontal padding | 16 |
| Gap (icon → text) | 10 |
| Search icon | 20 px, `onSurfaceMuted` |
| Placeholder text | Inter 14.5 sp, weight 400, `onSurfaceMuted` |
| Active text | Inter 14.5 sp, weight 500, `onSurface` |
| Placeholder string | `"Search notes, tags…"` |

On **Home screen**: widget is non-editable. Tap → `context.push(AppRoutes.search)`.  
On **Explore screen**: widget is editable, shows current query string.

---

### 2.3 MNNoteCard

Used on Home and Explore.

| Property | Value |
|---|---|
| Border radius | 20 |
| Padding | 16 top/bottom, 18 left/right |
| Background (unpinned) | `card` |
| Background (pinned, light) | `pinTint` (#FFF4D6) |
| Background (pinned, dark) | `card` (#232238) |
| Border (unpinned) | 0.5 px `outline` |
| Border (pinned) | 0.5 px `rgba(245,158,11,0.35)` |
| Internal gap | 10 (column) |

**Header row** (pin icon + title + timestamp):
- Gap: 8
- Pin icon: `pinSolid`, 14 px, `accent` colour; `marginTop: 3`; shown only when pinned
- Title: Plus Jakarta Sans 16.5 sp / 700 / `onSurface` / lineHeight 1.25 / letterSpacing −0.2; flex-expands
- Timestamp: Inter 11.5 sp / 500 / `onSurfaceMuted`; `marginTop: 2`; shrinks

**Body preview**:
- Inter 13.5 sp / 400 / `onSurfaceVariant` / lineHeight 1.4
- Single line, overflow ellipsis

**Tag row** (shown only when note has tags):
- `marginTop: 2`; flex-wrap row; gap 6
- Up to 3 chips rendered; size `sm`; label `#tagname`

---

### 2.4 MNFab

Amber floating action button.

| Property | Value |
|---|---|
| Position | `absolute`, bottom: 96, right: 20 |
| Size (icon-only) | 56×56 |
| Border radius | 18 |
| Background | `accent` (#F59E0B) |
| Icon | `Icons.add` (`plus`), 26 px, `accentOn`, strokeWidth 2.25 |
| Shadow | `0 6px 16px -4px rgba(245,158,11,0.55), 0 2px 4px rgba(28,27,46,0.12)` |
| On tap | `context.push(AppRoutes.newNote)` |

Extended FAB (with label): height 56, padding `0 22px 0 20px`, gap 10, label Plus Jakarta Sans 15 sp / 700 / `accentOn`.

---

### 2.5 MNBottomNav

Pill-style floating bottom nav.

| Property | Value |
|---|---|
| Position | `absolute`, left: 16, right: 16, bottom: 14 |
| Height | 64 |
| Background | `card` |
| Border | 0.5 px `outlineStrong` |
| Border radius | 32 |
| Padding | 6 (all sides) |
| Shadow (light) | `0 2px 8px rgba(28,27,46,0.04)` |
| Shadow (dark) | `0 2px 8px rgba(0,0,0,0.35)` |

**Tabs** (left to right):

| Index | Id | Icon | Label |
|---|---|---|---|
| 0 | home | `notes` | Home |
| 1 | explore | `explore` | Explore |
| 2 | tags | `tag` | Tags |
| 3 | settings | `settings` | Settings |

**Active tab pill**:
- Background: `primaryContainer`; border radius 26; fills full tab height
- Icon: 20 px, `onPrimaryContainer`, strokeWidth 2
- Label: Inter 13 sp / 600 / `onPrimaryContainer` / letterSpacing +0.1 — visible only on active tab

**Inactive tab**:
- Background: transparent
- Icon: 20 px, `onSurfaceVariant`, strokeWidth 1.75

---

## 3. Screens

### 3.1 Home — Note List (Phase 4)

**Structure** (top to bottom, inside scroll area):

```
StatusBar (40 px, handled by system)
─── App Bar ──────────────────────────────────
  padding: 4px top, 20px H
  Day label: Inter 12 / 500 / onSurfaceMuted / UPPERCASE / +0.4
  "Your notes": Plus Jakarta Sans 26 / 800 / onSurface / −0.6
  Avatar: 42×42 circle, gradient(135° primary→accent), "MA" PJS 14/800 white

─── Search Field ─────────────────────────────
  margin: 16px top, 20px H
  → MNSearchField (non-editable, tap navigates)

─── Section Header: PINNED ───────────────────
  padding: 14px top, 20px H, 4px bottom
  "PINNED" label + hairline divider + count badge
  label: Inter 12 / 600 / onSurfaceMuted / UPPERCASE / +0.6
  divider: flex 1, height 0.5, outline colour
  count: Inter 11 / 500 / onSurfaceMuted
  (hidden when no pinned notes)

─── Pinned Note Cards ────────────────────────
  padding: 10px top, 20px H, 150px bottom
  gap: 10 between cards

─── Section Header: RECENT ───────────────────
  margin: 10px top, −2px bottom (within scroll)
  "RECENT" label + hairline divider (no count badge)
  (hidden when no unpinned notes)

─── Recent Note Cards ────────────────────────
  gap: 10

─── FAB ──────────────────────────────────────
  → MNFab (bottom: 96, right: 20)

─── Bottom Nav ───────────────────────────────
  → MNBottomNav (active: 0)
```

**Loading state**: shimmer skeleton cards (same shape as MNNoteCard).  
**Error state**: message text + "Retry" button that calls `ref.invalidate(noteListViewModelProvider)`.  
**Empty state**: not specified in design; show "No notes yet" centred text + FAB visible.

**Data source**: `noteListViewModelProvider` (Phase 3). Returns `Stream<List<Note>>`. All notes returned are non-archived. UI splits by `note.isPinned`; each section sorted `updatedAt DESC`.

---

### 3.2 Explore — Search Screen

**Structure**:
```
App Bar:
  padding: 4px top, 20px H, 8px bottom
  "Explore": PJS 24 / 800 / onSurface / −0.5

Search Field (editable):
  padding: 8px top, 20px H
  → MNSearchField (editable, shows query)

Filter Chips (horizontal scroll, no scrollbar):
  padding: 14px top, 0px bottom, 0px side → inner 20px H
  height 34 pill chips; gap 8
  Active chip: primary bg, white text, 14px check icon
  Inactive chip: card bg, 0.5px outlineStrong border, onSurfaceVariant text
  fontSize 13 / 600

Results / Empty State:
  padding: 14px top, 20px H, 150px bottom

  Results:
    Count label: Inter 12 / 600 / onSurfaceMuted / UPPERCASE / +0.4 / marginBottom 10
    Cards: MNNoteCard, gap 10

  Empty state:
    140×140 rounded square (br 28), surfaceContainer bg, 0.5px outline border
    Striped pattern overlay (135° diagonal, opacity 0.6)
    48px search icon, onSurfaceMuted
    "No notes found": PJS 18 / 700 / onSurface / −0.3
    Subtitle: Inter 13.5 / 400 / onSurfaceMuted / lineHeight 1.4 / maxWidth 240

Bottom Nav (active: 1)
```

---

### 3.3 Tags Screen

**Structure**:
```
App Bar:
  padding: 4px top, 16px right, 8px bottom, 20px left
  "Tags": PJS 24 / 800 / onSurface / −0.5
  Subtitle: Inter 12.5 / 400 / onSurfaceMuted / marginTop 2
  Add button: 40×40 rounded rect (br 14), primaryContainer bg, 20px plus icon onPrimaryContainer

Tags List:
  padding: 14px top, 20px H, 150px bottom
  Outer card: card bg, 0.5px outline border, br 20, padding 6, column
  Each row:
    padding: 12px V, 14px H
    bottom divider: 0.5px outline (not on last row)
    Hash icon container: 36×36, br 12, chipBg bg → 18px hash icon, chipText
    Tag name: PJS 15 / 700 / onSurface / −0.1
    Density bar: height 3, full width, surfaceContainer track; primary fill at 55% opacity,
      width = (count/maxCount)×100%; br 2; marginTop 6
    Count badge: Inter 12 / 600 / onSurfaceMuted, padding 4×10, br 100, surfaceContainer bg
    Chevron: 16px, onSurfaceMuted

Bottom Nav (active: 2)
```

---

### 3.4 Note Editor Screen

**Structure** (bottom-up, as keyboard pushes layout):
```
App Bar:
  padding: 4px top, 12px H, 8px bottom; gap 6
  Back button: 40×40 circle, 22px back icon onSurface
  Title: PJS 17 / 700 / onSurface / −0.2; flex-expands
  Save badge: Inter 11.5 / 500 / onSurfaceMuted; padding 4×10; br 100; surfaceContainer bg
    Green dot: 6×6 circle, #22c55e
    Text: "Saved"
  More button: 40×40 circle, 22px more icon onSurface

Editor Body:
  padding: 8px top, 20px H, 4px bottom; gap 10; flex-expands
  Section headers in-content: PJS 13 / 700 / primary / UPPERCASE / +0.4
  Body text: Inter 15.5 / lineHeight 1.55 / onSurface
  Checklist item: 20×20 checkbox (br 6), primary fill when checked; check icon 14px white strokeWidth 3
    Unchecked: 1.5px outlineStrong border
    Checked text: onSurfaceMuted, line-through
  Blockquote: padding 10×14; borderLeft 3px accent; bg surfaceContainer; br "0 12 12 0"; italic;
    Inter 13.5 / lineHeight 1.5 / onSurfaceVariant

Tag Row (above toolbar):
  padding: 12px V, 16px H; borderTop 0.5px outline; gap 8; bg: surface colour
  Category chip: height 30, br 10, surfaceContainer bg, 0.5px outline border, padding 0 12px
    folder icon 14px onSurfaceVariant strokeWidth 1.75 + label Inter 12/600/onSurfaceVariant
    + chevronDown 12px onSurfaceMuted
  Tag chips: flex row, gap 6, overflow hidden
    Dismissible sm filled chips (#tagname)
    "+ tag" sm outlined chip
  Mic button: 40×40, br 14
    Idle: primaryContainer bg, 20px mic icon onPrimaryContainer
    Recording: recordRed bg, 14px stop icon white; glow 0 0 0 6px recordRed at 15% opacity

Formatting Toolbar:
  bg card; borderTop 0.5px outline; padding 10×12
  9 tools: bold italic underline h1 h2 bullet numList checklist quote
  Each slot: 34×34, br 10; active (first) gets primaryContainer bg
  Icon: 18px, inactive → onSurfaceVariant strokeWidth 1.75; active → onPrimaryContainer

Recording Overlay (absolute, shown when recording):
  position absolute; left/right 16; bottom 8
  bg card; 1px recordRed border; br 20; padding 14×16; gap 12
  Shadow: 0 10px 30px -8px rgba(229,72,77,0.35)
  Stop button: 36×36 circle, recordRed bg; glow 0 0 0 4px recordRed at 20%; pulsing
    Inner square: 10×10, br 2, white
  Label "Recording": PJS 13/700/recordRed; timer Inter 12/500/onSurfaceMuted
  Waveform: row of bars; played bars = recordRed, remaining = outlineStrong
```

---

### 3.5 Category Picker (Bottom Sheet)

```
Backdrop: dim overlay (light rgba(28,27,46,0.35) / dark rgba(0,0,0,0.55)) + blurred editor behind

Sheet:
  position absolute; left 0, right 0, bottom 0
  bg card; borderTopRadius 28; padding 12px top, 24px bottom
  Shadow: 0 -20px 40px -10px rgba(0,0,0,0.25)

Grabber: 36×4, br 2, outlineStrong; centred; paddingBottom 12

Header (padding 0 20px, pb 12):
  Title: PJS 19 / 800 / onSurface / −0.3 → "Move to category"
  Subtitle: Inter 12.5 / onSurfaceMuted / marginTop 2 → "Organize this note in your folder tree"
  Close button: 34×34 circle, surfaceContainer bg, 18px close icon onSurfaceVariant

Tree rows (padding 0 12px):
  Each row: padding 10px V; paddingLeft = 10 + (depth × 20)
  Border radius: 14
  Selected row bg: primaryContainer
  Expand chevron: chevronDown (expanded) / chevron (collapsed) / spacer (leaf); 14px, onSurfaceVariant
  Folder icon: 18px, selected → onPrimaryContainer; unselected → primary; strokeWidth 1.75
  Label: PJS 14.5 / 700 (selected) or 600 / selected → onPrimaryContainer; unselected → onSurface / −0.1
  Check icon (selected only): 18px, onPrimaryContainer, strokeWidth 2.5

"New category" row (marginTop 8):
  br 14; 1px dashed outlineStrong border; padding 12×14; gap 10
  Icon container: 26×26, br 8, accent bg → 16px plus icon, accentOn, strokeWidth 2.5
  Label: PJS 14 / 700 / onSurface
  Context hint: Inter 12 / onSurfaceMuted → "Under · YouTube"
```

---

### 3.6 Settings Screen

```
App Bar:
  padding: 4px top, 20px H, 8px bottom
  "Settings": PJS 24 / 800 / onSurface / −0.5

Sections (padding 8px top, 20px H, 150px bottom, gap 16):

Appearance card (bg card, 0.5px outline, br 22, padding 16):
  Section title: PJS 15 / 700 / onSurface / marginBottom 4
  Subtitle: Inter 12.5 / onSurfaceMuted / marginBottom 14
  Two option tiles (flex row, gap 10):
    Selected: 2px primary border, primaryContainer bg
    Unselected: 0.5px outlineStrong border, surfaceContainer bg
    br 16; padding 14px top, 14px H, 12px bottom
    Mini preview (height 56, br 10): simulated note lines + colour dots
    Label row: icon 16px + PJS 14/700 + radio button 18×18

SettingsRow (used in Storage and About cards):
  padding: 12px V, 18px H; borderTop 0.5px outline
  Icon container: 34×34, br 10, surfaceContainer bg (danger: rgba(229,72,77,0.12))
    Icon: 17px, onSurfaceVariant (danger: recordRed), strokeWidth 1.75
  Label: Inter 14 / 600 / onSurface (danger: recordRed)
  Subtitle: Inter 12 / onSurfaceMuted / marginTop 1
  Meta text: Inter 12.5 / 500 / onSurfaceMuted
  Action pill: padding 6×12, br 100, rgba(229,72,77,0.1) bg, Inter 12/700/recordRed
  Chevron: 16px, onSurfaceMuted

Bottom Nav (active: 3)
```

---

## 4. Flutter Implementation Notes

- All border widths that are `0.5px` in the spec → use `BorderSide(width: 0.5)` in Flutter.
- `borderRadius: 999` (pill) → `BorderRadius.circular(999)` or `StadiumBorder`.
- `position: absolute` → `Stack` + `Positioned`.
- `flex: 1` in a row → `Expanded` widget.
- Shadows with multiple layers → `BoxDecoration(boxShadow: [...])`.
- Bottom nav is absolute-positioned at `bottom: 14`, left/right 16; implement as `Stack` child in the scaffold body.
- The `150px` bottom padding in scroll areas gives clearance for the floating bottom nav + FAB.
- Font families are already registered in `app_typography.dart`; use `AppTypography.*` constants — do not hardcode font strings.
- Colour tokens are already in `AppColors` — confirm exact constant names before referencing.

---

## 5. Phase 4 Specific Decisions (pre-approved, from DECISIONS.md)

| Decision | Value |
|---|---|
| D4.1 Data source | `noteListViewModelProvider` — `AsyncValue<List<Note>>` via `build()` returning `Stream<List<Note>>` |
| D4.2 Two-section split | Pinned notes (`isPinned == true`), then Recent (`isPinned == false`); each section sorted `updatedAt DESC` |
| D4.3 Section header visibility | Show header only when that section is non-empty |
| D4.4 Loading state | Shimmer skeleton cards matching MNNoteCard shape |
| D4.5 Error state | Error message + Retry button calling `ref.invalidate(noteListViewModelProvider)` |
| D4.6 Widget type | `MNNoteCard extends StatelessWidget` (purely presentational); screen extends `ConsumerWidget` |
