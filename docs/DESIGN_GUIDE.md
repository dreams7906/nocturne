# Design guide

Nocturne uses the supplied charcoal glass-panel references: flat square toggles, quiet grey fields, translucent gradient surfaces, white rim highlights and a floating icon dock. Each category opens as a separate draggable, resizable window. The default window transparency is 16%.

![Themes](../preview/themes.svg)

## Surfaces

| Layer | Token | Treatment |
| --- | --- | --- |
| Dock, window, popups | `Backdrop` / `Elevated` | CanvasGroup body, 12–15 px radius, 2 dock / 3 window shadow layers at 3–4% opacity, thin `BorderStrong` edge |
| Section panel | `Surface` | 10 px radius, 1 px `Border` stroke, 2.5% top-lit gradient |
| Fields, idle controls | `Surface2` | 6 px radius; filled-square toggles are 18 px with a 5 px radius, without checks or glow |
| Hover / active pills | `Hover` | Same shape as the control, plus a gloss gradient |

The glass edge is a UIStroke on a frame inset 1 px inside the CanvasGroup, so the CanvasGroup's rounded clipping doesn't cut it off.

## Type

The font is Builder Sans throughout.

| Use | Size | Weight | Token |
| --- | --- | --- | --- |
| Window title | 14 | Bold | `Text` |
| Section title / active section tab | 12 | Bold | `Text` |
| Control labels | 12 | Medium | `TextDim` (`Text` when on or hovered) |
| Values | 12 | SemiBold | `Text` |
| Secondary, footer, hints | 11 | Medium | `TextMuted` |
| Badges, divider labels | 10 | Bold | `Text` / `TextMuted` |

## Spacing

- Window 680 × 520: header 44, tab row 36, footer 28.
- Page padding 12, column gap 10, section gap 10.
- Section header 34, body padding 6 / 12 / 10 / 12, row gap 2.
- Row heights: toggle 24, keybind 26, slider 40, dropdown or input with label 50, button 28, info 24.
- Dock buttons 34 with a 7 gap and 10 padding. Navigation icons are 24 px in the dock and 18 px in category sub-tabs, with heavier source strokes and brighter inactive tint. Each open category gets its own dot.
- Page widths use explicit side margins and a 10 px column gap. The scroll canvas follows the taller column without expanding the horizontal content area.
- InputObject positions stay in the same coordinate space as AbsolutePosition. Popup anchors subtract the overlay's AbsolutePosition before placement.

## Motion

| Preset | Duration | Easing | Used for |
| --- | --- | --- | --- |
| Micro | 80 ms | Quad Out | press-down, slider fill while dragging |
| Fast | 140 ms | Quad Out | hover, color changes, popup close |
| Normal | 220 ms | Quint Out | popups opening, window close |
| Smooth | 320 ms | Quint Out | window open, page switch, dock indicator, theme repaint |
| Slow | 450 ms | Quint Out | dock entrance |

- A new tween on a property replaces the running one (TweenService behaviour), so rapid clicks never stack.
- Window open/close and popup hide are guarded against a late hide after reopening. Minimize/restore changes the render area immediately to avoid a cropped CanvasGroup texture.
- Reduced motion applies values instantly. Animation speed divides every duration.

## Icons

The Nocturne and category icons share a bold three-by-three navigation atlas. Smaller controls share another atlas, and the resize handle uses a separate rounded-corner image with no interior grip marks. All three active images were uploaded through Studio MCP, and `Icons/Assets.luau` maps all 29 names to real asset IDs. ImageColor3 and ImageTransparency follow the active theme and hover states. Atlas regions adapt to Roblox's decoded texture size.

The original 18 × 18 native glyphs remain as loading and failure fallbacks. They use round-capped lines, arcs, circles and rounded rectangles. `tools/export_assets.py` exports the fallback shapes to SVG.

## Accent use

Accent marks state only: a checked toggle fill, the slider fill, the dock dot, the focused field ring, the selected dropdown check, the keybind listening ring and the notification bar. Large areas stay neutral. The default Midnight accent is a soft silver, so the UI reads as monochrome until you pick a color.
