# Generated Nocturne icons

Created with the built-in image-generation tool and uploaded through Roblox Studio MCP `upload_image`. Original transparent PNGs are kept here. `manifest.json` records the returned Roblox asset IDs and the row-major control-sheet mapping.

Nine images cover the Nocturne mark and eight categories. `controls.png` covers twenty smaller UI controls in a five-column, four-row atlas. The loader derives the sprite regions from the source dimensions and adjusts them to Roblox's decoded image size. Drawn fallbacks remain visible until images load.

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
