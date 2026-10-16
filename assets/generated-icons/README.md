# Generated Nocturne icons

Created with the built-in image-generation tool and uploaded through Roblox Studio MCP `upload_image`. Original transparent PNGs are kept here. `manifest.json` records the returned Roblox asset IDs and the row-major control-sheet mapping.

`navigation-bold.png` covers the Nocturne mark and eight categories in a three-by-three atlas. `controls.png` provides the small UI controls. `window-controls-bold.png` overrides minimize, close and restore with heavier artwork. `resize-rounded.png` overrides its old grip with one rounded corner and no interior marks. The manifest supports explicit pixel regions to center individual glyphs and exclude neighboring artwork at cell boundaries. The loader adjusts those regions to Roblox's decoded image size. Drawn fallbacks remain visible until images load.

To update the Lua mappings after replacing an image and its uploaded ID:

```sh
python tools/build_icon_assets.py
python tools/bundle.py
```

## Generation prompts

Common direction: production GUI glyphs for a charcoal-glass Roblox interface, pure-white monochrome artwork on a truly transparent background, clean smooth opaque linework, flat vector appearance, rounded caps and joins, consistent medium stroke, no texture, speckles, shadows, black outlines, gradients, glow, words or enclosing tiles. Center each main symbol with balanced margins and a roughly 78% canvas footprint, readable at 20 pixels and tintable with ImageColor3.

Individual subjects:

- Nocturne: an original crescent embracing a four-point north star, with an angular N integrated into the inner moon silhouette.
- Combat: a symmetrical heraldic shield with an upright sword, pointed base, gently sloped shoulders, straight blade and short crossguard.
- Visuals: a symmetric almond-shaped eye with a circular pupil and smooth eyelids.
- World: a geometric globe with two latitude arcs and a centered meridian ellipse.
- Player: a generic avatar with a circular head and clean symmetric shoulders, without facial features.
- Settings: three horizontal adjustment sliders with round knobs alternating left, right and center.
- Configs: a folder containing a document with two short lines, without letters.
- Utilities: a diagonal wrench with an open jaw and a rounded handle.
- Misc: three stacked diamond-shaped layers with evenly spaced contours.

Control-sheet prompt: one transparent GUI sprite atlas in a precise five-column, four-row grid, each glyph centered in its own cell, white uniform rounded strokes, no labels, grid lines, background, texture or shadows. Row 1: bottom-right resize grip, down chevron, check, close X, minimize minus. Row 2: maximize square, search, keyboard, save arrow into tray, load arrow from tray. Row 3: trash, pencil, plus, copy, bell. Row 4: circled info, triangular warning, circled success, palette, four-point sparkle.

Roblox may initially mark new uploads as pending. Upload success and asset-ID assignment do not mean moderation or image processing has completed.

## Bold navigation and rounded-corner revision

Navigation prompt: one transparent three-by-three icon atlas, pure-white opaque geometric symbols, consistent optically bold rounded strokes about 12% of each cell width and an 82% symbol footprint, designed for 18–24 px display. Row 1: crescent/N/star Nocturne mark, shield/sword Combat, eye Visuals. Row 2: globe World, head/shoulders Player, sliders Settings. Row 3: folder/document Configs, wrench Utilities, stacked layers Misc. No labels, enclosing frames, grid lines, glow or texture.

Resize prompt: only one white bottom-right corner bracket on transparency. A horizontal lower stroke bends through a generous quarter-circle into the right vertical stroke, with round end caps. No sharp point, triangle, arrow, diagonal grip strokes, interior marks, parallel lines, dots, background, glow or texture.

## Bold window controls

Generated with the built-in image-generation tool. Uploaded through Studio MCP as `rbxassetid://76947606468272`.

Prompt: Create a production UI icon sprite sheet: transparent PNG, wide 3:1 layout, exactly THREE equal square cells in a single row. Flat pure white crisp geometric icons. Left cell: a bold minus horizontal bar, width 50% of cell, thickness 9% of cell, slightly rounded ends. Middle cell: a bold close X, width and height 50% of cell, each diagonal stroke 9% of cell with slightly rounded caps. Right cell: one bold outlined square restore/maximize icon, outer width and height 50% of cell, border thickness 8% of cell, very slightly rounded corners. Precisely center each glyph in its own square cell with identical generous empty transparent padding. Nothing else. No shadows, no glow, no extra dots, no gradients, no texture, no text, no dividers, no background. Intended for 14px desktop window control buttons: substantial clearly visible strokes.
