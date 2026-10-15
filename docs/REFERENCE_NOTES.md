# Reference notes

The original screenshots are in `assets/references/`. No ZIP came with the brief, so these notes come from the nine screenshots only. Nocturne borrows their density and finish. It doesn't copy their layout pixel for pixel, and it doesn't copy their feature set.

## What the references do well

- **Floating dock (images 1, 4, 5, 9).** A thin-bordered rounded bar at the top centre with about ten evenly spaced line icons. Active or open windows get a small dot under the icon, inactive icons are heavily dimmed, and a small dark label appears under the hovered icon ("Explorer").
- **Main window (1, 2, 5).** A header reading *brand · Interface · Pro* and a username on the right. Below it sits a row of icon + label tabs, where the active tab is a soft filled pill rather than an underline. The body is two columns of rounded panels with a very small corner radius, and the footer has three parts: online count, a link, and the build date.
- **Sections.** Panel headers double as tabs (*ESP · Crosshair · Misc · Flags*), with the active one bright and the others faded.
- **Controls.** Small softly-squared checkboxes; toggles carry color swatches and key pills on the right; thin sliders with the value right-aligned; full-width dark dropdown fields; tiny round `?` help badges.
- **Dropdowns (3, 7).** An elevated dark list with a rounded highlight on the selected row and a chevron that flips when open.
- **Themes (6, 7).** About a dozen named presets (Midnight, Nord, Mocha, Tokyo Night, Rose Pine…) chosen from a dropdown in the options tab.
- **Configs (8).** A list box, a name field, and Load / Save buttons.

## How Nocturne interprets them

| Reference | Nocturne |
| --- | --- |
| Dock with dots under open windows | Dock with one gliding highlight pill and an accent dot, plus a hover label under the dock |
| Separate player list / explorer windows | One window whose tabs match the dock icons, so each icon is a page |
| Header tabs inside panels | `Tabs = { ... }` on any section |
| Checkboxes with swatches and key pills | `Toggle:AddColorPicker`, `Toggle:AddKeybind`, with conflict-checked keys |
| Options tab with themes and UI elements | Built-in Settings tab: themes, accent, transparency, gloss, blur, scale, motion, notifications, watermark, keybind list |
| Configs tab | Built-in Configs tab with rename, delete and JSON share, plus optional DataStore persistence |
| Watermark pill (156 MS · time · location · name) | Watermark with FPS · ping · session time · display name, single or two row |

## Deliberate differences

- The default accent is soft silver, with layered shadows and a top-lit gloss for a slightly more "glass" finish.
- All controls are original builds on a shared token system, and the icons are drawn in-engine.
- The example content uses ordinary game settings (lock-on, crosshair, lighting, accessibility). It doesn't recreate the aimbot, ESP or executor features shown in the references.
