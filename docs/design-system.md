# TrapShooterPro design system (Flat Glass · Brand Blue)

Source: the **Flat Glass · Brand Blue** theme (`AppTheme.swift`, `AppComponents.swift` and the font files in the
owner's `Theme-Colors` folder, copied from the Android app's `src/ui/tokens.ts`), applied on 3 Nov 2026 in place of the
earlier black‑and‑white system. Code: `Packages/TrapDesign` (SwiftUI). The `BW*` names stayed so screens did not
change; this document maps them to the theme and records where the app departs from it, and why.

## 1. Principles taken from the theme

- **Five brand colours**: blue `#2596BE`, grey `#666666`, light grey `#EBEAEA`, black and white. Green, amber and red only for real status (the G / Y / R results, errors, delete).
- **One flat background per screen**, no gradients: `#EBEAEA` light, black dark.
- **Glass cards**: a light fill with a 1 pt white edge, 16 pt radius and a blue‑tinted shadow. Glass buttons and icon buttons use the same recipe.
- **Two shadows only**, both tinted rgb(20, 71, 108): `control` (0 4 8, 15 %) and `card` (0 8 16, 20 %).
- **Inter for text** (400 / 500 / 600, never bold), **Bebas Neue for display titles and big numbers**.
- **Radii**: chip 10 · buttons, inputs, icon buttons 12 · cards and panels 16 · dialogs 18 · pills capsule.

## 2. Where the app departs from the theme, and why

| Theme | App | Why |
|---|---|---|
| Filled buttons in `#2596BE` with white text | **Deep blue `#1A6F8E`** (`BW.accentFill`, the theme's own link colour) for primary buttons, selected choices and table headers; `#2596BE` (`BW.accent`) for bars, rules, the current target and chart fills | White on `#2596BE` is 3.4:1; the app keeps text at WCAG AA 4.5:1 (5.7:1 on the deep blue). Owner's decision, 3 Nov. |
| System tint brand blue | `BW.tint`: deep blue in light (5.7:1 on white rows), brand blue in dark (5.0:1 on dark rows) | Form buttons and links are text. |
| Dark surfaces are see‑through | The timer readout and the round‑complete panel stay **black in both appearances** (`BW.panel`), with a faint white edge in dark mode | Owner's decision: white digits on black read best in sun on the range. |
| Glass fill white 55 % with backdrop blur | Opaque `BW.paper` (`#F6F6F6` / `#141414`, the same colour the glass shows on the flat background), no blur | Over one flat colour the blur adds nothing; an opaque fill keeps zebra rows and stacked cards one shade. |
| Delete red `#FF2C2C` | `BW.destructive` `#DC3545` / `#DC2626` | White text needs 4.5:1. |
| Theme status green / red | The existing `success` / `warning` / `danger` sets | Already AA‑checked in light and dark, and the G / Y / R results need amber, which the theme lacks. |
| Text sizes in px | Dynamic Type: every Inter and Bebas style uses `Font.custom(_:size:relativeTo:)` on the theme's scale | Accessibility and App Review. Only the timer readout and the scorecard keep fixed sizes. |
| Feather icons, floating bottom nav | SF Symbols, the system tab bar on iPhone and the black sidebar on iPad | Native navigation. |
| Section titles without rules | Same: `BWSectionLabel` and `BWCardTitle` lost the 2 pt ink rule | Follows the theme. |
| Screen side padding 20 | `BWMetrics.gutter` stays 16 | Seven‑column tables on a phone need the width. |

## 3. Colour tokens

| Token | Role | Light | Dark |
|---|---|---|---|
| `BW.ink` | strongest text: scores, titles, values | `#000000` | `#FFFFFF` |
| `BW.paper` | cards, sheets (opaque glass) | `#F6F6F6` | `#141414` |
| `BW.surface` | page background (`theme.bg`) | `#EBEAEA` | `#000000` |
| `BW.surfaceAlt` | zebra rows, quiet boxes | `#EFEFEF` | `#1F1F1F` |
| `BW.border` | hairlines, dividers | `#E2E1E1` | `#2E2E2E` |
| `BW.borderStrong` | control borders (`theme.outline`) | `#C4C4C4` | `#333333` |
| `BW.glassBorder` | glass edge on cards and buttons | white 85 % | white 16 % |
| `BW.glassFill` | glass buttons and icon buttons | white 60 % | white 8 % |
| `BW.text` | body text | `#000000` | `#FFFFFF` |
| `BW.textSecondary` | field labels, section titles (7.0:1) | `#4D4D4D` | `#D9D9D9` |
| `BW.textMuted` | hints, units (4.8:1 on `surface`) | `#666666` | `#A6A6A6` |
| `BW.accent` | brand blue for non‑text marks | `#2596BE` | `#2596BE` |
| `BW.accentFill` / `BW.onAccent` | filled controls with white text (5.7:1) | `#1A6F8E` / white | same |
| `BW.accentSoft` | pressed and selected highlights | blue 14 % | blue 24 % |
| `BW.tint` | system tint | `#1A6F8E` | `#2596BE` |
| `BW.panel` / `BW.onPanel` | timer readout, round complete, iPad sidebar | black / white | same |
| `BW.panelBorder` | panel edge | none | white 16 % |

Status sets are unchanged, each with foreground, background, border and dot:

| Token | Foreground | Background | Border | Dot |
|---|---|---|---|---|
| `BW.success` | `#065F46` | `#ECFDF5` | `#A7F3D0` | `#10B981` |
| `BW.warning` | `#92400E` | `#FFFBEB` | `#FDE68A` | `#F59E0B` |
| `BW.danger` | `#991B1B` | `#FEF2F2` | `#FECACA` | `#EF4444` |
| `BW.neutral` | text secondary | surface | border | text muted |
| `BW.accentStatus` | white | deep blue | deep blue | white |

In dark mode the status foreground becomes the light border tint and the background becomes the dot colour at 15 % opacity.

Shooting domain mapping (keeps the G / Y / R meaning of the web app):

| Meaning | Token |
|---|---|
| Hit with the first shot (G) | `BW.hitFirst` = success |
| Hit with the second shot (Y) | `BW.hitSecond` = warning |
| Lost (R) | `BW.lost` = danger |
| Delete, NO TARGET | `BW.destructive` `#DC3545` (`#DC2626` dark, for 4.5:1 with white `BW.onDestructive`) |
| Selected direction | `BW.accentStatus` |

## 4. Typography

Fonts live in `Packages/TrapDesign/Sources/TrapDesign/Resources/Fonts` (SIL OFL 1.1, licences beside them) and are
registered by `BWAppearance.install()` in `TrapAppRoot.init`, which also sets the navigation bar titles in Inter
SemiBold. Without registration every style falls back to the system font.

| Theme style | Token | Face, size at default text size |
|---|---|---|
| `type.figure` / `type.hero` | `BWFont.valueLarge`, `BWFont.readout(size:)` | Bebas Neue, tabular digits; the readout is fixed |
| display titles | `.bwDisplay(_:)`, `BWFont.display(_:)` | Bebas Neue × 1.25, uppercase, tracking 1 |
| `type.h1`, `type.title` | `BWFont.heading` | Inter SemiBold 24 |
| `type.subtitle` | `BWFont.subheading` | Inter SemiBold 18 |
| `type.body` | `BWFont.body` | Inter Regular 15 |
| secondary | `BWFont.secondary` | Inter Regular 14 |
| `type.caption` | `BWFont.note` | Inter Regular 13 |
| `type.micro` | `.bwLabel()` | Inter SemiBold 11, uppercase, tracking 0.8 |
| `type.overline` | `BWSectionLabel` | Inter SemiBold 12, uppercase, tracking 0.7, `textSecondary` |
| values (times, ids, table cells) | `BWFont.value(_:weight:)` | Inter with tabular digits |
| buttons (`type.heading`) | `.bwPrimary`, `.bwDestructive` | Inter SemiBold 16; glass buttons Inter Medium 15 |
| any style, fixed | `BWFont.inter(fixed:weight:)`, `BWFont.numeric(fixed:)` | for the printed scorecard |

## 5. Metrics

| Theme | Token |
|---|---|
| spacing 4 / 8 / 12 / 16 / 20 / 24 / 32 / 48 | `BWMetrics.s1 … s12` |
| radius chip 10, control 12, card 16, dialog 18, pill | `radiusSM`, `radiusMD`, `radiusLG`, `radiusXL`, `Capsule` |
| borders 1 px | `hairline` (1.5 `stroke` for pills) |
| 3 px top accent, 4 px left accent (brand blue) | `accentTop`, `accentLeft` |
| touch: control 48, action 44, icon 44 | `controlHeight`, `actionHeight`, `iconButton` |
| `shadow.primary`, `shadow.secondary` | `Shadow.control`, `.card` (and `.raised`), tint `BWMetrics.shadowTint` |
| motion 180 ms cubic‑bezier(0.22, 1, 0.36, 1), press scale 0.98 | `BWMotion.fast`, `pressedScale` |

## 6. Components

| Theme component | SwiftUI |
|---|---|
| `GlassCard` | `.bwCard()` |
| KPI card | `BWKPITile` (card + brand‑blue `.bwAccentTop()`) |
| identity banner | `.bwCard().bwAccentLeading()` |
| `SectionTitle` | `BWSectionLabel`; `BWCardTitle` for Bebas titles |
| field label | `.bwLabel()`, `BWField` |
| `AppBadge`, `StatusBadge` | `BWPill(status:dot:uppercase:)` |
| status dot | `BWStatusDot` |
| `PrimaryButtonStyle` | `.buttonStyle(.bwPrimary)` (deep blue, `control` shadow) |
| `GlassButtonStyle` | `.buttonStyle(.bwSecondary)` |
| destructive | `.buttonStyle(.bwDestructive)` |
| `AppIconButton` (glass) | `.buttonStyle(.bwIcon)` / `onInk: true` on a panel |
| table | `BWTableHeader` (deep blue), `.bwTableRow(index:)` |
| black panel | `BWInkPanel` (`BW.panel`) |

## 7. Breakpoints and iPad

| Window width | `Breakpoint` | Layout | Touch target | Navigation |
|---|---|---|---|---|
| < 600 pt | `.phone` | one column | 44 pt | tab bar |
| 600 to 1099 pt (8" iPad, Split View) | `.tabletSmall` | master‑detail 40 / 60 | 48 pt | sidebar 180 pt or tab bar |
| ≥ 1100 pt (11" and 13" iPad landscape) | `.tabletLarge` | master‑detail 35 / 65, three columns where useful | 48 pt | sidebar 220 pt |

The breakpoint is the window; a split lives in the space it is given. Beside the sidebar, `AdaptiveSplit` puts
master and detail side by side only when the master column gets at least a phone's width (375 pt), so an 8" iPad
and a 13" iPad in portrait show Record and Rounds as one column, as on a phone; `\.splitActive` tells rows whether
to select or push.

`BreakpointReader` at the root publishes `\.breakpoint`; `AdaptiveSplit` lays out master and detail; `BWKeys` holds
the hardware‑keyboard shortcuts (Space start/stop, 1 2 3 directions, G Y R results, N no target, ⌘Z undo, arrows
previous/next, ⌘S save, ⌘E share). Safe areas come from the system; split panes respect the trailing inset.

## 8. Where each screen uses it

- **Record**: range data and conditions in glass cards; the 25‑target entry uses deep‑blue selected directions and status pills for results; the current target in the strip has a brand‑blue frame; the ledger is a `BWTableHeader` table with zebra rows; the round‑complete panel is black.
- **Timer**: the readout in Bebas Neue on the black panel; the level meter fills brand blue past the threshold; audio‑in line in muted text.
- **Rounds**: list rows with a leading accent for the selected round; KPI tiles at the top (rounds, hit rate, average 1st shot).
- **Analysis**: `BWSectionLabel` per dimension, `BWTableHeader` tables, `BWKPITile` overview, brand‑blue trend bars and bullets.
- **Schemes**: deep‑blue header table, 15 machines per scheme.
- **Settings**: grouped cards; destructive actions in `.bwDestructive`.
- **iPad**: `NavigationSplitView` with a black sidebar (`BW.panel`), the active item on deep blue with white text.
- **Scorecard (PNG / PDF)**: white page, deep‑blue header band and table header, Bebas Neue for the brand line and the score, Inter elsewhere with tabular digits.
